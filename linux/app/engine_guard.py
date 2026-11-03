#!/usr/bin/env python3
"""Keep the owned engine tied to its launcher, including launcher SIGKILL."""
import ctypes
import os
import signal
import sys

if __name__ == '__main__':
    parent = int(sys.argv[1])
    libc = ctypes.CDLL(None, use_errno=True)
    if libc.prctl(1, signal.SIGTERM, 0, 0, 0) != 0:
        raise OSError(ctypes.get_errno(), 'PR_SET_PDEATHSIG')
    if os.getppid() != parent:
        raise SystemExit(1)
    os.execv(sys.argv[2], sys.argv[2:])
