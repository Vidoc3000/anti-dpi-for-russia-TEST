# AntiDPI Mobile (Android)

A no-root Android VPN prototype with a real local TUN datapath. `VpnService` captures routed device packets, a bundled Go/gVisor userspace TCP/IP stack relays TCP and UDP flows, and a per-flow dialer applies a server-safe, stream-level interpretation of the selected catalogue recipe to the first TLS ClientHello (or plaintext HTTP request). Egress sockets are protected with `VpnService.protect()` and the app's own UID is excluded from the VPN to prevent loops.

## What the Android engine applies

The Android adapter is **not a direct port of the desktop NFQUEUE packet engine**. For every selected desktop profile it:

- fragments the TLS ClientHello into two valid TLS handshake records at an SNI-relative point (`tlsrec`);
- translates recognized `multisplit`, `fakedsplit`, and `tcpseg` positions into best-effort TCP write boundaries;
- keeps the peer-visible handshake byte stream intact;
- optionally blocks outbound UDP/443 so apps can retry over TCP/TLS instead of QUIC.

The adapter intentionally ignores raw fake packets, TTL/SEQ/TS manipulation, SYN data, window-size tricks, TCP repair, and true segment reordering. Those require raw-packet or privileged TCP access unavailable to a normal Android `VpnService` app. Position names such as `midsld` and `endhost` are approximated by the mobile SNI-position parser; the UI labels this as an Android adaptation, not an exact replay of the desktop recipe. Efficacy depends on the network and target; the app does not claim every profile will work.

The VPN carries traffic directly to each destination; it is not a remote proxy, does not decrypt TLS, and does not hide the device IP. DNS and UDP are relayed directly. If a VPN start, socket protection, or engine initialization fails, the app tears down the TUN rather than leaving a dead interface in place.

## Build

Requirements: JDK 17, Android SDK 35, Android NDK r27c (`27.3.13750724`), Go 1.26.3 or newer, and the pinned `gomobile` version below.

```sh
cd android/engine
go install golang.org/x/mobile/cmd/gomobile@v0.0.0-20260908204917-8b95e45f8d3e
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/27.3.13750724"
gomobile init
./build-aar.sh
cd ..
./gradlew assembleDebug
```

The Go engine produces `app/libs/antidpi-engine.aar` locally; it is generated, ignored by Git, and required by the Gradle app build. CI builds the AAR, runs the Go engine tests and Android project tests, then builds the APK.

## Structure

- `app/src/main/java/ru/antidpi/mobile/` — catalogue UI, VPN consent/lifecycle, foreground notification, and Go bridge.
- `engine/desync/` — TLS/SNI parser, strategy parser and server-safe stream framing.
- `engine/tunnel/` — gVisor TCP/IP stack attached to the Android TUN fd; TCP/UDP forwarding.
- `engine/mobile/` — gomobile API and Android adaptation from the existing Zapret2 profile arguments.
- `app/src/main/assets/catalogue.json` — offline copy of the Linux strategy catalogue.
- `engine/THIRD_PARTY_NOTICES.md` — source commit and required third-party license information.

## Test

```sh
cd android/engine && go test ./...
cd ../.. && python3 -m unittest discover -s tests/android -v
```

On-device behavior still requires testing across Android versions, carriers, Wi-Fi/mobile networks, IPv4/IPv6, QUIC, and real target services. The build and protocol unit tests are not a substitute for field validation.
