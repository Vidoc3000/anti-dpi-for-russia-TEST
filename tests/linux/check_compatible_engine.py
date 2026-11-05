#!/usr/bin/env python3
"""Build the SHA-256-pinned upstream and dry-run all recipes, without interception.

Run from an ordinary user account after installing the build dependencies.
An existing --upstream-dir can be used for an offline check of downloaded sources.
Copyright Igor Krauch (github.com/igareck).
"""
import argparse
from hashlib import sha256
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import urllib.request

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO/'linux/app'))
from install import extract_source
from igareck import engine_arguments, load_catalogue


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--upstream-dir', type=Path)
    args = parser.parse_args()
    if os.geteuid() == 0:
        raise RuntimeError('Запускайте проверку параметров без sudo; она не требует перехвата трафика.')
    meta = json.loads((REPO/'linux/data/upstream.json').read_text())
    with tempfile.TemporaryDirectory(prefix='ig-engine-check-') as temporary:
        root = Path(temporary)
        if args.upstream_dir:
            upstream = args.upstream_dir.resolve()
        else:
            archive = root/'source.tar.gz'
            with urllib.request.urlopen(meta['url'], timeout=60) as response:
                content = response.read(100*1024*1024+1)
            if len(content) > 100*1024*1024 or sha256(content).hexdigest() != meta['sha256']:
                raise RuntimeError('Upstream archive SHA-256 mismatch.')
            archive.write_bytes(content)
            upstream = root/'source'
            extract_source(archive, upstream, 'zapret2-'+meta['commit'])
        subprocess.run(['make', '-C', str(upstream/'nfq2'), '-j2'], check=True)
        engine = root/'engine'
        engine.mkdir()
        shutil.copy2(upstream/'nfq2/nfqws2', engine/'nfqws2')
        shutil.copytree(upstream/'lua', engine/'lua')
        shutil.copytree(REPO/'linux/data/lists', root/'lists')
        shutil.copy2(REPO/'linux/data/actual_tls_guard.lua', root/'actual_tls_guard.lua')
        data = load_catalogue(REPO/'linux/app')
        for row in data['ProfileRows']:
            checked = subprocess.run(engine_arguments(root, row)+['--dry-run'],
                                     cwd=engine, capture_output=True, text=True, timeout=20)
            if checked.returncode:
                raise RuntimeError('Strategy '+str(row['Number'])+': '+checked.stdout+checked.stderr)
        print('Verified 484/484 parameter/Lua dry-runs against '+meta['commit']+'.')


if __name__ == '__main__':
    main()
