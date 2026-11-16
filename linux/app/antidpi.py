#!/usr/bin/env python3
"""AntiDPI Strategies + Bol-Van Zapret2, CLI Linux Version 1.9.
Copyright Igor Krauch (github.com/igareck).
"""
from __future__ import annotations

import argparse
import concurrent.futures
import csv
from collections import deque
import fcntl
import hashlib
import ipaddress
import io
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
import stat
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


def atomic_text(path, text, mode=0o600):
    path=Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temp=path.with_name(path.name+'.'+uuid.uuid4().hex+'.tmp')
    try:
        fd=os.open(temp,os.O_CREAT|os.O_EXCL|os.O_WRONLY|os.O_NOFOLLOW,mode)
        with os.fdopen(fd,'w',encoding='utf-8',newline='') as stream:
            stream.write(text)
        os.replace(temp,path)
    finally:
        temp.unlink(missing_ok=True)


def atomic_export_json(path,value):
    path=Path(path)
    path.parent.mkdir(parents=True,exist_ok=True)
    temp=path.with_name(path.name+'.'+uuid.uuid4().hex+'.tmp')
    fd=os.open(temp,os.O_CREAT|os.O_EXCL|os.O_WRONLY|os.O_NOFOLLOW,0o600)
    try:
        uid=os.environ.get('SUDO_UID','');gid=os.environ.get('SUDO_GID','')
        if os.geteuid()==0 and uid.isdecimal():os.fchown(fd,int(uid),int(gid) if gid.isdecimal() else -1)
        with os.fdopen(fd,'w',encoding='utf-8') as stream:
            json.dump(value,stream,ensure_ascii=False,indent=2);stream.write('\n')
        os.replace(temp,path)
    except BaseException:
        try:os.close(fd)
        except OSError:pass
        raise
    finally:
        temp.unlink(missing_ok=True)


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
                    'engines': [{'pid': p.pid, 'stamp': process_stamp(p.pid)} for p, _ in self.processes.values()],
                    'runtime': {'interface': self.interface, 'scope': self.scope,
                                'address_family': self.address_family, 'protocol': self.protocol,
                                'entries': self.entries}})

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
        try:
            for queue in list(self.processes):
                try:
                    self.stop(queue)
                except Exception as error:
                    failure = error
            # Retain the journal if table removal failed: bypass prevents a dead listener
            # blocking traffic; the next start/recover can remove the table explicitly.
            if not failure:
                try:
                    self.recover()
                except Exception as error:
                    failure = error
        finally:
            if self.lock:
                try:
                    self.lock.close()
                except Exception as error:
                    if failure is None:
                        failure = error
                finally:
                    self.lock = None
        return failure

    def __exit__(self, exc_type, exc, traceback_value):
        cleanup_error = self.close()
        if cleanup_error:
            if exc is None:
                raise cleanup_error
            print('Не завершена очистка; запустите START.sh recover. ' + str(cleanup_error), file=sys.stderr)
        return False


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


def status_report(root=ROOT):
    """Read-only snapshot of this installation's owned processes and nftables table."""
    from diagnostics import application_root
    root=application_root(root)
    result={'schema':'antidpi.status.v1','installed':False,'status':'unknown',
            'table':None,'journal':'unknown','nftables':{'ipv4':'unknown','ipv6':'unknown'},'engines':[],
            'active_queues':[],'owned_queues':[],'runtime':None,'recovery_pending':False}
    manifest_path=root/'installation.json'
    try:
        info=manifest_path.lstat()
        if not stat.S_ISREG(info.st_mode) or info.st_size>64*1024: return result
        manifest=json.loads(manifest_path.read_text(encoding='utf-8'))
        install_id=manifest.get('id')
        if (manifest.get('standard_uninstalled') or not isinstance(install_id,str) or
                not re.fullmatch(r'[0-9a-f]{32}',install_id) or Path(manifest.get('prefix',''))!=root):
            return result
    except (OSError,ValueError,TypeError):
        return result
    result['installed']=True
    table='antidpi_z2_'+install_id[:12]
    result['table']=table
    journal_path=root/'_state/runtime.json'
    journal=None;journal_present=False
    try:
        info=journal_path.lstat();journal_present=True
        if stat.S_ISREG(info.st_mode) and info.st_size<=256*1024:
            candidate=json.loads(journal_path.read_text(encoding='utf-8'))
            if isinstance(candidate,dict) and candidate.get('table')==table:journal=candidate
    except FileNotFoundError:
        pass
    except (OSError,ValueError,TypeError):
        pass
    result['journal']='valid' if journal is not None else 'invalid' if journal_present else 'absent'
    result['recovery_pending']=journal_present
    if journal is not None:
        runtime=journal.get('runtime')
        if isinstance(runtime,dict):
            entries=[]
            for entry in runtime.get('entries',[]) if isinstance(runtime.get('entries',[]),list) else []:
                if not isinstance(entry,dict):continue
                clean={'queue':entry.get('queue'),'strategy':entry.get('number')}
                if isinstance(entry.get('ports'),(list,tuple)) and len(entry['ports'])==2 and all(type(x) is int for x in entry['ports']):
                    clean['source_ports']=list(entry['ports'])
                entries.append(clean)
            result['runtime']={key:runtime.get(key) for key in ('interface','scope','address_family','protocol')}
            result['runtime']['entries']=entries
        expected_engine=(root/'engine/nfqws2').resolve()
        for record in journal.get('engines',[]) if isinstance(journal.get('engines',[]),list) else []:
            if not isinstance(record,dict) or type(record.get('pid')) is not int:continue
            pid=record['pid']
            alive=bool(record.get('stamp') and process_stamp(pid)==record['stamp'])
            owned=False
            if alive:
                try:owned=Path(f'/proc/{pid}/exe').resolve()==expected_engine
                except OSError:owned=None
            result['engines'].append({'pid':pid,'alive':owned if alive else False})
    try:
        result['active_queues']=sorted(queue_numbers())
        entries=result['runtime']['entries'] if result['runtime'] else []
        result['owned_queues']=sorted({item['queue'] for item in entries
                                       if type(item.get('queue')) is int and item['queue'] in result['active_queues']})
    except (OSError,ValueError):
        result['active_queues']=None;result['owned_queues']=None
    nft=shutil.which('nft')
    if nft:
        for family,key in (('ip','ipv4'),('ip6','ipv6')):
            try:
                listed=run([nft,'list','table',family,table])
                if listed.returncode==0:state='active'
                elif re.search(r'no such (?:file|table)|does not exist',listed.stderr,re.I):state='inactive'
                else:state='unknown'
            except (OSError,subprocess.TimeoutExpired):state='unknown'
            result['nftables'][key]=state
    engine_running=any(item['alive'] is True for item in result['engines'])
    engine_unknown=any(item['alive'] is None for item in result['engines'])
    table_running='active' in result['nftables'].values()
    if engine_running or table_running:result['status']='running'
    elif (engine_unknown or result['journal']=='invalid' or 'unknown' in result['nftables'].values() or
          result['active_queues'] is None):result['status']='unknown'
    else:result['status']='stopped'
    result['recovery_pending']=bool(journal_present and not (engine_running or table_running))
    return result


