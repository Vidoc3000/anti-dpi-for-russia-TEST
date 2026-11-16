"""Verified in-place Linux release updater. Copyright Igor Krauch."""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import subprocess
import sys
import tarfile
import tempfile
import urllib.error
import urllib.request
from urllib.parse import urlparse

API_URL = 'https://api.github.com/repos/Vidoc3000/anti-dpi-for-russia-TEST/releases/latest'
MAX_ARCHIVE_BYTES = 128 * 1024 * 1024
MAX_EXPANDED_BYTES = 512 * 1024 * 1024
MAX_FILES = 20000
ATTESTATION_REPOSITORY = 'Vidoc3000/anti-dpi-for-russia-TEST'
ATTESTATION_WORKFLOW = ATTESTATION_REPOSITORY + '/.github/workflows/build.yml'
ATTESTATION_API = 'https://api.github.com/repos/' + ATTESTATION_REPOSITORY + '/attestations/'
ATTESTATION_API_VERSION = '2026-03-10'  # The current response carries a signed bundle_url, not inline bytes.
ATTESTATION_BUNDLE_HOST = 'tmaproduction.blob.core.windows.net'  # Exact public GitHub bundle host; never forward credentials.
MAX_ATTESTATION_RESPONSE_BYTES = 8 * 1024 * 1024
MAX_ATTESTATION_BUNDLE_BYTES = 8 * 1024 * 1024
MAX_ATTESTATION_BUNDLES = 20


class _SafeRedirectHandler(urllib.request.HTTPRedirectHandler):
    def __init__(self, allowed_hosts=None):
        super().__init__()
        self.allowed_hosts = allowed_hosts

    def redirect_request(self, request, response, code, message, headers, new_url):
        parsed = urlparse(new_url)
        try:
            port = parsed.port
        except ValueError:
            port = -1
        if (parsed.scheme != 'https' or not parsed.hostname or port not in (None, 443) or
                parsed.username or parsed.password or
                (self.allowed_hosts is not None and parsed.hostname.lower() not in self.allowed_hosts)):
            raise urllib.error.URLError('redirect target rejected')
        return super().redirect_request(request, response, code, message, headers, new_url)


def _trusted_gh():
    candidate = shutil.which('gh')
    if not candidate:
        raise RuntimeError('Для безопасного обновления нужен официальный GitHub CLI (gh) с поддержкой `gh attestation verify`. Установите или обновите gh и повторите попытку.')
    try:
        executable = Path(candidate).resolve(strict=True)
        info = executable.stat()
        if not stat.S_ISREG(info.st_mode) or info.st_uid != 0 or info.st_mode & 0o022:
            raise RuntimeError('GitHub CLI найден, но его файл должен принадлежать root и не быть доступен для записи группе/остальным.')
        for parent in executable.parents:
            directory = parent.stat()
            if directory.st_uid != 0 or directory.st_mode & 0o022:
                raise RuntimeError('Путь к GitHub CLI проходит через каталог, изменяемый не-root пользователем.')
    except OSError as error:
        raise RuntimeError('Не удалось проверить безопасный путь GitHub CLI.') from error
    return str(executable)


def _validated_bundle_url(value):
    if not isinstance(value, str):
        raise RuntimeError('GitHub вернул недопустимую ссылку на attestation bundle.')
    try:
        parsed = urlparse(value)
        valid_port = parsed.port in (None, 443)
    except (TypeError, ValueError):
        valid_port = False
        parsed = urlparse('')
    if (parsed.scheme != 'https' or parsed.hostname != ATTESTATION_BUNDLE_HOST or
            not valid_port or parsed.username or parsed.password or parsed.fragment or
            not parsed.path.startswith('/attestations/') or not parsed.query):
        raise RuntimeError('GitHub вернул недопустимую ссылку на attestation bundle.')
    return value


