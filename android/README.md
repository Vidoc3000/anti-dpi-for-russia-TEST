# AntiDPI Mobile (Android)

A no-root Android VPN prototype with a local TUN datapath. `VpnService` captures routed device packets, a Go/gVisor userspace stack reconstructs TCP/UDP flows, and TCP flows are handed to a local native ByeDPI SOCKS engine before egress. The C engine uses socket-level TCP techniques; this is materially different from the previous stream-only Go adaptation. The app UID is excluded from the TUN to prevent the native proxy's own upstream sockets from looping. The in-app diagnostics explicitly use the local SOCKS listener while VPN is active.

## Android strategy behavior

Zapret2 desktop profiles are **not directly portable** to Android and the adapter does not claim exact equivalence. It translates the useful stream-level recipe parts into the bundled native ByeDPI engine:

- TLS record fragmentation around the SNI;
- native `fake` with the engine's low-TTL/retransmission technique;
- `split` and approximate position mappings;
- `disorder` for selected `fakeddisorder`/`multidisorder` recipes;
- optional UDP/443 blocking to encourage TCP fallback from QUIC.

This allows fake/TTL and some disorder strategies without root by using the TCP socket APIs and behavior of the native engine. That does **not** make every Zapret2 operation possible: arbitrary TCP sequence/timestamp field editing, custom packet blobs, SYN data, window-size tricks, and exact packet reordering are not faithfully mapped. Some socket options can also vary by Android kernel/device. The app should report failures rather than claiming unsupported flags were applied.

The VPN is local: it does not decrypt TLS, tunnel traffic to a remote server, or hide the device IP. The Go userspace layer handles UDP directly (except optionally dropped UDP/443); the native strategy engine processes TCP.

## Build

Requirements: JDK 17, Android SDK 35, Android NDK r27c (`27.3.13750724`), Go 1.26.3 or newer, CMake 3.22.1, and the pinned `gomobile` version below.

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

The Go engine produces `app/libs/antidpi-engine.aar` locally; it is generated, ignored by Git, and required by the Gradle app build. Gradle also uses CMake to build the bundled native engine. CI builds both native components, runs Go and Android project checks, and builds the APK.

## Structure

- `app/src/main/java/ru/antidpi/mobile/` — catalogue UI, VPN lifecycle, Go/JNI bridges, native proxy lifecycle, and tests.
- `app/src/main/cpp/byedpi/` — pinned MIT-licensed ByeDPI C engine source.
- `engine/desync/` — legacy stream engine plus SOCKS5 client for routing gVisor TCP flows to the native strategy proxy.
- `engine/tunnel/` — gVisor TCP/IP stack attached to the Android TUN fd; TCP/UDP forwarding.
- `engine/mobile/` — gomobile API and Zapret2-to-ByeDPI profile adaptation.
- `app/src/main/assets/catalogue.json` — offline copy of the Linux strategy catalogue.
- `engine/THIRD_PARTY_NOTICES.md` — pinned source commits and third-party license information.

## Test

```sh
cd android/engine && go test ./...
cd ../.. && python3 -m unittest discover -s tests/android -v
```

On-device behavior still requires testing across Android versions, carriers, Wi-Fi/mobile networks, IPv4/IPv6, QUIC, and real target services. Build and protocol tests are not a substitute for field validation.
