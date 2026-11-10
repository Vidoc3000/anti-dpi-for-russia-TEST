# Android engine third-party notices

The Android stream engine was adapted under the MIT License from **Zapret Mobile** by `revocx35`, pinned to commit [`76c09a21e6477593116c69bf137147edb219cfe4`](https://github.com/revocx35/zapret_mobile/commit/76c09a21e6477593116c69bf137147edb219cfe4). The upstream implementation supplies the gVisor TUN TCP/IP datapath and a Go stream-desynchronization engine. Its copyright and MIT terms are preserved in `LICENSE.zapret-mobile`.

The engine uses the following Go modules; copies of their license texts are included in `licenses/`:

- `gvisor.dev/gvisor` `v0.0.0-20261005053113-a1873cad2d51` — Apache-2.0 (`licenses/LICENSE-gvisor.txt`).
- `golang.org/x/sys` `v0.48.0` — BSD-3-Clause (`licenses/LICENSE-sys.txt`).
- `golang.org/x/mobile` `v0.0.0-20260908204917-8b95e45f8d3e` — BSD-3-Clause (`licenses/LICENSE-mobile.txt`).

Other indirect Go module dependencies and Go's standard library retain their own licenses and notices. The generated AAR is assembled from this module at build time; it is not committed to source control.