def doctor_report(root=ROOT,deep=False):
    """Read-only environment report; does not alter interfaces, modules or sysctls."""
    from diagnostics import application_root
    root=application_root(root)
    checks=[]
    def add(key,status,message,hint=None):
        item={'id':key,'status':status,'message':message}
        if hint:item['hint']=hint
        checks.append(item)

    try:
        metadata=json.loads((root/'data/release.json').read_text(encoding='utf-8'))
        version=str(metadata.get('version','unknown'))
        add('package_version','ok','Linux package v'+version)
    except (OSError,ValueError,TypeError):
        version='unknown';add('package_version','error','Не удалось прочитать версию пакета.')
    try:
        manifest=json.loads((root/'installation.json').read_text(encoding='utf-8'))
        valid=(re.fullmatch(r'[0-9a-f]{32}',str(manifest.get('id',''))) and
               Path(manifest.get('prefix',''))==root and not manifest.get('standard_uninstalled'))
        add('installation_marker','ok' if valid else 'error',
            'Маркер установки проверен.' if valid else 'Маркер установки отсутствует или некорректен.',
            None if valid else 'Запустите INSTALL.sh или укажите корень существующей установки.')
    except (OSError,ValueError,TypeError):
        add('installation_marker','error','Не удалось прочитать маркер установки.',
            'Запустите INSTALL.sh или укажите корень существующей установки.')
    try:
        load_catalogue()
        add('strategy_catalogue','ok','Каталог стратегий прочитан и проверен.')
    except Exception:
        add('strategy_catalogue','error','Каталог стратегий повреждён или недоступен.',
            'Переустановите пакет официальным установщиком или updater.')
    engine=root/'engine/nfqws2'
    add('engine_binary','ok' if engine.is_file() and os.access(engine,os.X_OK) else 'error',
        'Исполняемый nfqws2 найден.' if engine.is_file() and os.access(engine,os.X_OK) else 'Исполняемый nfqws2 не найден.',
        None if engine.is_file() and os.access(engine,os.X_OK) else 'Повторите установку Zapret2 через INSTALL.sh.')

    for command in ('ip','nft'):
        path=shutil.which(command)
        add('command_'+command,'ok' if path else 'error',
            f'Команда {command} найдена.' if path else f'Не найдена команда {command}.',
            None if path else 'Установите системный пакет iproute2/nftables.')
    for command in ('curl','modprobe'):
        path=shutil.which(command)
        add('command_'+command,'ok' if path else 'warning',
            f'Команда {command} найдена.' if path else f'Не найдена команда {command}.',
            None if path else 'Она нужна соответственно для загрузок или автоматической загрузки модулей ядра.')
    gh=shutil.which('gh')
    if not gh:
        add('github_cli','warning','GitHub CLI gh не найден; автоматическое обновление недоступно.',
            'Установите актуальный официальный GitHub CLI для antidpi update.')
    else:
        try:
            result=subprocess.run([gh,'attestation','verify','--help'],capture_output=True,text=True,timeout=8)
            supported=result.returncode==0
        except (OSError,subprocess.TimeoutExpired):
            supported=False
        add('github_cli','ok' if supported else 'warning',
            'GitHub CLI поддерживает проверку attestations.' if supported else 'GitHub CLI устарел или не поддерживает attestation verify.',
            None if supported else 'Обновите gh до версии с командой `gh attestation verify`.')
    if os.geteuid()==0:
        add('privileges','ok','Запущено от root.')
    else:
        add('privileges','warning','Сейчас запущено без root; диагностика read-only.',
            'Для применения сетевых стратегий используйте sudo antidpi start.')

    for family,flag in (('ipv4','-4'),('ipv6','-6')):
        if not shutil.which('ip'):
            add('route_'+family,'error','Нельзя проверить маршрут: отсутствует команда ip.')
            continue
        try:
            result=run(['ip',flag,'-j','route','show','default'])
            routes=json.loads(result.stdout) if result.returncode==0 else None
        except (OSError,ValueError,subprocess.TimeoutExpired):
            routes=None
        if routes:
            add('route_'+family,'ok',f'Маршрут по умолчанию для {family.upper()} найден.')
        else:
            add('route_'+family,'warning',f'Маршрут по умолчанию для {family.upper()} не обнаружен.',
                'Проверьте подключение; для IPv6 маршрут может не использоваться в этой сети.')
    acct=Path('/proc/sys/net/netfilter/nf_conntrack_acct')
    add('nf_conntrack_acct','ok' if acct.is_file() else 'warning',
        'Параметр nf_conntrack_acct доступен.' if acct.is_file() else 'Параметр nf_conntrack_acct пока не виден ядру.',
        None if acct.is_file() else 'Модуль nf_conntrack может загрузиться при первом запуске стратегии.')
    if deep:
        from engine_environment import CAPABILITIES, check_environment, engine_identity, snapshot
        try:
            state=snapshot()
            capabilities=int(state['cap_effective'],16)
            missing=[name for bit,name in CAPABILITIES.items() if not capabilities & (1<<bit)]
            if missing:
                level='warning' if os.geteuid()!=0 else 'error'
                add('deep_capabilities',level,'Недостаточно текущих Linux capabilities: '+', '.join(missing)+'.',
                    'Запустите deep-проверку через sudo; для контейнера проверьте разрешения на хосте.')
            else:
                uid,gid=engine_identity(state)
                add('deep_capabilities','ok',f'Capabilities NFQUEUE доступны; движок может сбросить UID/GID до {uid}:{gid}.')
        except (OSError,ValueError,RuntimeError) as error:
            add('deep_capabilities','error','Не удалось проверить capabilities и UID/GID: '+str(error))
        if os.geteuid()!=0:
            add('deep_nft_dry_run','warning','Проверка nft --check пропущена: для неё нужны root и доступ к NFQUEUE.',
                'Повторите команду: sudo antidpi doctor --deep.')
        elif not shutil.which('nft'):
            add('deep_nft_dry_run','error','Не найдена команда nft; dry-run правил пропущен.')
        else:
            try:
                check_environment(check_nft=True)
                add('deep_nft_dry_run','ok','Тестовая транзакция nft --check принята; правила не применялись.')
            except (OSError,RuntimeError,subprocess.TimeoutExpired) as error:
                add('deep_nft_dry_run','error','Read-only nft --check не прошёл: '+str(error),
                    'Проверка использует nft --check и не применяет правила к трафику.')
    statuses={item['status'] for item in checks}
    overall='error' if 'error' in statuses else 'warning' if 'warning' in statuses else 'ok'
    return {'schema':'antidpi.doctor.v1','version':version,'status':overall,'checks':checks}


