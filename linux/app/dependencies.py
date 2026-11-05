"""Check dependencies before using an available package manager.

Other distributions can proceed automatically when dependencies are ready.
Copyright Igor Krauch (github.com/igareck).
"""
from __future__ import annotations

import shlex
import shutil
import subprocess
import tempfile
from pathlib import Path

COMMANDS = ('cc', 'make', 'pkg-config', 'nft', 'ip', 'curl')


def missing_dependencies():
    missing = [name for name in COMMANDS if not shutil.which(name)]
    if 'cc' in missing or 'pkg-config' in missing:
        return missing
    flags = subprocess.run(['pkg-config', '--cflags', '--libs', 'luajit'],
                           capture_output=True, text=True, timeout=15)
    if flags.returncode:
        return missing+['LuaJIT: заголовки и библиотека разработки (pkg-config luajit)']
    source = ('#include <libnetfilter_queue/libnetfilter_queue.h>\n'
              '#include <libnfnetlink/libnfnetlink.h>\n#include <libmnl/libmnl.h>\n'
              '#include <sys/capability.h>\n#include <zlib.h>\n#include <lua.h>\n'
              'int main(void) { return 0; }\n')
    with tempfile.TemporaryDirectory(prefix='.ig-deps-') as temporary:
        checked = subprocess.run(['cc', '-x', 'c', '-', '-o', str(Path(temporary)/'probe'),
                                  '-lnetfilter_queue', '-lnfnetlink', '-lmnl', '-lcap', '-lz']+
                                 shlex.split(flags.stdout), input=source, text=True,
                                 capture_output=True, timeout=30)
    if checked.returncode:
        missing.append('заголовки/библиотеки nfnetlink, netfilter_queue, mnl, cap, zlib, LuaJIT: '+
                       checked.stderr.strip()[-1500:])
    return missing


def ensure_dependencies(packages, skip=False):
    missing = missing_dependencies()
    if not missing:
        print('Зависимости уже установлены; установка пакетов не требуется.', flush=True)
        return
    supported = Path('/etc/debian_version').is_file() and shutil.which('apt-get')
    if supported and not skip:
        subprocess.run(['apt-get', 'update'], check=True)
        subprocess.run(['apt-get', 'install', '-y', '--no-install-recommends']+packages, check=True)
        missing = missing_dependencies()
    if missing:
        raise RuntimeError('Не установлены зависимости:\n- '+'\n- '.join(missing)+
                           '\nУстановите их средствами своего дистрибутива и повторите INSTALL.sh. '
                           '--skip-deps пропускает установку пакетов, но не проверку зависимостей.')
