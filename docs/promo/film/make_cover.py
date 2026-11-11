# -*- coding: utf-8 -*-
"""DCTimer 宣传片封面 v3 · 1920x1080
v3 改动：三台手机全部完整显示（机身不出画布）；几何校验只针对机身本体（排除投影留白）；
左侧文字列安全区与手机区分离，确保不压字。
"""
import os, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H = 1920, 1080
HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.join(HERE, 'assets')
OUT = HERE
ACCENT = (68, 138, 255)

F_BD = r'C:\Windows\Fonts\msyhbd.ttc'
F_RG = r'C:\Windows\Fonts\msyh.ttc'
F_MO = r'C:\Windows\Fonts\consola.ttf'
F_TI = r'C:\Windows\Fonts\bahnschrift.ttf'


def font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except Exception:
        return ImageFont.truetype(F_BD, size)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def lerp_stops(stops, t):
    if t <= stops[0][0]:
        return stops[0][1]
    if t >= stops[-1][0]:
        return stops[-1][1]
    for i in range(len(stops) - 1):
        p0, c0 = stops[i]
        p1, c1 = stops[i + 1]
        if p0 <= t <= p1:
            k = (t - p0) / (p1 - p0) if p1 > p0 else 0.0
            return lerp(c0, c1, k)
    return stops[-1][1]


# ---------- 背景 ----------
BG = [(0.00, (9, 17, 29)), (0.35, (15, 36, 54)), (0.70, (15, 43, 41)), (1.00, (21, 20, 41))]
img = Image.new('RGB', (W, H))
d = ImageDraw.Draw(img)
for y in range(H):
    d.line([(0, y), (W, y)], fill=lerp_stops(BG, y / (H - 1)))
img = img.convert('RGBA')

glow = Image.new('RGB', (W, H), (0, 0, 0))
gd = ImageDraw.Draw(glow)
gd.ellipse([-620, -760, 1200, 800], fill=(24, 50, 94))
gd.ellipse([860, 220, 2300, 1600], fill=(32, 27, 70))
glow = glow.filter(ImageFilter.GaussianBlur(260)).convert('RGBA')
glow.putalpha(155)
img = Image.alpha_composite(img, glow)

grid = Image.new('RGBA', (W, H), (0, 0, 0, 0))
gd = ImageDraw.Draw(grid)
STEP = 64
for x in range(0, W + STEP, STEP):
    gd.line([(x, 0), (x, H)], fill=(120, 165, 230, 14), width=1)
for y in range(0, H + STEP, STEP):
    gd.line([(0, y), (W, y)], fill=(120, 165, 230, 14), width=1)
img = Image.alpha_composite(img, grid)


# ---------- 手机 ----------
def make_phone(src, height, cx, cy, angle=0.0, shadow=60, rim=150):
    im = Image.open(os.path.join(ASSETS, src)).convert('RGB')
    w = int(round(height * im.width / im.height))
    im = im.resize((w, height), Image.LANCZOS)
    r = int(w * 0.115)

    mask = Image.new('L', (w, height), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, w - 1, height - 1], radius=r, fill=255)

    body = Image.new('RGBA', (w, height), (0, 0, 0, 0))
    body.paste(im, (0, 0), mask)

    edge = Image.new('RGBA', (w, height), (0, 0, 0, 0))
    ImageDraw.Draw(edge).rounded_rectangle([1, 1, w - 2, height - 2], radius=r,
                                           outline=(150, 195, 255, rim), width=2)
    body = Image.alpha_composite(body, edge)

    if angle:
        body = body.rotate(angle, resample=Image.BICUBIC, expand=True)
    bw, bh = body.size

    pad = shadow * 2
    sh_mask = Image.new('L', (bw + pad * 2, bh + pad * 2), 0)
    sh_mask.paste(body.split()[-1], (pad, pad))
    sh_mask = sh_mask.filter(ImageFilter.GaussianBlur(shadow)).point(lambda v: int(v * 0.78))
    sh_layer = Image.new('RGBA', (bw + pad * 2, bh + pad * 2), (2, 5, 12, 255))
    sh_layer.putalpha(sh_mask)

    canvas = Image.alpha_composite(Image.new('RGBA', (bw + pad * 2, bh + pad * 2), (0, 0, 0, 0)), sh_layer)
    canvas.paste(body, (pad, pad), body)

    # 机身本体在画布中的位置（排除投影留白）
    body_box = (pad, pad, pad + bw, pad + bh)
    pos = (int(cx - canvas.width / 2), int(cy - canvas.height / 2))
    return canvas, pos, (pos[0] + body_box[0], pos[1] + body_box[1],
                         pos[0] + body_box[2], pos[1] + body_box[3])


placed = []


def put(base, layer, pos, name, body_box):
    placed.append((name, body_box))
    out = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    out.paste(layer, pos, layer)
    return Image.alpha_composite(base, out)


# 后排两台
ph, pos, bb = make_phone('s6_cfop.jpeg', 600, 1000, 556, -7.0)
img = put(img, ph, pos, 's6_cfop', bb)

ph, pos, bb = make_phone('s8_timer_dark.jpeg', 620, 1672, 512, 7.0)
img = put(img, ph, pos, 's8_dark', bb)

