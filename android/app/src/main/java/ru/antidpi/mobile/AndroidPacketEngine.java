package ru.antidpi.mobile;

import android.content.Context;
import android.net.VpnService;
import android.os.ParcelFileDescriptor;
import android.util.Log;

import org.json.JSONArray;

import go.Seq;
import ru.antidpi.mobile.engine.zapret.Engine;
import ru.antidpi.mobile.engine.zapret.Logger;
import ru.antidpi.mobile.engine.zapret.Protector;
import ru.antidpi.mobile.engine.zapret.Zapret;

/** Bridge to the Go/gVisor TUN datapath and native ByeDPI strategy proxy. */
final class AndroidPacketEngine {
    private static final String TAG = "AntiDpiEngine";
    private final Engine engine;

    private AndroidPacketEngine(Engine engine) {
        this.engine = engine;
    }

    static boolean isReady() {
        try {
            Class.forName("ru.antidpi.mobile.engine.zapret.Zapret");
            Class.forName("ru.antidpi.mobile.NativeByedpiProxy");
            return true;
        } catch (ClassNotFoundException | LinkageError error) {
            Log.e(TAG, "Native Android engine is missing", error);
            return false;
        }
    }

    static String adaptProfileArgs(String argsJson) {
        return Zapret.adaptZapretArgs(argsJson);
    }

    static String[] nativeProfileArgs(String argsJson) {
        try {
            JSONArray json = new JSONArray(Zapret.adaptByeDpiArgs(argsJson, NativeByedpiProxy.PORT));
            String[] args = new String[json.length()];
            for (int i = 0; i < json.length(); i++) args[i] = json.getString(i);
            return args;
        } catch (Exception error) {
            Log.e(TAG, "Failed to adapt native profile; using safe TLS-record fallback", error);
            return new String[]{"--ip", "127.0.0.1", "--port", String.valueOf(NativeByedpiProxy.PORT),
                    "--tlsrec", "0+sm"};
        }
    }

    static String describeNativeProfile(String argsJson) {
        String[] args = nativeProfileArgs(argsJson);
        StringBuilder summary = new StringBuilder();
        for (int i = 4; i < args.length; i++) {
            if (summary.length() > 0) summary.append(' ');
            summary.append(args[i]);
        }
        return summary.toString();
    }

    static AndroidPacketEngine create(Context context, VpnService service, Runnable onEngineLog) {
        Seq.setContext(context.getApplicationContext());
        Engine engine = Zapret.newEngine();
        engine.setLogger(new Logger() {
            @Override public void log(String line) {
                Log.i(TAG, line);
                if (onEngineLog != null) onEngineLog.run();
            }
        });
        engine.setProtector(new Protector() {
            @Override public boolean protect(long fd) {
                return service.protect((int) fd);
            }
        });
        return new AndroidPacketEngine(engine);
    }

    void startTunnel(ParcelFileDescriptor tun, int mtu, String strategy, boolean blockQuic)
            throws Exception {
        engine.startTunnel(tun.getFd(), mtu, strategy, blockQuic);
    }

    void startTunnelViaProxy(ParcelFileDescriptor tun, int mtu, String socks5Addr, boolean blockQuic)
            throws Exception {
        engine.startTunnelViaProxy(tun.getFd(), mtu, socks5Addr, blockQuic);
    }

    void stop() {
        engine.stop();
    }
}
