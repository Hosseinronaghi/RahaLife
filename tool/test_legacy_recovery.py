import base64, importlib.util, json, os, sqlite3, tempfile, unittest
from pathlib import Path
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
spec=importlib.util.spec_from_file_location('recovery',Path(__file__).with_name('recover_legacy_backup.py'))
recovery=importlib.util.module_from_spec(spec);spec.loader.exec_module(recovery)
class RecoveryTest(unittest.TestCase):
    def test_encrypted_round_trip_and_no_overwrite(self):
        with tempfile.TemporaryDirectory() as folder:
            folder=Path(folder);dbpath=folder/'source.sqlite';db=sqlite3.connect(dbpath)
            db.execute('CREATE TABLE entity_documents(id TEXT, entity_type TEXT, payload_json TEXT, version INT, device_id TEXT, created_at INT, updated_at INT, deleted_at INT)')
            db.execute('INSERT INTO entity_documents VALUES(?,?,?,?,?,?,?,?)',('p','person','{"id":"p","name":"Preserved"}',3,'old',1700000000,1700000000,None));db.commit();db.close()
            payload={'format':'raha-life-backup','payloadVersion':1,'preferences':{},'database':base64.b64encode(dbpath.read_bytes()).decode()}
            key=os.urandom(32);nonce=os.urandom(12);cipher=AESGCM(key);sealed=cipher.encrypt(nonce,json.dumps(payload).encode(),None)
            enc=lambda x:base64.urlsafe_b64encode(x).decode()
            source=folder/'old.rahabackup';source.write_text(json.dumps({'format':'raha-backup-aesgcm-v1','nonce':enc(nonce),'cipherText':enc(sealed[:-16]),'mac':enc(sealed[-16:])}));original=source.read_bytes()
            target=folder/'recovered.rahabackup'
            self.assertEqual(recovery.recover(source,target,key),1)
            result=json.loads(target.read_text());decoded=json.loads(cipher.decrypt(recovery.decode64(result['nonce']),recovery.decode64(result['cipherText'])+recovery.decode64(result['mac']),None))
            self.assertEqual(decoded['entities'][0]['payload']['name'],'Preserved');self.assertIsNone(decoded['database']);self.assertEqual(decoded['payloadVersion'],2)
            self.assertEqual(source.read_bytes(),original)
            with self.assertRaises(FileExistsError):recovery.recover(source,target,key)
    def test_unknown_schema_is_not_claimed_recovered(self):
        with self.assertRaises(ValueError):recovery.convert_payload({'format':'raha-life-backup','payloadVersion':1,'preferences':{'home.entries.v1':'[]'}})
if __name__=='__main__':unittest.main()
