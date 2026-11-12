#!/usr/bin/env python3
"""AntiDPI Strategies + Bol-Van Zapret2, CLI Linux Version 1.9.
Copyright Igor Krauch (github.com/igareck).
"""
from __future__ import annotations

import argparse
import concurrent.futures
from collections import deque
import fcntl
import hashlib
import ipaddress
import json
import os
from pathlib import Path
import re
import select
from queue import SimpleQueue, Empty
import shlex
import shutil
import signal
import socket
import statistics
import subprocess
import sys
import termios
import threading
import time
import tty
import textwrap
from urllib.parse import urljoin, urlparse
import uuid
import zipfile

import cli_ui
import target_probe
from app_paths import resource_path

ROOT = Path(__file__).resolve().parent
MARK = '0x20000000'
PACKETS = 32
THRESHOLD = 100 * 1024
VERSION = cli_ui.VERSION
PRINT_LOCK = threading.Lock()


def run(argv, **kwargs):
    kwargs.setdefault('env', dict(os.environ, LC_ALL='C'))
    return subprocess.run([str(x) for x in argv], text=True, capture_output=True, timeout=20, **kwargs)


def atomic_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_name(path.name + '.' + uuid.uuid4().hex + '.tmp')
    temp.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    temp.chmod(0o600)
    os.replace(temp, path)


def load_catalogue(root=ROOT):
    data = json.loads(resource_path(root, 'catalogue.json').read_text(encoding='utf-8'))
    rows, families = data['ProfileRows'], data['FamilyRows']
    expected_profiles = int(data['CatalogueInfo']['ProfileCount'])
    expected_families = int(data['CatalogueInfo']['FamilyCount'])
    if ([r['Number'] for r in rows] != list(range(1, expected_profiles + 1))
            or len(families) != expected_families):
        raise RuntimeError('Повреждён каталог: число стратегий/семейств не совпадает с метаданными.')
    for family in families:
        group = [r for r in rows if r['Family'] == family['Number']]
        if len(group) != family['Count'] or [r['Number'] for r in group] != list(range(family['First'], family['Last'] + 1)):
            raise RuntimeError('Повреждены границы семейства.')
    return data


def recipe_range(value):
    match = re.fullmatch(r'\s*(\d+)(?:\s*-\s*(\d+))?\s*', value)
    if not match:
        raise ValueError('Введите номер или диапазон, например 1-50.')
    first, last = int(match[1]), int(match[2] or match[1])
    maximum = int(load_catalogue()['CatalogueInfo']['ProfileCount'])
    if not 1 <= first <= last <= maximum:
        raise ValueError(f'Допустимые номера: 1–{maximum}.')
    return list(range(first, last + 1))


def port_ranges(value):
    value=str(value).strip().casefold()
    if value in ('','all','все'):return [(0,65535)]
    value=value.replace('–','-').replace('—','-')
    ranges=[]
    for part in value.split(','):
        match=re.fullmatch(r'\s*([0-9]{1,5})(?:\s*-\s*([0-9]{1,5}))?\s*',part)
        if not match:raise ValueError('Введите порты 0–65535, диапазоны, комбинацию через запятую или все/all.')
        first,last=int(match[1]),int(match[2] or match[1])
        if not 0<=first<=last<=65535:raise ValueError('Порты: 0–65535; начало диапазона не должно быть больше конца.')
        ranges.append((first,last))
    merged=[]
    for first,last in sorted(ranges):
        if merged and first<=merged[-1][1]+1:merged[-1]=(merged[-1][0],max(last,merged[-1][1]))
        else:merged.append((first,last))
    return merged


def parse_ports(value):
    ranges=port_ranges(value)
    if ranges==[(0,65535)]:return 'all'
    return ','.join(str(a) if a==b else f'{a}-{b}' for a,b in ranges)


def scope_guidance(scope, address_family='ipv4', protocol='tcp-tls'):
    scope=parse_ports(scope)
    family='IPv6' if address_family == 'ipv6' else 'IPv4'
    transport='UDP/QUIC' if protocol == 'udp-quic' else 'TCP/TLS'
    l4='UDP' if protocol == 'udp-quic' else 'TCP'
    lines=[f'Область действия: {family} {transport}; применяется только к распознанному QUIC Initial.' if protocol == 'udp-quic' else f'Область действия: {family} {transport}; стратегия применяется к распознанному TLS ClientHello.',
           f'Перехват ограничен выбранным IP-семейством, {l4} и портами; VPN/Tor-туннель, авторизация и доступность стороннего приложения не проверяются.',
           f'nftables направляет в NFQUEUE первые до {PACKETS} пакетов подходящего трафика; остальной трафик не подвергается данной стратегии.']
    if scope=='all':
        extra=' Динамические порты VPN могут требовать all.' if protocol=='tcp-tls' else ' Для QUIC обычно достаточно 443.'
        lines.append(f'Выбраны все {l4}-порты: в очередь может попасть больше трафика и вырасти нагрузка/задержка. Для известного порта выбирайте узкий диапазон.'+extra)
    else:
        count=sum(last-first+1 for first,last in port_ranges(scope))
        lines.append(f'Выбран набор {scope}: всего {count} {l4}-портов; остальные порты не перехватываются.')
    return lines

def show_scope_guidance(scope):
    cli_ui.paragraphs(scope_guidance(scope),'93')


def choose_ports(session,explicit=None):
    default='443' if session.protocol == 'udp-quic' else 'all'
    if explicit is not None:
        session.scope=parse_ports(explicit)
        show_scope_guidance(session.scope,session.address_family,session.protocol)
        return session.scope
    transport='UDP' if session.protocol == 'udp-quic' else 'TCP'
    print('\n----------------------\n')
    print(cli_ui.color(f'Выберите порты назначения {transport}, трафик которых будет перехватываться Zapret2.','96'))
    if session.protocol == 'udp-quic':
        cli_ui.paragraphs(['QUIC/HTTP/3 обрабатывается только на UDP-портах; обычно это 443.',
                           'QUIC-профили изменяют QUIC Initial; это не проверка доступности сайта или VPN/Tor-туннеля.'],'93')
    else:
        cli_ui.paragraphs(['TLS-стратегии работают только с TCP ClientHello; UDP/QUIC используйте в режиме QUIC.'],'93')
    while True:
        answer=input(f'Порты [Enter = {default}]: ').strip()
        try:
            session.scope=parse_ports(answer or default)
            print();show_scope_guidance(session.scope,session.address_family,session.protocol)
            return session.scope
        except ValueError as error:print(error)


