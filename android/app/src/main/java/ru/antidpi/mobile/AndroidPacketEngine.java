package ru.antidpi.mobile;

import android.content.Context;
import android.net.VpnService;
import android.os.ParcelFileDescriptor;
import android.util.Log;

import org.json.JSONArray;

import java.util.function.Consumer;

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

    static boolean supportsNativeProfile(String argsJson) {
        try {
            return Zapret.supportsByeDpiProfile(argsJson);
        } catch (RuntimeException | LinkageError error) {
            Log.w(TAG, "Could not validate Android profile", error);
            return false;
        }
    }

    static String[] nativeProfileArgs(String argsJson) {
        return nativeProfileArgs(argsJson, NativeByedpiProxy.DEFAULT_PORT);
    }

    static String[] nativeProfileArgs(String argsJson, int port) {
        return nativeProfileArgs(argsJson, port, false);
    }

    static String[] nativeProfileArgs(String argsJson, int port, boolean ipv4Only) {
        try {
            JSONArray json = new JSONArray(Zapret.adaptByeDpiArgs(argsJson, port));
            String[] original = new String[json.length()];
            boolean alreadyIpv4Only = false;
            for (int i = 0; i < json.length(); i++) {
                original[i] = json.getString(i);
                if ("--no-ipv6".equals(original[i])) alreadyIpv4Only = true;
            }
            boolean appendIpv4Only = ipv4Only && !alreadyIpv4Only;
            String[] args = java.util.Arrays.copyOf(original, original.length + (appendIpv4Only ? 1 : 0));
            if (appendIpv4Only) args[args.length - 1] = "--no-ipv6";
            return args;
        } catch (Exception error) {
            Log.e(TAG, "Failed to adapt native profile; using safe TLS-record fallback", error);
            String[] fallback = {"--ip", "127.0.0.1", "--port", String.valueOf(port),
                    "--tlsrec", "0+sm"};
            if (!ipv4Only) return fallback;
            String[] ipv4Fallback = java.util.Arrays.copyOf(fallback, fallback.length + 1);
            ipv4Fallback[fallback.length] = "--no-ipv6";
            return ipv4Fallback;
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

    static AndroidPacketEngine create(Context context, VpnService service, Consumer<String> onEngineLog) {
        Seq.setContext(context.getApplicationContext());
        Engine engine = Zapret.newEngine();
        engine.setLogger(new Logger() {
            @Override public void log(String line) {
                Log.i(TAG, line);
                if (onEngineLog != null) onEngineLog.accept(line);
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

    void startTunnelViaProxy(ParcelFileDescriptor tun, int mtu, String socks5Addr,
                             boolean blockQuic, boolean blockIPv6) throws Exception {
        engine.startTunnelViaProxy(tun.getFd(), mtu, socks5Addr, blockQuic, blockIPv6);
    }

    String tunnelStats() {
        return engine.tunnelStats();
    }

    void stop() {
        engine.stop();
    }
}
