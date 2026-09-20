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
