"""Per-user Linux launchers; all home writes run as that user, never as root."""
from __future__ import annotations
from hashlib import sha256
import json
import os
from pathlib import Path
import pwd
import re
import shutil
import subprocess
import sys
import tempfile

FOLDER_NAME = 'AntiDPI'
INSTALL_README = 'README_Установка_Linux_v1.9.txt'
STRATEGIES_README = 'README_Стратегии_Linux_v1.9.txt'


def graphical_user(environ=None):
    env = os.environ if environ is None else environ
    if env.get('SSH_CONNECTION') or env.get('SSH_TTY'):
        return None
    try:
        uid = int(env.get('SUDO_UID') or env.get('PKEXEC_UID') or os.getuid())
        account = pwd.getpwuid(uid)
    except (ValueError, KeyError):
        return None
    if uid == 0:
        return None
    graphical = bool(env.get('DISPLAY') or env.get('WAYLAND_DISPLAY') or
                     env.get('XDG_SESSION_TYPE') in ('x11', 'wayland'))
    if not graphical:
        try:
            display = subprocess.run(['loginctl', 'show-user', str(uid), '-p', 'Display', '--value'],
                                     capture_output=True, text=True, timeout=3, check=True).stdout.strip()
            if display:
                session_type = subprocess.run(['loginctl', 'show-session', display, '-p', 'Type', '--value'],
                                              capture_output=True, text=True, timeout=3, check=True).stdout.strip()
                graphical = session_type in ('x11', 'wayland')
        except (OSError, subprocess.SubprocessError):
            pass
    if not graphical:
        return None
    home = Path(account.pw_dir)
    result = dict(uid=uid, gid=account.pw_gid, username=account.pw_name, home=str(home))
    # Do not reuse root's XDG paths after sudo. User-owned custom XDG paths are
    # retained only when sudo preserved the original user's environment.
    for key in ('XDG_CONFIG_HOME', 'XDG_DATA_HOME'):
        value = env.get(key, '')
        if value and Path(value).is_absolute():
            try:
                if Path(value).stat().st_uid == uid:
                    result[key] = value
            except OSError:
                pass
    return result


def desktop_directory(user):
    home = Path(user['home'])
    config = Path(user.get('XDG_CONFIG_HOME', home/'.config'))/'user-dirs.dirs'
    try:
        text = config.read_text(encoding='utf-8')
    except OSError:
        text = ''
    match = re.search(r'^\s*XDG_DESKTOP_DIR="((?:\\.|[^"\\])*)"\s*$', text, re.M)
    if match:
        value = match.group(1)
        if value == '$HOME':
            return home
        if value.startswith('$HOME/'):
            value = str(home)+value[5:]
        value = re.sub(r'\\([\\"$`])', r'\1', value)
        if '$' not in value and '`' not in value and Path(value).is_absolute():
            return Path(value)
    # Localized desktops on systems without xdg-user-dirs.
    for name in ('Desktop', 'Рабочий стол'):
        if (home/name).is_dir():
            return home/name
    return home/'Desktop'


def key_string(value):
    return str(value).replace('\\', '\\\\').replace('\n', '\\n').replace('\r', '\\r')


def exec_argument(value):
    value = str(value).replace('%', '%%')
    # Desktop Entry value unescaping happens before Exec argument unquoting.
    for char in ('\\', '"', '`', '$'):
        value = value.replace(char, '\\'+char)
    return '"'+key_string(value)+'"'


def launcher(root, action, install_id):
    script = root/('START.sh' if action == 'start' else 'DELETE.sh')
    title = 'START_AntiDPI' if action == 'start' else 'DELETE_AntiDPI'
    comment = 'Запуск стратегий AntiDPI + Zapret2' if action == 'start' else 'Удаление этой установки AntiDPI + Zapret2 с подтверждением'
    return '\n'.join([
        '[Desktop Entry]', 'Version=1.0', 'Type=Application',
        'Name='+title, 'Comment='+comment,
        'Exec=/bin/bash '+exec_argument(script),
        'Icon='+key_string(root/('antidpi-zapret2.png' if action == 'start' else 'AntiDPI_Zapret2_delete.jpg')),
        'Terminal=true', 'Categories=Network;', 'StartupNotify=false',
        'X-AntiDPI-Install-ID='+install_id, ''
    ])


def _write_new(path, data, mode, records):
    # Existing user files and symlinks are never replaced.
    with path.open('xb') as stream:
        stream.write(data)
    path.chmod(mode)
    records.append(dict(path=str(path), sha256=sha256(data).hexdigest()))


def c_string(value):
    # Encode filenames as UTF-8 byte escapes, never as compiler/shell syntax.
    return '"'+''.join('\\%03o' % byte for byte in str(value).encode('utf-8'))+'"'


def native_shortcuts(root, folder, files):
    # Nautilus launches ELF programs by double-click, but deliberately opens
    # text-based .desktop files in the editor inside ordinary folders.
    # Compile with the existing build-essential dependency, as the user.
    result = []
    with tempfile.TemporaryDirectory(prefix='.antidpi-shortcuts-') as temporary:
        build = Path(temporary)
        for action in ('start', 'delete'):
            header = '#define AntiDPI_HELPER '+c_string(root/'desktop_integration.py')+'\n'
            header += '#define AntiDPI_ACTION '+c_string(action)+'\n'
            (build/'launcher_config.h').write_text(header, encoding='ascii')
            completed = subprocess.run(['cc', '-std=c99', '-Os', '-s', '-Wall', '-Wextra',
                '-I', str(build), str(root/'desktop_launcher.c'), '-o', str(build/'launcher')],
                capture_output=True, text=True, timeout=20)
            if completed.returncode:
                raise RuntimeError('Не удалось создать файл запуска: '+completed.stderr[-1500:])
            name = ('START' if action == 'start' else 'DELETE')+'_AntiDPI'
            path = folder/name
            _write_new(path, (build/'launcher').read_bytes(), 0o755, files)
            result.append(path)
    return result


