"""Console tracebacks and private error logs. Copyright Igor Krauch."""
from __future__ import annotations

from datetime import datetime, timezone
import os
from pathlib import Path
import sys
import traceback
import uuid


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
        candidates.append(Path('/var/log/igareck-zapret2'))
    else:
        state = os.environ.get('XDG_STATE_HOME', '')
        state = Path(state) if state and Path(state).is_absolute() else Path.home()/'.local/state'
        candidates.append(state/'igareck-antidpi/logs')
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
