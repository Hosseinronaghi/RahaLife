import json, plistlib, shutil, subprocess, sys, tempfile, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
class BrandingTest(unittest.TestCase):
 def test_preserves_identity_and_applies_display_assets_idempotently(self):
  with tempfile.TemporaryDirectory() as folder:
   root=Path(folder);(root/'tool').mkdir();shutil.copy(ROOT/'tool/configure_branding.py',root/'tool');shutil.copytree(ROOT/'assets/branding',root/'assets/branding')
   def put(path,text):
    p=root/path;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text);return p
   manifest=put('android/app/src/main/AndroidManifest.xml','<manifest package="com.raha.raha_life"><application android:label="raha_life" android:icon="@mipmap/ic_launcher" /></manifest>')
   windows=put('windows/runner/main.cpp','window.Create(L"raha_life", origin, size);');(root/'windows/runner/resources').mkdir()
   plist=root/'macos/Runner/Info.plist';plist.parent.mkdir(parents=True);plist.write_bytes(plistlib.dumps({'CFBundleIdentifier':'com.raha.rahaLife','CFBundleName':'raha_life'}))
   swift=put('macos/Runner/MainFlutterWindow.swift','super.awakeFromNib()')
   for _ in range(2):subprocess.run([sys.executable,str(root/'tool/configure_branding.py')],check=True,capture_output=True)
   self.assertEqual(manifest.read_text().count('android.permission.RECORD_AUDIO'),1);self.assertIn('android:label="Raha Life"',manifest.read_text());self.assertIn('com.raha.raha_life',manifest.read_text())
   self.assertEqual(plistlib.loads(plist.read_bytes())['CFBundleName'],'raha_life');self.assertEqual(plistlib.loads(plist.read_bytes())['CFBundleIdentifier'],'com.raha.rahaLife')
   self.assertEqual(swift.read_text().count('self.title'),1);self.assertIn('\\u0645',windows.read_text())
   self.assertTrue((root/'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png').is_file())
if __name__=='__main__':unittest.main()
