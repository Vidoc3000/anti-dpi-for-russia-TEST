#!/usr/bin/env python3
"""TLS handshake probe for a user-selected endpoint; no application data is sent."""
from __future__ import annotations
import hashlib
import ipaddress
import json
from pathlib import Path
import re
import socket
import ssl
import sys
import time


def hostname(value, label):
    value = str(value).strip().rstrip('.')
    if not value or len(value) > 253 or any(c in value for c in '/\\@?#[]'):
        raise ValueError(f'Некорректное имя {label}.')
    try:
        ipaddress.ip_address(value)
        return value
    except ValueError:
        pass
    try:
        ascii_name = value.encode('idna').decode('ascii')
    except UnicodeError as error:
        raise ValueError(f'Некорректное имя {label}.') from error
    labels = ascii_name.split('.')
    if any(not re.fullmatch(r'[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?', item) for item in labels):
        raise ValueError(f'Некорректное имя {label}.')
    return ascii_name


def validate_target(target):
    if not isinstance(target, dict):
        raise ValueError('Каждая цель должна быть JSON-объектом.')
    host = hostname(target.get('host', ''), 'адреса')
    try:
        address=ipaddress.ip_address(host)
    except ValueError:
        address=None
    try:
        port = int(target.get('port'))
    except (TypeError, ValueError) as error:
        raise ValueError('Порт цели должен быть числом от 1 до 65535.') from error
    if not 1 <= port <= 65535:
        raise ValueError('Порт цели должен быть числом от 1 до 65535.')
    sni_value = target.get('sni') or host
    sni = hostname(sni_value, 'SNI')
    try:
        ipaddress.ip_address(sni)
    except ValueError:
        pass
    else:  # IP literals are valid connection hosts, but not useful TLS SNI values.
        raise ValueError('SNI должен быть DNS-именем, а не IP-адресом.')
    verify = target.get('verify_certificate', True)
    if not isinstance(verify, bool):
        raise ValueError('verify_certificate должен быть true или false.')
    name = str(target.get('name') or f'{host}:{port}')
    if len(name) > 64 or any(ord(c) < 32 for c in name):
        raise ValueError('Имя цели должно быть не длиннее 64 символов и без управляющих знаков.')
    return {'name': name, 'host': host, 'port': port, 'sni': sni,
            'verify_certificate': verify}


def diagnose_target(target,interface=None,address_family='ipv4',timeout=8,
                    resolver=socket.getaddrinfo,socket_factory=socket.socket,
                    context_factory=ssl.create_default_context):
    """Read-only DNS, TCP and TLS check; sends no application payload and stores no host/IP."""
    target=validate_target(target)
    if address_family not in ('ipv4','ipv6'):
        raise ValueError('IP-семейство должно быть ipv4 или ipv6.')
    if not isinstance(timeout,(int,float)) or not 0.5<=timeout<=60:
        raise ValueError('Таймаут проверки должен быть в диапазоне 0,5–60 секунд.')
    if interface is not None and (not isinstance(interface,str) or
            not re.fullmatch(r'[A-Za-z0-9_.:@-]{1,15}',interface)):
        raise ValueError('Некорректное имя сетевого интерфейса.')
    started=time.monotonic()
    family=socket.AF_INET6 if address_family=='ipv6' else socket.AF_INET
    key='|'.join((target['host'].casefold(),str(target['port']),target['sni'].casefold()))
    report={'schema':'antidpi.connectivity-test.v1',
            'target_id':hashlib.sha256(key.encode('utf-8')).hexdigest()[:10],
            'address_family':address_family,'interface_bound':bool(interface),
            'certificate_verification':target['verify_certificate'],
            'dns':{'status':'pending','addresses':0,'seconds':None},
            'tcp':{'status':'skipped','seconds':None},
            'tls':{'status':'skipped','version':None,'seconds':None},'status':'error'}

    def finish():
        report['elapsed_seconds']=round(time.monotonic()-started,3)
        if report['tls']['status']=='ok':
            report['status']='ok' if target['verify_certificate'] else 'warning'
        else:
            report['status']='error'
        return report

    dns_started=time.monotonic()
    try:
        addresses=resolver(target['host'],target['port'],family,socket.SOCK_STREAM)
        if not addresses:raise socket.gaierror('No addresses for the selected family')
    except (OSError,ValueError):
        report['dns'].update(status='error',reason='DNS_ERROR',seconds=round(time.monotonic()-dns_started,3))
        report['tcp'].update(status='skipped',reason='DNS_FAILED')
        report['tls'].update(status='skipped',reason='DNS_FAILED')
        return finish()
    report['dns'].update(status='ok',addresses=len(addresses),seconds=round(time.monotonic()-dns_started,3))

    tcp_reason='TCP_CONNECT_ERROR'
    secure=None;raw=None
    tcp_started=time.monotonic()
    deadline=tcp_started+timeout
    try:
        for info in addresses[:8]:
            remaining=deadline-time.monotonic()
            if remaining<=0:
                tcp_reason='TIMEOUT';break
            raw=None
            try:
                raw=socket_factory(info[0],socket.SOCK_STREAM)
                raw.setsockopt(socket.IPPROTO_TCP,socket.TCP_NODELAY,1)
                if interface:
                    raw.setsockopt(socket.SOL_SOCKET,socket.SO_BINDTODEVICE,interface.encode()+b'\0')
                raw.settimeout(remaining)
                raw.connect(info[4])
                report['tcp'].update(status='ok',seconds=round(time.monotonic()-tcp_started,3))
                break
            except PermissionError:
                tcp_reason='INTERFACE_PERMISSION_ERROR'
                if raw is not None:raw.close();raw=None
                break
            except (TimeoutError,socket.timeout):
                tcp_reason='TIMEOUT'
                if raw is not None:raw.close();raw=None
            except OSError:
                tcp_reason='TCP_CONNECT_ERROR'
                if raw is not None:raw.close();raw=None
        if report['tcp']['status']!='ok':
            report['tcp'].update(status='error',reason=tcp_reason,
                                 seconds=round(time.monotonic()-tcp_started,3))
            report['tls'].update(status='skipped',reason='TCP_FAILED')
            return finish()
        tls_started=time.monotonic()
        try:
            context=context_factory() if target['verify_certificate'] else ssl._create_unverified_context()
            raw.settimeout(max(0.1,deadline-time.monotonic()))
            secure=context.wrap_socket(raw,server_hostname=target['sni'])
            raw=None
            report['tls'].update(status='ok',version=secure.version(),
                                 seconds=round(time.monotonic()-tls_started,3))
        except ssl.SSLCertVerificationError:
            report['tls'].update(status='error',reason='CERTIFICATE_VERIFY_FAILED',
                                 seconds=round(time.monotonic()-tls_started,3))
        except (TimeoutError,socket.timeout):
            report['tls'].update(status='error',reason='TIMEOUT',
                                 seconds=round(time.monotonic()-tls_started,3))
        except (OSError,ssl.SSLError,ValueError):
            report['tls'].update(status='error',reason='TLS_HANDSHAKE_ERROR',
                                 seconds=round(time.monotonic()-tls_started,3))
    finally:
        if secure is not None:
            try:secure.shutdown(socket.SHUT_RDWR)
            except OSError:pass
            secure.close()
        if raw is not None:raw.close()
    return finish()


