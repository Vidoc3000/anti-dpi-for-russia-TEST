package ru.antidpi.mobile;

/**
 * Capability gate for a future Android userspace packet engine.
 * The current Zapret2 NFQUEUE engine cannot consume VpnService's TUN descriptor,
 * so this deliberately remains false until that adapter is implemented and tested.
 */
final class AndroidPacketEngine {
    private AndroidPacketEngine() { }

    static boolean isReady() {
        return false;
    }
}
