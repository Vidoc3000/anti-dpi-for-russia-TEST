package ru.antidpi.mobile;

import android.os.SystemClock;
import android.util.Log;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.Socket;

/** Lifecycle bridge to the bundled MIT-licensed native ByeDPI SOCKS engine. */
final class NativeByedpiProxy {
    static final int PORT = 10808;
    private static final String TAG = "AntiDpiByedpi";
    private static final long START_TIMEOUT_MS = 6000;

    static {
        System.loadLibrary("antidpi_native");
    }

    private Thread worker;
    private volatile int exitCode = Integer.MIN_VALUE;

    private static native int nativeStartProxy(String[] arguments);
    private static native int nativeStopProxy();

    synchronized void start(String[] strategyArguments) throws IOException {
        if (worker != null && worker.isAlive()) {
            throw new IOException("Native ByeDPI proxy is already running");
        }
        exitCode = Integer.MIN_VALUE;
        worker = new Thread(() -> {
            try {
                exitCode = nativeStartProxy(strategyArguments);
            } catch (Throwable error) {
                Log.e(TAG, "Native ByeDPI worker failed", error);
                exitCode = -1;
            }
        }, "AntiDpi-ByeDPI");
        worker.start();

        long deadline = SystemClock.elapsedRealtime() + START_TIMEOUT_MS;
        while (SystemClock.elapsedRealtime() < deadline) {
            if (!worker.isAlive()) {
                throw new IOException("Native ByeDPI proxy exited during startup (code " + exitCode + ")");
            }
            if (socksHandshakeReady()) {
                Log.i(TAG, "Native ByeDPI SOCKS listener ready on 127.0.0.1:" + PORT);
                return;
            }
            SystemClock.sleep(40);
        }
        stop();
        throw new IOException("Native ByeDPI SOCKS listener did not become ready");
    }

    private boolean socksHandshakeReady() {
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress("127.0.0.1", PORT), 200);
            socket.setSoTimeout(500);
            OutputStream output = socket.getOutputStream();
            InputStream input = socket.getInputStream();
            output.write(new byte[]{5, 1, 0});
            output.flush();
            return input.read() == 5 && input.read() == 0;
        } catch (IOException ignored) {
            return false;
        }
    }

    synchronized void stop() {
        Thread running = worker;
        if (running == null) return;
        nativeStopProxy();
        try {
            running.join(1500);
        } catch (InterruptedException error) {
            Thread.currentThread().interrupt();
        }
        if (running.isAlive()) {
            Log.w(TAG, "Native ByeDPI worker did not stop within timeout");
        } else {
            worker = null;
        }
    }
}
