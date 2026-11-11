package ru.antidpi.mobile;

import android.content.Context;
import android.os.SystemClock;
import android.util.Log;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;

/** Lifecycle bridge to the bundled MIT-licensed native ByeDPI SOCKS engine. */
final class NativeByedpiProxy {
    static final int DEFAULT_PORT = 10808;
    private static final String TAG = "AntiDpiByedpi";
    private static final long START_TIMEOUT_MS = 6000;
    private static final int START_ATTEMPTS = 3;
    private static volatile Context logContext;
    private final Context appContext;
    private volatile int port;

    NativeByedpiProxy(Context context) {
        appContext = context.getApplicationContext();
        logContext = appContext;
    }

    static void onNativeLog(String message) {
        Context context = logContext;
        if (context == null || message == null) return;
        DiagnosticLog.record(context,
                message.contains("failed") ? DiagnosticLog.ERROR : DiagnosticLog.WARN,
                "ByeDPI: " + message);
    }

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
        IOException lastFailure = null;
        for (int attempt = 1; attempt <= START_ATTEMPTS; attempt++) {
            logContext = appContext;
            port = reserveEphemeralPort();
            String[] arguments = withPort(strategyArguments, port);
            exitCode = Integer.MIN_VALUE;
            worker = new Thread(() -> {
                try {
                    exitCode = nativeStartProxy(arguments);
                } catch (Throwable error) {
                    Log.e(TAG, "Native ByeDPI worker failed", error);
                    DiagnosticLog.record(appContext, DiagnosticLog.ERROR,
                            "Native ByeDPI worker failed: " + error.getMessage());
                    exitCode = -1;
                }
            }, "AntiDpi-ByeDPI");
            worker.start();

            long deadline = SystemClock.elapsedRealtime() + START_TIMEOUT_MS;
            while (SystemClock.elapsedRealtime() < deadline) {
                if (!worker.isAlive()) {
                    lastFailure = new IOException("Native ByeDPI exited during startup (code " + exitCode + ")");
                    break;
                }
                if (socksHandshakeReady(port)) {
                    Log.i(TAG, "Native ByeDPI SOCKS listener ready on 127.0.0.1:" + port);
                    DiagnosticLog.record(appContext, DiagnosticLog.INFO,
                            "ByeDPI SOCKS listener ready on local port " + port);
                    return;
                }
                SystemClock.sleep(40);
            }
            if (worker.isAlive()) {
                lastFailure = new IOException("SOCKS listener did not become ready on port " + port);
                stop();
                if (worker != null && worker.isAlive()) {
                    port = 0;
                    throw new IOException("Native ByeDPI failed to stop after startup timeout");
                }
            } else {
                worker = null;
            }
            Log.w(TAG, "Native proxy startup attempt " + attempt + " failed: " + lastFailure.getMessage());
            DiagnosticLog.record(appContext, DiagnosticLog.WARN,
                    "ByeDPI startup attempt " + attempt + " failed: " + lastFailure.getMessage());
        }
        port = 0;
        throw lastFailure == null ? new IOException("Native ByeDPI proxy failed to start") : lastFailure;
    }

    int port() {
        return port;
    }

    private static String[] withPort(String[] original, int port) {
        String[] result = original == null ? new String[0] : original.clone();
        for (int i = 0; i + 1 < result.length; i++) {
            if ("--port".equals(result[i])) {
                result[i + 1] = String.valueOf(port);
                return result;
            }
        }
        String[] expanded = new String[result.length + 2];
        System.arraycopy(result, 0, expanded, 0, result.length);
        expanded[result.length] = "--port";
        expanded[result.length + 1] = String.valueOf(port);
        return expanded;
    }

    private static int reserveEphemeralPort() throws IOException {
        try (ServerSocket socket = new ServerSocket(0, 1, java.net.InetAddress.getByName("127.0.0.1"))) {
            return socket.getLocalPort();
        }
    }

    private boolean socksHandshakeReady(int port) {
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress("127.0.0.1", port), 200);
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
            DiagnosticLog.record(appContext, DiagnosticLog.WARN,
                    "ByeDPI worker did not stop within timeout");
        } else {
            worker = null;
            if (logContext == appContext) logContext = null;
        }
    }
}
