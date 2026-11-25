"""Verify an in-place update on a disposable emulator using only synthetic data."""
import json
import os
from pathlib import Path
import sqlite3
import subprocess
import sys
import tempfile
import time
import uuid


def command(*args, **kwargs):
    return subprocess.run(args, check=True, timeout=90, **kwargs).stdout


def adb(*args, **kwargs):
    return command('adb', '-e', *args, **kwargs)


def output(*args):
    return adb(*args, stdout=subprocess.PIPE).decode().strip()


def launch(app_id):
    adb('shell', 'monkey', '-p', app_id, '-c',
        'android.intent.category.LAUNCHER', '1')


def database_path(app_id):
    for _ in range(45):
        matches = output('shell', 'run-as', app_id, 'find', '.', '-name',
                         'raha_life.sqlite').splitlines()
        if matches:
            return matches[0]
        time.sleep(1)
    raise RuntimeError('Raha Life did not open its SQLite database')


def snapshot(app_id, database, path):
    adb('shell', 'am', 'force-stop', app_id)
    for suffix in ('', '-wal'):
        name = database + suffix
        try:
            data = adb('exec-out', 'run-as', app_id, 'cat', name,
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        except subprocess.CalledProcessError:
            if not suffix:
                raise
        else:
            Path(str(path) + suffix).write_bytes(data)


def main():
    old_apk, new_apk = sys.argv[1:]
    root = Path(os.environ['ANDROID_HOME'])
    aapt = max((root / 'build-tools').glob('*/aapt'),
               key=lambda p: tuple(int(n) for n in p.parent.name.split('.')
                                   if n.isdigit()))

    def identity(apk):
        info = command(str(aapt), 'dump', 'badging', apk, stdout=subprocess.PIPE)
        package = next(line for line in info.decode().splitlines()
                       if line.startswith('package:'))
        fields = {field.split('=', 1)[0]: field.split('=', 1)[1].strip("'")
                  for field in package.split() if '=' in field}
        return fields['name'], int(fields['versionCode'])

    old_app, old_version = identity(old_apk)
    new_app, new_version = identity(new_apk)
    assert old_app == new_app and new_version > old_version, (old_app, new_app)
    assert output('shell', 'getprop', 'ro.kernel.qemu') == '1'
    installed = output('shell', 'pm', 'list', 'packages', new_app).splitlines()
    assert f'package:{new_app}' not in installed, 'A clean emulator is required'

    marker = str(uuid.uuid4())
    title = 'Synthetic upgrade fixture ' + marker
    body = 'متن ساختگی برای آزمون ارتقا'
    payload = json.dumps({
        'id': marker, 'title': title, 'plainText': body,
        'deltaJson': json.dumps([{'insert': body + '\n'}]),
        'updatedAt': '2026-11-25T00:00:00Z',
    })
    with tempfile.TemporaryDirectory() as temporary:
        old_db = Path(temporary) / 'baseline.sqlite'
        new_db = Path(temporary) / 'upgraded.sqlite'
        adb('install', old_apk)
        launch(old_app)
        db_path = database_path(old_app)
        snapshot(old_app, db_path, old_db)
        with sqlite3.connect(old_db) as db:
            db.execute('PRAGMA journal_mode=DELETE')
            db.execute('''
                INSERT INTO entity_documents
                    (id, entity_type, payload_json, version, device_id, created_at, updated_at)
                VALUES (?, 'rich_note', ?, 1, 'upgrade-fixture', 1795564800, 1795564800)
            ''', (marker, payload))
        # Write the synthetic fixture into the stopped app sandbox. No external
        # device or user database is read or written.
        adb('shell', 'run-as', old_app, 'rm', '-f', db_path + '-wal', db_path + '-shm')
        adb('shell', '-T', f'run-as {old_app} sh -c "cat > {db_path}"',
            input=old_db.read_bytes())

        adb('install', '-r', new_apk)
        launch(new_app)
        database_path(new_app)
        time.sleep(8)
        assert output('shell', 'pidof', new_app), 'The upgraded app did not stay open'
        snapshot(new_app, db_path, new_db)
        with sqlite3.connect(new_db) as db:
            assert db.execute('PRAGMA quick_check').fetchone() == ('ok',)
            restored = db.execute(
                "SELECT payload_json FROM entity_documents WHERE entity_type='rich_note' AND id=?",
                (marker,),
            ).fetchone()
        assert restored is not None, 'The note was lost during the upgrade'
        assert json.loads(restored[0])['title'] == title
        assert json.loads(restored[0])['plainText'] == body
    print(f'PASS: Android debug upgrade {old_version} -> {new_version}; original note retained')


if __name__ == '__main__':
    main()
