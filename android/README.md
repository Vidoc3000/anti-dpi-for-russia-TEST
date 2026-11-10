# AntiDPI Mobile (Android)

A no-root Android VPN prototype with a local TUN datapath. `VpnService` captures routed device packets, a Go/gVisor userspace stack reconstructs TCP/UDP flows, and TCP flows are handed to a local native ByeDPI SOCKS engine before egress. VPN/native-proxy startup (including socket readiness checks) runs on a worker thread so network operations do not execute on Android's main thread. The C engine uses socket-level TCP techniques; this is materially different from the previous stream-only Go adaptation. The app UID is excluded from the TUN to prevent the native proxy's own upstream sockets from looping. The in-app diagnostics explicitly use the local SOCKS listener while VPN is active.

## Android strategy behavior

Zapret2 desktop profiles are **not directly portable** to Android and the adapter does not claim exact equivalence. It translates the useful stream-level recipe parts into the bundled native ByeDPI engine:

- TLS record fragmentation, native `fake`, approximate `split` positions, and selected `disorder` recipes;
- supported fake details where practical: numeric fake TTL, fake SNI, and short inline hexadecimal fake payloads;
- optional UDP/443 blocking to encourage TCP fallback from QUIC;
- user-selectable DNS, tunnel MTU, and per-app routing. The app's own UID is always kept outside its VPN tunnel to prevent proxy egress loops.

The settings are applied to the Android tunnel and native proxy and trigger a VPN restart when changed. Zapret2 desktop profiles are still only approximately translated. Named desktop blobs, arbitrary TCP sequence/timestamp edits, SYN data, window-size manipulation, TCP option injection, and exact packet reordering are not faithfully reproduced by this socket-level no-root architecture. An inline hex fake payload is available only when the source profile actually supplies one; this does not enable arbitrary raw packet crafting. Socket behavior can vary by Android kernel/device.

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

## Test and routing diagnostics

```sh
cd android/engine && go test ./...
cd ../.. && python3 -m unittest discover -s tests/android -v
```

The in-app HTTPS 204 probes connect to the local SOCKS proxy from the app's excluded UID; they do not traverse the Android TUN and are not an end-to-end test of another app's route. While the VPN is active, the Tests page also shows TUN counters: TCP attempts/connected/failed (split into endpoint failures inside TUN/gVisor and upstream dial failures through SOCKS/ByeDPI), UDP flows, UDP/443 packets dropped for QUIC, and IPv6 flows blocked. The optional IPv4-only mode keeps the Android IPv6 default route captured by the VPN and drops IPv6 TCP/UDP inside the userspace tunnel; it does not route IPv6 directly outside the VPN. Apps may or may not retry over IPv4. DNS settings support public presets and custom numeric IPv4/IPv6 resolver addresses. Open the affected app or browser, retry a page, then return to the Tests page. Zero TCP attempts suggests the app's traffic did not reach this TUN. Endpoint failures occur before SOCKS is contacted; upstream failures occur while connecting through the local proxy. HTTPS test failures now include a bounded cause string; certificate verification remains enabled. A TCP connection count is not proof of DPI bypass or successful video playback.

On-device behavior still requires testing across Android versions, carriers, Wi-Fi/mobile networks, IPv4/IPv6, QUIC, and real target services. Build and protocol tests are not a substitute for field validation.
