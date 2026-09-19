#!/usr/bin/env python3
"""Apply display names and ready-made icons after flutter create; never alter IDs."""
from pathlib import Path
import json
import plistlib
import re
import shutil
root = Path(__file__).resolve().parent.parent
assets = root / 'assets/branding'
def copy_icon(size, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(assets / f'icon-{size}.png', target)
def patch(path, old, new):
    if path.exists():
        text = path.read_text(encoding='utf-8')
        path.write_text(text.replace(old, new), encoding='utf-8')
manifest = root/'android/app/src/main/AndroidManifest.xml'
if manifest.exists():
    text = manifest.read_text(encoding='utf-8')
    text = re.sub(r'(<application\b[^>]*?android:label=")[^"]*', r'\g<1>Raha Life', text, count=1, flags=re.S)
    manifest.write_text(text, encoding='utf-8')
    for density, size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
        copy_icon(size, manifest.parent/f'res/mipmap-{density}/ic_launcher.png')
if (root/'windows').exists():
    shutil.copyfile(assets/'app_icon.ico',root/'windows/runner/resources/app_icon.ico')
    patch(root/'windows/runner/main.cpp', 'L"raha_life"', 'L' + json.dumps('مدیریت زندگی رها'))
    rc=root/'windows/runner/Runner.rc'
    for label in ['FileDescription','ProductName']:
        if rc.exists():
            text=rc.read_text();text=re.sub(r'(VALUE "'+label+r'", ")[^"]*',r'\g<1>Raha Life',text);rc.write_text(text)
if (root/'linux').exists():
    patch(root/'linux/runner/my_application.cc','"raha_life"','"مدیریت زندگی رها"')
for platform in ['ios','macos']:
    info=root/platform/'Runner/Info.plist'
    if info.exists():
        data=plistlib.loads(info.read_bytes());data['CFBundleDisplayName']='Raha Life'
        # CFBundleName is also a platform default data-directory input. Keep it stable.
        info.write_bytes(plistlib.dumps(data))
    if platform == 'macos':
        window=root/platform/'Runner/MainFlutterWindow.swift'
        if window.exists() and 'self.title = ' not in window.read_text():
            patch(window, 'super.awakeFromNib()', 'super.awakeFromNib()\n    self.title = "مدیریت زندگی رها"')
    iconset=root/platform/'Runner/Assets.xcassets/AppIcon.appiconset'
    contents=iconset/'Contents.json'
    if contents.exists():
        data=json.loads(contents.read_text())
        for item in data.get('images',[]):
            if 'filename' not in item: continue
            size=round(float(item['size'].split('x')[0])*float(item.get('scale','1x')[:-1]))
            source=assets/f'icon-{size}.png'
            if source.exists(): shutil.copyfile(source,iconset/item['filename'])
web=root/'web'
if web.exists():
    for name,size in [('Icon-192.png',192),('Icon-512.png',512),('Icon-maskable-192.png',192),('Icon-maskable-512.png',512)]:
        copy_icon(size,web/'icons'/name)
    copy_icon(32,web/'favicon.png')
    manifest=web/'manifest.json'
    if manifest.exists():
        data=json.loads(manifest.read_text());data.update(name='Raha Life',short_name='Raha Life');manifest.write_text(json.dumps(data,indent=2)+'\n')
    for old_title in ['raha_life', 'Raha Life']:
        patch(web/'index.html',f'<title>{old_title}</title>','<title>مدیریت زندگی رها</title>')
print('Applied Raha Life branding; application IDs and storage paths unchanged.')
