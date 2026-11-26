#!/usr/bin/env python3
from pathlib import Path
import plistlib
import re

IOS_TARGET = "14.0"
LOCAL_NETWORK_USAGE = (
    "Raha Life connects to personal servers, NAS and storage services "
    "that you choose on your local network for backup and synchronization."
)

podfile = Path("ios/Podfile")
if podfile.exists():
    text = podfile.read_text(encoding="utf-8")
    text = re.sub(
        r"^#?\s*platform :ios, '[^']+'",
        f"platform :ios, '{IOS_TARGET}'",
        text,
        flags=re.MULTILINE,
    )
    podfile.write_text(text, encoding="utf-8")

project = Path("ios/Runner.xcodeproj/project.pbxproj")
if project.exists():
    text = project.read_text(encoding="utf-8")
    text = re.sub(
        r"IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;",
        f"IPHONEOS_DEPLOYMENT_TARGET = {IOS_TARGET};",
        text,
    )
    project.write_text(text, encoding="utf-8")

for plist_path in (Path("ios/Runner/Info.plist"), Path("macos/Runner/Info.plist")):
    if not plist_path.exists():
        continue
    with plist_path.open("rb") as source:
        values = plistlib.load(source)
    values["NSLocalNetworkUsageDescription"] = LOCAL_NETWORK_USAGE
    values["NSMicrophoneUsageDescription"] = "Raha Life records voice attachments only when you choose to start recording."
    with plist_path.open("wb") as destination:
        plistlib.dump(values, destination, sort_keys=False)

print(
    f"Configured iOS deployment target {IOS_TARGET} and Apple local-network privacy text"
)

for entitlement in Path('macos/Runner').glob('*.entitlements'):
    values=plistlib.loads(entitlement.read_bytes())
    values['com.apple.security.device.audio-input']=True
    entitlement.write_bytes(plistlib.dumps(values))

# The bridge is in a generated target file, so no Xcode project file reference
# is needed. Unsigned previews compile the bridge without cloud entitlements.
import os

root = Path(__file__).resolve().parent
bridge = (root / 'apple_icloud_bridge.swift').read_text(encoding='utf-8')
container = os.environ.get('RAHA_ICLOUD_CONTAINER', '').strip()
if container and not re.fullmatch(r'iCloud\.[A-Za-z0-9][A-Za-z0-9.-]+', container):
    raise SystemExit('RAHA_ICLOUD_CONTAINER must be an Apple iCloud container identifier')

targets = (
    ('ios', 'AppDelegate.swift',
     'GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)',
     'RahaICloudBridge.install(engineBridge.applicationRegistrar.messenger())'),
    ('macos', 'MainFlutterWindow.swift',
     'RegisterGeneratedPlugins(registry: flutterViewController)',
     'RahaICloudBridge.install(flutterViewController.engine.binaryMessenger)'),
)
for platform, filename, marker, registration in targets:
    runner = Path(platform) / 'Runner'
    target = runner / filename
    if not target.is_file():
        continue
    source = target.read_text(encoding='utf-8')
    if registration not in source:
        if source.count(marker) != 1:
            raise SystemExit(f'Cannot register iCloud bridge in {target}')
        source = source.replace(marker, marker + '\n    ' + registration, 1)
        target.write_text(source + '\n' + bridge, encoding='utf-8')
    if not container:
        continue
    info = runner / 'Info.plist'
    values = plistlib.loads(info.read_bytes())
    values['RahaICloudContainer'] = container
    info.write_bytes(plistlib.dumps(values, sort_keys=False))
    if platform == 'ios':
        entitlements = [runner / 'RahaCloud.entitlements']
        pbxproj = Path('ios/Runner.xcodeproj/project.pbxproj')
        project_text = pbxproj.read_text(encoding='utf-8')
        if 'CODE_SIGN_ENTITLEMENTS = Runner/RahaCloud.entitlements;' not in project_text:
            project_text, count = re.subn(
                r'(PRODUCT_BUNDLE_IDENTIFIER = [^;\n]+;\n)(?!\s*CODE_SIGN_ENTITLEMENTS)',
                lambda m: m.group(0) + '\t\t\t\tCODE_SIGN_ENTITLEMENTS = Runner/RahaCloud.entitlements;\n'
                if 'RunnerTests' not in m.group(1) else m.group(0),
                project_text,
            )
            if not count:
                raise SystemExit('Could not attach iOS iCloud entitlements')
            pbxproj.write_text(project_text, encoding='utf-8')
    else:
        entitlements = list(runner.glob('*.entitlements'))
    for path in entitlements:
        values = plistlib.loads(path.read_bytes()) if path.exists() else {}
        values['com.apple.developer.icloud-services'] = ['CloudDocuments']
        values['com.apple.developer.icloud-container-identifiers'] = [container]
        values['com.apple.developer.ubiquity-container-identifiers'] = [container]
        path.write_bytes(plistlib.dumps(values, sort_keys=False))
