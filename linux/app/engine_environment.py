"""Validate Linux privileges and select a mapped non-root engine UID/GID.

No namespace, host/container security policy or global firewall is changed.
Copyright Igor Krauch (github.com/igareck).
"""
from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import uuid

DEFAULT_ID = 0x7fffffff  # The pinned upstream's ordinary default.
CAPABILITIES = {6: 'CAP_SETGID', 7: 'CAP_SETUID',
                12: 'CAP_NET_ADMIN', 13: 'CAP_NET_RAW'}


def read_mapping(text):
    result = []
    for line in text.splitlines():
        fields = line.split()
        if not fields:
            continue
        if len(fields) != 3:
            raise RuntimeError('Некорректная карта UID/GID в /proc/self.')
        inside, outside, count = map(int, fields)
        if min(inside, outside) < 0 or count < 1:
            raise RuntimeError('Некорректный диапазон UID/GID.')
        result.append((inside, outside, count))
    if not result:
        raise RuntimeError('Пустая карта UID/GID в /proc/self.')
    return result


def mapped(value, ranges):
    return any(first <= value < first+count for first, _, count in ranges)


def select_id(ranges):
    for value in (DEFAULT_ID, 65534):
        if mapped(value, ranges):
            return value
    for first, _, count in reversed(ranges):
        value = min(first+count-1, DEFAULT_ID)
        if first <= value and value > 0:
            return value
    raise RuntimeError('В пространстве имён нет доступного ненулевого UID/GID '
                       'для безопасного запуска nfqws2. Проверьте карты UID/GID контейнера.')


def snapshot(proc=Path('/proc/self')):
    proc = Path(proc)
    result = {name: (proc/name).read_text().strip() for name in ('uid_map', 'gid_map')}
    try:
        result['setgroups'] = (proc/'setgroups').read_text().strip()
    except FileNotFoundError:
        result['setgroups'] = 'allow'
    status = (proc/'status').read_text()
    cap_line = next((line.split(':', 1)[1].strip() for line in status.splitlines()
                     if line.startswith('CapEff:')), None)
    if cap_line is None:
        raise RuntimeError('Не удалось прочитать CapEff из /proc/self/status.')
    result['cap_effective'] = cap_line
    return result


def engine_identity(state=None):
    state = snapshot() if state is None else state
    if state['setgroups'] == 'deny':
        raise RuntimeError('Контейнер запрещает setgroups. nfqws2 не сможет сменить группы. '
                           'Проверьте разрешения и карты UID/GID контейнера на хосте; '
                           'смена стратегии эту ошибку не исправит.')
    return (select_id(read_mapping(state['uid_map'])),
            select_id(read_mapping(state['gid_map'])))


def privilege_arguments():
    uid, gid = engine_identity()
    return ['--uid='+str(uid)+':'+str(gid)]


def check_environment(root=None, check_nft=True):
    state = snapshot()
    if root is not None:
        path = Path(root)/'engine-environment.json'
        # The installer saves this even when validation fails.
        with path.open('w', encoding='utf-8') as stream:
            json.dump(state, stream, ensure_ascii=False, indent=2)
            stream.write('\n')
        path.chmod(0o600)
    capabilities = int(state['cap_effective'], 16)
    missing = [name for bit, name in CAPABILITIES.items() if not capabilities & (1 << bit)]
    if missing:
        raise RuntimeError('Окружение не предоставляет '+', '.join(missing)+'. '
                           'Нужны права для NFQUEUE/raw-сокетов и смены UID/GID. '
                           'Для контейнера проверьте разрешения на хосте; это не ошибка стратегии.')
    uid, gid = engine_identity(state)
    if check_nft:
        table = 'antidpi_z2_probe_'+uuid.uuid4().hex[:12]
        rules = ('table ip '+table+' {\n'
                 ' chain probe { type filter hook output priority -150; policy accept;\n'
                 '  queue num 24999 bypass\n }\n}\n')
        # --check validates the transaction without applying rules to traffic.
        checked = subprocess.run(['nft', '--check', '-f', '-'], input=rules,
                                 text=True, capture_output=True, timeout=20,
                                 env=dict(os.environ, LC_ALL='C'))
        if checked.returncode:
            raise RuntimeError('Недоступны nftables/NFQUEUE в текущем окружении: '+
                               (checked.stderr or checked.stdout).strip()+
                               '. Проверьте модули ядра и разрешения контейнера на хосте.')
    return uid, gid


def failure_message(number, returncode, output):
    symptoms = ('setgroups', 'setgid', 'setuid', 'setpcap', 'operation not permitted',
                'permission denied', 'cap_net_', 'raw socket')
    if any(word in output.lower() for word in symptoms):
        return (f'Ошибка прав/окружения при проверке стратегии {number} '
                f'(nfqws2: код {returncode}). Проверьте UID/GID, capabilities '
                'и доступ к файлам программы; смена стратегии не устраняет эту причину.')
    return f'Проверка параметров/Lua стратегии {number}: nfqws2 завершился с кодом {returncode}.'
