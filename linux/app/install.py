#!/usr/bin/env python3
"""Ubuntu/Debian CLI 1.5 installer. Copyright Igor Krauch (github.com/igareck)."""
from __future__ import annotations
import argparse
from contextlib import ExitStack
from hashlib import sha256
import json
import os
from pathlib import Path
import shlex
import shutil
import signal
import stat
import subprocess
import sys
import tarfile
import tempfile
import time
import uuid
import zipfile

SOURCE = Path(__file__).resolve().parent
PACKAGES = ['python3', 'ca-certificates', 'curl', 'iproute2', 'nftables', 'kmod',
            'fontconfig','build-essential', 'pkg-config', 'libnetfilter-queue-dev', 'libnfnetlink-dev',
            'libmnl-dev', 'zlib1g-dev', 'libcap-dev', 'libluajit-5.1-dev']
from app_paths import FILE_LAYOUT, resource_path

FILES = tuple(FILE_LAYOUT)


def digest(path):
    return sha256(path.read_bytes()).hexdigest()


def extract_source(archive, destination, archive_root):
    """Validate the official archive, then omit only its outer GitHub directory."""
    if not archive_root or '/' in archive_root or '\\' in archive_root or archive_root in ('.', '..'):
        raise RuntimeError('Некорректный корень официального архива.')
    destination = Path(destination)
    records = []
    seen = set()
    total = 0

    def target(name, size, directory):
        nonlocal total
        path = Path(name)
        if (path.is_absolute() or '..' in path.parts or '\\' in name or
                not path.parts or path.parts[0] != archive_root):
            raise RuntimeError('Недопустимый элемент исходного архива: '+name)
        relative = Path(*path.parts[1:])
        if len(path.parts) == 1:
            if not directory:
                raise RuntimeError('Корень исходного архива должен быть папкой.')
            return None
        key = relative.as_posix()
        if key in seen:
            raise RuntimeError('Повторяющийся элемент исходного архива: '+name)
        seen.add(key)
        total += size
        if total > 100*1024*1024 or len(seen) > 20000:
            raise RuntimeError('Непредвиденный размер исходников.')
        return destination/relative

    if zipfile.is_zipfile(archive):
        with zipfile.ZipFile(archive) as stream:
            for member in stream.infolist():
                mode = member.external_attr >> 16
                if stat.S_ISLNK(mode) or stat.S_IFMT(mode) not in (0, stat.S_IFREG, stat.S_IFDIR):
                    raise RuntimeError('Недопустимый элемент исходного ZIP: '+member.filename)
                path = target(member.filename, member.file_size, member.is_dir())
                if path is not None:
                    records.append((member, path))
            for member, path in records:
                if member.is_dir():
                    path.mkdir(parents=True, exist_ok=True)
                else:
                    path.parent.mkdir(parents=True, exist_ok=True)
                    with stream.open(member) as source, path.open('xb') as output:
                        shutil.copyfileobj(source, output)
        return
    with tarfile.open(archive) as stream:
        for member in stream.getmembers():
            if not (member.isfile() or member.isdir()):
                raise RuntimeError('Недопустимый элемент исходного архива: '+member.name)
            path = target(member.name, member.size, member.isdir())
            if path is not None:
                records.append((member, path))
        for member, path in records:
            if member.isdir():
                path.mkdir(parents=True, exist_ok=True)
            else:
                path.parent.mkdir(parents=True, exist_ok=True)
                with stream.extractfile(member) as source, path.open('xb') as output:
                    shutil.copyfileobj(source, output)
                path.chmod(member.mode & 0o777)


def get_archive(meta, temporary):
    from source_download import download
    with (temporary/'source-download.log').open('w', encoding='utf-8') as log:
        return download(meta,temporary/'s.arc',log=log)


def choose_engine(value=None):
    from cli_ui import color, SEPARATOR
    if value:
        return value
    if not sys.stdin.isatty():
        return 'compatible'
    print(SEPARATOR)
    print(color('Выберите одно из двух.', '96'))
    print('1. Для установки максимально совместимой версии Zapret2 (рекомендуется) - нажмите 1')
    print('2. Для установки самой последней версии Zapret2 - нажмите 2')
    while True:
        answer = input('Ваш выбор [Enter = 1]: ').strip()
        if answer in ('', '1'):
            return 'compatible'
        if answer == '2':
            return 'latest'
        print('Введите 1 или 2. Enter выбирает 1.')


