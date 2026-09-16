#!/usr/bin/env python3
"""Configure persistent Android release signing in a generated Flutter project.

The keystore itself is supplied by GitHub Actions secrets and is never stored in
this repository. This script only patches the temporary generated Gradle file.
"""
from pathlib import Path
import os

required = [
    "RAHA_ANDROID_KEYSTORE_PASSWORD",
    "RAHA_ANDROID_KEY_ALIAS",
    "RAHA_ANDROID_KEY_PASSWORD",
]
missing = [name for name in required if not os.environ.get(name)]
if missing:
    raise SystemExit("Missing signing environment values: " + ", ".join(missing))

app_dir = Path("android/app")
gradle = app_dir / "build.gradle.kts"
if not gradle.exists():
    raise SystemExit("android/app/build.gradle.kts was not generated")

(app_dir.parent / "key.properties").write_text(
    "\n".join(
        [
            f"storePassword={os.environ['RAHA_ANDROID_KEYSTORE_PASSWORD']}",
            f"keyPassword={os.environ['RAHA_ANDROID_KEY_PASSWORD']}",
            f"keyAlias={os.environ['RAHA_ANDROID_KEY_ALIAS']}",
            "storeFile=raha-release.jks",
            "",
        ]
    ),
    encoding="utf-8",
)

text = gradle.read_text(encoding="utf-8")
imports = """import java.io.FileInputStream
import java.util.Properties

"""
if "import java.util.Properties" not in text:
    text = imports + text

properties_block = """val rahaKeystoreProperties = Properties()
val rahaKeystorePropertiesFile = rootProject.file("key.properties")
rahaKeystoreProperties.load(FileInputStream(rahaKeystorePropertiesFile))

"""
if "val rahaKeystoreProperties = Properties()" not in text:
    # Gradle's plugins block must remain before ordinary script statements.
    # Kotlin imports may precede it, so insert the Properties values directly
    # after the generated plugins { ... } block.
    start = text.find("plugins {")
    if start == -1:
        raise SystemExit("Could not find plugins block in generated Gradle file")
    brace = text.find("{", start)
    depth = 0
    end = -1
    for index in range(brace, len(text)):
        char = text[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                end = index + 1
                break
    if end == -1:
        raise SystemExit("Could not find end of plugins block")
    text = text[:end] + "\n\n" + properties_block + text[end:].lstrip("\n")

signing_block = """
    signingConfigs {
        create("rahaRelease") {
            keyAlias = rahaKeystoreProperties["keyAlias"] as String
            keyPassword = rahaKeystoreProperties["keyPassword"] as String
            storeFile = file(rahaKeystoreProperties["storeFile"] as String)
            storePassword = rahaKeystoreProperties["storePassword"] as String
        }
    }

"""
if 'create("rahaRelease")' not in text:
    marker = "    buildTypes {"
    if marker not in text:
        raise SystemExit("Could not find buildTypes block in generated Gradle file")
    text = text.replace(marker, signing_block + marker, 1)

old_debug = 'signingConfig = signingConfigs.getByName("debug")'
release_signing = 'signingConfig = signingConfigs.getByName("rahaRelease")'
if old_debug in text:
    text = text.replace(old_debug, release_signing, 1)
elif release_signing not in text:
    release_marker = '        getByName("release") {'
    if release_marker not in text:
        raise SystemExit("Could not locate release build type")
    text = text.replace(
        release_marker,
        release_marker + "\n            " + release_signing,
        1,
    )

gradle.write_text(text, encoding="utf-8")
print("Configured persistent Raha Life Android release signing.")
