"""Owned global launcher for the archive installation.

Copyright Igor Krauch (github.com/igareck).
"""
from __future__ import annotations
from contextlib import contextmanager
import fcntl
from hashlib import sha256
import json
import os
from pathlib import Path
import re
import shlex
import stat
import sys
import uuid

COMMAND = Path('/usr/local/bin/antidpi')
LOCK = Path('/run/lock/antidpi-command.lock')
MARKER = '# antidpi-launcher-v1 '


def launcher_bytes(root, install_id):
    root = Path(root)
    if not root.is_absolute() or not re.fullmatch(r'[0-9a-f]{32}', install_id):
        raise RuntimeError('Некорректная установка для команды запуска.')
    metadata = json.dumps({'id':install_id, 'prefix':str(root)}, ensure_ascii=True, separators=(',', ':'))
    return ('#!/bin/sh\n'+MARKER+metadata+'\nexec /bin/bash '+
            shlex.quote(str(root/'START.sh'))+' "$@"\n').encode('utf-8')


def snapshot():
    if not COMMAND.exists() and not COMMAND.is_symlink():
        return None
    info = COMMAND.lstat()
    if not stat.S_ISREG(info.st_mode) or info.st_size > 65536:
        return {'owned':False, 'sha256':None}
    data = COMMAND.read_bytes()
    owned = False
    try:
        metadata = json.loads(data.decode('utf-8').splitlines()[1].removeprefix(MARKER))
        owned = (info.st_uid == 0 and not info.st_mode & 0o022 and
                 data == launcher_bytes(Path(metadata['prefix']), metadata['id']))
    except (ValueError, IndexError, KeyError, TypeError, RuntimeError, UnicodeError):
        pass
    return {'owned':owned, 'sha256':sha256(data).hexdigest()}


def path_commands(environ=None):
    env = os.environ if environ is None else environ
    result = []
    seen = set()
    for entry in env.get('PATH', '').split(os.pathsep):
        folder = Path(entry)
        if not folder.is_absolute():
            continue
        path = folder/COMMAND.name
        if path == COMMAND or not path.is_file() or not os.access(path, os.X_OK):
            continue
        real = path.resolve()
        if real not in seen:
            result.append(str(path))
            seen.add(real)
    return result


def prepare(value=None):
    if value == 'no':
        return None
    existing = snapshot()
    if existing and not existing['owned']:
        print('Команда '+str(COMMAND)+' уже занята чужим файлом. Он сохранён; используйте START.sh или ярлыки.')
        return None
    others = path_commands()
    if existing or others:
        print('Найдена команда antidpi другой установки:')
        if existing:
            print(str(COMMAND))
        for path in others:
            print(path)
        if value != 'yes':
            if not sys.stdin.isatty():
                print('Глобальная команда сохранена за прежней установкой.')
                return None
            print('Использовать новую установку по команде antidpi?')
            while True:
                answer = input('Введите Да/Yes или Нет/No: ').strip().casefold()
                if answer in ('нет', 'no'):
                    return None
                if answer in ('да', 'yes'):
                    break
    return {'expected_sha256':existing['sha256'] if existing else None}


@contextmanager
def command_lock():
    LOCK.parent.mkdir(parents=True, exist_ok=True)
    fd = os.open(LOCK, os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
    with os.fdopen(fd, 'w') as stream:
        fcntl.flock(stream, fcntl.LOCK_EX)
        yield


def register(root, install_id, plan):
    if plan is None:
        return None
    root = Path(root)
    if not (root/'START.sh').is_file():
        raise RuntimeError('Не найден START.sh установленной программы.')
    data = launcher_bytes(root, install_id)
    with command_lock():
        current = snapshot()
        actual = current['sha256'] if current else None
        if (current and not current['owned']) or actual != plan['expected_sha256']:
            raise RuntimeError('Команда запуска изменилась во время установки; чужой файл сохранён.')
        COMMAND.parent.mkdir(parents=True, exist_ok=True)
        temporary = COMMAND.with_name('.antidpi-launcher-'+uuid.uuid4().hex)
        try:
            with temporary.open('xb') as stream:
                stream.write(data)
            temporary.chmod(0o755)
            if current:
                os.replace(temporary, COMMAND)
            else:
                # Do not overwrite an unrelated file created after our check.
                os.link(temporary, COMMAND)
        finally:
            temporary.unlink(missing_ok=True)
    return {'schema':'antidpi.command.v1', 'path':str(COMMAND), 'id':install_id,
            'prefix':str(root), 'sha256':sha256(data).hexdigest()}


def remove(record):
    if record.get('schema') != 'antidpi.command.v1' or record.get('path') != str(COMMAND):
        raise RuntimeError('Некорректный маркер глобальной команды.')
    expected = launcher_bytes(Path(record['prefix']), record['id'])
    if sha256(expected).hexdigest() != record.get('sha256'):
        raise RuntimeError('Повреждён маркер глобальной команды.')
    with command_lock():
        current = snapshot()
        if current and current['owned'] and current['sha256'] == record['sha256']:
            COMMAND.unlink()
            return True
    return False
