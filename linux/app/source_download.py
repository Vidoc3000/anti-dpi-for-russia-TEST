"""Download official compatible/latest sources. Igor Krauch (github.com/igareck)."""
from __future__ import annotations
from hashlib import sha256
import json
import math
from pathlib import Path
import re
import subprocess
import tempfile
import time
import zipfile

WINDOW_SECONDS = 15
MINIMUM_PROGRESS = 0.03
MAX_ARCHIVE_BYTES = 64 * 1024 * 1024


def select_source(compatible, selection):
    if compatible.get('repo') != 'bol-van/zapret2':
        raise RuntimeError('Некорректный репозиторий официального Zapret2.')
    if not re.fullmatch(r'[0-9a-f]{40}', compatible.get('commit', '')):
        raise RuntimeError('Не задан коммит совместимой версии Zapret2.')
    if not re.fullmatch(r'[0-9a-f]{64}', compatible.get('sha256', '')):
        raise RuntimeError('Не задана контрольная сумма совместимой версии Zapret2.')
    if selection not in ('compatible', 'latest'):
        raise RuntimeError('Неизвестный вариант версии Zapret2.')
    result = dict(compatible)
    result['selection'] = selection
    if selection == 'latest':
        # The GitHub git-archive ZIP comment identifies the actual full commit.
        # No prerequisite request to api.github.com is required.
        result.update(commit='', sha256='', commit_date='', archive_ref='refs/heads/master',
                      archive_format='zip',
                      url='https://codeload.github.com/bol-van/zapret2/zip/refs/heads/master',
                      mirror='https://cdn.gh-proxy.org/https://github.com/bol-van/zapret2/archive/refs/heads/master.zip')
    else:
        commit = result['commit']
        result.update(archive_ref=commit, archive_format='tar.gz',
                      url='https://codeload.github.com/bol-van/zapret2/tar.gz/'+commit,
                      mirror='https://cdn.gh-proxy.org/https://github.com/bol-van/zapret2/archive/'+commit+'.tar.gz')
    return result


def content_length(path):
    """Ignore CONNECT and redirect sizes; only use a complete final response."""
    try:
        headers = path.read_text(encoding='iso-8859-1').replace('\r\n', '\n')
    except OSError:
        return 0
    for block in reversed(headers.split('\n\n')):
        lines = block.splitlines()
        if not lines or not re.match(r'^HTTP/\S+ 2\d\d(?: |$)', lines[0]):
            continue
        if 'connection established' in lines[0].lower():
            continue
        for line in lines[1:]:
            if line.lower().startswith('content-length:'):
                value = line.split(':', 1)[1].strip()
                return int(value) if value.isdecimal() else 0
        return 0
    return 0


def stop_download(process):
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=2)