def verify_release_attestation(package_path):
    """Cryptographically verify a public Sigstore bundle with strict workflow identity."""
    gh = _trusted_gh()
    package_path = Path(package_path).resolve()
    digest = hashlib.sha256(package_path.read_bytes()).hexdigest()
    url = ATTESTATION_API + 'sha256:' + digest + '?per_page=100'
    response = read_url(url, MAX_ATTESTATION_RESPONSE_BYTES, 'application/vnd.github+json',
                        ATTESTATION_API_VERSION)
    try:
        records = json.loads(response).get('attestations')
    except (ValueError, AttributeError) as error:
        raise RuntimeError('GitHub вернул некорректный список attestations.') from error
    if not isinstance(records, list):
        raise RuntimeError('GitHub не вернул список attestations для пакета.')

    attempted = 0
    for record in records[:MAX_ATTESTATION_BUNDLES]:
        bundle = record.get('bundle') if isinstance(record, dict) else None
        if not isinstance(bundle, dict) and isinstance(record, dict) and record.get('bundle_url'):
            bundle_url = _validated_bundle_url(record['bundle_url'])
            try:
                bundle_data = read_url(bundle_url, MAX_ATTESTATION_BUNDLE_BYTES,
                                       'application/vnd.dev.sigstore.bundle.v0.3+json',
                                       allowed_hosts={ATTESTATION_BUNDLE_HOST})
            except RuntimeError:
                raise RuntimeError('Не удалось безопасно загрузить публичную Sigstore attestation bundle; обновление остановлено.') from None
            try:
                bundle = json.loads(bundle_data)
            except ValueError as error:
                raise RuntimeError('GitHub вернул некорректную Sigstore attestation bundle.') from error
        if not isinstance(bundle, dict):
            continue
        fd, bundle_name = tempfile.mkstemp(prefix='.antidpi-attestation-', suffix='.json',
                                           dir=package_path.parent)
        bundle_path = Path(bundle_name)
        try:
            with os.fdopen(fd, 'w', encoding='utf-8') as stream:
                json.dump(bundle, stream, ensure_ascii=False, separators=(',', ':'))
            command = [gh, 'attestation', 'verify', str(package_path),
                       '--repo', ATTESTATION_REPOSITORY,
                       '--bundle', str(bundle_path),
                       '--signer-workflow', ATTESTATION_WORKFLOW,
                       '--source-ref', 'refs/heads/main', '--deny-self-hosted-runners']
            result = subprocess.run(command, capture_output=True, text=True, timeout=180,
                                    env=dict(os.environ, LC_ALL='C'), check=False)
            attempted += 1
            if result.returncode == 0:
                return None
        except (OSError, subprocess.TimeoutExpired) as error:
            raise RuntimeError('GitHub CLI не смог проверить attestation релизного архива; обновление остановлено.') from error
        finally:
            bundle_path.unlink(missing_ok=True)
    if attempted == 0:
        raise RuntimeError('Для SHA-256 пакета нет доступной Sigstore attestation; обновление остановлено.')
    raise RuntimeError('Ни одна Sigstore attestation не подтвердила пакет и ожидаемый release workflow из main; обновление остановлено. Обновите gh и проверьте релиз вручную.')


def version_key(value):
    if not re.fullmatch(r'[0-9]+(?:\.[0-9]+){1,3}', str(value)):
        raise ValueError('Некорректная версия Linux-пакета.')
    parts = [int(part) for part in str(value).split('.')]
    while len(parts) > 2 and parts[-1] == 0:
        parts.pop()
    return tuple(parts)


def read_url(url, limit, accept='application/octet-stream', api_version=None, allowed_hosts=None):
    headers = {'Accept': accept, 'User-Agent': 'AntiDPI-Linux-Updater/1'}
    if api_version:
        headers['X-GitHub-Api-Version'] = api_version
    request = urllib.request.Request(url, headers=headers)
    opener = urllib.request.build_opener(_SafeRedirectHandler(allowed_hosts))
    try:
        with opener.open(request, timeout=30) as response:
            final = urlparse(response.geturl())
            try:
                final_port = final.port
            except ValueError:
                final_port = -1
            if (final.scheme != 'https' or not final.hostname or final_port not in (None, 443) or
                    final.username or final.password or
                    (allowed_hosts is not None and final.hostname.lower() not in allowed_hosts)):
                raise RuntimeError('Обновление перенаправлено на небезопасный адрес.')
            length = response.headers.get('Content-Length')
            if length:
                try:
                    declared_size = int(length)
                except ValueError as error:
                    raise RuntimeError('GitHub вернул некорректный размер файла.') from error
                if declared_size < 0 or declared_size > limit:
                    raise RuntimeError('Файл обновления превышает допустимый размер.')
            data = bytearray()
            while True:
                chunk = response.read(min(1024 * 1024, limit + 1 - len(data)))
                if not chunk:
                    break
                data.extend(chunk)
                if len(data) > limit:
                    raise RuntimeError('Файл обновления превышает допустимый размер.')
            return bytes(data)
    except (urllib.error.URLError, TimeoutError, OSError) as error:
        raise RuntimeError('Не удалось получить релиз с GitHub: ' + str(error)) from error


