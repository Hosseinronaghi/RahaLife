#!/usr/bin/env python3
"""Verify package identity, increasing versionCode and signing cert of two APKs.
Usage: python tool/verify_android_upgrade.py previous.apk new.apk
Requires Android SDK apkanalyzer and apksigner on PATH. Does not alter/install APKs.
"""
import re, subprocess, sys
from pathlib import Path
if len(sys.argv)!=3: raise SystemExit(__doc__)
old,new=map(Path,sys.argv[1:])
for p in (old,new):
    if not p.is_file():raise SystemExit(f'Missing APK: {p}')
def apk(command,p):return subprocess.check_output(['apkanalyzer','manifest',command,str(p)],text=True).strip()
def certificate(p):
    text=subprocess.check_output(['apksigner','verify','--print-certs',str(p)],text=True)
    values=re.findall(r'Signer #\d+ certificate SHA-256 digest: ([0-9a-fA-F]+)',text)
    if not values:raise SystemExit('Could not read APK signing certificate')
    return set(v.lower() for v in values)
assert apk('application-id',old)==apk('application-id',new),'Application ID changed'
assert int(apk('version-code',new))>int(apk('version-code',old)),'versionCode must increase'
assert certificate(old)==certificate(new),'Signing certificate differs; ordinary in-place update is not supported'
print('PASS package ID, increasing versionCode and same signing certificate. Device/data upgrade still needs an installation test.')
