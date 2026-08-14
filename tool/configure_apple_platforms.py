#!/usr/bin/env python3
from pathlib import Path
import re

IOS_TARGET = "14.0"

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

print(f"Configured iOS deployment target {IOS_TARGET}")
