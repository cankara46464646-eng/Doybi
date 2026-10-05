"""Pexels'ten (ücretsiz lisans) aday fotoğrafları indirip küçültür ve bir önizleme sayfası yapar."""
import io, sys, urllib.request
from pathlib import Path
from PIL import Image, ImageDraw

out = Path("out"); out.mkdir(exist_ok=True)
items = [l.split() for l in Path("tool/photo_candidates.txt").read_text().splitlines() if l.strip()]
thumbs = []
for key, pid in items:
    urls = [
        f"https://images.pexels.com/photos/{pid}/pexels-photo-{pid}.jpeg?auto=compress&cs=tinysrgb&w=1000",
        f"https://www.pexels.com/photo/{pid}/download/?w=1000",
    ]
    data = None
    for u in urls:
        try:
            req = urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0 (DoybiBuild)"})
            data = urllib.request.urlopen(req, timeout=30).read()
            Image.open(io.BytesIO(data)).verify()
            break
        except Exception as e:
            print("fail", key, u, e)
            data = None
    if not data:
        continue
    im = Image.open(io.BytesIO(data)).convert("RGB")
    im.thumbnail((1000, 1000))
    im.save(out / f"{key}.jpg", quality=80)
    t = im.copy(); t.thumbnail((300, 300)); thumbs.append((key, t))
    print("ok", key, im.size)

cols = 5
w, h = 300, 330
rows = (len(thumbs) + cols - 1) // cols
sheet = Image.new("RGB", (cols * w, rows * h), "white")
d = ImageDraw.Draw(sheet)
for i, (k, t) in enumerate(thumbs):
    x, y = (i % cols) * w, (i // cols) * h
    sheet.paste(t, (x + (w - t.width) // 2, y))
    d.text((x + 6, y + 304), k, fill="black")
sheet.save(out / "sheet.jpg", quality=80)
