"""`flutter create` ile üretilen android/ klasörünü Doybi için ayarlar (GitHub Actions içinde çalışır).

- uygulama adı ve ikonlar
- internet izni
- sabit imza anahtarı (yeni APK eskisinin üstüne kurulabilsin diye)
"""
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ANDROID = ROOT / "android"
APP = ANDROID / "app"
MAIN = APP / "src" / "main"


def fail(msg):
    print(f"[patch_android] HATA: {msg}")
    sys.exit(1)


def sub_once(pattern, repl, text, what, flags=0):
    new, n = re.subn(pattern, repl, text, count=1, flags=flags)
    if n == 0:
        fail(f"bulunamadı: {what}")
    return new


# ikonlar
for d in (ROOT / "tool" / "res").iterdir():
    target = MAIN / "res" / d.name
    target.mkdir(parents=True, exist_ok=True)
    for f in d.iterdir():
        shutil.copy2(f, target / f.name)
print("[patch_android] ikonlar kopyalandı")

# manifest
manifest_path = MAIN / "AndroidManifest.xml"
m = manifest_path.read_text(encoding="utf-8")
m = sub_once(r'android:label="[^"]*"', 'android:label="Doybi"', m, "android:label")
if "android:roundIcon" not in m:
    m = sub_once(
        r'android:icon="@mipmap/ic_launcher"',
        'android:icon="@mipmap/ic_launcher"\n        android:roundIcon="@mipmap/ic_launcher_round"',
        m,
        "android:icon",
    )
if "android.permission.INTERNET" not in m:
    m = sub_once(r"(<manifest[^>]*>)", lambda mo: mo.group(1) + '\n    <uses-permission android:name="android.permission.INTERNET" />', m, "<manifest>")
manifest_path.write_text(m, encoding="utf-8")
print("[patch_android] manifest ayarlandı")

# imza
kts = APP / "build.gradle.kts"
groovy = APP / "build.gradle"
if kts.exists():
    g = kts.read_text(encoding="utf-8")
    if "doybiTest" not in g:
        g = sub_once(
            r"(\n\s*buildTypes\s*\{)",
            lambda mo: """
    signingConfigs {
        create("doybiTest") {
            storeFile = file("../../tool/keys/doybi-test.jks")
            storePassword = "doybi123"
            keyAlias = "doybi"
            keyPassword = "doybi123"
        }
    }
""" + mo.group(1),
            g,
            "buildTypes (kts)",
        )
        g = sub_once(
            r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)',
            'signingConfig = signingConfigs.getByName("doybiTest")',
            g,
            "release signingConfig (kts)",
        )
    kts.write_text(g, encoding="utf-8")
    print("[patch_android] build.gradle.kts ayarlandı")
elif groovy.exists():
    g = groovy.read_text(encoding="utf-8")
    if "doybiTest" not in g:
        g = sub_once(
            r"(\n\s*buildTypes\s*\{)",
            lambda mo: """
    signingConfigs {
        doybiTest {
            storeFile file("../../tool/keys/doybi-test.jks")
            storePassword "doybi123"
            keyAlias "doybi"
            keyPassword "doybi123"
        }
    }
""" + mo.group(1),
            g,
            "buildTypes (groovy)",
        )
        g = sub_once(r"signingConfig\s*=?\s*signingConfigs\.debug", "signingConfig signingConfigs.doybiTest", g, "release signingConfig (groovy)")
    groovy.write_text(g, encoding="utf-8")
    print("[patch_android] build.gradle ayarlandı")
else:
    fail("android/app/build.gradle(.kts) yok")

# Kotlin sürümü
settings = ANDROID / "settings.gradle.kts"
if settings.exists():
    s = settings.read_text(encoding="utf-8")
    s2 = re.sub(r'(id\("org\.jetbrains\.kotlin\.android"\)\s*version\s*")1\.[0-9.]+(")', r"\g<1>2.1.0\2", s)
    if s2 != s:
        settings.write_text(s2, encoding="utf-8")
        print("[patch_android] Kotlin 2.1.0")

print("[patch_android] tamam")