# 主手机后置柔光
halo = Image.new('RGBA', (W, H), (0, 0, 0, 0))
ImageDraw.Draw(halo).ellipse([1150, 70, 1570, 1030], fill=ACCENT + (44,))
halo = halo.filter(ImageFilter.GaussianBlur(130))
img = Image.alpha_composite(img, halo)

# 主手机
ph, pos, bb = make_phone('s1_timer.jpeg', 880, 1330, 540, 0.0, shadow=72, rim=168)
img = put(img, ph, pos, 's1_timer', bb)

# ---------- 斜向光带 ----------
streak = Image.new('RGBA', (W, H), (0, 0, 0, 0))
sd = ImageDraw.Draw(streak)
sd.polygon([(950, -140), (1215, -140), (760, 1220), (495, 1220)], fill=(175, 212, 255, 20))
streak = streak.filter(ImageFilter.GaussianBlur(72))
img = Image.alpha_composite(img, streak)

# ---------- 文字 ----------
X = 110
txt = Image.new('RGBA', (W, H), (0, 0, 0, 0))
td = ImageDraw.Draw(txt)

f_tag = font(F_RG, 26)
tag = 'HarmonyOS 原生'
tw = td.textlength(tag, font=f_tag)
pill_w = int(tw) + 52
pill = Image.new('RGBA', (W, H), (0, 0, 0, 0))
pd = ImageDraw.Draw(pill)
pd.rounded_rectangle([X, 92, X + pill_w, 146], radius=27,
                     fill=(68, 138, 255, 34), outline=ACCENT + (135,), width=2)
txt = Image.alpha_composite(txt, pill)
td = ImageDraw.Draw(txt)
td.text((X + 26, 106), tag, font=f_tag, fill=(206, 227, 255, 255))

f_title = font(F_TI, 152)
td.text((X - 6, 176), 'DCTimer', font=f_title, fill=(255, 255, 255, 255))

f_sub = font(F_BD, 56)
td.text((X + 2, 376), '鸿蒙魔方计时器', font=f_sub, fill=(224, 237, 255, 255))

td.rectangle([X + 2, 474, X + 2 + 120, 480], fill=ACCENT + (255,))

f_feat = font(F_RG, 37)
feats = ['141 种打乱 · 22 组分类', '全场求解器 · CFOP / 桥式 / ZZ', '沉浸光感 · 深浅主题']
yy = 528
for s in feats:
    td.ellipse([X + 3, yy + 16, X + 14, yy + 27], fill=(110, 170, 255, 255))
    td.text((X + 34, yy), s, font=f_feat, fill=(194, 213, 240, 255))
    yy += 60

f_foot = font(F_RG, 28)
f_mono = font(F_MO, 28)
td.text((X + 2, 906), 'GPL-3.0 开源', font=f_foot, fill=(146, 169, 203, 255))
td.text((X + 228, 905), 'github.com/emmm00/DCTimer-HarmonyOS', font=f_mono, fill=(124, 149, 188, 255))

f_wm = font(F_RG, 23)
td.text((W - 264, H - 60), '真实界面实录', font=f_wm, fill=(118, 140, 173, 255))

img = Image.alpha_composite(img, txt)

# ---------- 暗角 ----------
vig = Image.new('L', (W, H), 0)
vd = ImageDraw.Draw(vig)
vd.ellipse([-W * 0.30, -H * 0.36, W * 1.30, H * 1.36], fill=255)
vig = vig.filter(ImageFilter.GaussianBlur(230))
img = Image.composite(img, Image.new('RGBA', (W, H), (4, 7, 14, 255)), vig)

# ---------- 校验 ----------
TEXT_RIGHT = 700  # 左侧文字列右边界（经验值，下面用实测覆盖）
print('=== 机身本体框（排除投影）===')
bad = []
for name, bb in placed:
    x0, y0, x1, y1 = bb
    print('  %-10s x:%4d..%4d  y:%4d..%4d' % (name, x0, x1, y0, y1))
    if x0 < 0 or y0 < 0 or x1 > W or y1 > H:
        bad.append(name)
print('  出画布:', bad if bad else '无')

# 文字右边界实测
probe = Image.new('RGBA', (W, H), (0, 0, 0, 0))
pdd = ImageDraw.Draw(probe)
rights = []
for s, fnt in [('DCTimer', font(F_TI, 152)),
               ('鸿蒙魔方计时器', font(F_BD, 56)),
               ('141 种打乱 · 22 组分类', font(F_RG, 37)),
               ('全场求解器 · CFOP / 桥式 / ZZ', font(F_RG, 37)),
               ('沉浸光感 · 深浅主题', font(F_RG, 37)),
               ('github.com/emmm00/DCTimer-HarmonyOS', font(F_MO, 28))]:
    right = X + pdd.textlength(s, font=fnt)
    rights.append((s, int(right)))
    print('  文字右界 %-40s %d' % (s[:38], right))
min_phone_x = min(bb[0] for _, bb in placed)
print('  手机最左 x = %d ；文字最右 = %d ；净空 = %d px'
      % (min_phone_x, max(r for _, r in rights), min_phone_x - max(r for _, r in rights)))

out = os.path.join(OUT, 'cover_1920x1080.jpg')
img.convert('RGB').save(out, 'JPEG', quality=96, subsampling=0, optimize=True)
print('saved:', out, os.path.getsize(out), 'bytes', img.size)
