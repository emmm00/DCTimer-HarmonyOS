# -*- coding: utf-8 -*-
"""
DCTimer 宣传片 · 配乐与音效合成
=================================
全部程序化生成：音乐用加法合成（正弦 + 泛音 + ADSR），音效用 lemo-opuscar 的 sfx.py。
不采样任何现有作品，符合 TREATMENT §11 的版权要求。

输出: mix.wav  (48kHz / 16bit / stereo, 40s)
"""
import sys, io, os, json, math
sys.path.insert(0, r'C:\Users\Administrator\lemo-opuscar\core\audio')
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

import numpy as np
import soundfile as sf
import sfx

SR = sfx.SR
DUR = 40.0
N = int(DUR * SR)

# ============================================================
# 音乐素材：加法合成
# ============================================================

def n2f(name):
    """音名 → 频率。C4=261.63"""
    names = {'C':0,'C#':1,'D':2,'D#':3,'E':4,'F':5,'F#':6,'G':7,'G#':8,'A':9,'A#':10,'B':11}
    base = name[0] + (name[1] if len(name) > 1 and name[1] == '#' else '')
    octv = int(name[len(base):])
    semis = names[base] + (octv - 4) * 12
    return 440.0 * (2 ** ((semis - 9) / 12.0))


def add_synth(buf, f, at, dur, gain=1.0, pan=0.0,
              harm=(1.0, 0.5, 0.25, 0.12, 0.06), att=0.01, dec=0.12, sus=0.6, rel=0.4,
              detune=0.0, gliss=0.0):
    """单个音符：正弦泛音叠加 + ADSR。detune 制造轻微的厚度。"""
    n = int(dur * SR)
    if n <= 0:
        return
    tt = np.arange(n) / SR
    # 轻微滑音
    ff = f * (1.0 + gliss * tt / dur)
    x = np.zeros(n)
    for k, a in enumerate(harm, start=1):
        fk = ff * k
        if detune > 0:
            x += a * 0.5 * np.sin(2 * np.pi * fk * (1 - detune) * tt)
            x += a * 0.5 * np.sin(2 * np.pi * fk * (1 + detune) * tt)
        else:
            x += a * np.sin(2 * np.pi * fk * tt)
    # ADSR
    a_n = max(1, int(att * SR))
    d_n = max(1, int(dec * SR))
    r_n = max(1, int(rel * SR))
    env = np.ones(n)
    env[:a_n] = np.linspace(0, 1, a_n)
    if n > a_n + d_n:
        env[a_n:a_n + d_n] = np.linspace(1, sus, d_n)
        env[a_n + d_n:] = sus
    if n > r_n:
        env[-r_n:] *= np.linspace(1, 0, r_n)
    x = x * env
    x = sfx.norm(x, 1.0)
    # 加一点低通，去掉刺耳的高频
    x = sfx.lp(x, min(16000, f * 9))
    sfx.add(buf, x, at, gain, pan)


def pad_note(buf, f, at, dur, gain=1.0, pan=0.0):
    """暖色 pad：慢起慢收，多加几个泛音和轻微 detune。"""
    add_synth(buf, f, at, dur, gain, pan,
              harm=(1.0, 0.42, 0.20, 0.10, 0.05, 0.03),
              att=0.55, dec=0.5, sus=0.62, rel=1.1, detune=0.0035)


def sine_sub(buf, f, at, dur, gain=1.0, pan=0.0):
    """低频支撑：纯正弦，加极轻的二次谐波。"""
    add_synth(buf, f, at, dur, gain, pan,
              harm=(1.0, 0.08), att=0.03, dec=0.2, sus=0.75, rel=0.5)


def mallet(buf, f, at, dur, gain=1.0, pan=0.0):
    """木琴 / 马林巴：瞬态强、衰减快、泛音是 1、4、10 倍。"""
    n = int(dur * SR)
    tt = np.arange(n) / SR
    x = np.zeros(n)
    for k, a in [(1, 1.0), (4, 0.35), (10, 0.12), (2, 0.18)]:
        x += a * np.sin(2 * np.pi * f * k * tt) * np.exp(-tt / (dur * 0.28))
    # 敲击瞬态
    tr = np.zeros(n)
    tn = min(n, int(0.008 * SR))
    tr[:tn] = np.random.default_rng(int(f)).standard_normal(tn) * np.linspace(1, 0, tn)
    x += sfx.bp(tr, 2500, 7000) * 0.35
    x *= np.minimum(1, np.arange(n) / (0.002 * SR))     # 2ms 起音
    x = sfx.norm(x, 1.0)
    sfx.add(buf, x, at, gain, pan)


