#!/usr/bin/env python3
"""TLS handshake probe for a user-selected endpoint; no application data is sent."""
from __future__ import annotations
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
    if address is not None and address.version != 4:
        raise ValueError('Проверка TLS-узла пока поддерживает только IPv4.')
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


def probe(interface, ports, target, timeout=12, resolver=socket.getaddrinfo,
          context_factory=ssl.create_default_context):
    target = validate_target(target)
    started = time.monotonic()
    result = {'pass': False, 'reason': 'NOT_STARTED', 'seconds': 0.0,
              'tls': '', 'technical': False, 'error': '', 'source_port': 0}
    raw = secure = None
    try:
        addresses = resolver(target['host'], target['port'], socket.AF_INET, socket.SOCK_STREAM)
        if not addresses:
            raise socket.gaierror('DNS не вернул IPv4-адрес.')
        deadline = started + timeout
        last_error = None
        for info in addresses:
            raw = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            try:
                raw.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
                if interface:
                    raw.setsockopt(socket.SOL_SOCKET, socket.SO_BINDTODEVICE, interface.encode() + b'\0')
                bound = False
                for local_port in range(int(ports[0]), int(ports[1]) + 1):
                    try:
                        raw.bind(('0.0.0.0', local_port))
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
        answer = probe(request['interface'], request['ports'], request['target'], request.get('timeout', 12))
        print(json.dumps(answer, ensure_ascii=False), flush=True)
    except Exception as error:
        print(json.dumps({'pass': False, 'technical': True, 'reason': 'PROBE_INTERNAL_ERROR',
                          'error': str(error), 'seconds': 0}, ensure_ascii=False), flush=True)
        raise SystemExit(2)