def latest_linux_assets(release):
    if not isinstance(release, dict) or release.get('draft') or release.get('prerelease'):
        raise RuntimeError('GitHub не вернул опубликованный стабильный релиз.')
    assets = release.get('assets')
    if not isinstance(assets, list):
        raise RuntimeError('В релизе отсутствует список файлов.')
    package = re.compile(r'^AntiDPI_CLI_v([0-9]+(?:\.[0-9]+){1,3})_Linux_x64\.tar\.gz$')
    found = []
    for asset in assets:
        if not isinstance(asset, dict):
            continue
        match = package.fullmatch(str(asset.get('name', '')))
        if match:
            found.append((match[1], asset))
    if len(found) != 1:
        raise RuntimeError('В релизе должен быть ровно один Linux x64 TAR.GZ.')
    version, archive = found[0]
    if release.get('tag_name') != 'v' + version:
        raise RuntimeError('Тег релиза не совпадает с версией Linux-пакета.')
    sums_name = 'SHA256SUMS_Linux_v' + version + '.txt'
    sums = [asset for asset in assets if isinstance(asset, dict) and asset.get('name') == sums_name]
    if len(sums) != 1:
        raise RuntimeError('В релизе отсутствует однозначный файл контрольных сумм Linux.')
    base_url = f"https://github.com/Vidoc3000/anti-dpi-for-russia-TEST/releases/download/{release['tag_name']}/"
    archive_url = archive.get('browser_download_url', '')
    sums_url = sums[0].get('browser_download_url', '')
    if archive_url != base_url + archive['name'] or sums_url != base_url + sums_name:
        raise RuntimeError('Ссылки на файлы обновления не соответствуют официальному репозиторию и тегу.')
    size = int(archive.get('size') or 0)
    if size <= 0 or size > MAX_ARCHIVE_BYTES:
        raise RuntimeError('Размер Linux-пакета вне допустимого диапазона.')
    return version, archive['name'], archive_url, sums_url, size


def checksum_for(text, filename):
    lines = [line for line in text.splitlines() if line.strip()]
    matching = [re.fullmatch(r'([0-9a-fA-F]{64})  (.+)', line) for line in lines]
    matching = [match for match in matching if match and match[2] == filename]
    if len(matching) != 1 or len(lines) != 1:
        raise RuntimeError('Файл SHA256SUMS содержит некорректную или неоднозначную запись.')
    return matching[0][1].lower()


def safe_extract(archive_path, destination, expected_root):
    destination = Path(destination)
    records = []
    seen = set()
    total = 0
    with tarfile.open(archive_path, mode='r:gz') as archive:
        members = archive.getmembers()
        if len(members) > MAX_FILES:
            raise RuntimeError('В архиве слишком много файлов.')
        for member in members:
            name = member.name
            path = PurePosixPath(name)
            if (not name or name.startswith('/') or '\\' in name or name != path.as_posix() or
                    any(part in ('', '.', '..') for part in path.parts) or
                    path.parts[0] != expected_root):
                raise RuntimeError('Недопустимый путь в Linux-архиве: ' + name)
            if not (member.isfile() or member.isdir()):
                raise RuntimeError('Ссылки и специальные файлы в Linux-архиве запрещены: ' + name)
            key = path.as_posix()
            if key in seen:
                raise RuntimeError('Повторяющийся путь в Linux-архиве: ' + name)
            seen.add(key)
            if member.isfile():
                if member.size < 0:
                    raise RuntimeError('Некорректный размер файла в Linux-архиве.')
                total += member.size
                if total > MAX_EXPANDED_BYTES:
                    raise RuntimeError('Распакованный Linux-архив превышает допустимый размер.')
            relative = Path(*path.parts[1:])
            if not relative.parts:
                if not member.isdir():
                    raise RuntimeError('Корень Linux-архива должен быть каталогом.')
                continue
            records.append((member, destination / relative))
        for member, target in records:
            if member.isdir():
                target.mkdir(parents=True, exist_ok=True)
                target.chmod(0o755)
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            source = archive.extractfile(member)
            if source is None:
                raise RuntimeError('Не удалось прочитать файл из Linux-архива: ' + member.name)
            with source, target.open('xb') as output:
                shutil.copyfileobj(source, output, length=1024 * 1024)
            target.chmod(0o755 if member.mode & 0o111 else 0o644)
    if not (destination / 'INSTALL.sh').is_file() or not (destination / 'app/install.py').is_file():
        raise RuntimeError('В Linux-архиве отсутствует установщик обновления.')
    metadata = json.loads((destination / 'data/release.json').read_text(encoding='utf-8'))
    if metadata.get('version') != expected_root.removeprefix('AntiDPI_CLI_v').removesuffix('_Linux_x64'):
        raise RuntimeError('Версия внутри Linux-архива не совпадает с именем пакета.')
    return destination


