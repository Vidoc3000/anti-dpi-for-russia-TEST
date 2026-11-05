"""CLI/desktop startup, with an optional GNOME artwork window.

The graphical terminal runs as the original user. Only the installer/engine
command requests sudo. No terminal profile, default font or zoom is changed.
Copyright Igor Krauch (github.com/igareck).
"""
from __future__ import annotations
import ctypes
from hashlib import sha256
import os
from pathlib import Path
import pwd
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ET
from app_paths import resource_path

ROOT = Path(__file__).resolve().parent
FONT = 'IgareckArtLinux16.ttf'
READY = 'IGARECK_ARTWORK_RENDERER'
RENDERER = 'fresh-gnome-fontconfig-v1'
TERMINAL_UNAVAILABLE = 77  # Used only before the application command starts.


class TerminalUnavailable(RuntimeError):
    pass


def program_command(role, arguments):
    if role == 'install':
        return [sys.executable, str(ROOT/'install.py'), 'install']+arguments
    if role == 'run':
        return [sys.executable, str(ROOT/'igareck.py')]+arguments
    if role == 'uninstall':
        return [sys.executable, str(ROOT/'remove_installation.py')]+arguments
    raise RuntimeError('Неизвестный режим запуска.')


def find_terminal():
    # Ubuntu's wrapper spawns another server for --app-id. Use the native
    # client when supplied by the distribution; we already own the server.
    client = shutil.which('gnome-terminal.real') or shutil.which('gnome-terminal')
    server = next((str(path) for path in (
        Path('/usr/libexec/gnome-terminal-server'),
        Path('/usr/lib/gnome-terminal/gnome-terminal-server'),
        Path('/usr/lib/gnome-terminal-server')
    ) if path.is_file() and os.access(path, os.X_OK)), None)
    return client, server


def stop_owned(process):
    if process is not None and process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=3)


def bus_name_owned(name):
    """No shell commands, extra Python modules or global session mutations."""
    gio = ctypes.CDLL('libgio-2.0.so.0')
    glib = ctypes.CDLL('libglib-2.0.so.0')
    gobject = ctypes.CDLL('libgobject-2.0.so.0')
    gio.g_bus_get_sync.argtypes = [ctypes.c_int, ctypes.c_void_p, ctypes.c_void_p]
    gio.g_bus_get_sync.restype = ctypes.c_void_p
    glib.g_variant_new.argtypes = [ctypes.c_char_p]
    glib.g_variant_new.restype = ctypes.c_void_p
    gio.g_dbus_connection_call_sync.argtypes = [ctypes.c_void_p, ctypes.c_char_p,
        ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p, ctypes.c_void_p,
        ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_void_p, ctypes.c_void_p]
    gio.g_dbus_connection_call_sync.restype = ctypes.c_void_p
    glib.g_variant_get_child_value.argtypes = [ctypes.c_void_p, ctypes.c_size_t]
    glib.g_variant_get_child_value.restype = ctypes.c_void_p
    glib.g_variant_get_boolean.argtypes = [ctypes.c_void_p]
    glib.g_variant_get_boolean.restype = ctypes.c_int
    glib.g_variant_unref.argtypes = [ctypes.c_void_p]
    gobject.g_object_unref.argtypes = [ctypes.c_void_p]
    connection = gio.g_bus_get_sync(2, None, None)
    if not connection:
        return False
    result = child = None
    try:
        result = gio.g_dbus_connection_call_sync(connection, b'org.freedesktop.DBus',
            b'/org/freedesktop/DBus', b'org.freedesktop.DBus', b'NameHasOwner',
            glib.g_variant_new(b'(s)', name.encode()), None, 0, 1000, None, None)
        if not result:
            return False
        child = glib.g_variant_get_child_value(result, 0)
        return bool(glib.g_variant_get_boolean(child))
    finally:
        if child:
            glib.g_variant_unref(child)
        if result:
            glib.g_variant_unref(result)
        gobject.g_object_unref(connection)


def fontconfig_file(folder, environ):
    # Add only this application's font directory. All normal text continues
    # to use the user's existing Fontconfig and terminal profile settings.
    config = ET.Element('fontconfig')
    inherited = environ.get('FONTCONFIG_FILE')
    if not inherited or not Path(inherited).is_file():
        inherited = '/etc/fonts/fonts.conf'
    ET.SubElement(config, 'include', ignore_missing='yes').text = inherited
    ET.SubElement(config, 'dir').text = str(resource_path(ROOT, FONT).parent)
    cache = folder/'font-cache'
    cache.mkdir(mode=0o700)
    ET.SubElement(config, 'cachedir').text = str(cache)
    path = folder/'fonts.conf'
    ET.ElementTree(config).write(path, encoding='utf-8', xml_declaration=True)
    return path


