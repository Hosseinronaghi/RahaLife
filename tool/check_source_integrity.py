"""Catch incomplete uploads and mixed release files before Flutter runs.
Run --refresh after intentionally editing release source files.
"""
from pathlib import Path
import hashlib
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / 'tool/source_integrity.json'

def digest(path):
    return hashlib.sha256(path.read_bytes().replace(b'\r\n', b'\n')).hexdigest()

def tracked():
    for folder in ('lib', 'test', 'assets'):
        yield from (p for p in (ROOT / folder).rglob('*') if p.is_file())
    yield ROOT / 'pubspec.yaml'
    yield ROOT / 'pubspec.lock'

if (ROOT / 'lib/app/app').exists():
    sys.exit('WRONG NESTING: lib/app/app exists. Use tool/repair_nested_app.py to review and repair it.')

if '--refresh' in sys.argv:
    MANIFEST.write_text(json.dumps({p.relative_to(ROOT).as_posix(): digest(p)
                                  for p in sorted(tracked())}, indent=2) + '\n')
    print('Release source manifest refreshed.')
else:
    errors = []
    entries = json.loads(MANIFEST.read_text())
    for folder in ('lib', 'test'):
        for path in (ROOT / folder).rglob('*.dart'):
            name = path.relative_to(ROOT).as_posix()
            if name not in entries:
                errors.append('UNEXPECTED DART FILE: ' + name)
    for name, expected in entries.items():
        path = ROOT / name
        if not path.is_file():
            errors.append('MISSING: ' + name)
        elif digest(path) != expected:
            errors.append('DIFFERENT RELEASE CONTENT: ' + name)
    if errors:
        print('\n'.join(errors))
        sys.exit('Upload the complete release source, or refresh the manifest after intentional edits.')
    print(f'PASS: {len(entries)} release files match.')