def tick(buf, at, gain=0.3, pan=0.0):
    """极短的点：数字跳动的节拍感。"""
    d = 0.012
    n = int(d * SR)
    tt = np.arange(n) / SR
    x = np.sin(2 * np.pi * 3400 * tt) * np.exp(-tt / 0.0025)
    x += sfx.bp(np.random.default_rng(3).standard_normal(n), 4000, 9000) * np.exp(-tt / 0.0012) * 0.6
    sfx.add(buf, sfx.norm(x) * gain, at, 1.0, pan)


# ============================================================
# 1. 音乐层（40 秒，四段结构）
# ============================================================

music = np.zeros((N, 2), dtype=np.float32)

# ---- 段 A：0–9s 开场（稀疏，一拍一个音） ----
# 低音持续
pad_note(music, n2f('C2'), 0.0, 8.6, 0.34)
sine_sub(music, n2f('C1'), 0.0, 8.6, 0.22)
# 逐拍加入
for i, nm in enumerate(['C4', 'E4', 'G4', 'B4', 'C5', 'E5']):
    at = 0.9 + i * 0.72
    if at < 8.4:
        mallet(music, n2f(nm), at, 2.0, 0.16)
# 光扫来的 shimmer：高音簇
for i, nm in enumerate(['G6', 'C7', 'E7']):
    add_synth(music, n2f(nm), 0.85 + i * 0.06, 1.6, 0.055, -0.2 + i * 0.2,
              harm=(1.0, 0.3), att=0.02, dec=0.3, sus=0.35, rel=1.1)

# ---- 段 B：9–17s 计时（打击层叠加，逐渐加密） ----
# 心跳低频
for i in range(8):
    at = 9.2 + i * 0.98
    sine_sub(music, n2f('C1'), at, 0.30, 0.16)
    sine_sub(music, n2f('C1'), at + 0.13, 0.24, 0.10)
# 16 分音符底鼓感（越来越密）
for i in range(46):
    at = 9.5 + i * 0.16
    if at > 16.7:
        break
    g = 0.05 + 0.05 * (i / 46)
    sine_sub(music, n2f('D2'), at, 0.11, g)
# 高音跑动的琶音（对应数字飞涨）
arp = ['C5', 'E5', 'G5', 'C6', 'G5', 'E5']
for i in range(40):
    at = 9.6 + i * 0.18
    if at > 16.8:
        break
    mallet(music, n2f(arp[i % len(arp)]), at, 1.0, 0.075, -0.35 + 0.7 * ((i % 6) / 5.0))
# pad 铺底
pad_note(music, n2f('G2'), 7.85, 1.5, 0.19)
pad_note(music, n2f('D3'), 7.85, 1.5, 0.13)
pad_note(music, n2f('A2'), 9.0, 8.0, 0.24)
pad_note(music, n2f('E3'), 9.0, 8.0, 0.16)

# ---- 段 C：17–26s 停表 → 落表（先全停，再重新建立） ----
# 17.0–18.2 故意留白（下面的音效层有 clack 尾音）
# 18.2 之后：温暖的持续和弦
pad_note(music, n2f('F2'), 18.15, 7.6, 0.28)
pad_note(music, n2f('C3'), 18.15, 7.6, 0.20)
pad_note(music, n2f('A3'), 18.15, 7.6, 0.15)
# 数字锁定 → 落表，木琴跟着列表节奏走（八分音符）
row_pitch = ['F4', 'G4', 'A4', 'C5', 'A4', 'G4', 'F4', 'A4', 'C5']
for i in range(9):
    at = 21.06 + i * 0.085 * 3.1          # 跟行滑入大致对齐
    if at > 25.6:
        break
    mallet(music, n2f(row_pitch[i % len(row_pitch)]), at, 1.4, 0.13,
           -0.4 + 0.8 * ((i % 3) / 2.0))
# 均值栏出现时的一个亮音
mallet(music, n2f('F5'), 22.15, 2.2, 0.15)
mallet(music, n2f('A5'), 22.22, 2.0, 0.10)

