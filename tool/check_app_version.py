#!/usr/bin/env python3
"""Print the platform marketing version and reject drift from the app display."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
spec = (root / 'pubspec.yaml').read_text(encoding='utf-8')
match = re.search(r'^version: (\d+\.\d+\.\d+)(?:-[0-9A-Za-z.-]+)?\+([1-9]\d*)$', spec, re.M)
if not match:
    raise SystemExit('Expected a SemVer release and a positive build number')
display = (root / 'lib/core/app_version.dart').read_text(encoding='utf-8')
full = match.group(0).removeprefix('version: ')
if display.strip() != f"const rahaAppVersion = '{full}';":
    raise SystemExit('Application display version must match pubspec.yaml')
print(match.group(1))
