# AntiDPI Mobile (Android preview)

Native Android project for the no-root `VpnService` direction. Open this folder in Android Studio, or build a debug APK with:

```sh
./gradlew assembleDebug
```

Requirements: Android Studio with Android SDK 35 and JDK 17. The APK uses the project strategy catalogue and needs only the `INTERNET` permission for its optional direct-connectivity check.

## What works now

- Browse and search the 492 TLS strategy descriptions, grouped by family; the last selection is saved locally.
- Run an optional direct HTTPS connectivity check to YouTube. This is a baseline check only: it does not apply the selected strategy or test a VPN/Tor tunnel.
- Display an explicit engine-readiness state.

## Important limitation

This is an early mobile UI prototype, **not yet a DPI-circumvention client**. The current Zapret2 engine consumes Linux NFQUEUE packets; an ordinary Android app cannot configure that path without root. Android `VpnService` supplies a TUN file descriptor instead, and a no-root userspace packet-processing adapter has not been implemented. Therefore the “Start DPI” control stays disabled and `AntiDpiVpnService` fails closed without establishing a VPN interface. The app does not alter, capture, or reroute device traffic.

Implement and test the TUN-to-engine data plane before enabling the readiness gate. Do not replace this guard with an empty `VpnService.Builder.establish()` call: that would capture traffic without forwarding it and could interrupt the phone's network.

## Project layout

- `app/src/main/java/ru/antidpi/mobile/` — native Android UI, catalogue reader, baseline probe, and fail-closed VPN service stub.
- `app/src/main/assets/catalogue.json` — snapshot of the repository's strategy catalogue for offline browsing.

The catalogue snapshot is expected to match `../../linux/data/catalogue.json`; `tests/android/test_android_project.py` checks the copy and fail-closed service contract.