def choose_shortcuts(user, value=None):
    if user is None:
        return False
    if value is not None:
        return value == 'yes'
    if not sys.stdin.isatty():
        return False
    from cli_ui import color, SEPARATOR
    print(SEPARATOR)
    print(color('Создать папку с ярлыками Запуска и Удаления (Рабочий Стол и Главное Меню) + с подробным Описанием и Инструкциями?', '96'))
    while True:
        answer = input('Введите Да/Yes или Нет/No: ').strip().casefold()
        if answer in ('да', 'yes'):
            return True
        if answer in ('нет', 'no'):
            return False
        print('Введите Да/Yes или Нет/No.')


def installation_summary(prefix, shortcuts, global_command=None):
    from cli_ui import color
    print()
    if shortcuts:
        print(color('Создана папка с удобными Ярлыками Запуска и Удаления на Рабочем Столе:'))
        print(color(Path(shortcuts['folder']).name))
        print(color('В папку также добавлено подробное Описание Стратегий и Инструкции в формате txt.'))
        print(color('Добавлен ярлык запуска в Главное Меню программ.'))
    print(color('Установлено в:'))
    print(color(str(prefix)))
    print(color('Исходные файлы запуска и удаления находятся в этой корневой папке.'))
    if shortcuts and not shortcuts.get('icons_set', True):
        print('Не удалось назначить значки в файловом менеджере; файлы запуска доступны.')
    print()
    print(color('Запуск:', '92')+' sudo bash '+shlex.quote(str(prefix/'START.sh')))
    if global_command:
        print(color('Запуск из любой папки:', '92')+' antidpi')
    print(color('Стандартное удаление (не удаляет логи и измененные файлы):', '91')+
          ' sudo bash '+shlex.quote(str(prefix/'DELETE.sh')))
    print(color('Полное удаление (вместе с корневой папкой и логами):', '91')+
          ' sudo bash '+shlex.quote(str(prefix/'DELETE.sh'))+' --purge')
    print()


def choose_prefix(value):
    while True:
        answer = value or (input('Папка установки [/opt/antidpi]: ').strip() if sys.stdin.isatty() else '')
        path = Path(answer or '/opt/antidpi').expanduser().resolve()
        if path == Path('/') or (path.exists() and (not path.is_dir() or any(path.iterdir()))):
            print('Папка уже занята, выберите другую папку или удалите текущую!')
            if value or not sys.stdin.isatty(): raise RuntimeError('Укажите новую пустую папку через --prefix.')
            continue
        return path


