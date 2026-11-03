#!/bin/sh
set -eu
IGARECK_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
IGARECK_BOOTSTRAP="$IGARECK_DIR/app/terminal_bootstrap.py"
if [ ! -f "$IGARECK_BOOTSTRAP" ]; then
    IGARECK_BOOTSTRAP="$IGARECK_DIR/terminal_bootstrap.py"
fi
exec /usr/bin/python3 "$IGARECK_BOOTSTRAP" install "$@"
