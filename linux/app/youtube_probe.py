#!/usr/bin/env python3
"""Fresh IPv4/TLS GET probe; no browser/proxy/cache. Igor Krauch (github.com/igareck)."""
from __future__ import annotations
import http.client
import json
from pathlib import Path
import re
import socket
import ssl
import sys
import time
from urllib.parse import urljoin,urlparse
import zlib

ALLOWED={'www.youtube.com','youtube.com','m.youtube.com'}
LIMIT=102400
SAMPLE_LIMIT=1048576


def signature(data,encoding):
    encoding=encoding.lower().strip()
    if encoding in ('','identity'):
        text=data[:SAMPLE_LIMIT].decode('utf-8',errors='replace')
    elif encoding in ('gzip','deflate'):
        try:
            decoder=zlib.decompressobj(31 if encoding=='gzip' else zlib.MAX_WBITS)
            text=decoder.decompress(data,SAMPLE_LIMIT).decode('utf-8',errors='replace')
        except zlib.error:
            if encoding!='deflate':return False,'INVALID_CONTENT_ENCODING'
            try:text=zlib.decompressobj(-zlib.MAX_WBITS).decompress(data,SAMPLE_LIMIT).decode('utf-8',errors='replace')
            except zlib.error:return False,'INVALID_CONTENT_ENCODING'
    else:return False,'UNSUPPORTED_CONTENT_ENCODING'
    lower=text.lower()
    if re.search(r'''(?is)<(?:form|div)[^>]*(?:id|class)\s*=\s*['" ][^>]*\b(?:g-recaptcha|captcha-form)\b|<form[^>]*action\s*=\s*['"][^'"]*(?:/sorry/|consent\.google\.)''',lower):
        return False,'CAPTCHA_OR_CONSENT'
    html=bool(re.search(r'<!doctype\s+html|<html\b',lower))
    bootstrap=any(x in lower for x in ('ytcfg.set','ytinitialdata','<ytd-app'))
    identity='innertube_' in lower or bool(re.search(r'<title[^>]*>[^<]*youtube',lower))
    return html and bootstrap and identity,'THRESHOLD_REACHED' if html and bootstrap and identity else 'NOT_YOUTUBE_HTML'


def remaining(deadline):
    left=deadline-time.monotonic()
    if left<=0:raise TimeoutError('Истекло время HTTPS GET.')
    return left


def connect(host,port,interface,ports,deadline,resolver=socket.getaddrinfo):
    addresses=resolver(host,port,socket.AF_INET,socket.SOCK_STREAM)
    last=None
    for info in addresses:
        address=info[4]
        client=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
        try:
            client.setsockopt(socket.IPPROTO_TCP,socket.TCP_NODELAY,1)
            if interface:
                client.setsockopt(socket.SOL_SOCKET,socket.SO_BINDTODEVICE,interface.encode()+b'\0')
            bound=False
            for local in range(int(ports[0]),int(ports[1])+1):
                try:client.bind(('0.0.0.0',local));bound=True;break
                except OSError as error:last=error
            if not bound:raise OSError('Не найден свободный исходящий порт в блоке проверки: '+str(last))
            client.settimeout(min(5,remaining(deadline)))
            client.connect(address)
            return client
        except (PermissionError,ValueError):
            client.close();raise
        except OSError as error:
            client.close();last=error
    raise last or OSError('DNS не вернул адрес IPv4.')