def choose_network_mode(session,address_family=None,protocol=None):
    if address_family is None:
        if sys.stdin.isatty():
            print('Семейство IP: 1) IPv4  2) IPv6')
            address_family='ipv6' if input('Выбор [1]: ').strip()=='2' else 'ipv4'
        else:address_family='ipv4'
    if protocol is None:
        if sys.stdin.isatty():
            print('Протокол: 1) TCP + TLS  2) UDP + QUIC/HTTP/3')
            protocol='udp-quic' if input('Выбор [1]: ').strip()=='2' else 'tcp-tls'
        else:protocol='tcp-tls'
    session.address_family=address_family
    session.protocol=protocol
    session.nft_family='ip6' if address_family=='ipv6' else 'ip'
    return address_family,protocol

QUIC_PROFILES={
    'fake2': {'Number':493,'Name':'QUIC fake (2 повторения)','Protocol':'udp-quic','NeedsTimestamps':False,
              'Args':['--payload=quic_initial','--lua-desync=fake:blob=fake_default_quic:repeats=2']},
    'fake11': {'Number':494,'Name':'QUIC fake (11 повторений)','Protocol':'udp-quic','NeedsTimestamps':False,
               'Args':['--payload=quic_initial','--lua-desync=fake:blob=fake_default_quic:repeats=11']},
}


def engine_arguments(root, row, queue=20000, scope='all', address_family='ipv4', protocol='tcp-tls'):
    engine = root / 'engine'
    ipver='6' if address_family=='ipv6' else '4'
    transport='udp' if protocol=='udp-quic' else 'tcp'
    app_proto='quic' if protocol=='udp-quic' else 'tls'
    args = [str(engine / 'nfqws2'), '--qnum=' + str(queue), '--fwmark=' + MARK, '--bind-fix'+ipver,
            '--lua-init=@' + str(engine / 'lua/zapret-lib.lua'),
            '--lua-init=@' + str(engine / 'lua/zapret-antidpi.lua')]
    if os.geteuid() == 0:
        from engine_environment import privilege_arguments
        args[1:1] = privilege_arguments()
    if protocol == 'tcp-tls' and any(a.startswith('--lua-desync=fake:') and 'blob=reasm_data' in a and ':tls_mod=' in a for a in row['Args']):
        args.append('--lua-init=@' + str(root / 'actual_tls_guard.lua'))
    if row.get('Init'):
        args.append('--lua-init=' + row['Init'])
    scope=parse_ports(scope)
    args += [f'--filter-{transport}=' + ('*' if scope == 'all' else scope), '--filter-l7='+app_proto,
             '--ipset-exclude=' + str(root / 'lists' / ('ips6-exclude.txt' if address_family=='ipv6' else 'ips-exclude.txt'))]
    return args + row['Args']

def nft_rules(table, interface, entries, networks, scope='all', replace=False,
              address_family='ipv4', protocol='tcp-tls'):
    if not re.fullmatch(r'antidpi_z2_[0-9a-f]{12}', table) or not re.fullmatch(r'[A-Za-z0-9_.:@-]{1,15}', interface):
        raise ValueError('Некорректное имя таблицы или интерфейса.')
    version=6 if address_family=='ipv6' else 4
    nft_family='ip6' if version==6 else 'ip'
    addr_type='ipv6_addr' if version==6 else 'ipv4_addr'
    l4='udp' if protocol=='udp-quic' else 'tcp'
    nets=list(ipaddress.collapse_addresses(ipaddress.ip_network(x) for x in networks
              if ipaddress.ip_network(x).version==version))
    scope=parse_ports(scope)
    selected=port_ranges(scope)
    port_set='{ '+', '.join(str(a) if a==b else f'{a}-{b}' for a,b in selected)+' }'
    out=[f'delete table {nft_family} {table}'] if replace else []
    out += [f'table {nft_family} {table} {{', f' set excluded {{ type {addr_type}; flags interval;',
            '  elements = { '+', '.join(str(n) for n in nets)+' };', ' }',
            ' chain raw_out { type filter hook output priority -401; policy accept;',
            f'  oifname "{interface}" meta mark & {MARK} != 0 notrack', ' }',
            ' chain out { type filter hook output priority -150; policy accept;',
            f'  meta mark & {MARK} != 0 return', f'  {nft_family} daddr @excluded return']
    for entry in entries:
        service_port=f'{l4} dport {entry["ports"][0]}-{entry["ports"][1]} ' if entry.get('ports') else ''
        dest=f'{l4} dport {port_set} ' if scope!='all' else f'meta l4proto {l4} '
        out.append(f'  oifname "{interface}" {dest}{service_port}ct original packets 1-{PACKETS} counter queue num {entry["queue"]} bypass')
    out += [' }', ' chain incoming { type filter hook input priority -150; policy accept;',
            f'  meta mark & {MARK} != 0 return', f'  {nft_family} saddr @excluded return']
    for entry in entries:
        service_port=f'{l4} dport {entry["ports"][0]}-{entry["ports"][1]} ' if entry.get('ports') else ''
        src=f'{l4} sport {port_set} ' if scope!='all' else f'meta l4proto {l4} '
        guard=f'{l4} flags & (syn | ack) == (syn | ack) ' if l4=='tcp' else f'ct original packets 1-{PACKETS} '
        out.append(f'  iifname "{interface}" {src}{service_port}{guard}counter queue num {entry["queue"]} bypass')
    out += [' }', '}']
    return '\n'.join(out)+'\n'

def stop_process(process):
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=4)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=3)


def process_stamp(pid):
    try:
        return Path(f'/proc/{pid}/stat').read_text().rsplit(')', 1)[1].split()[19]
    except (OSError, IndexError):
        return None


def queue_numbers():
    try:
        return {int(line.split()[0]) for line in Path('/proc/net/netfilter/nfnetlink_queue').read_text().splitlines() if line.split()}
    except FileNotFoundError:
        return set()


