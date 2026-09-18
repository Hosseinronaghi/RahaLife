"""Review known lib/app/app upload mistake; pass --apply to back up and repair.
Unknown or modified duplicates are never automatically removed.
"""
from pathlib import Path
import hashlib
import json
import shutil
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
source = root / 'lib/app/app'
manifest = json.loads((root / 'tool/source_integrity.json').read_text())
def digest(p):
    return hashlib.sha256(p.read_bytes().replace(b'\r\n', b'\n')).hexdigest()

if not source.exists():
    print('No nested lib/app/app folder. Nothing to repair.')
    sys.exit(0)
if source.is_symlink() or not source.is_dir():
    sys.exit('Refusing unexpected source type.')
restore = []
errors = []
for p in sorted(source.rglob('*')):
    if p.is_symlink():
        errors.append('Symbolic link: ' + str(p))
    elif p.is_file():
        target = source.parent / p.relative_to(source)
        name = target.relative_to(root).as_posix()
        expected = manifest.get(name)
        if not expected or digest(p) != expected:
            errors.append('Unknown or modified duplicate: ' + str(p))
        elif target.exists():
            if not target.is_file() or target.is_symlink() or digest(target) != expected:
                errors.append('Conflicting canonical file: ' + name)
        else:
            restore.append((p, target))
if errors:
    sys.exit('\n'.join(errors) + '\nNo files changed. Resolve these differences manually.')
print(f'Known duplicate folder: {source}; missing canonical files to restore: {len(restore)}')
if '--apply' not in sys.argv:
    print('Preview only. Run again with --apply to back up and repair.')
    sys.exit(0)
backup = Path(tempfile.mkdtemp(prefix='RahaLife-upload-backup-', dir=root.parent)) / 'app'
shutil.copytree(source, backup)
for p, target in restore:
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(p, target)
shutil.rmtree(source)
print('Repair completed. Backup outside repository: ' + str(backup))
print('Commit the lib/app/app deletions and any restored canonical files.')