PROFILE_SCHEMA='antidpi.profiles.v1'
PROFILE_BUNDLE_SCHEMA='antidpi.profile-bundle.v1'
PROFILE_NAME=re.compile(r'[A-Za-z0-9][A-Za-z0-9_-]{0,31}')
INTERFACE_NAME=re.compile(r'[A-Za-z0-9_.:@-]{1,15}')

def _profiles_path(root=ROOT):
    root=Path(root).resolve()
    if root.name=='app' and (root.parent/'INSTALL.sh').is_file():root=root.parent
    state=root/'_state'
    if state.is_symlink() or (state.exists() and not state.is_dir()):
        raise RuntimeError('Каталог состояния установки небезопасен.')
    return state/'profiles.json'

def _validate_profiles(profiles):
    if not isinstance(profiles,dict) or not profiles or len(profiles)>50:
        raise RuntimeError('Файл должен содержать от 1 до 50 сетевых профилей.')
    rows={row['Number'] for row in load_catalogue()['ProfileRows']}
    validated={}
    for name,profile in profiles.items():
        if not isinstance(name,str) or not PROFILE_NAME.fullmatch(name) or not isinstance(profile,dict):
            raise RuntimeError('Имя или описание сетевого профиля некорректно.')
        if set(profile)-{'family','protocol','interface','scope','strategy','quic_profile'}:
            raise RuntimeError('Профиль содержит неподдерживаемые параметры.')
        family=profile.get('family');protocol=profile.get('protocol')
        interface=profile.get('interface');scope=profile.get('scope')
        if (family not in ('ipv4','ipv6') or protocol not in ('tcp-tls','udp-quic') or
                not isinstance(interface,str) or not INTERFACE_NAME.fullmatch(interface) or
                not isinstance(scope,str)):
            raise RuntimeError('Семейство, протокол, интерфейс или scope профиля некорректен.')
        try:scope=parse_ports(scope)
        except ValueError as error:raise RuntimeError('Scope профиля некорректен.') from error
        strategy=profile.get('strategy');quic_profile=profile.get('quic_profile')
        if strategy is not None and (type(strategy) is not int or strategy not in rows):
            raise RuntimeError('TLS-стратегия профиля отсутствует в каталоге.')
        if strategy is not None and protocol!='tcp-tls':
            raise RuntimeError('TLS-стратегия задана для не-TLS профиля.')
        if quic_profile is not None and (protocol!='udp-quic' or not isinstance(quic_profile,str) or quic_profile not in QUIC_PROFILES):
            raise RuntimeError('QUIC-профиль не соответствует протоколу или неизвестен.')
        clean={'family':family,'protocol':protocol,'interface':interface,'scope':scope}
        if strategy is not None:clean['strategy']=strategy
        if quic_profile is not None:clean['quic_profile']=quic_profile
        validated[name]=clean
    return validated


