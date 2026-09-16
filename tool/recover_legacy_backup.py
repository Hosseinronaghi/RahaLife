#!/usr/bin/env python3
"""Convert a v1 encrypted backup to v2 without opening the application's database.
Requires: pip install cryptography
Usage: python tool/recover_legacy_backup.py old.rahabackup recovered.rahabackup
The recovery key is requested privately; the output remains encrypted.
"""
import argparse, base64, getpass, json, os, sqlite3, tempfile
from pathlib import Path
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

def decode64(value):
    return base64.urlsafe_b64decode(value + '=' * (-len(value) % 4))

def convert_payload(payload):
    if payload.get('format') != 'raha-life-backup' or payload.get('payloadVersion') != 1:
        raise ValueError('Expected a v1 Raha backup; input was not changed.')
    entities = []
    raw = payload.get('database')
    if raw:
        with tempfile.TemporaryDirectory(prefix='raha-recovery-') as tmp:
            path = Path(tmp) / 'isolated.sqlite'
            path.write_bytes(base64.b64decode(raw, validate=True))
            db = sqlite3.connect(path.as_uri() + '?mode=ro&immutable=1', uri=True)
            db.row_factory = sqlite3.Row
            try:
                if db.execute('PRAGMA integrity_check').fetchone()[0] != 'ok':
                    raise ValueError('SQLite integrity check failed.')
                tables = {row[0] for row in db.execute("SELECT name FROM sqlite_master WHERE type='table'")}
                if 'entity_documents' not in tables:
                    raise ValueError('This older typed-table schema needs a dedicated converter. Original retained.')
                for row in db.execute('SELECT * FROM entity_documents'):
                    r = dict(row)
                    def date(value):
                        if value is None: return None
                        if isinstance(value, (int, float)):
                            from datetime import datetime, timezone
                            return datetime.fromtimestamp(value, timezone.utc).isoformat()
                        return str(value)
                    entities.append(dict(id=r['id'],entityType=r['entity_type'],payload=json.loads(r['payload_json']),
                        version=r['version'],deviceId=r['device_id'],
                        clock=json.loads(r.get('clock_json') or '{}') or {r['device_id']:r['version']},
                        createdAtUtc=date(r['created_at']),updatedAtUtc=date(r['updated_at']),deletedAtUtc=date(r['deleted_at'])))
            finally:
                db.close()
    result = dict(payload, payloadVersion=2, database=None, entities=entities)
    # Old domain preference lists are retained for manual review if no records
    # exist. Never claim successful conversion of unmigrated domain data.
    domain_keys = ('home.entries.', 'people.', 'notes.rich.', 'shopping.lists.', 'finance.', 'projects.', 'medications.', 'cycle.logs.')
    if not entities and any(str(k).startswith(domain_keys) for k in payload.get('preferences', {})):
        raise ValueError('Backup contains preference-only domain data; migrate it in the original app first. Input retained.')
    return result

def recover(source, destination, key):
    destination = Path(destination)
    if destination.exists(): raise FileExistsError('Refusing to overwrite output.')
    envelope=json.loads(Path(source).read_text())
    if envelope.get('format') != 'raha-backup-aesgcm-v1': raise ValueError('Unsupported encryption format')
    cipher=AESGCM(key)
    clear=cipher.decrypt(decode64(envelope['nonce']),decode64(envelope['cipherText'])+decode64(envelope['mac']),None)
    payload=convert_payload(json.loads(clear))
    nonce=os.urandom(12)
    sealed=cipher.encrypt(nonce,json.dumps(payload,ensure_ascii=False).encode(),None)
    enc=lambda b:base64.urlsafe_b64encode(b).decode()
    result=dict(format='raha-backup-aesgcm-v1',nonce=enc(nonce),cipherText=base64.b64encode(sealed[:-16]).decode(),mac=enc(sealed[-16:]))
    with destination.open('x') as f: json.dump(result,f)
    return len(payload['entities'])

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source');parser.add_argument('destination');args=parser.parse_args()
    key=decode64(getpass.getpass('Recovery key (hidden): ').strip())
    print(f"Recovered {recover(args.source,args.destination,key)} records into an encrypted copy.")