# ---- 段 D：26–36s 图表 → 解法（上行，情绪高点） ----
# 进段前的过渡：让 pad 提前压进来，避免静默感
pad_note(music, n2f('D2'), 24.55, 1.9, 0.20)
pad_note(music, n2f('A2'), 24.55, 1.9, 0.14)
pad_note(music, n2f('G1'), 34.45, 1.9, 0.20)
pad_note(music, n2f('D2'), 34.45, 1.9, 0.14)
pad_note(music, n2f('C2'), 26.0, 5.2, 0.30)
pad_note(music, n2f('G2'), 26.0, 5.2, 0.22)
pad_note(music, n2f('E3'), 26.0, 5.2, 0.16)
# 折线生长：音阶上行，跟着数据点
scale_up = ['C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4', 'C5', 'D5', 'E5',
            'F5', 'G5', 'A5', 'B5', 'C6', 'D6']
for i, nm in enumerate(scale_up):
    at = 26.2 + i * 0.165
    mallet(music, n2f(nm), at, 1.2, 0.085 + 0.04 * (i / 16), -0.45 + 0.9 * (i / 16))
# 平均虚线出现
mallet(music, n2f('G5'), 28.75, 2.0, 0.14)
# 解法面板升起
pad_note(music, n2f('F1'), 31.0, 4.8, 0.30)
pad_note(music, n2f('C2'), 31.0, 4.8, 0.22)
# 五声音阶（对应五段解法）
pent = ['C4', 'D4', 'E4', 'G4', 'A4', 'C5']
for i, nm in enumerate(pent):
    at = 32.15 + i * 0.42
    mallet(music, n2f(nm), at, 2.2, 0.20, -0.3 + 0.6 * (i / 5))
    # 双击，让"点亮"更有分量
    mallet(music, n2f(nm) * 2, at + 0.015, 1.2, 0.06, -0.3 + 0.6 * (i / 5))

# ---- 段 E：36–40s 终卡（收束成一个和弦） ----
for nm, g in [('C2', 0.30), ('G2', 0.22), ('E3', 0.18), ('C4', 0.14), ('G4', 0.10)]:
    pad_note(music, n2f(nm), 36.55, 3.4, g)
# 最后的高音闪光
for nm in ['C6', 'E6', 'G6']:
    add_synth(music, n2f(nm), 37.0, 2.6, 0.045,
              harm=(1.0, 0.25), att=0.12, dec=0.6, sus=0.20, rel=1.6)


# ============================================================
# 2. 音效层（按 EV 表铺）
# ============================================================

fx = np.zeros((N, 2), dtype=np.float32)

# --- 开场 ---
sfx.add(fx, sfx.whoosh(0.55, 0.42), 0.55, 1.0, -0.2)          # 光扫
# --- 镜头 2：手机升起 ---
sfx.add(fx, sfx.whoosh(0.50, 0.55), 4.02, 1.0, 0.0)
sfx.add(fx, sfx.thump(0.60, 62), 5.30, 1.0, 0.0)
for at in [6.10, 7.10, 8.10]:
    sfx.add(fx, sfx.step(0.16), at, 1.0, 0.25)
# 8.0-9.0 的推进：抬起来的 whoosh，把观众推向计时那一镜
sfx.add(fx, sfx.whoosh(0.62, 0.40), 8.05, 1.0, 0.0)
sfx.add(fx, sfx.rumble(0.95, 0.22), 8.05, 1.0, 0.0)
# --- 镜头 3：起跑 ---
sfx.add(fx, sfx.thump(0.45, 48), 9.74, 1.0, 0.0)               # 落指
sfx.add(fx, sfx.ding(0.22), 13.0, 1.0, -0.3)
# 计时期间的细碎 tick（每 1/8 拍）
for i in range(60):
    at = 9.95 + i * 0.12
    if at > 16.80:
        break
    tick(fx, at, 0.055 + 0.03 * (i / 60), -0.15 + 0.3 * ((i % 4) / 3.0))
# --- 镜头 4：停表 ---
sfx.add(fx, sfx.clack(0.72, 0.92), 17.00, 1.0, 0.0)            # 一记重 clack
# 数字逐位锁定
for i in range(5):
    at = 18.25 + i * 0.17
    sfx.add(fx, sfx.pop(0.26 + 0.03 * i), at, 1.0, -0.2 + 0.1 * i)