def probe_mode(interface,ports,mode,deadline,url='https://www.youtube.com/',context_factory=ssl.create_default_context,resolver=socket.getaddrinfo):
    result={'pass':False,'bytes':0,'http':0,'url':url,'reason':'NOT_STARTED','error':'','source_port':0,'remote_ip':'',
            'content_type':'','content_encoding':'','tls':'','mode':mode,'technical':False,'headers':{}}
    for redirect in range(4):
        parsed=urlparse(url)
        result['url']=url
        if parsed.scheme!='https' or parsed.username or parsed.hostname not in ALLOWED:
            result['reason']='UNEXPECTED_FINAL_DOMAIN';return result
        raw=secure=None;response=None
        try:
            raw=connect(parsed.hostname,parsed.port or 443,interface,ports,deadline,resolver)
            result['source_port']=raw.getsockname()[1];result['remote_ip']=raw.getpeername()[0]
            context=context_factory()
            if context.verify_mode!=ssl.CERT_REQUIRED or not context.check_hostname:
                raise ValueError('TLS-проверка сертификата и имени должна быть включена.')
            context.set_alpn_protocols(['http/1.1'])
            if mode=='TLS1.2':
                context.minimum_version=context.maximum_version=ssl.TLSVersion.TLSv1_2
            raw.settimeout(remaining(deadline))
            secure=context.wrap_socket(raw,server_hostname=parsed.hostname);raw=None
            result['tls']=secure.version()
            target=(parsed.path or '/')+('?' + parsed.query if parsed.query else '')
            request=('GET '+target+' HTTP/1.1\r\nHost: '+parsed.netloc+
                     '\r\nUser-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/147.0.0.0 Safari/537.36'
                     '\r\nAccept: text/html,application/xhtml+xml\r\nAccept-Encoding: identity\r\nCache-Control: no-cache'
                     '\r\nConnection: close\r\n\r\n')
            secure.settimeout(remaining(deadline));secure.sendall(request.encode('ascii'))
            response=http.client.HTTPResponse(secure);response.begin()
            result['http']=response.status
            headers={k.lower():v for k,v in response.getheaders()}
            result['headers']=headers
            if 300<=response.status<400 and response.status!=304:
                if not headers.get('location'):result['reason']='REDIRECT_WITHOUT_LOCATION';return result
                url=urljoin(url,headers['location']);continue
            if response.status not in (200,206):result['reason']='HTTP_STATUS';return result
            content_type=headers.get('content-type','');encoding=headers.get('content-encoding','')
            result['content_type']=content_type;result['content_encoding']=encoding
            if not any(x in content_type.lower() for x in ('text/html','application/xhtml+xml')):
                result['reason']='NOT_HTML';return result
            body=bytearray()
            while len(body)<SAMPLE_LIMIT:
                secure.settimeout(remaining(deadline))
                chunk=response.read1(min(16384,SAMPLE_LIMIT-len(body)))
                if not chunk:break
                body.extend(chunk);result['bytes']=len(body)
                if len(body)>=LIMIT:
                    good,reason=signature(body,encoding)
                    if good:result['pass']=True;result['reason']=reason;return result
                    if reason in ('CAPTCHA_OR_CONSENT','UNSUPPORTED_CONTENT_ENCODING','INVALID_CONTENT_ENCODING'):
                        result['reason']=reason;return result
            good,reason=signature(body,encoding)
            result['reason']='SHORT_COMPLETE_RESPONSE' if good else reason
            return result
        except PermissionError as error:
            result.update(reason='LOCAL_PERMISSION_ERROR',technical=True,error=str(error));return result
        except ssl.SSLCertVerificationError as error:
            result.update(reason='CERTIFICATE_VERIFY_FAILED',error=str(error));return result
        except (FileNotFoundError,ValueError) as error:
            result.update(reason='LOCAL_CONFIGURATION_ERROR',technical=True,error=str(error));return result
        except socket.gaierror as error:
            result.update(reason='DNS_ERROR',error=str(error));return result
        except (TimeoutError,socket.timeout) as error:
            result.update(reason='TIMEOUT',error=str(error));return result
        except (ssl.SSLError,OSError,http.client.HTTPException) as error:
            result.update(reason='TRANSFER_ERROR',error=str(error));return result
        finally:
            if response is not None:response.close()
            if secure is not None:
                try:secure.shutdown(socket.SHUT_RDWR)
                except OSError:pass
                secure.close()
            if raw is not None:raw.close()
    result['reason']='TOO_MANY_REDIRECTS';return result


def probe(interface,ports,timeout=25,url='https://www.youtube.com/',context_factory=ssl.create_default_context,resolver=socket.getaddrinfo):
    started=time.monotonic();deadline=started+timeout;modes=[]
    for mode in ('AUTO','TLS1.2'):
        if deadline-time.monotonic()<.1:break
        # Preserve time for a TLS 1.2 fallback if default negotiation stalls.
        current=min(deadline,started+min(12,timeout*.55)) if mode=='AUTO' else deadline
        result=probe_mode(interface,ports,mode,current,url,context_factory,resolver);modes.append(result)
        if result['pass'] or result['technical'] or result['reason'] in ('DNS_ERROR','CERTIFICATE_VERIFY_FAILED','HTTP_STATUS','CAPTCHA_OR_CONSENT','UNEXPECTED_FINAL_DOMAIN'):
            break
    final=next((x for x in modes if x['pass']),max(modes,key=lambda x:x['bytes']))
    return dict(final, modes=modes,seconds=round(time.monotonic()-started,3),backend='python-ssl-direct')


if __name__=='__main__':
    try:
        request=json.loads(Path(sys.argv[1]).read_text())
        answer=probe(request['interface'],request['ports'],request.get('timeout',25))
        print(json.dumps(answer,ensure_ascii=False),flush=True)
    except Exception as error:
        print(json.dumps({'pass':False,'technical':True,'reason':'PROBE_INTERNAL_ERROR','error':str(error),'bytes':0,'http':0,'seconds':0},ensure_ascii=False),flush=True)
        raise SystemExit(2)
