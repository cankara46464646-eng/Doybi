"""iOS ana ekran açılış görselleri (apple-touch-startup-image).

Zemin, web/index.html'deki açılış ekranıyla birebir aynıdır: yukarıdan aşağı #FC361B → #FD5C0F
geçişi ve logonun arkasında yumuşak turuncu ışık. Böylece uygulama açılırken beyaz parlama olmaz.
Çalıştır: python3 tool/make_startup.py  (web/icons/startup/ altına yazar, <link> satırlarını basar)
"""
import os
import numpy as np
from PIL import Image

# (css genişlik, css yükseklik, piksel oranı)
DEVICES = [
    (440, 956, 3),  # 16 Pro Max, 17 Pro Max
    (420, 912, 3),  # Air
    (402, 874, 3),  # 16 Pro, 17, 17 Pro
    (430, 932, 3),  # 16 Plus, 15 Pro Max, 15 Plus, 14 Pro Max
    (393, 852, 3),  # 16, 15, 15 Pro, 14 Pro
    (428, 926, 3),  # 14 Plus, 13 Pro Max, 12 Pro Max
    (390, 844, 3),  # 16e, 14, 13, 13 Pro, 12, 12 Pro
    (375, 812, 3),  # 13 mini, 12 mini, 11 Pro, XS, X
    (414, 896, 3),  # 11 Pro Max, XS Max
    (414, 896, 2),  # 11, XR
    (414, 736, 3),  # 8 Plus
    (375, 667, 2),  # SE 2-3, 8
]

TOP = np.array([0xFC, 0x36, 0x1B], dtype=np.float64)
BOTTOM = np.array([0xFD, 0x5C, 0x0F], dtype=np.float64)
GLOW = np.array([255, 140, 60], dtype=np.float64)


def render(w, h):
    y = (np.arange(h, dtype=np.float64) + 0.5) / h
    x = (np.arange(w, dtype=np.float64) + 0.5) / w
    base = TOP[None, None, :] + (BOTTOM - TOP)[None, None, :] * y[:, None, None]
    base = np.broadcast_to(base, (h, w, 3))
    dx = (x[None, :] - 0.5) / 0.60
    dy = (y[:, None] - 0.44) / 0.42
    a = 0.55 * np.clip(1 - np.sqrt(dx * dx + dy * dy), 0, 1)
    out = base * (1 - a[..., None]) + GLOW[None, None, :] * a[..., None]
    return Image.fromarray(np.clip(np.rint(out), 0, 255).astype(np.uint8), 'RGB')


def main():
    root = os.path.join(os.path.dirname(__file__), '..', 'web', 'icons', 'startup')
    os.makedirs(root, exist_ok=True)
    links = []
    for cw, ch, r in DEVICES:
        w, h = cw * r, ch * r
        name = f'startup-{w}x{h}.png'
        render(w, h).save(os.path.join(root, name), optimize=True)
        links.append(
            f'  <link rel="apple-touch-startup-image" href="icons/startup/{name}" '
            f'media="(device-width: {cw}px) and (device-height: {ch}px) and (-webkit-device-pixel-ratio: {r}) and (orientation: portrait)">'
        )
    print('\n'.join(links))


if __name__ == '__main__':
    main()