# --- 镜头 5：落表 ---
for i in range(9):
    at = 21.06 + i * 0.085 * 3.1
    if at > 25.6:
        break
    sfx.add(fx, sfx.step(0.13), at, 1.0, -0.35 + 0.7 * ((i % 3) / 2.0))
sfx.add(fx, sfx.ding(0.16), 22.15, 1.0, 0.2)
# --- 段间推进：25s / 35s 的空档补一层 rising pad，避免"音乐断掉" ---
sfx.add(fx, sfx.rumble(1.35, 0.30), 24.95, 1.0, 0.0)
sfx.add(fx, sfx.rumble(1.25, 0.26), 34.85, 1.0, 0.0)
for i in range(10):
    tick(fx, 25.02 + i * 0.19, 0.030 + 0.012 * i, -0.3 + 0.6 * (i / 9))
    tick(fx, 34.92 + i * 0.11, 0.026 + 0.010 * i, 0.3 - 0.6 * (i / 9))
# --- 镜头 6：折线生长（极轻的电流感） ---
for i in range(16):
    at = 26.2 + i * 0.165
    tick(fx, at, 0.030, -0.4 + 0.8 * (i / 16))
sfx.add(fx, sfx.ding(0.18), 28.75, 1.0, 0.15)
# --- 镜头 7：解法面板 ---
sfx.add(fx, sfx.whoosh(0.46, 0.48), 31.02, 1.0, 0.0)
for i in range(6):
    at = 32.15 + i * 0.42
    sfx.add(fx, sfx.pop(0.16), at + 0.02, 1.0, -0.3 + 0.6 * (i / 5))
# --- 镜头 8：收束 ---
sfx.add(fx, sfx.thump(0.50, 55), 36.00, 1.0, 0.0)
sfx.add(fx, sfx.whoosh(0.40, 0.30), 36.0, 1.0, 0.0)


# ============================================================
# 3. 混音
# ============================================================

# 音乐动态：开场轻、计时渐强、停表处一个 dip、终卡回落
def music_gain(t):
    if t < 4.0:      return 0.72
    if t < 9.0:      return 0.80
    if t < 17.0:     return 0.95          # 计时段最满
    if t < 18.5:     return 0.30          # 停表后突然空下来
    if t < 26.0:     return 0.78
    if t < 31.0:     return 0.90
    if t < 36.0:     return 1.00          # 情绪高点
    return 0.84

tt = np.arange(N) / SR
mg = np.array([music_gain(x) for x in np.linspace(0, DUR, N)])
# 平滑，避免台阶
k = int(0.12 * SR)
mg = np.convolve(mg, np.ones(k) / k, mode='same')

mix = music * mg[:, None] + fx * 0.92

# 总线压缩 + 限幅
mix[:, 0] = sfx.compress(mix[:, 0], thr=0.42, ratio=2.6, att=0.006, rel=0.14)
mix[:, 1] = sfx.compress(mix[:, 1], thr=0.42, ratio=2.6, att=0.006, rel=0.14)

# 淡出（最后一秒）
fo = np.ones(N)
fn = int(1.2 * SR)
fo[-fn:] = np.linspace(1, 0, fn) ** 1.4
mix *= fo[:, None]

# 边缘静音（防爆音）
rn = int(0.01 * SR)
mix[:rn] *= np.linspace(0, 1, rn)[:, None]
mix[-rn:] *= np.linspace(1, 0, rn)[:, None]

peak = np.abs(mix).max()
print(f'压缩前峰值: {peak:.4f}')
mix = mix / max(peak, 1e-9) * 0.89
mix = np.stack([sfx.limit(mix[:, 0], 0.94), sfx.limit(mix[:, 1], 0.94)], axis=1)

# 停表后两处「数字零」：17.0–18.2 与 9.72–9.95 的近似静默由 mg 与环境声保证
out = r'D:\_PORJOCT\AI\trae\dc\docs\promo\film\out\mix.wav'
os.makedirs(os.path.dirname(out), exist_ok=True)
sf.write(out, mix.astype(np.float32), SR, subtype='PCM_16')

dur = len(mix) / SR
print(f'写入: {out}')
print(f'时长: {dur:.2f}s  采样率: {SR}  声道: 2')
print(f'峰值: {np.abs(mix).max():.3f}  RMS: {np.sqrt((mix**2).mean()):.4f}')
