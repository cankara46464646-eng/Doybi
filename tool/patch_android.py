"""`flutter create` ile üretilen android/ klasörünü Doybi için ayarlar (GitHub Actions içinde çalışır).

- uygulama adı ve ikonlar
- internet, konum ve kamera izinleri
- kırmızı açılış arka planı (animasyon hemen başlasın diye)
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
perms = [
    "android.permission.INTERNET",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.CAMERA",
]
add = "".join(f'\n    <uses-permission android:name="{p}" />' for p in perms if p not in m)
if add:
    m = sub_once(r"(<manifest[^>]*>)", lambda mo: mo.group(1) + add, m, "<manifest>")
# telefonla arama ve harita bağlantıları için (Android 11+ paket görünürlüğü)
if "android.intent.action.DIAL" not in m:
    q = """
        <intent>
            <action android:name="android.intent.action.DIAL" />
            <data android:scheme="tel" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>"""
    if "<queries>" in m:
        m = m.replace("<queries>", "<queries>" + q, 1)
    else:
        m = sub_once(r"(</manifest>)", lambda mo: "    <queries>" + q + "\n    </queries>\n" + mo.group(1), m, "</manifest>")
manifest_path.write_text(m, encoding="utf-8")
print("[patch_android] manifest ayarlandı")

# açılış arka planı: Doybi kırmızısı, ortada ikon yok (uygulama içi animasyon hemen başlar)
RED = "#FC361B"
res = MAIN / "res"
(res / "values").mkdir(parents=True, exist_ok=True)
(res / "values" / "colors.xml").write_text(
    f"""<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="doybi_red">{RED}</color>
</resources>
""",
    encoding="utf-8",
)
for d in ("drawable", "drawable-v21"):
    (res / d).mkdir(parents=True, exist_ok=True)
    (res / d / "launch_background.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/doybi_red" />
</layer-list>
""",
        encoding="utf-8",
    )
styles = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:statusBarColor">@color/doybi_red</item>
        <item name="android:navigationBarColor">@color/doybi_red</item>
        {extra}
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
"""
v31 = """<item name="android:windowSplashScreenBackground">@color/doybi_red</item>
        <item name="android:windowSplashScreenAnimatedIcon">@android:color/transparent</item>"""
for d, extra in (("values", ""), ("values-night", ""), ("values-v31", v31), ("values-night-v31", v31)):
    (res / d).mkdir(parents=True, exist_ok=True)
    (res / d / "styles.xml").write_text(styles.replace("{extra}", extra), encoding="utf-8")
print("[patch_android] açılış ekranı kırmızı")

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
    # kamera (QR) kütüphanesi en az Android 6 ister
    g = re.sub(r"minSdk\s*=\s*flutter\.minSdkVersion", "minSdk = 23", g)
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
    g = re.sub(r"minSdkVersion\s+flutter\.minSdkVersion", "minSdkVersion 23", g)
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