def _read_json_file(path,limit=64*1024):
    path=Path(path)
    try:
        info=path.lstat()
        if not stat.S_ISREG(info.st_mode) or info.st_size>limit:
            raise RuntimeError('Файл должен быть обычным файлом допустимого размера.')
        return json.loads(path.read_text(encoding='utf-8'))
    except (OSError,ValueError) as error:
        raise RuntimeError('Не удалось прочитать JSON-файл профилей.') from error


def _read_profiles(path):
    path=Path(path)
    if path.is_symlink():raise RuntimeError('Файл профилей не может быть символической ссылкой.')
    if not path.exists():return {}
    data=_read_json_file(path)
    if not isinstance(data,dict) or data.get('schema')!=PROFILE_SCHEMA:
        raise RuntimeError('Повреждён файл профилей сети.')
    profiles=data.get('profiles')
    if profiles=={}:return {}
    return _validate_profiles(profiles)


def _read_profile_bundle(path):
    data=_read_json_file(path)
    if (not isinstance(data,dict) or data.get('schema')!=PROFILE_BUNDLE_SCHEMA or
            set(data)!={'schema','profiles'}):
        raise RuntimeError('Неизвестный формат или версия переносимого файла профилей.')
    return _validate_profiles(data.get('profiles'))

def handle_profile_command(args,parser):
    operation=args.profile_operation
    name=args.profile_name
    path=_profiles_path()
    file_path=getattr(args,'file',None)
    replace_existing=getattr(args,'replace',False)
    if operation is None:parser.error('Используйте profile list|save|delete|run|export|import|validate.')
    if operation=='list':
        if name or file_path or replace_existing:parser.error('Используйте `profile list` без дополнительных параметров.')
        profiles=_read_profiles(path)
        if args.json:print(json.dumps({'schema':PROFILE_SCHEMA,'profiles':profiles},ensure_ascii=False,indent=2))
        elif not profiles:print('Сохранённых сетевых профилей пока нет.')
        else:
            for key,profile in sorted(profiles.items()):
                mode='QUIC' if profile['protocol']=='udp-quic' else 'TLS'
                selected=profile.get('quic_profile') or profile.get('strategy') or 'меню выбора'
                print(f"{key}: {profile['family']} {mode}, {profile['interface']}, порты {profile['scope']}, профиль {selected}")
        return True
    if operation=='validate':
        if name or replace_existing:parser.error('Для `profile validate` имя и --replace не используются.')
        validated=_read_profile_bundle(file_path) if file_path else _read_profiles(path)
        report={'schema':'antidpi.profile-validation.v1','valid':True,'count':len(validated),
                'profiles':sorted(validated)}
        print(json.dumps(report,ensure_ascii=False,indent=2) if args.json else
              f"Профили проверены: {len(validated)} шт.; ошибок формата нет.")
        return True
    if operation=='export':
        if not file_path:parser.error('Для `profile export` укажите --file путь.json.')
        if replace_existing or any((args.family,args.protocol,args.interface,args.scope,args.strategy,args.quic_profile)):
            parser.error('Сетевые параметры и --replace не используются для экспорта.')
        profiles=_read_profiles(path)
        if name:
            if not PROFILE_NAME.fullmatch(name):parser.error('Некорректное имя профиля.')
            if name not in profiles:parser.error('Сохранённый профиль не найден: '+name)
            profiles={name:profiles[name]}
        if not profiles:raise RuntimeError('Нет профилей для экспорта.')
        export_path=Path(file_path)
        atomic_export_json(export_path,{'schema':PROFILE_BUNDLE_SCHEMA,'profiles':profiles})
        print(f'Экспортировано профилей: {len(profiles)}; файл: {file_path}')
        return True
    if operation=='import':
        if not file_path:parser.error('Для `profile import` укажите --file путь.json.')
        if name or any((args.family,args.protocol,args.interface,args.scope,args.strategy,args.quic_profile)):
            parser.error('При импорте имя и сетевые параметры не указываются; имена берутся из файла.')
        if os.geteuid()!=0:raise RuntimeError('Импорт профилей установки выполняйте через sudo.')
        incoming=_read_profile_bundle(file_path)
        profiles=_read_profiles(path)
        collisions=sorted(set(profiles)&set(incoming))
        if collisions and not replace_existing:
            raise RuntimeError('Имена уже существуют: '+', '.join(collisions)+'. Для замены добавьте --replace.')
        merged={**profiles,**incoming}
        if len(merged)>50:raise RuntimeError('После импорта будет больше 50 профилей; удалите лишние и повторите.')
        atomic_json(path,{'schema':PROFILE_SCHEMA,'profiles':merged})
        print(f'Импортировано профилей: {len(incoming)}; заменено: {len(collisions)}.')
        return True
    if operation in ('save','delete','run') and (file_path or replace_existing):
        parser.error('--file/--replace используются только с profile export|import|validate.')
    if not name or not PROFILE_NAME.fullmatch(name):parser.error('Имя профиля: 1–32 латинских букв, цифр, `_` или `-`; первый символ — буква/цифра.')
    profiles=_read_profiles(path)
    if operation=='delete':
        if any((args.family,args.protocol,args.interface,args.scope,args.strategy,args.quic_profile)):
            parser.error('Параметры сети нельзя указывать для profile delete.')
        if name not in profiles:parser.error('Сохранённый профиль не найден: '+name)
        del profiles[name];atomic_json(path,{'schema':PROFILE_SCHEMA,'profiles':profiles})
        print('Профиль удалён: '+name);return True
    if operation=='save':
        if os.geteuid()!=0:raise RuntimeError('Изменение профилей установки выполняйте через sudo.')
        if not all((args.family,args.protocol,args.interface,args.scope is not None)):
            parser.error('Для profile save нужны --family, --protocol, --interface и --scope.')
        if args.protocol=='udp-quic' and args.strategy is not None:parser.error('--strategy не подходит для UDP/QUIC профиля.')
        if args.protocol=='tcp-tls' and args.quic_profile is not None:parser.error('--quic-profile не подходит для TCP/TLS профиля.')
        if args.strategy is not None:
            rows={row['Number'] for row in load_catalogue()['ProfileRows']}
            if args.strategy not in rows:parser.error(f'Допустимые TLS-стратегии: 1–{max(rows)}.')
        if args.quic_profile is not None and args.quic_profile not in QUIC_PROFILES:
            parser.error('Допустимые QUIC-профили: '+', '.join(QUIC_PROFILES))
        if not any(item['name']==args.interface for item in interfaces(args.family)):
            parser.error('Интерфейс сейчас не найден для выбранного IP-семейства.')
        profile={'family':args.family,'protocol':args.protocol,'interface':args.interface,'scope':parse_ports(args.scope)}
        if args.strategy is not None:profile['strategy']=args.strategy
        if args.quic_profile is not None:profile['quic_profile']=args.quic_profile
        profiles[name]=profile
        if len(profiles)>50:parser.error('Можно хранить не более 50 профилей.')
        atomic_json(path,{'schema':PROFILE_SCHEMA,'profiles':profiles})
        print('Профиль сохранён: '+name);return True
    if operation=='run':
        if any((args.family,args.protocol,args.interface,args.scope,args.strategy,args.quic_profile)):
            parser.error('При `profile run` не указывайте сетевые параметры повторно.')
        if name not in profiles:parser.error('Сохранённый профиль не найден: '+name)
        profile=profiles[name]
        args.action='start';args.family=profile['family'];args.protocol=profile['protocol']
        args.interface=profile['interface'];args.scope=profile['scope']
        args.strategy=profile.get('strategy');args.quic_profile=profile.get('quic_profile')
        print('Запускаю сетевой профиль: '+name)
        return False
    parser.error('Неизвестная операция profile.')