def transfer(url, destination, expected_bytes):
    """A separate curl process makes even a stalled TLS/read cancellable."""
    with tempfile.TemporaryDirectory(prefix='d-', dir=destination.parent) as scratch:
        scratch = Path(scratch)
        headers, errors = scratch/'headers', scratch/'errors'
        with errors.open('wb') as stderr:
            process = subprocess.Popen([
                'curl', '--disable', '--location', '--fail', '--silent', '--show-error',
                '--globoff', '--proto', '=https', '--proto-redir', '=https',
                '--connect-timeout', str(WINDOW_SECONDS), '--max-redirs', '5',
                '--user-agent', 'Igareck-Zapret2-Linux/1.0',
                '--dump-header', str(headers), '--output', str(destination),
                '--write-out', '%{url_effective}', url
            ], stdout=subprocess.PIPE, stderr=stderr)
            try:
                window_start = last_print = time.monotonic()
                window_bytes = 0
                last_percent = -1
                while process.poll() is None:
                    now = time.monotonic()
                    received = destination.stat().st_size if destination.exists() else 0
                    if received > MAX_ARCHIVE_BYTES:
                        raise RuntimeError('Непредвиденный размер исходного архива.')
                    known_total = content_length(headers)
                    total = max(1, known_total or expected_bytes)
                    if now-window_start >= WINDOW_SECONDS:
                        if received-window_bytes < math.ceil(total*MINIMUM_PROGRESS):
                            raise RuntimeError('Прирост меньше 3% за 15 секунд. Переключаю источник.')
                        window_start, window_bytes = now, received
                    percent = min(99, received*100//total)
                    if percent != last_percent and (percent-last_percent >= 5 or now-last_print >= 1):
                        approximate = '~' if not known_total else ''
                        print('\rЗагрузка: ['+'#'*(percent//5)+'-'*(20-percent//5)+'] '+approximate+str(percent)+'%', end='', flush=True)
                        last_percent, last_print = percent, now
                    time.sleep(0.1)
                final_url = process.communicate(timeout=2)[0].decode('utf-8', errors='replace').strip()
                if process.returncode:
                    message = errors.read_text(errors='replace').strip()[-1000:]
                    raise RuntimeError(message or 'Ошибка загрузки curl: '+str(process.returncode))
                if not destination.is_file() or not 0 < destination.stat().st_size <= MAX_ARCHIVE_BYTES:
                    raise RuntimeError('Пустой или слишком большой исходный архив.')
                return final_url
            finally:
                stop_download(process)
                if process.stdout:
                    process.stdout.close()


def identify_archive(meta, path):
    actual_hash = sha256(path.read_bytes()).hexdigest()
    if meta['selection'] == 'compatible':
        if actual_hash != meta['sha256']:
            raise RuntimeError('SHA-256 исходников не совпал с проверенной совместимой версией.')
        commit = meta['commit']
        root = 'zapret2-'+commit
    else:
        with zipfile.ZipFile(path) as archive:
            commit = archive.comment.decode('ascii').strip().lower()
            if not re.fullmatch(r'[0-9a-f]{40}', commit):
                raise RuntimeError('В официальном ZIP master не найден точный коммит; установка остановлена.')
            roots = {item.filename.split('/', 1)[0] for item in archive.infolist()}
            if roots != {'zapret2-master'}:
                raise RuntimeError('Неожиданная структура официального архива master.')
            root = 'zapret2-master'
    return dict(commit=commit, sha256=actual_hash, archive_root=root,
                bytes=path.stat().st_size, hash_verified_against_known_value=meta['selection']=='compatible')


def download(meta, destination, log=None):
    if meta.get('selection') not in ('compatible', 'latest'):
        meta.update(select_source(meta, 'compatible'))
    destination = Path(destination)
    estimate = max(1, int(meta.get('bytes') or 657657))
    sources = (meta['url'], meta['mirror'])
    for url in sources:
        if not url.startswith('https://'):
            raise RuntimeError('Исходники должны загружаться через HTTPS.')
    while True:
        for index, url in enumerate(sources):
            label = 'GitHub' if index == 0 else 'cdn.gh-proxy.org'
            partial = destination.with_name(destination.name+'.part')
            partial.unlink(missing_ok=True)
            print('Скачиваю исходники Zapret2: '+label+'\n'+url, flush=True)
            try:
                final_url = transfer(url, partial, estimate)
                verified = identify_archive(meta, partial)
                meta.update(verified, download_url=url, download_final_url=final_url,
                            download_mirror=label)
                partial.replace(destination)
                suffix = ' — SHA-256 совпал.' if meta['selection']=='compatible' else ' — коммит '+meta['commit']
                print('\rЗагрузка: ['+'#'*20+'] 100%'+suffix+'\n', flush=True)
                if log:
                    log.write('SOURCE_DOWNLOAD '+json.dumps(meta, ensure_ascii=False)+'\n')
                    log.flush()
                return destination
            except Exception as error:
                print('\nИсточник недоступен: '+str(error), flush=True)
                if log:
                    log.write('DOWNLOAD_FAILED '+url+': '+str(error)+'\n')
                    log.flush()
            finally:
                partial.unlink(missing_ok=True)
        print('Оба источника недоступны. Повторяю загрузку по кругу; для отмены нажмите Ctrl+C.', flush=True)
        time.sleep(2)
