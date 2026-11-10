package ru.antidpi.mobile;

import android.content.Context;
import android.net.VpnService;
import android.os.ParcelFileDescriptor;
import android.util.Log;

import go.Seq;
import ru.antidpi.mobile.engine.zapret.Engine;
import ru.antidpi.mobile.engine.zapret.Logger;
import ru.antidpi.mobile.engine.zapret.Protector;
import ru.antidpi.mobile.engine.zapret.Zapret;

/** JNI bridge to the Go/gVisor userspace TUN datapath and stream-safe desync engine. */
final class AndroidPacketEngine {
    private static final String TAG = "AntiDpiEngine";
    private final Engine engine;

    private AndroidPacketEngine(Engine engine) {
        this.engine = engine;
    }

    static boolean isReady() {
        try {
            Class.forName("ru.antidpi.mobile.engine.zapret.Zapret");
            return true;
        } catch (ClassNotFoundException | LinkageError error) {
            Log.e(TAG, "Native Android engine is missing", error);
            return false;
        }
    }

    static String adaptProfileArgs(String argsJson) {
        return Zapret.adaptZapretArgs(argsJson);
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

    void stop() {
        engine.stop();
    }
}
