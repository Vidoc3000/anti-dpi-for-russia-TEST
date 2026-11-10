#!/bin/sh
set -eu
AntiDPI_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
AntiDPI_BOOTSTRAP="$AntiDPI_DIR/app/terminal_bootstrap.py"
if [ ! -f "$AntiDPI_BOOTSTRAP" ]; then
    AntiDPI_BOOTSTRAP="$AntiDPI_DIR/terminal_bootstrap.py"
fi
exec /usr/bin/python3 "$AntiDPI_BOOTSTRAP" uninstall "$@"