def probe(interface, ports, target, timeout=12, resolver=socket.getaddrinfo,
          context_factory=ssl.create_default_context, address_family='ipv4'):
    target = validate_target(target)
    started = time.monotonic()
    result = {'pass': False, 'reason': 'NOT_STARTED', 'seconds': 0.0,
              'tls': '', 'technical': False, 'error': '', 'source_port': 0}
    raw = secure = None
    try:
        family=socket.AF_INET6 if address_family=='ipv6' else socket.AF_INET
        addresses=resolver(target['host'],target['port'],family,socket.SOCK_STREAM)
        if not addresses:
            raise socket.gaierror('DNS не вернул адрес выбранного IP-семейства.')
        deadline = started + timeout
        last_error = None
        for info in addresses:
            raw = socket.socket(info[0],socket.SOCK_STREAM)
            try:
                raw.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
                if interface:
                    raw.setsockopt(socket.SOL_SOCKET, socket.SO_BINDTODEVICE, interface.encode() + b'\0')
                bound = False
                for local_port in range(int(ports[0]), int(ports[1]) + 1):
                    try:
                        raw.bind(('::',local_port,0,0) if info[0]==socket.AF_INET6 else ('0.0.0.0',local_port))
                        bound = True
                        break
                    except OSError as error:
                        last_error = error
                if not bound:
                    raise OSError('Не найден свободный исходящий порт для проверки: ' + str(last_error))
                raw.settimeout(max(0.1, min(5, deadline - time.monotonic())))
                raw.connect(info[4])
                result['source_port'] = raw.getsockname()[1]
                context = context_factory() if target['verify_certificate'] else ssl._create_unverified_context()
                raw.settimeout(max(0.1, deadline - time.monotonic()))
                secure = context.wrap_socket(raw, server_hostname=target['sni'])
                raw = None
                result.update({'pass': True, 'reason': 'TLS_HANDSHAKE_OK', 'tls': secure.version()})
                break
            except (PermissionError, ValueError):
                raise
            except OSError as error:
                last_error = error
                if raw is not None:
                    raw.close()
                    raw = None
        else:
            if isinstance(last_error, socket.gaierror):
                raise last_error
            raise last_error or OSError('Не удалось подключиться к IPv4-адресу цели.')
    except PermissionError as error:
        result.update(reason='LOCAL_PERMISSION_ERROR', technical=True, error=str(error))
    except ssl.SSLCertVerificationError as error:
        result.update(reason='CERTIFICATE_VERIFY_FAILED', error=str(error))
    except socket.gaierror as error:
        result.update(reason='DNS_ERROR', error=str(error))
    except (TimeoutError, socket.timeout) as error:
        result.update(reason='TIMEOUT', error=str(error))
    except (FileNotFoundError, ValueError) as error:
        result.update(reason='LOCAL_CONFIGURATION_ERROR', technical=True, error=str(error))
    except (ssl.SSLError, OSError) as error:
        result.update(reason='TLS_OR_CONNECT_ERROR', error=str(error))
    finally:
        result['seconds'] = round(time.monotonic() - started, 3)
        if secure is not None:
            try:
                secure.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass
            secure.close()
        if raw is not None:
            raw.close()
    return result


if __name__ == '__main__':
    try:
        request = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
        answer = probe(request['interface'],request['ports'],request['target'],request.get('timeout',12),address_family=request.get('address_family','ipv4'))
        print(json.dumps(answer, ensure_ascii=False), flush=True)
    except Exception as error:
        print(json.dumps({'pass': False, 'technical': True, 'reason': 'PROBE_INTERNAL_ERROR',
                          'error': str(error), 'seconds': 0}, ensure_ascii=False), flush=True)
        raise SystemExit(2)
