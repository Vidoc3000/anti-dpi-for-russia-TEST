package ru.antidpi.mobile;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.graphics.drawable.Icon;
import android.content.Context;
import android.content.Intent;
import android.net.VpnService;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.ParcelFileDescriptor;
import android.util.Log;

import java.util.Arrays;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/** Runs the no-root TUN -> gVisor -> native ByeDPI datapath as a foreground VPN service. */
public final class AntiDpiVpnService extends VpnService {
    static final String ACTION_START = "ru.antidpi.mobile.START_VPN";
    static final String ACTION_STOP = "ru.antidpi.mobile.STOP_VPN";
    static final String EXTRA_STRATEGY = "strategy";
    static final String EXTRA_PROFILE_ARGS = "profile_args";
    static final String EXTRA_BLOCK_QUIC = "block_quic";
    static final String EXTRA_MTU = "mtu";
    static final String EXTRA_DNS_SERVERS = "dns_servers";
    static final String EXTRA_ALLOWED_APPS = "allowed_apps";
    static final String EXTRA_FORCE_RESTART = "force_restart";
    private static final String TAG = "AntiDpiVpnService";
    private static final String CHANNEL_ID = "antidpi_vpn";
    private static final int NOTIFICATION_ID = 412;
    private static final String PREFS = "vpn_state";