def history_report(root=ROOT,limit=20):
    root=Path(root).resolve()
    if root.name=='app' and (root.parent/'INSTALL.sh').is_file():root=root.parent
    logs=root/'logs';found=[]
    if logs.is_dir() and not logs.is_symlink():
        for path in logs.rglob('summary.json'):
            try:
                info=path.lstat()
                if not stat.S_ISREG(info.st_mode) or path.is_symlink() or info.st_size>1024*1024:continue
                summary=json.loads(path.read_text(encoding='utf-8'))
                scan_path=path.with_name('scan.json')
                scan=json.loads(scan_path.read_text(encoding='utf-8')) if scan_path.is_file() and not scan_path.is_symlink() else {}
                found.append((info.st_mtime_ns,{'time':path.parent.name,'mode':'benchmark' if scan.get('target_id') else 'youtube',
                    'target_id':scan.get('target_id'),'requested':summary.get('requested',0),
                    'completed':summary.get('completed',0),'interrupted':bool(summary.get('interrupted')),
                    'found':summary.get('found',[]),'ranking':summary.get('ranking',[])[:5]}))
            except (OSError,ValueError,TypeError):continue
    found.sort(key=lambda item:item[0],reverse=True)
    return {'schema':'antidpi.history.v1','runs':[item for _,item in found[:limit]],
            'omitted':max(0,len(found)-limit)}


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


def percentile(values,percent):
    values=sorted(float(value) for value in values)
    if not values:return None
    position=(len(values)-1)*percent/100
    lower=int(position);upper=min(lower+1,len(values)-1)
    result=values[lower]+(values[upper]-values[lower])*(position-lower)
    return round(result,3)


def rank_endpoint_scores(scores):
    return sorted(scores,key=lambda x:(-x['success_rate'],-x['successes'],
                  x['median_seconds'] if x['median_seconds'] is not None else float('inf'),x['number']))


def benchmark_report(target_id,requested,completed,adaptive,representatives,baseline,scores):
    baseline_times=[item['seconds'] for item in baseline if item.get('pass') and isinstance(item.get('seconds'),(int,float))]
    baseline_successes=sum(bool(item.get('pass')) for item in baseline)
    return {'schema':'antidpi.benchmark.v1','target_id':target_id,'protocol':'tcp-tls',
            'requested':requested,'completed':completed,'adaptive':bool(adaptive),
            'representatives':list(representatives),
            'baseline':{'attempts':len(baseline),'successes':baseline_successes,
                        'success_rate':baseline_successes/len(baseline) if baseline else 0.0,
                        'median_seconds':percentile(baseline_times,50),
                        'p95_seconds':percentile(baseline_times,95),
                        'results':[{'attempt':item.get('attempt'),'pass':bool(item.get('pass')),
                                    'reason':item.get('reason'),'seconds':item.get('seconds'),
                                    'tls':item.get('tls','')} for item in baseline]},
            'ranking':rank_endpoint_scores(scores)}


