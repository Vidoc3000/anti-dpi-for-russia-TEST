package ru.antidpi.mobile;

import android.content.Intent;
import android.net.VpnService;

/** Fails closed: without a packet engine this service never establishes a VPN interface. */
public final class AntiDpiVpnService extends VpnService {
    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (!AndroidPacketEngine.isReady()) {
            stopSelf(startId);
            return START_NOT_STICKY;
        }
        // A real TUN-to-engine data plane must be implemented before enabling the capability gate.
        stopSelf(startId);
        return START_NOT_STICKY;
    }
}
