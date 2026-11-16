"""Privacy-conscious diagnostic bundles and private error logs. Copyright Igor Krauch."""
from __future__ import annotations

from datetime import datetime, timezone
import json
import os
from pathlib import Path
import platform
import re
import stat
import sys
import traceback
import uuid
import zipfile


def application_root(root):
    root = Path(root).resolve()
    if root.name == 'app' and (root.parent/'INSTALL.sh').is_file():
        return root.parent
    return root


def report_exception(root, error, context='application'):
    """Reporting failure must never hide the original exception."""
    details = ''.join(traceback.format_exception(type(error), error, error.__traceback__))
    print('ОШИБКА: '+str(error), file=sys.stderr)
    print(details, end='', file=sys.stderr)
    root = application_root(root)
    # Standard uninstall must not recreate the directory it just removed.
    candidates = [root/'logs'] if root.is_dir() else []
    if os.geteuid() == 0:
        candidates.append(Path('/var/log/antidpi-zapret2'))
    else:
        state = os.environ.get('XDG_STATE_HOME', '')
        state = Path(state) if state and Path(state).is_absolute() else Path.home()/'.local/state'
        candidates.append(state/'antidpi/logs')
    stamp = datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')
    for folder in candidates:
        try:
            folder.mkdir(mode=0o700, parents=True, exist_ok=True)
            path = folder/('error_'+stamp+'_'+uuid.uuid4().hex[:8]+'.log')
            fd = os.open(path, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
            with os.fdopen(fd, 'w', encoding='utf-8') as stream:
                stream.write('UTC: '+stamp+'\nContext: '+context+'\n'+details)
            print('Подробный журнал ошибки: '+str(path), file=sys.stderr)
            return path
        except OSError:
            continue
    return None


_SECRET_FIELD = re.compile(
    r'(?i)(["\']?(?:authorization|password|passwd|token|secret|api[_-]?key|cookie)'
    r'["\']?\s*[:=]\s*)(["\'][^"\']*["\']|Bearer\s+[^\s,;]+|[^\s,;]+)')
_URL = re.compile(r'(?i)\b(?:https?|socks[45]?)://[^\s"\'<>]+')
_EMAIL = re.compile(r'(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b')
_IPV4 = re.compile(r'(?<![\w.])(?:\d{1,3}\.){3}\d{1,3}(?![\w.])')
_IPV6 = re.compile(r'(?i)(?<![\w:])(?:[0-9a-f]{0,4}:){2,7}[0-9a-f]{0,4}(?:%[A-Za-z0-9_.-]+)?(?![\w:])')
_DOMAIN = re.compile(r'(?i)\b(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+'
                     r'(?:com|net|org|ru|рф|io|dev|app|cloud|info|biz|xyz|example|local)\b')
_HOME_PATH = re.compile(r'(?<!\w)/(?:home|Users)/[^/\s]+')
_BEARER = re.compile(r'(?i)\bBearer\s+[A-Za-z0-9._~+/-]+=*')
_COMMON_TOKEN = re.compile(r'\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|'
                           r'xox[baprs]-[A-Za-z0-9-]{16,}|AKIA[0-9A-Z]{16})\b')
_FIELD_VALUE = re.compile(
    r'(?i)(["\']?(?:interface|adapter|hostname|host|sni|target|user|username|prefix|address|ip)'
    r'["\']?\s*[:=]\s*)(["\'][^"\']*["\']|[^\s,;]+)')


def redact_text(text):
    """Scrub common credentials and network/user identifiers from diagnostic text."""
    text = _SECRET_FIELD.sub(r'\1[REDACTED]', text)
    text = _BEARER.sub('Bearer [REDACTED]', text)
    text = _COMMON_TOKEN.sub('[TOKEN REDACTED]', text)
    text = _FIELD_VALUE.sub(r'\1[REDACTED]', text)
    text = _URL.sub('[URL REDACTED]', text)
    text = _EMAIL.sub('[EMAIL REDACTED]', text)
    text = _IPV4.sub('[IP REDACTED]', text)
    text = _IPV6.sub('[IP REDACTED]', text)
    text = _DOMAIN.sub('[HOST REDACTED]', text)
    return _HOME_PATH.sub('/home/[USER REDACTED]', text)


def _system_report(root):
    values = {
        'application_version': 'unknown',
        'python_version': platform.python_version(),
        'platform': platform.system(),
        'kernel_release': platform.release(),
        'architecture': platform.machine(),
    }
    release = Path('/etc/os-release')
    if release.is_file():
        for line in release.read_text(encoding='utf-8', errors='replace').splitlines():
            key, separator, value = line.partition('=')
            if separator and key in {'ID', 'VERSION_ID', 'VERSION_CODENAME', 'PRETTY_NAME'}:
                values['os_' + key.lower()] = value.strip().strip('"\'')
    app_release = Path(root)/'data/release.json'
    try:
        values['application_version'] = json.loads(app_release.read_text(encoding='utf-8')).get('version', 'unknown')
    except (OSError, ValueError, AttributeError):
        pass
    return json.dumps(values, ensure_ascii=False, indent=2) + '\n'


def _diagnostic_files(root, max_files=25, max_bytes=512 * 1024):
    logs = Path(root)/'logs'
    if not logs.is_dir() or logs.is_symlink():
        return []
    found = []
    try:
        for path in logs.rglob('*'):
            try:
                info = path.lstat()
            except OSError:
                continue
            if not stat.S_ISREG(info.st_mode) or path.suffix.lower() not in {'.log', '.json', '.jsonl', '.nft'}:
                continue
            if info.st_size > max_bytes:
                continue
            found.append((info.st_mtime_ns, path))
    except OSError:
        return []
    found.sort(reverse=True)
    files = []
    for _, path in found[:max_files]:
        fd = None
        try:
            fd = os.open(path, os.O_RDONLY | getattr(os, 'O_NOFOLLOW', 0))
            opened = os.fstat(fd)
            if not stat.S_ISREG(opened.st_mode) or opened.st_size > max_bytes:
                os.close(fd)
                continue
            with os.fdopen(fd, 'rb') as stream:
                fd = None
                raw = stream.read(max_bytes + 1)
            if len(raw) > max_bytes:
                continue
            text = raw.decode('utf-8', errors='replace')
        except OSError:
            if fd is not None:
                os.close(fd)
            continue
        relative = redact_text(path.relative_to(root).as_posix())
        files.append((relative, redact_text(text)))
    return files


def diagnostic_preview(root):
    """Return the exact sanitized members that would enter the archive."""
    root = application_root(root)
    items = [('system.json', redact_text(_system_report(root)))]
    items.extend(_diagnostic_files(root))
    return items


def create_diagnostic_archive(root, output=None, *, yes=False, input_fn=input, output_fn=print):
    """Preview, let the user exclude entries, then write a mode-0600 ZIP."""
    root = application_root(root)
    items = diagnostic_preview(root)
    output_fn('Диагностический архив содержит только сведения о системе и выбранные журналы.')
    output_fn('Чувствительные значения (адреса, узлы, интерфейсы, учётные данные и домашний путь) автоматически маскируются.')
    output_fn('Предварительный просмотр включаемых файлов:')
    for index, (name, content) in enumerate(items, 1):
        output_fn(f'{index}. {name} — {len(content.encode("utf-8"))} байт после маскировки')
        snippet = content.strip().replace('\n', ' ')[:220]
        if snippet:
            output_fn('   ' + snippet)

    excluded = set()
    if items and sys.stdin.isatty() and not yes:
        answer = input_fn('Исключить файлы по номерам через запятую (Enter — ничего не исключать): ').strip()
        if answer:
            try:
                excluded = {int(part.strip()) for part in answer.split(',')}
            except ValueError as error:
                raise ValueError('Номера исключаемых файлов должны быть числами через запятую.') from error
            if any(number < 1 or number > len(items) for number in excluded):
                raise ValueError('Номер исключаемого файла вне списка.')
    selected = [(name, content) for index, (name, content) in enumerate(items, 1) if index not in excluded]
    output_fn('Будут включены: ' + (', '.join(name for name, _ in selected) or '(пустой архив)'))
    if not yes and sys.stdin.isatty():
        if input_fn('Создать архив? [y/N]: ').strip().lower() not in {'y', 'yes', 'д', 'да'}:
            output_fn('Создание архива отменено.')
            return None
    elif not yes and not sys.stdin.isatty():
        raise RuntimeError('Для создания в неинтерактивном режиме укажите --yes после просмотра состава архива.')

    stamp = datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')
    if output is None:
        output = Path.cwd()/f'antidpi-diagnostics-{stamp}.zip'
    output = Path(output).expanduser()
    parent = output.parent.resolve()
    parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    target = parent/output.name
    if target.suffix.lower() != '.zip':
        raise ValueError('Файл диагностического архива должен иметь расширение .zip.')
    fd = os.open(target, os.O_CREAT | os.O_EXCL | os.O_WRONLY | getattr(os, 'O_NOFOLLOW', 0), 0o600)
    try:
        with os.fdopen(fd, 'w+b') as stream, zipfile.ZipFile(stream, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
            notice = ('Создано AntiDPI по запросу пользователя.\n'
                      'Автоматическая маскировка может не распознать все персональные данные.\n'
                      'Проверьте содержимое архива перед отправкой.\n')
            archive.writestr('README.txt', notice)
            for name, content in selected:
                archive.writestr(name, content)
    except BaseException:
        try:
            target.unlink()
        except OSError:
            pass
        raise
    target.chmod(0o600)
    output_fn('Архив создан: ' + str(target))
    output_fn('Проверьте содержимое архива перед отправкой: маскировка не может гарантировать удаление всех персональных данных.')
    return target