def benchmark_csv(report):
    fields=('target_id','baseline_successes','baseline_attempts','baseline_success_rate',
            'baseline_median_seconds','baseline_p95_seconds','strategy','stage','successes',
            'attempts','success_rate','median_seconds','p95_seconds')
    stream=io.StringIO(newline='')
    writer=csv.DictWriter(stream,fieldnames=fields,lineterminator='\n')
    writer.writeheader()
    baseline=report['baseline']
    if not report['ranking']:
        writer.writerow({'target_id':report.get('target_id'),
            'baseline_successes':baseline['successes'],'baseline_attempts':baseline['attempts'],
            'baseline_success_rate':baseline['success_rate'],
            'baseline_median_seconds':baseline['median_seconds'],'baseline_p95_seconds':baseline['p95_seconds']})
    for score in report['ranking']:
        writer.writerow({'target_id':report.get('target_id'),
            'baseline_successes':baseline['successes'],'baseline_attempts':baseline['attempts'],
            'baseline_success_rate':baseline['success_rate'],
            'baseline_median_seconds':baseline['median_seconds'],'baseline_p95_seconds':baseline['p95_seconds'],
            'strategy':score['number'],'stage':score['stage'],'successes':score['successes'],
            'attempts':score['attempts'],'success_rate':score['success_rate'],
            'median_seconds':score['median_seconds'],'p95_seconds':score['p95_seconds']})
    return stream.getvalue()


def write_benchmark_report(report,path,private=False):
    path=Path(path)
    if path.suffix.lower()=='.json':
        payload=json.dumps(report,ensure_ascii=False,indent=2)+'\n'
    elif path.suffix.lower()=='.csv':
        payload=benchmark_csv(report)
    else:raise ValueError('Отчёт benchmark должен иметь расширение .json или .csv.')
    atomic_text(path,payload,0o600 if private else 0o644)


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


def baseline_endpoint_results(session,target,attempts=2):
    ports=reserve_ports((),session.address_family)
    results=[]
    for attempt in range(1,attempts+1):
        result=target_probe.probe(session.interface,ports,target,timeout=12,
                                  address_family=session.address_family)
        result.pop('error',None);result.pop('remote_ip',None);result.pop('host',None);result.pop('sni',None)
        result['attempt']=attempt
        results.append(result)
    return results


def scan(session, rows, numbers, parallel, target=None, adaptive=False, report_file=None):
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
    baseline_results=[]
    log=session.scan_logs/'results.jsonl'
    completed=0;interrupted=False;benchmark_result=None
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
            samples=[x['seconds'] for x in results if x.get('pass') and isinstance(x.get('seconds'),(int,float))]
            scores.append({'number':number,'stage':'representative' if number in representative_set else 'expanded',
                           'successes':successes,'attempts':len(results),
                           'success_rate':successes/len(results) if results else 0.0,
                           'median_seconds':percentile(samples,50),'p95_seconds':percentile(samples,95),
                           'latency_samples':len(samples)})
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
        if target:
            print('Контрольный TLS baseline: два соединения без активной AntiDPI-стратегии.')
            baseline_results=baseline_endpoint_results(session,target)
            atomic_json(session.scan_logs/'baseline.json',{'target_id':endpoint_id(target),
                        'results':[{'attempt':item['attempt'],'pass':item.get('pass',False),
                                    'reason':item.get('reason'),'seconds':item.get('seconds'),
                                    'tls':item.get('tls','')} for item in baseline_results]})
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
        if target:
            benchmark_result=benchmark_report(endpoint_id(target),len(numbers),completed,adaptive,
                                              representatives,baseline_results,scores)
            atomic_json(session.scan_logs/'benchmark_report.json',benchmark_result)
        archive=shutil.make_archive(str(session.scan_logs),'zip',str(session.scan_logs))
        # The full diagnostic ZIP is saved silently; only working recipes are printed.
        print()
        del session.scan_logs
    if report_file and benchmark_result is not None:
        write_benchmark_report(benchmark_result,report_file)
        print('Benchmark-отчёт сохранён: '+str(report_file))
    if target and benchmark_result is not None:
        baseline=benchmark_result['baseline']
        print(f"Baseline без стратегии: {baseline['successes']}/{baseline['attempts']} успешных; медиана {baseline['median_seconds'] if baseline['median_seconds'] is not None else '—'} с; p95 {baseline['p95_seconds'] if baseline['p95_seconds'] is not None else '—'} с.")
    if not found:
        if interrupted:print('Проверка остановлена пользователем.')
        print('Не найдены стратегии с успешным TLS-handshake.' if target else 'Рабочие стратегии не найдены')
    if adaptive:
        print(f'Адаптивный поиск завершён: протестировано {completed} из {len(numbers)} отобранных стратегий; расширено семейств: {len(expanded_families)}.')
    if target and scores:
        print('Рейтинг TLS-проверки (сначала доля успехов, затем медианная задержка):')
        ranking=rank_endpoint_scores(scores)
        cli_ui.table(['Место','Этап','Стратегия','Успехи','p50, с','p95, с'],[[str(i),'Предст.' if x['stage']=='representative' else 'Расшир.',str(x['number']),f"{x['successes']}/{x['attempts']}",str(x['median_seconds'] if x['median_seconds'] is not None else '—'),str(x['p95_seconds'] if x['p95_seconds'] is not None else '—')] for i,x in enumerate(ranking,1)],[6,9,10,8,10,10])
    print('----------------------')
    return found


def ask_parallel():
    while True:
        answer = input('Параллельная проверка: введите число одновременно проверяемых стратегий [от 1 до 5]: ').strip()
        if answer in ('1','2','3','4','5'):
            return int(answer)


