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
import android.os.ParcelFileDescriptor;
import android.util.Log;

/** Runs the no-root TUN -> gVisor -> protected socket datapath as a foreground VPN service. */
public final class AntiDpiVpnService extends VpnService {
    static final String ACTION_START = "ru.antidpi.mobile.START_VPN";
    static final String ACTION_STOP = "ru.antidpi.mobile.STOP_VPN";
    static final String EXTRA_STRATEGY = "strategy";
    static final String EXTRA_BLOCK_QUIC = "block_quic";
    private static final String TAG = "AntiDpiVpnService";
    private static final String CHANNEL_ID = "antidpi_vpn";
    private static final int NOTIFICATION_ID = 412;
    private static final int MTU = 1500;
    private static final String PREFS = "vpn_state";

    private ParcelFileDescriptor tun;
    private AndroidPacketEngine engine;

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && ACTION_STOP.equals(intent.getAction())) {
            stopVpn();
            return START_NOT_STICKY;
        }
        if (engine != null) {
            startForegroundCompat(buildNotification("Подключено"));
            return START_STICKY;
        }
        ensureNotificationChannel();
        startForegroundCompat(buildNotification("Запуск VPN…"));
        setState(false, "Подготовка VPN");

        if (!AndroidPacketEngine.isReady()) {
            fail("Встроенный DPI-движок не загружен. Пересоберите APK с Android engine.");
            return START_NOT_STICKY;
        }

        try {
            String strategy = intent == null ? "tlsrec:sni" :
                    intent.getStringExtra(EXTRA_STRATEGY);
            if (strategy == null || strategy.isEmpty()) strategy = "tlsrec:sni";
            boolean blockQuic = intent == null || intent.getBooleanExtra(EXTRA_BLOCK_QUIC, true);
            tun = establishTun();
            if (tun == null) throw new IllegalStateException("Android отказал в создании VPN-интерфейса");

            engine = AndroidPacketEngine.create(getApplicationContext(), this,
                    () -> Log.d(TAG, "native engine log callback"));
            engine.startTunnel(tun, MTU, strategy, blockQuic);
            setState(true, "VPN активен · " + strategy + (blockQuic ? " · QUIC блокируется" : ""));
            startForegroundCompat(buildNotification("Защита включена"));
            Log.i(TAG, "VPN started; strategy=" + strategy + ", blockQuic=" + blockQuic);
            return START_STICKY;
        } catch (Exception | LinkageError error) {
            Log.e(TAG, "Failed to start VPN", error);
            fail("Не удалось запустить движок: " + safeMessage(error));
            return START_NOT_STICKY;
        }
    }

    private ParcelFileDescriptor establishTun() throws Exception {
        Builder builder = new Builder()
                .setSession(getString(R.string.app_name))
                .setMtu(MTU)
                .addAddress("10.111.222.1", 32)
                .addAddress("fd00:0:0:beef::1", 128)
                .addRoute("0.0.0.0", 0)
                .addRoute("::", 0)
                .addDnsServer("1.1.1.1")
                .addDnsServer("1.0.0.1")
                .addDnsServer("2606:4700:4700::1111");
        // App-owned upstream sockets are additionally protected one-by-one from the VPN.
        builder.addDisallowedApplication(getPackageName());
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) builder.setMetered(false);
        return builder.establish();
    }

    private void stopVpn() {
        cleanup();
        setState(false, "VPN остановлен");
        stopForegroundCompat();
        stopSelf();
    }

    private void fail(String message) {
        cleanup();
        setState(false, message);
        stopForegroundCompat();
        stopSelf();
    }

    private void cleanup() {
        if (engine != null) {
            try { engine.stop(); } catch (RuntimeException error) { Log.w(TAG, "Engine stop failed", error); }
            engine = null;
        }
        if (tun != null) {
            try { tun.close(); } catch (Exception error) { Log.w(TAG, "TUN close failed", error); }
            tun = null;
        }
    }

    @Override
    public void onRevoke() {
        Log.w(TAG, "VPN permission revoked by system");
        stopVpn();
        super.onRevoke();
    }

    @Override
    public void onDestroy() {
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
        getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putBoolean("active", active).putString("message", message).apply();
    }

    static boolean isRunning(Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getBoolean("active", false);
    }

    static String stateMessage(Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString("message", "VPN выключен");
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