def verify_font(environ):
    executable = shutil.which('fc-match')
    if not executable:
        # GNOME's renderer uses the native Fontconfig library; the CLI utility
        # may not be present before installer dependencies are installed.
        return
    checked = subprocess.run([executable, '-f', '%{file}', 'monospace:charset=104001'],
                             env=environ, capture_output=True, text=True, timeout=30)
    matched = Path(checked.stdout.strip())
    if checked.returncode or not matched.is_file() or sha256(matched.read_bytes()).digest() != sha256(resource_path(ROOT, FONT).read_bytes()).digest():
        raise RuntimeError('Рисунковый шрифт не выбран в окружении графического пользователя.')


def session(role, arguments):
    if os.geteuid() == 0:
        raise RuntimeError('Графический терминал должен запускаться от имени обычного пользователя.')
    return artwork_session(role, arguments)


def artwork_session(role, arguments):
    client_path, server_path = find_terminal()
    if not client_path or not server_path:
        raise TerminalUnavailable('GNOME Terminal недоступен.')
    account = pwd.getpwuid(os.geteuid())
    env = dict(os.environ, HOME=account.pw_dir, USER=account.pw_name, LOGNAME=account.pw_name)
    env.setdefault('XDG_RUNTIME_DIR', '/run/user/'+str(account.pw_uid))
    env.setdefault('DBUS_SESSION_BUS_ADDRESS', 'unix:path='+env['XDG_RUNTIME_DIR']+'/bus')
    app_id = 'io.github.igareck.Zapret2.Terminal.t'+os.urandom(8).hex()
    server = client = None
    with tempfile.TemporaryDirectory(prefix='igareck-artwork-') as temporary:
        folder = Path(temporary)
        try:
            env['FONTCONFIG_FILE'] = str(fontconfig_file(folder, env))
            verify_font(env)
        except Exception as error:
            raise TerminalUnavailable(str(error)) from error
        with (folder/'terminal-errors.log').open('wb') as errors:
            try:
                server = subprocess.Popen([server_path, '--app-id='+app_id],
                    env=env, stdin=subprocess.DEVNULL, stdout=errors, stderr=errors)
                deadline = time.monotonic()+30
                while not bus_name_owned(app_id):
                    if server.poll() is not None or time.monotonic() >= deadline:
                        errors.flush()
                        details = (folder/'terminal-errors.log').read_text(errors='replace')[-1500:]
                        raise RuntimeError('Не удалось открыть отдельный процесс терминала: '+details)
                    time.sleep(0.05)
                size = env.get('IGARECK_TERMINAL_GEOMETRY', '110x40')
                command = [client_path, '--app-id='+app_id, '--wait', '--window',
                           '--geometry='+size, '--working-directory='+env.get('IGARECK_TERMINAL_CWD', str(ROOT)),
                           '--', 'sudo', '--', sys.executable,
                           str(ROOT/'terminal_bootstrap.py'), '--inside', role]+arguments
                client = subprocess.Popen(command, env=env)
                result = client.wait()
                # A child command failure must never trigger a second install/run.
                return 1 if result == TERMINAL_UNAVAILABLE else result
            except Exception as error:
                if client is None:
                    raise TerminalUnavailable(str(error)) from error
                raise
            finally:
                stop_owned(client)
                stop_owned(server)


def current_terminal(role, arguments):
    os.environ.pop(READY, None)
    command = program_command(role, arguments)
    if os.geteuid() != 0:
        command = ['sudo', '--']+command
    os.execvp(command[0], command)


def text_terminals():
    desktop = os.environ.get('XDG_CURRENT_DESKTOP', '').lower()
    names = ['konsole'] if 'kde' in desktop else []
    names += ['x-terminal-emulator', 'konsole', 'xfce4-terminal', 'mate-terminal', 'xterm']
    seen = set()
    for name in names:
        path = shutil.which(name)
        if not path or path in seen:
            continue
        seen.add(path)
        real_name = Path(path).resolve().name
        # An alternative pointing to the GNOME client would repeat its failure.
        if real_name.startswith('gnome-terminal'):
            continue
        kind = next((item for item in ('konsole', 'xfce4-terminal', 'mate-terminal')
                     if item in real_name), name)
        options = {'konsole': ['--separate', '--nofork', '-e'],
                   'xfce4-terminal': ['--disable-server', '-x'],
                   'mate-terminal': ['--disable-factory', '-x']}.get(kind, ['-e'])
        yield [path]+options


