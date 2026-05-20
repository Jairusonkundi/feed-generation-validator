#!/usr/bin/env bash
set -euo pipefail

python3 - << 'PATCH'
p = '/app/scripts/build_feed.py'

with open(p, encoding='utf-8') as fh:
    code = fh.read().replace('\r\n', '\n')

# Fix 1: strptime only handles trailing Z; fails on real offsets like -05:00
code = code.replace(
    'datetime.strptime(date_value, "%Y-%m-%dT%H:%M:%SZ")',
    'datetime.fromisoformat(date_value.strip().replace("Z", "+00:00"))'
)
if 'datetime.strptime' in code:
    raise RuntimeError('patch 1 failed: strptime still in file')

# Fix 2: string sort gives wrong order when mixing offset formats
code = code.replace(
    'posts.sort(key=lambda p: p["published_at"], reverse=True)',
    'posts.sort(key=lambda p: datetime.fromisoformat(p["published_at"].replace("Z", "+00:00")), reverse=True)'
)
if 'p["published_at"], reverse=True' in code:
    raise RuntimeError('patch 2 failed: string sort still in file')

with open(p, 'w', encoding='utf-8') as fh:
    fh.write(code)
PATCH
