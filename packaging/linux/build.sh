#!/usr/bin/env bash
# Copyright (C) 2026 Igor Krauch (github.com/igareck). See the repository LICENSE.
set -euo pipefail
AntiDPI_PACKAGING_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
AntiDPI_DEFAULT_ROOT=$(CDPATH= cd -- "$AntiDPI_PACKAGING_DIR/../.." && pwd)
exec python3 - "$AntiDPI_DEFAULT_ROOT" "$@" <<'PY'
import argparse
import gzip
import hashlib
import io
import json
import os
from pathlib import Path
import re
import stat
import sys
import tarfile
import tempfile


def main():
    if sys.version_info < (3, 9):
        raise RuntimeError('Для сборки нужен Python 3.9 или новее.')
    parser = argparse.ArgumentParser(description='Сборка исходного Linux tar.gz AntiDPI.')
    parser.add_argument('--repo-root', type=Path, default=Path(sys.argv[1]))
    parser.add_argument('--output-dir', type=Path)
    parser.add_argument('--version', default='1.4')
    parser.add_argument('--source-date-epoch', type=int)
    parser.add_argument('--force', action='store_true', help='Разрешить замену ранее собранных файлов.')
    args = parser.parse_args(sys.argv[2:])
    if not re.fullmatch(r'[0-9]+\.[0-9]+(?:\.[0-9]+){0,2}', args.version):
        parser.error('--version: используйте числовую версию, например 1.4.')
    if any(int(part) > 65534 for part in args.version.split('.')):
        parser.error('Компоненты версии должны быть не больше 65534.')
    epoch = args.source_date_epoch
    if epoch is None:
        value = os.environ.get('SOURCE_DATE_EPOCH', '0')
        if not re.fullmatch(r'[0-9]+', value):
            parser.error('SOURCE_DATE_EPOCH должен быть целым неотрицательным числом.')
        epoch = int(value)
    if not 0 <= epoch <= 4294967295:
        parser.error('SOURCE_DATE_EPOCH должен находиться в диапазоне 0..4294967295.')

    repo = args.repo_root.resolve()
    platform = repo / 'linux'
    if not platform.is_dir():
        raise RuntimeError('Не найдена папка linux/: ' + str(platform))
    source = platform
    if not (source / 'INSTALL.sh').is_file():
        candidates = [p for p in platform.iterdir()
                      if p.is_dir() and re.fullmatch(r'AntiDPI_CLI_v[0-9.]+_Linux_x64', p.name)
                      and (p / 'INSTALL.sh').is_file()]
        if len(candidates) != 1:
            raise RuntimeError('Поместите в linux/ содержимое папки из Linux tar.gz.')
        source = candidates[0]
    for relative in ('INSTALL.sh', 'START.sh', 'DELETE.sh', 'app/antidpi.py', 'app/install.py', 'data/catalogue.json'):
        if not (source / relative).is_file():
            raise RuntimeError('Не найден обязательный файл Linux: ' + relative)
    source_version = json.loads((source / 'data/release.json').read_text(encoding='utf-8'))['version']
    if args.version != source_version:
        raise RuntimeError('Версия пакета '+args.version+' не совпадает с linux/data/release.json: '+source_version)
    output = (args.output_dir or repo / 'dist').resolve()
    if output == repo or output == Path(output.anchor):
        raise RuntimeError('Укажите отдельную папку результатов, например dist/.')
    for protected in (repo / 'windows', platform, repo / 'packaging'):
        protected = protected.resolve()
        if output == protected or protected in output.parents:
            raise RuntimeError('Папка результатов не должна находиться внутри windows/, linux/ или packaging/.')

    excluded_dirs = {'.git', '.svn', '.venv', 'venv', 'node_modules', '__pycache__',
                     '.pytest_cache', 'dist', 'build', 'logs', '_state', 'engine'}
    excluded_files = {'.DS_Store', 'Thumbs.db', 'desktop.ini', '.antidpi-install.json'}

    def collect(directory, prefix=''):
        for child in sorted(directory.iterdir(), key=lambda p: p.name.encode('utf-8')):
            if child.name in excluded_files or re.search(r'\.(pyc|pyo|log|tmp)$|^SHA256SUMS|^Verification_', child.name, re.I):
                continue
            if child.is_symlink():
                raise RuntimeError('Ссылки в исходном комплекте не поддерживаются: ' + str(child))
            mode = child.stat().st_mode
            if stat.S_ISDIR(mode):
                if child.name.lower() not in excluded_dirs:
                    yield from collect(child, prefix + child.name + '/')
            elif stat.S_ISREG(mode):
                if '\\' in child.name or any(ord(c) < 32 for c in child.name):
                    raise RuntimeError('Недопустимое имя файла: ' + str(child))
                yield prefix + child.name, child
            else:
                raise RuntimeError('Специальные файлы в исходном комплекте не поддерживаются: ' + str(child))

    files = dict(collect(source))

    def add(name, path):
        if path.is_symlink() or not path.is_file():
            raise RuntimeError('Нужен обычный файл: ' + str(path))
        if name in files and files[name].read_bytes() != path.read_bytes():
            raise RuntimeError('Конфликт разных файлов с одним путём в пакете: ' + name)
        files[name] = path

    license_files = [repo / name for name in ('LICENSE', 'LICENSE.txt') if (repo / name).is_file()]
    if not license_files:
        raise RuntimeError('В корне репозитория нужен основной LICENSE или LICENSE.txt.')
    if len(license_files) == 2 and license_files[0].read_bytes() != license_files[1].read_bytes():
        raise RuntimeError('В корне обнаружены разные LICENSE и LICENSE.txt. Оставьте один основной текст.')
    add('LICENSE', license_files[0])
    add('THIRD_PARTY_NOTICES.md', repo / 'THIRD_PARTY_NOTICES.md')
    third_party = repo / 'licenses'
    if not third_party.is_dir() or third_party.is_symlink():
        raise RuntimeError('В корне нужна обычная непустая папка licenses/.')
    licenses = list(collect(third_party))
    if not licenses:
        raise RuntimeError('Папка licenses/ пуста.')
    for name, path in licenses:
        add('licenses/' + name, path)
    if source.is_symlink():
        raise RuntimeError('Папка исходников не должна быть ссылкой.')

    package_root = 'AntiDPI_CLI_v' + args.version + '_Linux_x64'
    archive_name = package_root + '.tar.gz'
    checksum_name = 'SHA256SUMS_Linux_v' + args.version + '.txt'
    destinations = (output / archive_name, output / checksum_name)
    if not args.force:
        for path in destinations:
            if path.exists() or path.is_symlink():
                raise RuntimeError('Файл уже существует: ' + str(path) + '. Для пересборки используйте --force.')
    output.mkdir(parents=True, exist_ok=True)
    temporary_paths = []
    try:
        descriptor, temporary_name = tempfile.mkstemp(prefix='.ig-build-', suffix='.tar.gz', dir=output)
        temporary = Path(temporary_name)
        temporary_paths.append(temporary)
        with os.fdopen(descriptor, 'wb') as raw:
            with gzip.GzipFile(filename='', mode='wb', fileobj=raw, mtime=epoch, compresslevel=9) as compressed:
                with tarfile.open(fileobj=compressed, mode='w', format=tarfile.PAX_FORMAT, encoding='utf-8') as archive:
                    directories = {package_root}
                    for name in files:
                        parts = name.split('/')[:-1]
                        for count in range(1, len(parts) + 1):
                            directories.add(package_root + '/' + '/'.join(parts[:count]))
                    for name in sorted(directories):
                        info = tarfile.TarInfo(name)
                        info.type = tarfile.DIRTYPE
                        info.mode = 0o755
                        info.mtime = epoch
                        info.uid = info.gid = 0
                        info.uname = info.gname = 'root'
                        archive.addfile(info)
                    for name, path in sorted(files.items()):
                        data = path.read_bytes()
                        info = tarfile.TarInfo(package_root + '/' + name)
                        original_mode = path.stat().st_mode
                        info.mode = 0o755 if name in ('INSTALL.sh', 'START.sh', 'DELETE.sh') or original_mode & 0o111 else 0o644
                        info.size = len(data)
                        info.mtime = epoch
                        info.uid = info.gid = 0
                        info.uname = info.gname = 'root'
                        archive.addfile(info, io.BytesIO(data))
        digest = hashlib.sha256(temporary.read_bytes()).hexdigest()
        descriptor, sum_name = tempfile.mkstemp(prefix='.ig-build-', suffix='.sha256', dir=output)
        sums = Path(sum_name)
        temporary_paths.append(sums)
        with os.fdopen(descriptor, 'w', encoding='utf-8', newline='\n') as stream:
            stream.write(digest + '  ' + archive_name + '\n')
        for staged, target in zip((temporary, sums), destinations):
            if args.force:
                os.replace(staged, target)
            else:
                os.link(staged, target)
                staged.unlink()
            print('Создано: ' + str(target))
    finally:
        for path in temporary_paths:
            if path.exists():
                path.unlink()


try:
    main()
except (OSError, ValueError, RuntimeError, tarfile.TarError) as error:
    print('ОШИБКА: ' + str(error), file=sys.stderr)
    raise SystemExit(1)
PY