def launch_desktop(role, arguments):
    """ELF shortcuts have no terminal; open one before asking sudo for a password."""
    if sys.stdin.isatty() and sys.stdout.isatty():
        return launch(role, arguments)
    if os.geteuid() == 0:
        raise RuntimeError('Запускайте графический ярлык от обычного пользователя. '
                           'Из root-консоли используйте bash START.sh / DELETE.sh.')
    client, server = find_terminal()
    if client and server:
        try:
            return session(role, arguments)
        except TerminalUnavailable as error:
            print('GNOME Terminal: '+str(error)+' Открываю другой терминал.', file=sys.stderr)
    env = dict(os.environ)
    env.pop(READY, None)
    env.pop('PYTHONPATH', None)
    command = ['sudo', '--', sys.executable, str(ROOT/'terminal_bootstrap.py'),
               '--inside-plain', role]+arguments
    for terminal in text_terminals():
        try:
            process = subprocess.Popen(terminal+command, env=env, cwd=str(ROOT))
        except OSError:
            continue  # No terminal process, so no application command has started.
        return process.wait()
    raise RuntimeError('Не найден терминал для ярлыка. Установите Konsole, XTerm '
                       'или другой поддерживаемый терминал; либо откройте терминал '
                       'самостоятельно и выполните bash '+str(ROOT/'START.sh' if role == 'run' else ROOT/'DELETE.sh')+'.')


def launch(role, arguments):
    from desktop_integration import graphical_user
    # Pure information commands retain their original non-root CLI behavior.
    if ('--help' in arguments or '-h' in arguments or
            (role == 'run' and arguments and arguments[0] in ('list','show','check-engine'))):
        os.execv(sys.executable, program_command(role, arguments))
    user = graphical_user()
    client_path, server_path = find_terminal()
    graphical = user is not None and sys.stdin.isatty() and sys.stdout.isatty() and client_path and server_path
    if graphical:
        env = dict(os.environ, HOME=user['home'], USER=user['username'], LOGNAME=user['username'])
        env.pop('PYTHONPATH', None)
        env.pop(READY, None)
        env['IGARECK_TERMINAL_CWD'] = os.getcwd()
        try:
            size = os.get_terminal_size(sys.stdout.fileno())
            env['IGARECK_TERMINAL_GEOMETRY'] = str(max(110, size.columns))+'x'+str(max(40, size.lines))
        except (OSError, AttributeError):
            env['IGARECK_TERMINAL_GEOMETRY'] = '110x40'
        env.setdefault('XDG_RUNTIME_DIR','/run/user/'+str(user['uid']))
        env.setdefault('DBUS_SESSION_BUS_ADDRESS','unix:path='+env['XDG_RUNTIME_DIR']+'/bus')
        def lower_privileges():
            os.initgroups(user['username'], int(user['gid']))
            os.setgid(int(user['gid']))
            os.setuid(int(user['uid']))
        print('Открываю окно программы с подключённым рисунковым шрифтом...', flush=True)
        process = subprocess.Popen([sys.executable, str(ROOT/'terminal_bootstrap.py'),
            '--session', role]+arguments, env=env, cwd='/',
            preexec_fn=lower_privileges if os.geteuid()==0 else None)
        try:
            result = process.wait()
            if result != TERMINAL_UNAVAILABLE:
                return result
            print('Не удалось подготовить графическое окно. Продолжаю в текущем терминале.', flush=True)
        except KeyboardInterrupt:
            stop_owned(process)
            return 130
    return current_terminal(role, arguments)


def main():
    arguments = sys.argv[1:]
    if not arguments:
        raise RuntimeError('Не указан режим запуска.')
    if arguments[0] in ('--inside', '--inside-plain'):
        role, rest = arguments[1], arguments[2:]
        env = dict(os.environ)
        if arguments[0] == '--inside':
            env[READY] = RENDERER
        else:
            env.pop(READY, None)
        env['IGARECK_TERMINAL_WINDOW'] = '1'
        command = program_command(role, rest)
        if os.geteuid() != 0:
            raise RuntimeError('Команда программы должна запускаться через sudo.')
        os.execve(sys.executable, command, env)
    if arguments[0] == '--session':
        try:
            return session(arguments[1], arguments[2:])
        except TerminalUnavailable as error:
            print('Графическое окно недоступно: '+str(error), file=sys.stderr)
            return TERMINAL_UNAVAILABLE
    return launch(arguments[0], arguments[1:])


if __name__ == '__main__':
    def terminate(_signal, _frame):
        raise KeyboardInterrupt
    signal.signal(signal.SIGTERM, terminate)
    signal.signal(signal.SIGHUP, terminate)
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise SystemExit(130)
    except Exception as error:
        from diagnostics import report_exception
        report_exception(ROOT, error, 'terminal bootstrap')
        raise SystemExit(1)