def print_connectivity_report(report):
    reasons={'DNS_ERROR':'не удалось разрешить имя',
             'INTERFACE_PERMISSION_ERROR':'недостаточно прав для привязки к интерфейсу',
             'TCP_CONNECT_ERROR':'TCP-соединение не установлено','TIMEOUT':'истёк таймаут',
             'CERTIFICATE_VERIFY_FAILED':'сертификат не прошёл проверку',
             'TLS_HANDSHAKE_ERROR':'TLS handshake не завершился',
             'DNS_FAILED':'пропущено после ошибки DNS','TCP_FAILED':'пропущено после ошибки TCP'}
    reason=lambda stage: reasons.get(stage.get('reason'),stage.get('reason',''))
    print(f"Проверка TCP/TLS: IPv{6 if report['address_family']=='ipv6' else 4}; ID {report['target_id']}")
    dns=report['dns']
    print('DNS: '+('OK' if dns['status']=='ok' else 'ОШИБКА')+
          (f"; адресов: {dns['addresses']}" if dns['status']=='ok' else '')+
          (f"; {dns['seconds']} с" if dns['seconds'] is not None else '')+
          (('; '+reason(dns)) if dns.get('reason') else ''))
    tcp=report['tcp']
    tcp_label='OK' if tcp['status']=='ok' else 'пропущено' if tcp['status']=='skipped' else 'ОШИБКА'
    print('TCP connect: '+tcp_label+
          (f"; {tcp['seconds']} с" if tcp['seconds'] is not None else '')+
          (('; '+reason(tcp)) if tcp.get('reason') else ''))
    tls=report['tls']
    tls_label='OK' if tls['status']=='ok' else 'пропущено' if tls['status']=='skipped' else 'ОШИБКА'
    print('TLS handshake: '+tls_label+
          (f"; {tls['version']}" if tls.get('version') else '')+
          (f"; {tls['seconds']} с" if tls['seconds'] is not None else '')+
          (('; '+reason(tls)) if tls.get('reason') else ''))
    if not report['certificate_verification']:
        print('ВНИМАНИЕ: проверка сертификата отключена; TLS-успех не подтверждает подлинность узла.')
    print('Проба не отправляет HTTP/приложенческие данные и не проверяет VPN/Tor или обход DPI.')


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
    parser.add_argument('action', nargs='?', default='menu', choices=('menu','start','youtube','benchmark','test','list','show','check-engine','recover','update','rollback','diagnostics','doctor','history','profile','status'))
    parser.add_argument('profile_operation',nargs='?',choices=('list','save','delete','run','export','import','validate'))
    parser.add_argument('profile_name',nargs='?')
    parser.add_argument('--skip-intro',action='store_true',help=argparse.SUPPRESS)
    parser.add_argument('--yes',action='store_true',help='Подтвердить обновление/откат или создание архива после ознакомления с его составом')
    parser.add_argument('--check',action='store_true',help='Проверить доступность и целостность обновления без установки; используется с update')
    parser.add_argument('--output',help='Путь к ZIP диагностическому архиву; используется с diagnostics')
    parser.add_argument('--file',help='JSON-файл для profile export/import/validate')
    parser.add_argument('--replace',action='store_true',help='Заменить совпадающие имена при profile import')
    parser.add_argument('--deep',action='store_true',help='Дополнительные read-only проверки capabilities и nft --check; используется с doctor')
    parser.add_argument('--report-file',help='Путь экспорта benchmark-отчёта (.json или .csv)')
    parser.add_argument('--json',action='store_true',help='Вывести doctor/status/history/test или проверку profile в машиночитаемом JSON')
    parser.add_argument('--limit',type=int,default=20,help='Число последних результатов для history (1–100)')
    parser.add_argument('--strategy', type=int)
    parser.add_argument('--interface')
    parser.add_argument('--family', choices=('ipv4','ipv6'), help='IP-семейство для перехвата; для test — семейство цели')
    parser.add_argument('--protocol', choices=('tcp-tls','udp-quic'), help='Протокол обработки')
    parser.add_argument('--quic-profile', choices=tuple(QUIC_PROFILES), help='QUIC-профиль: fake2 или fake11')
    parser.add_argument('--recipes', default=None)
    parser.add_argument('--parallel', type=int, choices=range(1, 6))
    parser.add_argument('--target', help='TLS-узел для benchmark/test в формате имя:порт')
    parser.add_argument('--timeout',type=float,help='Лимит TCP connect + TLS handshake для test, 0,5–60 секунд (DNS может занять дополнительное время)')
    parser.add_argument('--sni', help='TLS SNI; по умолчанию совпадает с именем узла')
    parser.add_argument('--insecure', action='store_true', help='не проверять сертификат (только для диагностики; небезопасно)')
    parser.add_argument('--exhaustive', action='store_true', help='не применять адаптивный отбор в benchmark: проверить все номера из --recipes')
    parser.add_argument('--scope',type=parse_ports,help='Порты выбранного TCP/UDP протокола: all/все, 443, 0-1023 или 53,80,443,1000-2000')
    args = parser.parse_args()
    if args.json and args.action not in ('doctor','status','history','profile','test'):
        parser.error('--json используется только с doctor, status, history, test или profile list|validate.')
    if args.json and args.action=='profile' and args.profile_operation not in ('list','validate'):
        parser.error('--json для profile доступен только с list или validate.')
    if args.deep and args.action!='doctor':
        parser.error('--deep используется только с doctor.')
    if args.file and args.action!='profile':
        parser.error('--file используется только с profile export|import|validate.')
    if args.replace and not (args.action=='profile' and args.profile_operation=='import'):
        parser.error('--replace используется только с profile import.')
    if args.report_file:
        if args.action!='benchmark':parser.error('--report-file используется только с benchmark.')
        if Path(args.report_file).suffix.lower() not in ('.json','.csv'):
            parser.error('--report-file должен иметь расширение .json или .csv.')
    if args.target and args.action not in ('benchmark','test'):
        parser.error('--target используется только с benchmark или test.')
    if args.sni and args.action not in ('benchmark','test'):
        parser.error('--sni используется только с benchmark или test.')
    if args.insecure and args.action not in ('benchmark','test'):
        parser.error('--insecure используется только с benchmark или test.')
    if args.timeout is not None and args.action!='test':
        parser.error('--timeout используется только с test.')
    if args.timeout is not None and not 0.5<=args.timeout<=60:
        parser.error('--timeout для test должен быть от 0,5 до 60 секунд.')
    if args.limit!=20 and args.action!='history':
        parser.error('--limit используется только с history.')
    if not 1<=args.limit<=100:
        parser.error('--limit для history должен быть от 1 до 100.')
    if args.action!='profile' and (args.profile_operation is not None or args.profile_name is not None):
        parser.error('Дополнительные позиционные аргументы используются только с profile.')
    if args.check and args.action!='update':
        parser.error('--check используется только с update.')
    if args.check and args.yes:
        parser.error('--check не совмещается с --yes.')
    if args.output and args.action != 'diagnostics':
        parser.error('--output используется только с diagnostics.')
    if args.action=='profile':
        finished=handle_profile_command(args,parser)
        if finished:return
    if args.action=='test':
        if not args.target:parser.error('Для `test` укажите --target имя:порт.')
        if args.protocol=='udp-quic':parser.error('Команда test проверяет только TCP/TLS; QUIC Initial этим тестом не проверяется.')
        try:target=parse_target_argument(args.target,args.sni,not args.insecure)
        except ValueError as error:parser.error(str(error))
        try:report=target_probe.diagnose_target(target,args.interface,args.family or 'ipv4',
                                                timeout=args.timeout if args.timeout is not None else 8)
        except ValueError as error:parser.error(str(error))
        if args.json:print(json.dumps(report,ensure_ascii=False,indent=2))
        else:print_connectivity_report(report)
        if report['status']=='error':raise SystemExit(1)
        return
    if args.action == 'doctor':
        report=doctor_report(deep=args.deep)
        if args.json:
            print(json.dumps(report,ensure_ascii=False,indent=2))
        else:
            print('Проверка окружения AntiDPI (без изменения настроек системы):')
            for check in report['checks']:
                mark={'ok':'OK','warning':'WARN','error':'ERROR'}[check['status']]
                print(f"[{mark}] {check['message']}")
                if check.get('hint'):print('      '+check['hint'])
            print('Итог: '+report['status'].upper())
        if report['status']=='error':
            raise SystemExit(1)
        return
    if args.action=='status':
        report=status_report(ROOT)
        if args.json:
            print(json.dumps(report,ensure_ascii=False,indent=2))
        else:
            print('Состояние AntiDPI: '+report['status'].upper())
            if not report['installed']:
                print('Установка не найдена или маркер повреждён.')
            else:
                print('Таблица nftables: IPv4 '+report['nftables']['ipv4']+'; IPv6 '+report['nftables']['ipv6'])
                print('Процессы движка: '+str(sum(item['alive'] is True for item in report['engines'])))
                print('Собственные активные NFQUEUE: '+(', '.join(map(str,report['owned_queues'])) if report['owned_queues'] else 'нет'))
                if report['runtime']:
                    runtime=report['runtime']
                    print(f"Последняя конфигурация: {runtime.get('address_family')} {runtime.get('protocol')}, интерфейс {runtime.get('interface')}, порты {runtime.get('scope')}")
                if report['journal']=='invalid':
                    print('Журнал восстановления повреждён или не совпадает с установкой; автоматическое восстановление не запускалось.')
                elif report['recovery_pending']:
                    print('Есть незавершённое состояние; после проверки соединения выполните: sudo antidpi recover')
                elif report['status']=='stopped':
                    print('Собственная перехватывающая таблица не активна.')
        if not report['installed']:raise SystemExit(1)
        return
    if args.action=='history':
        report=history_report(ROOT,args.limit)
        if args.json:print(json.dumps(report,ensure_ascii=False,indent=2))
        elif not report['runs']:print('История проверок пока пуста.')
        else:
            for item in report['runs']:
                target=('TLS '+str(item.get('target_id')) if item['mode']=='benchmark' else 'YouTube')
                print(f"{item['time']}: {target}; завершено {item['completed']}/{item['requested']}; найдено {len(item['found'])}; прервано {'да' if item['interrupted'] else 'нет'}")
            if report['omitted']:print(f"Не показано старых запусков: {report['omitted']}.")
        return
    if args.action == 'diagnostics':
        from diagnostics import create_diagnostic_archive
        create_diagnostic_archive(ROOT, args.output, yes=args.yes)
        return
    if args.action in ('update', 'rollback'):
        from updater import rollback, update
        result = update(ROOT, yes=args.yes,check=args.check) if args.action == 'update' else rollback(ROOT, yes=args.yes)
        if result:
            raise SystemExit(result)
        return
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
            scan(session,rows,recipe_range(args.recipes),args.parallel or ask_parallel(),target=target,adaptive=not args.exhaustive,
                 report_file=args.report_file)
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
