#!/usr/bin/env bash
# Build the Android JNI/AAR bridge for the Go TUN stack and safe stream desync engine.
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
ANDROID_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
: "${ANDROID_HOME:?Set ANDROID_HOME to an Android SDK installation}"
ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-$ANDROID_HOME/ndk/27.3.13750724}"
: "${GOMOBILE_VERSION:=v0.0.0-20260908204917-8b95e45f8d3e}"

if [[ ! -x "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/clang" ]]; then
  echo "Android NDK not found at $ANDROID_NDK_HOME" >&2
  exit 1
fi
if ! command -v gomobile >/dev/null 2>&1; then
  echo "gomobile is missing; install golang.org/x/mobile/cmd/gomobile@$GOMOBILE_VERSION" >&2
  exit 1
fi

GOMOBILE="$(command -v gomobile)"
mkdir -p "$ANDROID_DIR/app/libs"
(
  cd "$SCRIPT_DIR"
  GOFLAGS=-mod=readonly "$GOMOBILE" bind \
    -target=android/arm64,android/amd64 \
    -androidapi 26 \
    -javapkg ru.antidpi.mobile.engine \
    -o "$ANDROID_DIR/app/libs/antidpi-engine.aar" \
    ./mobile
)
echo "Built $ANDROID_DIR/app/libs/antidpi-engine.aar"