def current_version(root):
    from app_paths import resource_path
    metadata_path = resource_path(root, 'release.json')
    try:
        metadata = json.loads(metadata_path.read_text(encoding='utf-8'))
        return str(metadata['version'])
    except (OSError, ValueError, KeyError, TypeError) as error:
        raise RuntimeError('Не удалось определить установленную версию Linux-пакета.') from error


def update(root, yes=False, check=False):
    if os.geteuid() != 0 and not check:
        raise RuntimeError('Для обновления нужны права администратора. Запустите: sudo antidpi update')
    if check and yes:
        raise RuntimeError('--check не совмещается с --yes: проверка не вносит изменений.')
    root = Path(root).resolve()
    if root.name == 'app' and (root.parent / 'INSTALL.sh').is_file():
        root = root.parent
    current = current_version(root)
    print('Проверяю сведения о стабильном GitHub-релизе…',flush=True)
    release = json.loads(read_url(API_URL, 2 * 1024 * 1024, 'application/vnd.github+json'))
    version, archive_name, archive_url, sums_url, expected_size = latest_linux_assets(release)
    if version_key(version) <= version_key(current):
        print(f'Установлена актуальная Linux-версия v{current}.')
        return 0
    print(f'Найдена версия v{version}; загружаю контрольную сумму…',flush=True)
    sums = read_url(sums_url, 64 * 1024, 'text/plain').decode('utf-8')
    expected = checksum_for(sums, archive_name)
    print('Загружаю Linux x64 пакет…',flush=True)
    package = read_url(archive_url, MAX_ARCHIVE_BYTES)
    if len(package) != expected_size:
        raise RuntimeError('Размер Linux-пакета не совпал с метаданными GitHub release.')
    actual = hashlib.sha256(package).hexdigest()
    if actual != expected:
        raise RuntimeError('SHA-256 Linux-пакета не совпал с опубликованным файлом контрольных сумм.')
    print('Контрольная сумма Linux-пакета проверена.')
    package_root = 'AntiDPI_CLI_v' + version + '_Linux_x64'
    with tempfile.TemporaryDirectory(prefix='antidpi-update-') as temporary:
        temporary = Path(temporary)
        archive_path = temporary / archive_name
        archive_path.write_bytes(package)
        print('Проверяю подпись происхождения релиза…',flush=True)
        verify_release_attestation(archive_path)
        print('GitHub provenance attestation подтверждена ожидаемым workflow.')
        print('Проверяю состав и структуру пакета…',flush=True)
        source = safe_extract(archive_path, temporary / 'release', package_root)
        if check:
            print(f'Проверка завершена: v{version} доступна; SHA-256, attestation и архив проверены. Система не изменена.')
            return 0
        installer = source / 'app/install.py'
        command = [sys.executable, str(installer), 'update', '--prefix', str(root)]
        if yes:
            command.append('--yes')
        result = subprocess.run(command, cwd=source, check=False)
        return result.returncode


def rollback(root, yes=False):
    if os.geteuid() != 0:
        raise RuntimeError('Для отката нужны права администратора. Запустите: sudo antidpi rollback')
    root = Path(root).resolve()
    if root.name == 'app' and (root.parent / 'INSTALL.sh').is_file():
        root = root.parent
    installer = root / 'install.py'
    if not installer.is_file():
        installer = root / 'app/install.py'
    command = [sys.executable, str(installer), 'rollback', '--prefix', str(root)]
    if yes:
        command.append('--yes')
    return subprocess.run(command, cwd=root, check=False).returncode
