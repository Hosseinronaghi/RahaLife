from pathlib import Path

gradle = Path("android/app/build.gradle.kts")
if not gradle.exists():
    raise SystemExit("android/app/build.gradle.kts was not generated")

text = gradle.read_text(encoding="utf-8")

if "isCoreLibraryDesugaringEnabled = true" not in text:
    compile_marker = "    compileOptions {"
    start = text.find(compile_marker)
    if start == -1:
        android_marker = "android {"
        block = '''android {
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
'''
        text = text.replace(android_marker, block, 1)
    else:
        end = text.find("    }", start)
        if end == -1:
            raise SystemExit("Could not locate compileOptions block end")
        block = text[start:end + 5]
        if "sourceCompatibility" in block:
            block = block.replace(
                "sourceCompatibility = JavaVersion.VERSION_11",
                "sourceCompatibility = JavaVersion.VERSION_17",
            ).replace(
                "targetCompatibility = JavaVersion.VERSION_11",
                "targetCompatibility = JavaVersion.VERSION_17",
            )
            block = block.replace(
                "sourceCompatibility = JavaVersion.VERSION_17\n",
                "sourceCompatibility = JavaVersion.VERSION_17\n        isCoreLibraryDesugaringEnabled = true\n",
                1,
            )
        else:
            block = block[:-5] + '''        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }'''
        text = text[:start] + block + text[end + 5:]

dependency = 'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")'
if dependency not in text:
    text += f'''\n\ndependencies {{\n    {dependency}\n}}\n'''

gradle.write_text(text, encoding="utf-8")
print("Android core library desugaring configured.")