def set_icons(paths, root, user):
    env = dict(os.environ, HOME=user['home'], USER=user['username'], LOGNAME=user['username'])
    env['XDG_RUNTIME_DIR'] = '/run/user/'+str(user['uid'])
    env['DBUS_SESSION_BUS_ADDRESS'] = 'unix:path='+env['XDG_RUNTIME_DIR']+'/bus'
    if not shutil.which('gio'):
        return False
    success = True
    for path in paths:
        try:
            icon = root/('AntiDPI_Zapret2_delete.jpg' if path.name.startswith('DELETE_') else 'antidpi-zapret2.png')
            completed = subprocess.run(['gio', 'set', str(path), 'metadata::custom-icon',
                icon.as_uri()], env=env,
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=3)
            success = success and completed.returncode == 0
        except (OSError, subprocess.TimeoutExpired):
            success = False
    return success


def _create(user, root, install_id):
    desktop = desktop_directory(user)
    data_home = Path(user.get('XDG_DATA_HOME', Path(user['home'])/'.local/share'))
    applications = data_home/'applications'
    desktop.mkdir(parents=True, exist_ok=True)
    applications.mkdir(parents=True, exist_ok=True)
    folder = desktop/FOLDER_NAME
    suffix = 1
    while folder.exists() or folder.is_symlink():
        suffix += 1
        folder = desktop/(FOLDER_NAME+'_'+str(suffix))
    folder.mkdir(mode=0o755)
    files = []
    record = dict(schema='antidpi.desktop.v1', user=user, folder=str(folder), files=files)
    try:
        native = native_shortcuts(root, folder, files)
        for name in (INSTALL_README, STRATEGIES_README):
            _write_new(folder/name, (root/name).read_bytes(), 0o644, files)
        menu = applications/('io.github.antidpi.Zapret2-'+install_id+'.desktop')
        _write_new(menu, launcher(root, 'start', install_id).replace(
            'Name=START_AntiDPI', 'Name=AntiDPI').encode('utf-8'), 0o644, files)
        record['menu'] = str(menu)
        if shutil.which('update-desktop-database'):
            subprocess.run(['update-desktop-database', str(applications)], stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL, check=False, timeout=10)
        record['icons_set'] = set_icons(native, root, user)
        return record
    except BaseException:
        _remove(record)
        raise


def _remove(record):
    for item in record.get('files', []):
        path = Path(item['path'])
        if path.is_file() and not path.is_symlink() and sha256(path.read_bytes()).hexdigest() == item['sha256']:
            path.unlink()
    try:
        Path(record['folder']).rmdir()
    except OSError:
        pass
    return {'removed': True}


def run_as_user(action, user, helper=None, **payload):
    account = pwd.getpwuid(int(user['uid']))
    if account.pw_name != user['username'] or account.pw_dir != user['home']:
        raise RuntimeError('Учётная запись владельца ярлыков изменилась.')
    def lower_privileges():
        os.initgroups(account.pw_name, account.pw_gid)
        os.setgid(account.pw_gid)
        os.setuid(account.pw_uid)
    env = dict(os.environ, HOME=account.pw_dir, USER=account.pw_name, LOGNAME=account.pw_name)
    env.pop('PYTHONPATH', None)
    completed = subprocess.run([
        sys.executable, str(helper or Path(__file__).resolve()), action
    ], input=json.dumps(dict(user=user, **payload)), text=True, capture_output=True,
        cwd='/', env=env, preexec_fn=lower_privileges if os.geteuid()==0 else None,
        timeout=90)
    if completed.returncode:
        raise RuntimeError(completed.stderr.strip() or 'Не удалось настроить ярлыки.')
    return json.loads(completed.stdout)


def create_shortcuts(user, root, install_id):
    if not re.fullmatch(r'[0-9a-f]{32}', install_id):
        raise RuntimeError('Некорректный ID установки.')
    return run_as_user('create', user, helper=root/'desktop_integration.py', root=str(root), install_id=install_id)


def remove_shortcuts(record):
    if record.get('schema') != 'antidpi.desktop.v1':
        raise RuntimeError('Некорректный маркер ярлыков.')
    return run_as_user('remove', record['user'], record=record)


if __name__ == '__main__':
    try:
        if len(sys.argv) == 3 and sys.argv[1] == '--launch' and sys.argv[2] in ('start', 'delete'):
            from terminal_bootstrap import launch_desktop
            raise SystemExit(launch_desktop('run' if sys.argv[2] == 'start' else 'uninstall', []))
        payload = json.load(sys.stdin)
        if os.geteuid() != int(payload['user']['uid']):
            raise RuntimeError('Создание ярлыков должно выполняться от имени пользователя.')
        if sys.argv[1] == 'create':
            result = _create(payload['user'], Path(payload['root']), payload['install_id'])
        elif sys.argv[1] == 'remove':
            result = _remove(payload['record'])
        else:
            raise RuntimeError('Неизвестное действие с ярлыками.')
        print(json.dumps(result, ensure_ascii=False))
    except Exception as error:
        from diagnostics import report_exception
        report_exception(Path(__file__).resolve().parent, error, 'desktop integration')
        raise SystemExit(1)