    private ParcelFileDescriptor tun;
    private AndroidPacketEngine engine;
    private NativeByedpiProxy nativeProxy;
    private String activeStrategy;
    private boolean activeBlockQuic;
    private int activeMtu;
    private String[] activeDnsServers;
    private String[] activeAllowedApps;
    private final ExecutorService startupExecutor = Executors.newSingleThreadExecutor(runnable -> {
        Thread thread = new Thread(runnable, "AntiDpi-VpnStartup");
        thread.setDaemon(true);
        return thread;
    });
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private final Runnable statsUpdater = new Runnable() {
        @Override public void run() {
            if (engine == null) return;
            String stats = engine.tunnelStats();
            android.content.SharedPreferences prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE);
            if (!stats.equals(prefs.getString("traffic_stats", ""))) {
                prefs.edit().putString("traffic_stats", stats).apply();
            }
            mainHandler.postDelayed(this, 1000);
        }
    };
    private volatile int startupGeneration;
    private boolean starting;

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && ACTION_STOP.equals(intent.getAction())) {
            stopVpn();
            return START_NOT_STICKY;
        }
        if (intent == null && engine != null) {
            startForegroundCompat(buildNotification("Подключено"));
            return START_STICKY;
        }
        try {
            ensureNotificationChannel();
            startForegroundCompat(buildNotification(engine == null ? "Запуск VPN…" : "Перезапуск VPN…"));
        } catch (RuntimeException | LinkageError error) {
            Log.e(TAG, "Could not enter foreground service state", error);
            fail("Android не разрешил запустить VPN-службу: " + safeMessage(error));
            return START_NOT_STICKY;
        }

        String strategy = intent == null ? "tlsrec:sni" : intent.getStringExtra(EXTRA_STRATEGY);
        if (strategy == null || strategy.isEmpty()) strategy = "tlsrec:sni";
        boolean blockQuic = intent == null || intent.getBooleanExtra(EXTRA_BLOCK_QUIC, true);
        String profileArgs = intent == null ? "[]" : intent.getStringExtra(EXTRA_PROFILE_ARGS);
        if (profileArgs == null) profileArgs = "[]";
        int mtu = intent == null ? 1500 : intent.getIntExtra(EXTRA_MTU, 1500);
        String[] dnsServers = intent == null ? new String[]{"1.1.1.1", "1.0.0.1"}
                : intent.getStringArrayExtra(EXTRA_DNS_SERVERS);
        if (dnsServers == null || dnsServers.length == 0) dnsServers = new String[]{"1.1.1.1", "1.0.0.1"};
        String[] allowedApps = intent == null ? new String[0] : intent.getStringArrayExtra(EXTRA_ALLOWED_APPS);
        if (allowedApps == null) allowedApps = new String[0];
        boolean forceRestart = intent != null && intent.getBooleanExtra(EXTRA_FORCE_RESTART, false);
        if (engine != null) {
            if (!ACTION_START.equals(intent.getAction())) return START_STICKY;
            if (!forceRestart && strategy.equals(activeStrategy) && blockQuic == activeBlockQuic
                    && mtu == activeMtu && Arrays.equals(dnsServers, activeDnsServers)
                    && Arrays.equals(allowedApps, activeAllowedApps)) {
                startForegroundCompat(buildNotification("Защита включена"));
                return START_STICKY;
            }
            cleanup();
            setState(false, "Перезапуск VPN с новой стратегией");
        } else {
            setState(false, "Подготовка VPN");
        }

        if (!AndroidPacketEngine.isReady()) {
            fail("Встроенный DPI-движок не загружен. Пересоберите APK с Android engine.");
            return START_NOT_STICKY;
        }

        int generation = ++startupGeneration;
        starting = true;
        setState(false, "Подготовка VPN");
        final String requestedStrategy = strategy;
        final String requestedProfileArgs = profileArgs;
        final boolean requestedBlockQuic = blockQuic;
        final int requestedMtu = mtu;
        final String[] requestedDnsServers = dnsServers.clone();
        final String[] requestedAllowedApps = allowedApps.clone();
        startupExecutor.execute(() -> startInBackground(generation, startId, requestedStrategy,
                requestedProfileArgs, requestedBlockQuic, requestedMtu, requestedDnsServers,
                requestedAllowedApps));
        return START_STICKY;
    }

    private void startInBackground(int generation, int startId, String strategy, String profileArgs,
                                   boolean blockQuic, int mtu, String[] dnsServers, String[] allowedApps) {
        ParcelFileDescriptor startedTun = null;
        AndroidPacketEngine startedEngine = null;
        NativeByedpiProxy startedProxy = null;
        String startupStage = "создания TUN";
        try {
            if (generation != startupGeneration) throw new InterruptedException("Запуск отменён");
            startedTun = establishTun(mtu, dnsServers, allowedApps);
            if (startedTun == null) throw new IllegalStateException("Android отказал в создании VPN-интерфейса");
            if (generation != startupGeneration) throw new InterruptedException("Запуск отменён");

            startupStage = "запуска native ByeDPI";
            startedEngine = AndroidPacketEngine.create(getApplicationContext(), this,
                    () -> Log.d(TAG, "native engine log callback"));
            startedProxy = new NativeByedpiProxy();
            startedProxy.start(AndroidPacketEngine.nativeProfileArgs(profileArgs));
            if (generation != startupGeneration) throw new InterruptedException("Запуск отменён");

            startupStage = "подключения TUN к движку";
            startedEngine.startTunnelViaProxy(startedTun, mtu,
                    "127.0.0.1:" + startedProxy.port(), blockQuic);

            ParcelFileDescriptor completedTun = startedTun;
            AndroidPacketEngine completedEngine = startedEngine;
            NativeByedpiProxy completedProxy = startedProxy;
            mainHandler.post(() -> {
                if (generation != startupGeneration) {
                    stopComponents(completedEngine, completedProxy, completedTun);
                    return;
                }
                tun = completedTun;
                engine = completedEngine;
                nativeProxy = completedProxy;
                activeStrategy = strategy;
                activeBlockQuic = blockQuic;
                activeMtu = mtu;
                activeDnsServers = dnsServers.clone();
                activeAllowedApps = allowedApps.clone();
                starting = false;
                setState(true, "VPN активен · native ByeDPI · " + strategy + (blockQuic ? " · QUIC блокируется" : ""));
                mainHandler.removeCallbacks(statsUpdater);
                mainHandler.post(statsUpdater);
                try {
                    startForegroundCompat(buildNotification("Защита включена"));
                    Log.i(TAG, "VPN started; strategy=" + strategy + ", blockQuic=" + blockQuic);
                } catch (RuntimeException | LinkageError error) {
                    Log.e(TAG, "Failed to update VPN foreground notification", error);
                    fail("Android не разрешил показать VPN-службу: " + safeMessage(error));
                }
            });
            startedTun = null;
            startedEngine = null;
            startedProxy = null;
        } catch (Exception | LinkageError error) {
            Log.e(TAG, "Failed to start VPN", error);
            stopComponents(startedEngine, startedProxy, startedTun);
            if (!(error instanceof InterruptedException)) {
                String message = "Не удалось запустить VPN на этапе " + startupStage + ": " + safeMessage(error);
                mainHandler.post(() -> {
                    if (generation != startupGeneration) return;
                    starting = false;
                    setState(false, message);
                    stopForegroundCompat();
                    stopSelfResult(startId);
                });
            }
        }
    }

    private ParcelFileDescriptor establishTun(int mtu, String[] dnsServers, String[] allowedApps) throws Exception {
        if (mtu < 1280 || mtu > 1500) throw new IllegalArgumentException("MTU должно быть от 1280 до 1500");
        Builder builder = new Builder()
                .setSession(getString(R.string.app_name))
                .setMtu(mtu)
                .addAddress("10.111.222.1", 32)
                .addAddress("fd00:0:0:beef::1", 128)
                .addRoute("0.0.0.0", 0)
                .addRoute("::", 0);
        for (String dns : dnsServers) builder.addDnsServer(dns);

        // Allow-list routing keeps the VPN app itself outside the tunnel. With no
        // valid selected apps, all apps except this UID are routed as before.
        int addedApps = 0;
        if (allowedApps != null) {
            for (String packageName : allowedApps) {
                if (packageName == null || packageName.isEmpty() || getPackageName().equals(packageName)) continue;
                try {
                    builder.addAllowedApplication(packageName);
                    addedApps++;
                } catch (android.content.pm.PackageManager.NameNotFoundException error) {
                    Log.w(TAG, "Ignoring unavailable selected app " + packageName);
                }
            }
        }
        if (addedApps == 0) builder.addDisallowedApplication(getPackageName());
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) builder.setMetered(false);
        Log.i(TAG, "Creating TUN: mtu=" + mtu + ", dns=" + Arrays.toString(dnsServers)
                + ", app routing=" + (addedApps == 0 ? "all apps" : addedApps + " selected apps"));
        return builder.establish();
    }

    private void stopVpn() {
        startupGeneration++;
        starting = false;
        cleanup();
        setState(false, "VPN остановлен");
        stopForegroundCompat();
        stopSelf();
    }

    private void fail(String message) {
        startupGeneration++;
        starting = false;
        cleanup();
        setState(false, message);
        stopForegroundCompat();
        stopSelf();
    }

    private void stopComponents(AndroidPacketEngine targetEngine, NativeByedpiProxy targetProxy,
                                ParcelFileDescriptor targetTun) {
        if (targetEngine != null) {
            try { targetEngine.stop(); } catch (RuntimeException error) { Log.w(TAG, "Engine stop failed", error); }
        }
        if (targetProxy != null) {
            try { targetProxy.stop(); } catch (RuntimeException error) { Log.w(TAG, "Native proxy stop failed", error); }
        }
        if (targetTun != null) {
            try { targetTun.close(); } catch (Exception error) { Log.w(TAG, "TUN close failed", error); }
        }
    }

    private void cleanup() {
        mainHandler.removeCallbacks(statsUpdater);
        if (engine != null) {
            try { engine.stop(); } catch (RuntimeException error) { Log.w(TAG, "Engine stop failed", error); }
            engine = null;
        }
        if (nativeProxy != null) {
            try { nativeProxy.stop(); } catch (RuntimeException error) { Log.w(TAG, "Native proxy stop failed", error); }
            nativeProxy = null;
        }
        if (tun != null) {
            try { tun.close(); } catch (Exception error) { Log.w(TAG, "TUN close failed", error); }
            tun = null;
        }
        activeStrategy = null;
        activeBlockQuic = false;
        activeMtu = 0;
        activeDnsServers = null;
        activeAllowedApps = null;
    }

    @Override
    public void onRevoke() {
        Log.w(TAG, "VPN permission revoked by system");
        stopVpn();
        super.onRevoke();
    }

    @Override
    public void onDestroy() {
        startupGeneration++;
        starting = false;
        startupExecutor.shutdownNow();
        cleanup();
        setState(false, "VPN остановлен");
        super.onDestroy();
    }

    private void ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager.getNotificationChannel(CHANNEL_ID) == null) {
                manager.createNotificationChannel(new NotificationChannel(
                        CHANNEL_ID, "AntiDPI VPN", NotificationManager.IMPORTANCE_LOW));
            }
        }
    }

    private Notification buildNotification(String status) {
        Intent open = new Intent(this, MainActivity.class);
        PendingIntent contentIntent = PendingIntent.getActivity(this, 0, open,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        Intent stop = new Intent(this, AntiDpiVpnService.class).setAction(ACTION_STOP);
        PendingIntent stopIntent = PendingIntent.getService(this, 1, stop,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        Notification.Builder builder = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                ? new Notification.Builder(this, CHANNEL_ID) : new Notification.Builder(this);
        builder.setSmallIcon(android.R.drawable.stat_sys_warning)
                .setContentTitle(getString(R.string.app_name))
                .setContentText(status)
                .setOngoing(true)
                .setCategory(Notification.CATEGORY_SERVICE)
                .setContentIntent(contentIntent)
                .addAction(new Notification.Action.Builder(
                        Icon.createWithResource(this, android.R.drawable.ic_media_pause),
                        "Остановить", stopIntent).build());
        return builder.build();
    }

    private void startForegroundCompat(Notification notification) {
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(NOTIFICATION_ID, notification,
                    android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE);
        } else {
            startForeground(NOTIFICATION_ID, notification);
        }
    }

    private void stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) stopForeground(STOP_FOREGROUND_REMOVE);
        else {
            //noinspection deprecation
            stopForeground(true);
        }
    }

    private void setState(boolean active, String message) {
        int port = active && nativeProxy != null ? nativeProxy.port() : 0;
        boolean isStarting = !active && ("Подготовка VPN".equals(message)
                || message.startsWith("Перезапуск VPN"));
        getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putBoolean("active", active).putBoolean("starting", isStarting)
                .putString("message", message).putInt("proxy_port", port).apply();
    }

    static boolean isRunning(Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getBoolean("active", false);
    }

    static String stateMessage(Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString("message", "VPN выключен");
    }

    static boolean isStarting(Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getBoolean("starting", false);
    }

    static int proxyPort(Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getInt("proxy_port", 0);
    }

    static String trafficStats(Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString("traffic_stats", "No TUN traffic stats yet");
    }

    static void stop(Context context) {
        context.startService(new Intent(context, AntiDpiVpnService.class).setAction(ACTION_STOP));
    }

    private static String safeMessage(Throwable error) {
        String value = error.getMessage();
        if (value == null || value.trim().isEmpty()) value = error.getClass().getSimpleName();
        return value.length() > 180 ? value.substring(0, 180) : value;
    }
}