class Session:
    def __init__(self, root=ROOT):
        self.root = root
        manifest = json.loads((root / 'installation.json').read_text())
        if manifest.get('standard_uninstalled'):
            raise RuntimeError('Программа уже удалена. Для удаления сохранённых логов и папки используйте DELETE.sh --purge.')
        if not re.fullmatch(r'[0-9a-f]{32}', manifest['id']) or Path(manifest['prefix']) != root:
            raise RuntimeError('Неверный маркер установки. Запустите INSTALL.sh.')
        self.table = 'antidpi_z2_' + manifest['id'][:12]
        self.journal = root / '_state/runtime.json'
        self.config = root / '_state/adapter.json'
        self.lock = None
        self.entries = []
        self.processes = {}
        self.sysctls = {}
        self.active_table = False
        self.interface = None
        self.scope = 'all'
        self.address_family = 'ipv4'
        self.protocol = 'tcp-tls'
        self.nft_family = 'ip'
        self.stamp = time.strftime('%Y%m%d_%H%M%S') + '_' + uuid.uuid4().hex[:8]
        self.logs = root / 'logs'
        self.logs.mkdir(exist_ok=True)
        self.networks = [line.strip() for line in (root / 'lists/ips-exclude.txt').read_text().splitlines() if line.strip() and not line.startswith('#')]
        self.networks6 = [line.strip() for line in (root / 'lists/ips6-exclude.txt').read_text().splitlines() if line.strip() and not line.startswith('#')]

    def __enter__(self):
        if os.geteuid() != 0:
            raise RuntimeError('Запустите START.sh: для NFQUEUE нужны права root.')
        fd = os.open('/run/lock/antidpi-zapret2-public.lock', os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
        self.lock = os.fdopen(fd, 'w')
        try:
            fcntl.flock(self.lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            self.lock.close()
            raise RuntimeError('Уже работает другая копия Linux-оболочки AntiDPI. Закройте её сначала.')
        try:
            self.recover()
        except BaseException:
            self.lock.close(); self.lock = None
            raise
        return self

    def save(self):
        atomic_json(self.journal, {'table': self.table, 'sysctls': self.sysctls,
                    'engines': [{'pid': p.pid, 'stamp': process_stamp(p.pid)} for p, _ in self.processes.values()]})

    def recover(self):
        record = json.loads(self.journal.read_text()) if self.journal.exists() else {'table': self.table}
        if record['table'] != self.table:
            raise RuntimeError('Маркер восстановления не принадлежит этой установке.')
        for nft_family in ('ip', 'ip6'):
            listed = run(['nft', 'list', 'table', nft_family, self.table])
            if listed.returncode == 0:
                deleted = run(['nft', 'delete', 'table', nft_family, self.table])
                if deleted.returncode:
                    raise RuntimeError(deleted.stderr.strip())
            elif 'No such file or directory' not in listed.stderr and 'does not exist' not in listed.stderr:
                raise RuntimeError(listed.stderr.strip())
        for item in record.get('engines', []):
            pid = item['pid']
            if item.get('stamp') and process_stamp(pid) == item['stamp']:
                try:
                    if Path(f'/proc/{pid}/exe').resolve() == (self.root / 'engine/nfqws2').resolve():
                        os.kill(pid, signal.SIGTERM)
                except (ProcessLookupError, FileNotFoundError):
                    pass
        for name, old in record.get('sysctls', {}).items():
            path = Path('/proc/sys') / name.replace('.', '/')
            if path.exists() and path.read_text().strip() == '1':
                path.write_text(old + '\n')
        self.journal.unlink(missing_ok=True)

    def settings(self, timestamps=False):
        if shutil.which('modprobe'):
            for module in ('nf_conntrack', 'nfnetlink_queue', 'nft_queue'):
                run(['modprobe', module])
        names = ['net.netfilter.nf_conntrack_acct']
        if self.protocol == 'tcp-tls':
            names.append('net.netfilter.nf_conntrack_tcp_be_liberal')
            if timestamps:
                names.append('net.ipv4.tcp_timestamps')
        for name in names:
            path = Path('/proc/sys') / name.replace('.', '/')
            if not path.is_file():
                raise RuntimeError('Ядро Linux не предоставляет ' + name)
            current = path.read_text().strip()
            if name == 'net.ipv4.tcp_timestamps' and current in ('1','2'):
                continue
            if current != '1':
                if name not in self.sysctls:
                    self.sysctls[name] = current
                    self.save()
                path.write_text('1\n')

    def apply(self):
        if not self.entries:
            if self.active_table:
                result = run(['nft', 'delete', 'table', self.nft_family, self.table])
                if result.returncode:
                    raise RuntimeError('Не удалось убрать собственную таблицу: ' + result.stderr.strip())
            self.active_table = False
            return
        networks=self.networks6 if self.address_family=='ipv6' else self.networks
        rules = nft_rules(self.table, self.interface, self.entries, networks, self.scope, self.active_table,
                          self.address_family,self.protocol)
        (getattr(self, 'scan_logs', self.logs) / ('nft_' + self.stamp + '.nft')).write_text(rules)
        self.save()
        result = run(['nft', '-f', '-'], input=rules)
        if result.returncode:
            raise RuntimeError('nftables: ' + result.stderr.strip())
        self.active_table = True

    def start(self, row, ports=None):
        from engine_environment import check_environment, failure_message
        check_environment()
        self.settings(row['NeedsTimestamps'])
        used = queue_numbers() | {e['queue'] for e in self.entries}
        queue = next((n for n in range(24000, 25000) if n not in used), None)
        if queue is None:
            raise RuntimeError('Не найден свободный номер NFQUEUE.')
        log_path = getattr(self, 'scan_logs', self.logs) / f'nfqws2_{self.stamp}_p{row["Number"]}_{queue}.log'
        argv = engine_arguments(self.root, row, queue, self.scope,self.address_family,self.protocol)
        checked = run(argv + ['--dry-run'])
        if checked.returncode:
            log_path.write_text(checked.stdout + checked.stderr)
            raise RuntimeError(failure_message(row['Number'], checked.returncode,
                                              checked.stdout+checked.stderr)+' Лог: '+str(log_path))
        stream = log_path.open('w')
        stream.write(shlex.join(argv) + '\n'); stream.flush()
        process = subprocess.Popen([sys.executable, str(self.root / 'engine_guard.py'), str(os.getpid())] + argv,
                                   cwd=self.root / 'engine', stdout=stream, stderr=subprocess.STDOUT)
        self.processes[queue] = (process, stream)
        self.save()
        try:
            deadline = time.monotonic() + 10
            while time.monotonic() < deadline:
                if process.poll() is not None:
                    raise RuntimeError(f'nfqws2 завершился, код {process.returncode}. Лог: {log_path}')
                if queue in queue_numbers():
                    break
                time.sleep(0.05)
            else:
                raise RuntimeError('NFQUEUE не открылась за 10 секунд. Лог: ' + str(log_path))
            self.entries.append({'queue': queue, 'ports': ports, 'number': row['Number']})
            self.apply()
            return queue
        except BaseException:
            self.stop(queue)
            raise

    def stop(self, queue):
        self.entries = [e for e in self.entries if e['queue'] != queue]
        try:
            self.apply()  # Stop interception before stopping its listener.
        finally:
            if queue in self.processes:
                process, stream = self.processes.pop(queue)
                stop_process(process); stream.close()
            self.save()

    def close(self):
        failure = None
        for queue in list(self.processes):
            try:
                self.stop(queue)
            except Exception as error:
                failure = error
        # Retain the journal if table removal failed: bypass prevents a dead listener
        # blocking traffic; the next start/recover can remove the table explicitly.
        if not failure:
            self.recover()
        if self.lock:
            self.lock.close(); self.lock = None
        if failure:
            print('Не завершена очистка; запустите START.sh recover. ' + str(failure), file=sys.stderr)

    def __exit__(self, *_):
        self.close()


def interfaces(address_family='ipv4'):
    ip_switch='-6' if address_family=='ipv6' else '-4'
    addr_family='inet6' if address_family=='ipv6' else 'inet'
    addresses=json.loads(run(['ip','-j',ip_switch,'addr','show','up']).stdout)
    links={x['ifindex']:x for x in json.loads(run(['ip','-j','link']).stdout)}
    excluded={'tun','wireguard','gre','gretap','sit','ipip','vti'}
    result=[]
    for item in addresses:
        link=links.get(item['ifindex'],{})
        kind=link.get('linkinfo',{}).get('info_kind','')
        if item['ifname']=='lo' or kind in excluded or Path('/sys/class/net',item['ifname'],'tun_flags').exists():
            continue
        ips=[]
        for address in item.get('addr_info',[]):
            if address['family']!=addr_family or address.get('scope')!='global':
                continue
            local=address['local']
            if address_family=='ipv6' and (local.lower().startswith(('fe80:','ff')) or local=='::1'):
                continue
            ips.append(local)
        if ips:
            result.append({'index':item['ifindex'],'name':item['ifname'],'addresses':ips,
                           'description':adapter_description(item['ifname'])})
    return result

def adapter_description(name):
    path = Path('/sys/class/net') / name
    alias = (path/'ifalias').read_text().strip() if (path/'ifalias').exists() else ''
    driver = (path/'device/driver').resolve().name if (path/'device/driver').exists() else ''
    return alias or driver or ('Wi-Fi' if (path/'wireless').exists() else 'Ethernet / сетевой адаптер')


def choose_interface(session,explicit=None):
    family=session.address_family
    ip_switch='-6' if family=='ipv6' else '-4'
    items=interfaces(family)
    if explicit:
        matches=[x for x in items if x['name']==explicit]
        if len(matches)!=1:
            raise RuntimeError(f'Интерфейс не найден среди активных {family.upper()}-интерфейсов: '+explicit)
        session.interface=explicit
        return explicit
    if not items:
        raise RuntimeError(f'Не найден активный {family.upper()}-интерфейс. Проверьте IPv{6 if family=="ipv6" else 4} и маршрут.')
    previous=json.loads(session.config.read_text()).get('name') if session.config.exists() else None
    defaults=json.loads(run(['ip','-j',ip_switch,'route','show','default']).stdout)
    defaults.sort(key=lambda x:x.get('metric',0))
    recommended=next((r['dev'] for r in defaults if any(i['name']==r.get('dev') for i in items)),items[0]['name'])
    default=next(i for i in items if i['name']==(previous if any(x['name']==previous for x in items) else recommended))
    print(cli_ui.color(f'\nВыберите активный Интернет-адаптер для {family.upper()} AntiDPI-стратегий','96'))
    width=cli_ui.columns()
    adapter_width=min(35,max(12,(width-18)//3))
    description_width=max(12,(width-adapter_width-18)//2)
    cli_ui.table(['Индекс','Адаптер (Up)','Описание'],
                 [[str(i['index']),i['name'],i.get('description','')+f'; {family.upper()}: '+', '.join(i['addresses'])] for i in items],
                 [6,adapter_width,description_width])
    rec=next(i for i in items if i['name']==recommended)
    print('Активные (Up) индексы: '+', '.join(str(i['index']) for i in items)+'. Рекомендуется: '+str(rec['index'])+'.')
    if previous:
        print('Прошлый выбор: '+previous+(' (доступен).' if any(i['name']==previous for i in items) else ' (сейчас недоступен).'))
    print(cli_ui.color('Нажмите Enter, если хотите использовать прошлый/рекомендуемый адаптер. Либо введите индекс из предложенного списка.','96'))
    while True:
        answer=input(f'Индекс основного адаптера [Enter = {default["index"]}]: ').strip()
        selected=default if not answer else next((i for i in items if str(i['index'])==answer),None)
        if selected is None:
            print('Введите индекс из таблицы.');continue
        session.interface=selected['name']
        atomic_json(session.config,{'name':selected['name'],'index':selected['index'],'family':family})
        return session.interface


class Keyboard:
    def __enter__(self):
        self.old = termios.tcgetattr(sys.stdin) if sys.stdin.isatty() else None
        if self.old:
            tty.setcbreak(sys.stdin.fileno())
        return self

    def key(self, timeout=0.1):
        if not self.old:
            time.sleep(timeout); return None
        if not select.select([sys.stdin], [], [], timeout)[0]:
            return None
        value = os.read(sys.stdin.fileno(), 32).decode(errors='ignore')
        if value == '\x1b' and select.select([sys.stdin], [], [], 0.06)[0]:
            value += os.read(sys.stdin.fileno(), 32).decode(errors='ignore')
        return {'\x1bOP': 'switch', '\x1b[11~': 'switch', 's': 'switch',
                '\x1bOQ': 'restart', '\x1b[12~': 'restart', 'r': 'restart',
                '\x1bOR': 'adapter', '\x1b[13~': 'adapter', 'i': 'adapter',
                'q': 'quit', '\x1b': 'escape'}.get(value)

    def __exit__(self, *_):
        if self.old:
            termios.tcsetattr(sys.stdin, termios.TCSADRAIN, self.old)


def colored(text, code='93'):
    return cli_ui.color(text,code)


def show_table(data):
    cli_ui.catalogue(data)


def activate(session, row):
    queue = session.start(row)
    try:
        category='QUIC' if row.get('Protocol')=='udp-quic' else ('Golden' if row['Number']<=45 else 'Silver')
        print(f'\n{category} #{row["Number"]}: {row["Name"]}')
        transport='UDP/QUIC' if session.protocol=='udp-quic' else 'TCP/TLS'
        print(f'Интерфейс: {session.interface}; {session.address_family.upper()} {transport}; порты {session.scope}')
        print(colored(f'\nСЕЙЧАС РАБОТАЕТ СТРАТЕГИЯ {row["Number"]}!\n\n'
                      'ЧТОБЫ СМЕНИТЬ СТРАТЕГИЮ — нажмите F1 (или s)\n'
                      'ЧТОБЫ ПЕРЕЗАГРУЗИТЬ ТЕКУЩУЮ СТРАТЕГИЮ — нажмите F2 (или r)\n'
                      'ЧТОБЫ СМЕНИТЬ СЕТЕВОЙ АДАПТЕР/ПОРТ — нажмите F3 (или i)\n'
                      'ЧТОБЫ ПОЛНОСТЬЮ ОСТАНОВИТЬ РАБОТУ AntiDPI/ZAPRET2 - нажмите CTRL+C (или q)'))
        with Keyboard() as keyboard:
            while True:
                if session.processes[queue][0].poll() is not None:
                    raise RuntimeError('nfqws2 завершился. Проверьте logs/nfqws2_*.log.')
                key = keyboard.key()
                if key in ('switch', 'restart', 'adapter', 'quit'):
                    return key
    finally:
        stats=queue_snapshot(queue)
        try:
            session.stop(queue)
        finally:
            show_queue_metrics(row['Number'],stats)


def final_headers(raw, initial):
    status, headers, effective = 0, {}, initial
    for block in re.split(rb'\r?\n\r?\n', raw):
        lines = block.decode('iso-8859-1').splitlines()
        if not lines or not lines[0].startswith('HTTP/'):
            continue
        fields = lines[0].split()
        if len(fields) < 2 or not fields[1].isdigit():
            continue
        status = int(fields[1]); headers = {}
        for line in lines[1:]:
            if ':' in line:
                name, value = line.split(':', 1); headers[name.lower()] = value.strip()
        if 300 <= status < 400 and headers.get('location'):
            effective = urljoin(effective, headers['location'])
    return status, headers, effective


def queue_snapshot(queue):
    try:
        for line in Path('/proc/net/netfilter/nfnetlink_queue').read_text().splitlines():
            fields=line.split()
            if fields and int(fields[0])==queue:
                return {'raw':fields,'id_sequence':int(fields[7]),'kernel_drops':int(fields[5]),'userspace_drops':int(fields[6])}
    except (OSError,ValueError,IndexError):
        pass
    return {}


def queue_progressed(before,after):
    return bool(before and after and before.get('id_sequence') is not None and
                after.get('id_sequence') is not None and before['id_sequence']!=after['id_sequence'])


def show_queue_metrics(number,stats):
    if not stats:
        return
    sequence=stats.get('id_sequence',0)
    kernel=stats.get('kernel_drops',0)
    userspace=stats.get('userspace_drops',0)
    print(f'Очередь NFQUEUE стратегии {number}: последний ID пакета {sequence}; потери ядра {kernel}, userspace {userspace}. ID и потери очереди не измеряют объём всего сетевого трафика.')
    if kernel or userspace:
        print('Есть потери в NFQUEUE: они могут влиять на соединения. Проверьте загрузку системы; если возможно, сузьте порты и повторите тест.')


def youtube_attempt(session, ports, number, attempt, stop):
    directory = getattr(session,'scan_logs',session.logs)
    base = directory / f'YouTube_p{number:04}_r{attempt}'
    request_path=base.with_suffix('.request.json')
    error_path=base.with_suffix('.stderr')
    result_path=base.with_suffix('.result.json')
    atomic_json(request_path,{'interface':session.interface,'ports':ports,'timeout':25})
    app_root=getattr(session,'root',ROOT)
    argv=[sys.executable,str(app_root/'engine_guard.py'),str(os.getpid()),sys.executable,'-B',str(app_root/'youtube_probe.py'),str(request_path)]
    started=time.monotonic()
    queue=next((x['queue'] for x in getattr(session,'entries',[]) if x['number']==number),None)
    before=queue_snapshot(queue) if queue is not None else {}
    with error_path.open('wb') as errors:
        process=subprocess.Popen(argv,stdout=subprocess.PIPE,stderr=errors)
        try:
            while process.poll() is None and not stop.is_set() and time.monotonic()-started<28:
                time.sleep(.05)
            if process.poll() is None:
                stop_process(process)
                result={'pass':False,'bytes':0,'http':0,'reason':'CANCELLED' if stop.is_set() else 'TIMEOUT',
                        'seconds':round(time.monotonic()-started,3),'technical':False}
                process.communicate()
            else:
                output,_=process.communicate()
                try:
                    result=json.loads(output.decode('utf-8'))
                    if not isinstance(result,dict) or 'pass' not in result:raise ValueError('Некорректный результат')
                except (ValueError,UnicodeDecodeError) as error:
                    result={'pass':False,'technical':True,'bytes':0,'http':0,'reason':'PROBE_PROCESS_ERROR',
                            'error':str(error)+'; '+error_path.read_text(errors='replace')[-2000:],'exit_code':process.returncode}
        finally:
            stop_process(process)
            if process.stdout is not None:process.stdout.close()
    result.update(number=number,attempt=attempt,ports=list(ports),queue=queue,queue_before=before,
                  queue_after=queue_snapshot(queue) if queue is not None else {})
    if result.get('source_port') and before and result['queue_after'] and not queue_progressed(before,result['queue_after']):
        result.update(technical=True,reason='TRAFFIC_NOT_INTERCEPTED',error='TCP-запрос не попал в назначенную NFQUEUE. Проверьте интерфейс и маршрутизацию.')
    atomic_json(result_path,result)
    if result.get('technical'):
        raise RuntimeError('Техническая ошибка проверки YouTube: '+result['reason']+'; '+result.get('error','')+'. Лог: '+str(result_path))
    return result


def endpoint_id(target):
    if target.get('report_id'):
        return target['report_id']
    key='|'.join((target['host'].casefold(),str(target['port']),target['sni'].casefold()))
    return hashlib.sha256(key.encode('utf-8')).hexdigest()[:10]


def rank_endpoint_scores(scores):
    return sorted(scores,key=lambda x:(-x['success_rate'],-x['successes'],
                  x['median_seconds'] if x['median_seconds'] is not None else float('inf'),x['number']))


def adaptive_representatives(rows,numbers):
    families={}
    for number in numbers:
        families.setdefault(rows[number]['Family'],[]).append(number)
    return [families[family][len(families[family])//2] for family in sorted(families)]


def adaptive_family_candidates(rows,numbers,family,scheduled):
    return [number for number in numbers
            if rows[number]['Family']==family and number not in scheduled]


def endpoint_attempt(session, ports, number, attempt, stop, target):
    directory=getattr(session,'scan_logs',session.logs)
    target_key=endpoint_id(target)
    base=directory/f'Endpoint_{target_key}_p{number:04}_r{attempt}'
    result_path=base.with_suffix('.result.json')
    app_root=getattr(session,'root',ROOT)
    queue=next((x['queue'] for x in getattr(session,'entries',[]) if x['number']==number),None)
    before=queue_snapshot(queue) if queue is not None else {}
    with tempfile.TemporaryDirectory(prefix='antidpi-endpoint-') as temporary:
        request_path=Path(temporary)/'request.json'
        atomic_json(request_path,{'interface':session.interface,'ports':ports,'timeout':12,'target':target,'address_family':session.address_family})
        argv=[sys.executable,str(app_root/'engine_guard.py'),str(os.getpid()),sys.executable,'-B',str(app_root/'target_probe.py'),str(request_path)]
        started=time.monotonic()
        with tempfile.TemporaryFile() as errors:
            process=subprocess.Popen(argv,stdout=subprocess.PIPE,stderr=errors)
            try:
                while process.poll() is None and not stop.is_set() and time.monotonic()-started<15:
                    time.sleep(.05)
                if process.poll() is None:
                    stop_process(process)
                    result={'pass':False,'reason':'CANCELLED' if stop.is_set() else 'TIMEOUT',
                            'seconds':round(time.monotonic()-started,3),'technical':False}
                    process.communicate()
                else:
                    output,_=process.communicate()
                    try:
                        result=json.loads(output.decode('utf-8'))
                        if not isinstance(result,dict) or 'pass' not in result:raise ValueError('Некорректный результат')
                    except (ValueError,UnicodeDecodeError) as error:
                        result={'pass':False,'technical':True,'reason':'PROBE_PROCESS_ERROR',
                                'error':str(error),'exit_code':process.returncode}
            finally:
                stop_process(process)
                if process.stdout is not None:process.stdout.close()
    # Do not persist endpoint names, addresses, SNI, IPs, or exception text in the report.
    result.pop('error',None);result.pop('remote_ip',None);result.pop('host',None);result.pop('sni',None)
    result.update(number=number,attempt=attempt,target_id=target_key,ports=list(ports),queue=queue,
                  queue_before=before,queue_after=queue_snapshot(queue) if queue is not None else {})
    if result.get('source_port') and before and result['queue_after'] and not queue_progressed(before,result['queue_after']):
        result.update(technical=True,reason='TRAFFIC_NOT_INTERCEPTED')
    atomic_json(result_path,result)
    if result.get('technical'):
        raise RuntimeError('Техническая ошибка проверки TLS-узла: '+result['reason']+'.')
    return result


def reserve_ports(excluded=(),address_family='ipv4'):
    # Bind all 64 ports simultaneously while choosing a disjoint worker block.
    ephemeral = [int(x) for x in Path('/proc/sys/net/ipv4/ip_local_port_range').read_text().split()]
    af=socket.AF_INET6 if address_family=='ipv6' else socket.AF_INET
    for first in range(10000, 30000, 64):
        if (first, first+63) in excluded or not (first+63 < ephemeral[0] or first > ephemeral[1]):
            continue
        held = []
        try:
            for port in range(first, first+64):
                sock = socket.socket(af, socket.SOCK_STREAM)
                held.append(sock); sock.bind(('::',port,0,0) if af==socket.AF_INET6 else ('0.0.0.0',port) )
            return first, first+63
        except OSError:
            pass
        finally:
            for sock in held:
                sock.close()
    raise RuntimeError('Не найден блок свободных TCP-портов.')


def scan(session, rows, numbers, parallel, target=None, adaptive=False):
    if not 1 <= parallel <= 5:
        raise ValueError('Число параллелей должно быть от 1 до 5.')
    if target is None and not any(a<=443<=b for a,b in port_ranges(getattr(session,'scope','all'))):
        print('Проверка YouTube требует TCP-порт 443; выбранные порты его не включают.')
        return []
    if target is not None:
        target=target_probe.validate_target(target)
        target['report_id']=uuid.uuid4().hex[:10]
        session.scope=str(target['port'])
        show_scope_guidance(session.scope)
        if not target['verify_certificate']:
            print('ВНИМАНИЕ: проверка сертификата отключена; успешный результат не подтверждает подлинность сервера.')
    adaptive=bool(adaptive and target)
    numbers=list(numbers)
    representatives=adaptive_representatives(rows,numbers) if adaptive else []
    representative_set=set(representatives)
    if adaptive:
        print(f'Адаптивный поиск: сначала {len(representatives)} представителей семейств; семейство расширяется, если представитель успешен хотя бы в одной из двух попыток.')
    probe_name='Endpoint_'+endpoint_id(target) if target else 'YouTube'
    backend='TLS handshake only, IPv4' if target else 'Python SSL, IPv4, HTTP/1.1'
    print('Перед проверкой выключите VPN/TUN. Проверяется только TCP/TLS, не авторизация или работа самого VPN/Tor-клиента. Для остановки нажмите Esc.\n----------------------')
    session.scan_logs=session.logs/(probe_name+'_'+session.stamp+'_'+uuid.uuid4().hex[:6])
    session.scan_logs.mkdir(mode=0o700)
    atomic_json(session.scan_logs/'scan.json',{'version':VERSION,'interface':getattr(session,'interface',''),'numbers':numbers,'parallel':parallel,'threshold':THRESHOLD,'backend':backend,'target_id':endpoint_id(target) if target else None,'adaptive':adaptive,'representatives':representatives})
    initial=representatives if adaptive else numbers
    pending=deque(initial);scheduled=set(initial);expanded_families=set()
    stop=threading.Event();found=[];scores=[];jobs={};used=set();finished=SimpleQueue()
    log=session.scan_logs/'results.jsonl'
    completed=0;interrupted=False
    def worker(number,ports):
        results=[]
        for attempt in (1,2):
            if stop.is_set():break
            check=endpoint_attempt if target else youtube_attempt
            results.append(check(session,ports,number,attempt,stop,target) if target else check(session,ports,number,attempt,stop))
        return results
    def emit(number,results):
        nonlocal completed
        successes=sum(x['pass'] for x in results)
        status=('TLS_OK' if successes==2 else 'TLS_UNSTABLE' if successes else 'CANCELLED' if not results or any(x.get('reason')=='CANCELLED' for x in results) else 'FAIL') if target else ('PASS' if successes==2 else 'UNSTABLE' if successes else 'CANCELLED' if not results or any(x.get('reason')=='CANCELLED' for x in results) else 'FAIL')
        with log.open('a',encoding='utf-8') as file:
            file.write(json.dumps({'number':number,'status':status,'attempts':results},ensure_ascii=False)+'\n')
        completed+=1
        if target:
            samples=[x.get('seconds',0) for x in results if x.get('pass')]
            scores.append({'number':number,'stage':'representative' if number in representative_set else 'expanded',
                           'successes':successes,'attempts':len(results),
                           'success_rate':successes/len(results) if results else 0.0,
                           'median_seconds':round(statistics.median(samples),3) if samples else None})
        if adaptive and number in representative_set and successes:
            family=rows[number]['Family']
            candidates=adaptive_family_candidates(rows,numbers,family,scheduled)
            if candidates:
                expanded_families.add(family)
                for candidate in candidates:
                    pending.append(candidate);scheduled.add(candidate)
        if successes:
            print(cli_ui.color((', ' if found else '')+f'{number} ({status})','92'),end='',flush=True)
            found.append(number)
    try:
        with concurrent.futures.ThreadPoolExecutor(max_workers=parallel) as pool,Keyboard() as keyboard:
            try:
                while True:
                    while not stop.is_set() and len(jobs)<parallel:
                        if not pending:break
                        number=pending.popleft()
                        ports=reserve_ports(used,session.address_family)
                        queue=session.start(rows[number],ports)
                        used.add(ports)
                        future=pool.submit(worker,number,ports)
                        jobs[future]=(number,queue,ports)
                        future.add_done_callback(finished.put)
                    if not jobs:break
                    if keyboard.key(.08) in ('escape','quit'):
                        interrupted=True;stop.set()
                    while True:
                        try:future=finished.get_nowait()
                        except Empty:break
                        if future not in jobs:continue
                        number,queue,ports=jobs.pop(future)
                        try:emit(number,future.result())
                        finally:session.stop(queue);used.remove(ports)
                    for number,queue,ports in jobs.values():
                        if session.processes[queue][0].poll() is not None:
                            raise RuntimeError(f'nfqws2 стратегии {number} завершился; проверка остановлена, см. логи.')
            finally:
                stop.set()
                cleanup_error=None
                for future,(number,queue,ports) in list(jobs.items()):
                    try:emit(number,future.result(timeout=8))
                    except Exception as error:cleanup_error=error
                    finally:
                        try:session.stop(queue)
                        except Exception as error:cleanup_error=error
                if cleanup_error is not None and sys.exc_info()[0] is None:raise cleanup_error
    except BaseException as error:
        atomic_json(session.scan_logs/'technical_error.json',{'error':str(error),'type':type(error).__name__})
        raise
    finally:
        ranking=rank_endpoint_scores(scores)
        atomic_json(session.scan_logs/'summary.json',{'requested':len(numbers),'scheduled':len(scheduled),'completed':completed,'interrupted':interrupted,'found':found,'target_id':endpoint_id(target) if target else None,'adaptive':adaptive,'representatives':representatives,'expanded_families':sorted(expanded_families),'ranking':ranking})
        archive=shutil.make_archive(str(session.scan_logs),'zip',str(session.scan_logs))
        # The full diagnostic ZIP is saved silently; only working recipes are printed.
        print()
        del session.scan_logs
    if not found:
        if interrupted:print('Проверка остановлена пользователем.')
        print('Не найдены стратегии с успешным TLS-handshake.' if target else 'Рабочие стратегии не найдены')
    if adaptive:
        print(f'Адаптивный поиск завершён: протестировано {completed} из {len(numbers)} отобранных стратегий; расширено семейств: {len(expanded_families)}.')
    if target and scores:
        print('Рейтинг TLS-проверки (сначала доля успехов, затем медианная задержка):')
        ranking=rank_endpoint_scores(scores)
        cli_ui.table(['Место','Этап','Стратегия','Успехи','Медиана, с'],[[str(i),'Предст.' if x['stage']=='representative' else 'Расшир.',str(x['number']),f"{x['successes']}/{x['attempts']}",str(x['median_seconds'] if x['median_seconds'] is not None else '—')] for i,x in enumerate(ranking,1)],[6,9,10,8,12])
    print('----------------------')
    return found


def ask_parallel():
    while True:
        answer = input('Параллельная проверка: введите число одновременно проверяемых стратегий [от 1 до 5]: ').strip()
        if answer in ('1','2','3','4','5'):
            return int(answer)


def parse_target_argument(value, sni=None, verify=True):
    if not isinstance(value,str):
        raise ValueError('Введите узел как имя:порт или IPv6 в квадратных скобках:порт.')
    ipv6_match=re.fullmatch(r'\[([^\]]+)\]:(\d+)',value.strip())
    if ipv6_match:
        host,port=ipv6_match.groups()
    elif value.count(':')==1:
        host,port=value.rsplit(':',1)
    else:
        raise ValueError('Введите узел как имя:порт или IPv6 в квадратных скобках:порт.')
    if not port.isdecimal():
        raise ValueError('Порт цели должен быть числом от 1 до 65535.')
    return target_probe.validate_target({'host':host,'port':int(port),'sni':sni or host,
                                         'verify_certificate':verify})


def choose_benchmark_target(args):
    value=args.target
    if value is None:
        if not sys.stdin.isatty():
            raise ValueError('Для benchmark укажите --target имя:порт.')
        value=input('Адрес TLS-узла в формате имя:порт (например vpn.example.org:443): ').strip()
        if not args.sni:
            args.sni=input('SNI, если отличается от адреса (Enter = адрес): ').strip() or None
    return parse_target_argument(value,args.sni,not args.insecure)


def main():
    parser = argparse.ArgumentParser(description='AntiDPI + Zapret2 CLI 1.9 — Linux Ubuntu/Debian')
    parser.add_argument('action', nargs='?', default='menu', choices=('menu','start','youtube','benchmark','list','show','check-engine','recover'))
    parser.add_argument('--skip-intro',action='store_true',help=argparse.SUPPRESS)
    parser.add_argument('--strategy', type=int)
    parser.add_argument('--interface')
    parser.add_argument('--family', choices=('ipv4','ipv6'), help='IP-семейство для перехвата')
    parser.add_argument('--protocol', choices=('tcp-tls','udp-quic'), help='Протокол обработки')
    parser.add_argument('--quic-profile', choices=tuple(QUIC_PROFILES), help='QUIC-профиль: fake2 или fake11')
    parser.add_argument('--recipes', default=None)
    parser.add_argument('--parallel', type=int, choices=range(1, 6))
    parser.add_argument('--target', help='TLS-узел для benchmark в формате имя:порт (по умолчанию тестируются Golden 1-45)')
    parser.add_argument('--sni', help='TLS SNI; по умолчанию совпадает с именем узла')
    parser.add_argument('--insecure', action='store_true', help='не проверять сертификат (только для диагностики; небезопасно)')
    parser.add_argument('--exhaustive', action='store_true', help='не применять адаптивный отбор в benchmark: проверить все номера из --recipes')
    parser.add_argument('--scope',type=parse_ports,help='Порты выбранного TCP/UDP протокола: all/все, 443, 0-1023 или 53,80,443,1000-2000')
    args = parser.parse_args()
    data = load_catalogue()
    maximum = int(data['CatalogueInfo']['ProfileCount'])
    args.recipes=args.recipes or ('1-45' if args.action=='benchmark' else f'1-{maximum}')
    rows = {r['Number']: r for r in data['ProfileRows']}
    if args.action == 'list':
        show_table(data); return
    if args.action == 'show':
        if args.strategy not in rows:
            parser.error(f'Укажите --strategy от 1 до {maximum}.')
        print(json.dumps(rows[args.strategy], ensure_ascii=False, indent=2)); return
    if args.action == 'check-engine':
        for n in recipe_range(args.recipes):
            result = run(engine_arguments(ROOT, rows[n]) + ['--dry-run'])
            if result.returncode:
                raise RuntimeError(f'Стратегия {n}: '+result.stdout+result.stderr)
        print('Параметры всех выбранных стратегий приняты nfqws2.'); return
    if args.action!='recover' and not args.skip_intro:
        cli_ui.show_intro(ROOT)
    if args.action in ('youtube','benchmark') and args.protocol == 'udp-quic':
        parser.error('YouTube и benchmark используют TCP/TLS; QUIC этим тестированием не проверяется.')
    with Session() as session:
        if args.action == 'recover':
            print('Собственные оставшиеся правила и временные параметры восстановлены.'); return
        default_family='ipv4' if args.action in ('youtube','benchmark') else None
        choose_network_mode(session,args.family or default_family,args.protocol or ('tcp-tls' if default_family else None))
        if args.action == 'youtube' and session.address_family != 'ipv4':
            parser.error('Текущая YouTube-проверка ограничена IPv4/TCP/TLS; выберите --family ipv4.')
        choose_interface(session,args.interface)
        if args.action == 'benchmark':
            try:
                target=choose_benchmark_target(args)
            except ValueError as error:
                parser.error(str(error))
            session.scope=str(target['port'])
            scan(session,rows,recipe_range(args.recipes),args.parallel or ask_parallel(),target=target,adaptive=not args.exhaustive)
            return
        noninteractive_scope=('443' if session.protocol=='udp-quic' else 'all') if not sys.stdin.isatty() else None
        choose_ports(session,args.scope if args.scope is not None else noninteractive_scope)
        if args.action == 'youtube':
            scan(session, rows, recipe_range(args.recipes), args.parallel or ask_parallel()); return
        if session.protocol == 'udp-quic':
            if args.strategy is not None:
                parser.error('--strategy относится к TCP/TLS; используйте --quic-profile fake2|fake11.')
            preset=args.quic_profile
            if preset is None:
                if sys.stdin.isatty():
                    print('QUIC-профиль: 1) fake2  2) fake11')
                    preset='fake11' if input('Выбор [1]: ').strip()=='2' else 'fake2'
                else:preset='fake2'
            row=QUIC_PROFILES[preset]
            while True:
                key=activate(session,row)
                if key=='quit':return
                if key=='restart':
                    print(f'\nПЕРЕЗАГРУЗКА QUIC-профиля {preset}...');continue
                if key=='adapter':
                    choose_interface(session);choose_ports(session);continue
                print(colored('\nQUIC-профиль остановлен.\n','91'))
                if sys.stdin.isatty():
                    answer=input('Нажмите Enter для повтора или 0 для выхода: ').strip()
                    if answer=='0':return
                else:return
        show_table(data)
        number = args.strategy
        while True:
            if number is None:
                answer = cli_ui.selection_prompt()
                if answer == '0':
                    return
                if answer.lower() == 'youtube':
                    try:
                        numbers = recipe_range(input('Введите для проверки номер одиночной стратегии или диапазон в формате Первая-Последняя (например 1-50): '))
                    except ValueError as error:
                        print(error); continue
                    scan(session, rows, numbers, ask_parallel()); continue
                number = int(answer) if answer.isdigit() else None
            if number not in rows:
                if args.action == 'start':
                    parser.error(f'Укажите --strategy от 1 до {maximum}.')
                print(f'Допустимые номера: 1–{maximum}.'); number = None; continue
            key = activate(session, rows[number])
            if key == 'quit':
                return
            if key == 'restart':
                print(f'\nПЕРЕЗАГРУЗКА СТРАТЕГИИ {number}...'); continue
            print(colored(f'\nСТРАТЕГИЯ {number} ОСТАНОВЛЕНА!\n', '91'))
            if key == 'adapter':
                choose_interface(session);choose_ports(session);continue
            number = None


if __name__ == '__main__':
    def terminate(_signal, _frame):
        raise KeyboardInterrupt
    signal.signal(signal.SIGTERM, terminate)
    signal.signal(signal.SIGHUP, terminate)
    try:
        main()
    except (KeyboardInterrupt, EOFError):
        print('\nZapret2 остановлен.')
    except Exception as error:
        from diagnostics import report_exception
        report_exception(ROOT, error, 'runtime')
        if os.environ.get('AntiDPI_TERMINAL_WINDOW') == '1' and sys.stdin.isatty():
            try:
                input('\nНажмите Enter, чтобы закрыть окно.\n')
            except (EOFError, KeyboardInterrupt):
                pass
        raise SystemExit(1)