def install(args):
    if sys.version_info < (3, 9):
        raise RuntimeError('Нужен Python 3.9 или новее.')
    # PR #2 enabled --skip-deps outside Debian; ready dependencies now also
    # permit the same installation automatically, without a manual flag.
    from cli_ui import show_intro, color
    from desktop_integration import graphical_user, create_shortcuts, remove_shortcuts
    from source_download import select_source
    from global_command import prepare, register, remove as remove_global_command
    with ExitStack() as rollback:
        install_id=uuid.uuid4().hex
        show_intro(SOURCE, installing=True)
        print(color('Нажмите Enter для установки в /opt/antidpi по умолчанию или укажите новую пустую папку.', '94'))
        prefix = choose_prefix(args.prefix)
        selection = choose_engine(args.engine)
        desktop_user = graphical_user()
        create_desktop = choose_shortcuts(desktop_user, args.shortcuts)
        command_plan = prepare(args.global_command)
        print('----------------------')
        catalogue = json.loads((ROOT/'catalogue.json').read_text(encoding='utf-8'))
        info = catalogue['CatalogueInfo']
        total = int(info["ProfileCount"])
        print(f'\nУстановка: {prefix}\n{total} TCP/TLS-стратегий: 45 Golden + {total-45} Silver; также IPv4/IPv6 UDP/QUIC.')
        from dependencies import ensure_dependencies
        ensure_dependencies(PACKAGES, args.skip_deps)
        meta = select_source(json.loads(resource_path(SOURCE, 'upstream.json').read_text()), selection)
        prefix.parent.mkdir(parents=True, exist_ok=True)
        stage = Path(tempfile.mkdtemp(prefix='.ig-', dir=prefix.parent))
        # Lua is opened again after nfqws2 drops UID: all program ancestors must be traversable.
        stage.chmod(0o755)
        complete = False
        try:
            for name in FILES:
                target = stage/name
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(resource_path(SOURCE, name), target)
            from engine_environment import check_environment
            uid, gid = check_environment(stage)
            print(f'Окружение NFQUEUE проверено. UID/GID движка: {uid}:{gid}.', flush=True)
            archive = get_archive(meta, stage)
            unpacked = stage/'s'; unpacked.mkdir(mode=0o700)
            extract_source(archive, unpacked, meta['archive_root'])
            upstream = unpacked
            if not (upstream/'nfq2/Makefile').is_file() or not (upstream/'lua/zapret-lib.lua').is_file():
                raise RuntimeError('В официальных исходниках не найдены nfqws2 и Lua-библиотека.')
            (stage/'upstream-selected.json').write_text(json.dumps(meta, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
            print('Сборка nfqws2 под текущий Linux/CPU. Подробности: '+str(stage/'build.log'), flush=True)
            (stage/'build.log').touch(mode=0o600)
            with (stage/'build.log').open('w') as log:
                result = subprocess.run(['make','-C',str(upstream/'nfq2'),'-j'+str(min(os.cpu_count() or 2, 8))], stdout=log, stderr=subprocess.STDOUT)
            if result.returncode:
                print((stage/'build.log').read_text()[-8000:])
                raise RuntimeError('Ошибка компиляции nfqws2, см. сообщения выше.')
            engine = stage/'engine'; engine.mkdir()
            shutil.copy2(upstream/'nfq2/nfqws2', engine/'nfqws2')
            shutil.copytree(upstream/'lua', engine/'lua')
            license_file = upstream/'docs/LICENSE.txt'
            shutil.copy2(license_file, engine/'LICENSE_Bol-Van.txt')
            from antidpi import load_catalogue, engine_arguments
            for path in stage.rglob('*'):
                if path == unpacked or unpacked in path.parents: continue
                if path.is_dir(): path.chmod(0o755)
                elif path.is_file() and path.name not in ('build.log',): path.chmod(0o755 if path.name=='nfqws2' or path.suffix=='.sh' else 0o644)
            data = load_catalogue(stage)
            print(f'Проверяю параметры всех {len(data["ProfileRows"])} стратегий...', flush=True)
            with (stage/'parameters-check.log').open('w') as log:
                for row in data['ProfileRows']:
                    checked = subprocess.run(engine_arguments(stage, row)+['--dry-run'], cwd=engine, stdout=log, stderr=subprocess.STDOUT)
                    if checked.returncode:
                        log.flush()
                        print((stage/'parameters-check.log').read_text()[-8000:])
                        from engine_environment import failure_message
                        details = (stage/'parameters-check.log').read_text(errors='replace')[-8000:]
                        hint = ' Для проверки с закреплённым движком выберите вариант 1.' if selection == 'latest' else ''
                        raise RuntimeError(failure_message(row['Number'], checked.returncode, details)+hint)
            shutil.rmtree(unpacked)
            archive.unlink()  # The source is fetched again on the next installation.
            for path in stage.rglob('*'):
                if path.is_file(): path.chmod(0o755 if path.suffix=='.sh' or path.name=='nfqws2' else 0o644)
            (stage/'_state').mkdir(mode=0o700); (stage/'logs').mkdir(mode=0o700)
            for name in ('build.log','parameters-check.log','source-download.log','engine-environment.json'):
                shutil.move(stage/name, stage/'logs'/name)
            identity = {'schema':'antidpi.zapret2.linux.install.v1','version':'1.5','prefix':str(prefix),
                        'id':install_id,'upstream_commit':meta['commit'],'upstream_selection':selection,'shortcuts':None,'global_command':None,
                        'files':{p.relative_to(stage).as_posix():digest(p) for p in stage.rglob('*') if p.is_file() and p.relative_to(stage).parts[0] not in ('logs','_state','__pycache__')}}
            (stage/'installation.json').write_text(json.dumps(identity,ensure_ascii=False,indent=2)+'\n')
            if prefix.exists(): prefix.rmdir()  # Only the empty directory accepted above.
            stage.chmod(0o755)
            os.replace(stage, prefix); complete = True
            rollback.pop_all()
            if create_desktop:
                shortcuts = None
                try:
                    shortcuts = create_shortcuts(desktop_user, prefix, install_id)
                    identity['shortcuts'] = shortcuts
                    temporary_marker = prefix/'installation.json.tmp'
                    temporary_marker.write_text(json.dumps(identity, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
                    os.replace(temporary_marker, prefix/'installation.json')
                except Exception as error:
                    identity['shortcuts'] = None
                    if shortcuts:
                        remove_shortcuts(shortcuts)
                    print('Программа установлена, но создать ярлыки не удалось: '+str(error))
            command_record = None
            try:
                command_record = register(prefix, install_id, command_plan)
                identity['global_command'] = command_record
                temporary_marker = prefix/'installation.json.tmp'
                temporary_marker.write_text(json.dumps(identity, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
                os.replace(temporary_marker, prefix/'installation.json')
            except Exception as error:
                identity['global_command'] = None
                if command_record:
                    remove_global_command(command_record)
                print('Программа установлена, но создать глобальную команду не удалось: '+str(error))
            installation_summary(prefix, identity['shortcuts'], identity['global_command'])
        finally:
            if not complete:
                saved = Path('/var/log/antidpi-zapret2')/('install_failed_'+time.strftime('%Y%m%d_%H%M%S')+'_'+uuid.uuid4().hex[:8])
                try:
                    saved.mkdir(parents=True)
                    for name in ('build.log','parameters-check.log','source-download.log','engine-environment.json'):
                        if (stage/name).exists(): shutil.copy2(stage/name, saved/name)
                    print('Логи неудачной установки: '+str(saved))
                finally:
                    shutil.rmtree(stage, ignore_errors=True)
        if not args.no_launch and sys.stdin.isatty():
            subprocess.run([sys.executable,str(prefix/'antidpi.py'),'--skip-intro'], check=False)


def uninstall(args):
    from remove_installation import uninstall as remove
    remove(SOURCE, purge=args.purge, yes=args.yes)


if __name__ == '__main__':
    def terminate(_signal, _frame):
        # Closing the terminal can make sudo forward both HUP and TERM.
        # Let the first cancellation unwind cleanup without a second signal.
        for item in (signal.SIGHUP, signal.SIGTERM, signal.SIGINT):
            signal.signal(item, signal.SIG_IGN)
        raise KeyboardInterrupt
    signal.signal(signal.SIGHUP, terminate)
    signal.signal(signal.SIGTERM, terminate)
    parser=argparse.ArgumentParser(description='Установка/удаление AntiDPI CLI Linux 1.5')
    parser.add_argument('action', nargs='?', choices=('install','uninstall'),default='install')
    parser.add_argument('--prefix')
    parser.add_argument('--engine', choices=('compatible','latest'), help='Версия официального Zapret2; без аргумента предлагается выбор')
    parser.add_argument('--shortcuts', choices=('yes','no'), help='Ярлыки для пользователя графической сессии; в терминальной среде пропускаются')
    parser.add_argument('--global-command', choices=('yes','no'), help='Создать глобальную команду запуска; при конфликте без аргумента предлагается выбор')
    parser.add_argument('--skip-deps', action='store_true',help='Не устанавливать пакеты; проверить уже установленные зависимости')
    parser.add_argument('--no-launch',action='store_true')
    parser.add_argument('--yes',action='store_true')
    parser.add_argument('--purge',action='store_true',help='При удалении полностью удалить папку этой установки, включая логи и изменённые файлы')
    args=parser.parse_args()
    if os.geteuid()!=0: parser.error('Запустите через sudo bash INSTALL.sh / DELETE.sh.')
    exit_code = 0
    try:
        install(args) if args.action=='install' else uninstall(args)
    except KeyboardInterrupt:
        print('\nУстановка остановлена.'); exit_code = 130
    except Exception as error:
        from diagnostics import report_exception
        report_exception(SOURCE, error, 'installer'); exit_code = 1
    if (os.environ.get('AntiDPI_TERMINAL_WINDOW') == '1' and sys.stdin.isatty() and
            (args.no_launch or exit_code not in (0,130)) and exit_code != 130):
        try:input('\nНажмите Enter, чтобы закрыть окно.\n')
        except (EOFError, KeyboardInterrupt):pass
    raise SystemExit(exit_code)
