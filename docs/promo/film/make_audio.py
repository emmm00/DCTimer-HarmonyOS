# -*- coding: utf-8 -*-
"""
DCTimer 宣传片（真实界面实录版 66s）· 配乐与音效合成
=====================================================
沿用第一版 40s 配乐的音色动机（加法合成 pad / mallet / sub / tick +
lemo-opuscar 的 sfx.py），按 66s / 9 镜重排段落。
全部程序化生成，不采样任何现有作品；无旁白、无字幕、无 TTS。

输出: out/mix.wav  (48kHz / 16bit / stereo, 66s)
"""
import sys, io, os, math
# lemo-opuscar 的 sfx.py 位置：可用 LEMO_LIB 环境变量指定，未设时回落到常见安装路径
_lemo = os.environ.get('LEMO_LIB', r'C:\Users\Administrator\lemo-opuscar')
sys.path.insert(0, os.path.join(_lemo, 'core', 'audio'))
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

import numpy as np
import soundfile as sf
import sfx

SR = sfx.SR
DUR = 66.0
N = int(DUR * SR)

# ============================================================
# 音色（与第一版完全一致）
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
    """单个音符：正弦泛音叠加 + ADSR。"""
    n = int(dur * SR)
    if n <= 0:
        return
    tt = np.arange(n) / SR
    ff = f * (1.0 + gliss * tt / dur)
    x = np.zeros(n)
    for k, a in enumerate(harm, start=1):
        fk = ff * k
        if detune > 0:
            x += a * 0.5 * np.sin(2 * np.pi * fk * (1 - detune) * tt)
            x += a * 0.5 * np.sin(2 * np.pi * fk * (1 + detune) * tt)
        else:
            x += a * np.sin(2 * np.pi * fk * tt)
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
    x = sfx.lp(x, min(16000, f * 9))
    sfx.add(buf, x, at, gain, pan)


def pad_note(buf, f, at, dur, gain=1.0, pan=0.0):
    """暖色 pad：慢起慢收。"""
    add_synth(buf, f, at, dur, gain, pan,
              harm=(1.0, 0.42, 0.20, 0.10, 0.05, 0.03),
              att=0.55, dec=0.5, sus=0.62, rel=1.1, detune=0.0035)


def sine_sub(buf, f, at, dur, gain=1.0, pan=0.0):
    """低频支撑。"""
    add_synth(buf, f, at, dur, gain, pan,
              harm=(1.0, 0.08), att=0.03, dec=0.2, sus=0.75, rel=0.5)


def mallet(buf, f, at, dur, gain=1.0, pan=0.0):
    """木琴 / 马林巴。"""
    n = int(dur * SR)
    tt = np.arange(n) / SR
    x = np.zeros(n)
    for k, a in [(1, 1.0), (4, 0.35), (10, 0.12), (2, 0.18)]:
        x += a * np.sin(2 * np.pi * f * k * tt) * np.exp(-tt / (dur * 0.28))
    tr = np.zeros(n)
    tn = min(n, int(0.008 * SR))
    tr[:tn] = np.random.default_rng(int(f)).standard_normal(tn) * np.linspace(1, 0, tn)
    x += sfx.bp(tr, 2500, 7000) * 0.35
    x *= np.minimum(1, np.arange(n) / (0.002 * SR))
    x = sfx.norm(x, 1.0)
    sfx.add(buf, x, at, gain, pan)


def tick(buf, at, gain=0.3, pan=0.0):
    """极短的点：数字跳动 / 逐段点亮。"""
    d = 0.012
    n = int(d * SR)
    tt = np.arange(n) / SR
    x = np.sin(2 * np.pi * 3400 * tt) * np.exp(-tt / 0.0025)
    x += sfx.bp(np.random.default_rng(3).standard_normal(n), 4000, 9000) * np.exp(-tt / 0.0012) * 0.6
    sfx.add(buf, sfx.norm(x) * gain, at, 1.0, pan)


# ============================================================
# 1. 音乐层（66 秒，九段 = 九个镜头）
# ============================================================
music = np.zeros((N, 2), dtype=np.float32)

# ---- 镜 0：0–7s 开场 / 标题光扫（稀疏，逐拍加入） ----
pad_note(music, n2f('C2'), 0.0, 7.0, 0.34)
sine_sub(music, n2f('C1'), 0.0, 7.0, 0.22)
for i, nm in enumerate(['C4', 'E4', 'G4', 'B4', 'C5', 'E5']):
    at = 0.9 + i * 0.72
    if at < 6.6:
        mallet(music, n2f(nm), at, 2.0, 0.16)
for i, nm in enumerate(['G6', 'C7', 'E7']):          # 光扫 shimmer
    add_synth(music, n2f(nm), 0.85 + i * 0.06, 1.6, 0.055, -0.2 + i * 0.2,
              harm=(1.0, 0.3), att=0.02, dec=0.3, sus=0.35, rel=1.1)
# 手机升起
pad_note(music, n2f('G2'), 2.6, 4.4, 0.20)
pad_note(music, n2f('D3'), 2.6, 4.4, 0.13)

# ---- 镜 1：7–15s WCA 观察（心跳渐起，15→12 倒计时） ----
pad_note(music, n2f('A2'), 7.0, 8.0, 0.26)
pad_note(music, n2f('E3'), 7.0, 8.0, 0.16)
for i in range(8):                                    # 心跳低频
    at = 7.2 + i * 0.98
    sine_sub(music, n2f('C1'), at, 0.30, 0.16)
    sine_sub(music, n2f('C1'), at + 0.13, 0.24, 0.10)
for i in range(46):                                   # 16 分底鼓渐密
    at = 7.5 + i * 0.16
    if at > 14.7:
        break
    sine_sub(music, n2f('D2'), at, 0.11, 0.05 + 0.05 * (i / 46))
arp = ['C5', 'E5', 'G5', 'C6', 'G5', 'E5']
for i in range(40):                                   # 高音跑动
    at = 7.6 + i * 0.18
    if at > 14.8:
        break
    mallet(music, n2f(arp[i % len(arp)]), at, 1.0, 0.075, -0.35 + 0.7 * ((i % 6) / 5.0))
# 推进到下一镜的过渡 pad
pad_note(music, n2f('G2'), 14.0, 1.6, 0.20)

# ---- 镜 2：15–22s 打乱下拉（轻快琶音 = 面板展开） ----
pad_note(music, n2f('F2'), 15.0, 7.0, 0.26)
pad_note(music, n2f('C3'), 15.0, 7.0, 0.18)
drop_arp = ['F4', 'A4', 'C5', 'F5', 'C5', 'A4', 'F4', 'C5']
for i in range(28):
    at = 15.1 + i * 0.24
    if at > 21.7:
        break
    mallet(music, n2f(drop_arp[i % len(drop_arp)]), at, 1.3, 0.10,
           -0.4 + 0.8 * ((i % 4) / 3.0))
pad_note(music, n2f('A2'), 21.0, 1.6, 0.18)

# ---- 镜 3：22–29s 确认成绩（温暖和弦 + 数字锁定） ----
pad_note(music, n2f('C2'), 22.0, 7.0, 0.30)
pad_note(music, n2f('G2'), 22.0, 7.0, 0.22)
pad_note(music, n2f('E3'), 22.0, 7.0, 0.16)
for i, nm in enumerate(['E4', 'G4', 'C5', 'E5']):    # 三胶囊依次亮起
    mallet(music, n2f(nm), 22.6 + i * 0.32, 2.2, 0.15, -0.3 + 0.2 * i)
mallet(music, n2f('C5'), 25.0, 2.6, 0.14)           # 确认音
pad_note(music, n2f('D2'), 28.0, 1.6, 0.18)

# ---- 镜 4：29–36s 成绩列表（木琴跟行滑入，八分音符） ----
pad_note(music, n2f('G2'), 29.0, 7.0, 0.28)
pad_note(music, n2f('D3'), 29.0, 7.0, 0.18)
row_pitch = ['G4', 'A4', 'B4', 'D5', 'B4', 'A4', 'G4', 'B4', 'D5']
for i in range(16):
    at = 29.2 + i * 0.38
    if at > 35.3:
        break
    mallet(music, n2f(row_pitch[i % len(row_pitch)]), at, 1.4, 0.12,
           -0.4 + 0.8 * ((i % 3) / 2.0))
mallet(music, n2f('D5'), 33.0, 2.2, 0.15)           # 均值栏亮音
mallet(music, n2f('A5'), 33.08, 2.0, 0.10)
pad_note(music, n2f('E2'), 35.0, 1.6, 0.18)

# ---- 镜 5：36–43s 趋势图（音阶上行，跟折线生长） ----
pad_note(music, n2f('C2'), 36.0, 7.0, 0.30)
pad_note(music, n2f('G2'), 36.0, 7.0, 0.22)
pad_note(music, n2f('E3'), 36.0, 7.0, 0.16)
scale_up = ['C4','D4','E4','F4','G4','A4','B4','C5','D5','E5','F5','G5','A5','B5','C6','D6']
for i, nm in enumerate(scale_up):
    at = 36.2 + i * 0.30
    mallet(music, n2f(nm), at, 1.2, 0.085 + 0.04 * (i / 16), -0.45 + 0.9 * (i / 16))
mallet(music, n2f('G5'), 40.9, 2.0, 0.14)           # 平均虚线出现
pad_note(music, n2f('F1'), 42.0, 1.6, 0.20)

# ---- 镜 6：43–51s CFOP 求解器（五声音阶 = 逐段点亮，情绪高点） ----
pad_note(music, n2f('F1'), 43.0, 8.0, 0.30)
pad_note(music, n2f('C2'), 43.0, 8.0, 0.22)
pad_note(music, n2f('G2'), 43.0, 8.0, 0.14)
pent = ['C4', 'D4', 'E4', 'G4', 'A4', 'C5', 'D5', 'E5']
for i, nm in enumerate(pent):
    at = 43.3 + i * 0.85
    mallet(music, n2f(nm), at, 2.4, 0.20, -0.3 + 0.6 * (i / 7))
    mallet(music, n2f(nm) * 2, at + 0.015, 1.2, 0.06, -0.3 + 0.6 * (i / 7))
pad_note(music, n2f('A2'), 50.0, 1.6, 0.18)

# ---- 镜 7：51–59s 沉浸光感（柔和、空间感，主题切换） ----
for nm, g in [('A2', 0.26), ('E3', 0.18), ('C4', 0.12)]:
    pad_note(music, n2f(nm), 51.0, 8.0, g)
for i in range(12):                                   # 稀疏的高音星点
    at = 51.4 + i * 0.6
    nm = ['C6','E6','G6','E6'][i % 4]
    add_synth(music, n2f(nm), at, 2.2, 0.045, -0.3 + 0.6 * ((i % 4) / 3),
              harm=(1.0, 0.25), att=0.12, dec=0.6, sus=0.20, rel=1.4)
pad_note(music, n2f('G2'), 58.0, 1.6, 0.18)

# ---- 镜 8：59–66s 终卡（收束成一个和弦 + 高音闪光） ----
for nm, g in [('C2', 0.30), ('G2', 0.22), ('E3', 0.18), ('C4', 0.14), ('G4', 0.10)]:
    pad_note(music, n2f(nm), 59.2, 6.6, g)
for nm in ['C6', 'E6', 'G6']:
    add_synth(music, n2f(nm), 59.6, 3.0, 0.045,
              harm=(1.0, 0.25), att=0.12, dec=0.6, sus=0.20, rel=1.6)


# ============================================================
# 2. 音效层（按镜头缝铺）
# ============================================================
fx = np.zeros((N, 2), dtype=np.float32)

# 镜 0 开场
sfx.add(fx, sfx.whoosh(0.55, 0.42), 0.55, 1.0, -0.2)     # 光扫
sfx.add(fx, sfx.whoosh(0.50, 0.55), 2.62, 1.0, 0.0)      # 手机升起
sfx.add(fx, sfx.thump(0.60, 62), 3.5, 1.0, 0.0)
for at in [4.3, 5.3, 6.3]:
    sfx.add(fx, sfx.step(0.14), at, 1.0, 0.25)

# 镜 1 WCA 观察：每帧跳一次 + 落指
sfx.add(fx, sfx.thump(0.45, 48), 7.15, 1.0, 0.0)
for i in range(60):
    at = 7.35 + i * 0.12
    if at > 14.8:
        break
    tick(fx, at, 0.050 + 0.028 * (i / 60), -0.15 + 0.3 * ((i % 4) / 3.0))
for at in [9.0, 11.0, 13.0]:                                # 倒计时跳数
    sfx.add(fx, sfx.ding(0.18), at, 1.0, -0.25)
sfx.add(fx, sfx.whoosh(0.62, 0.36), 14.05, 1.0, 0.0)     # 推向下一镜

# 镜 2 打乱下拉：面板展开 + 分类逐条
sfx.add(fx, sfx.whoosh(0.50, 0.42), 15.05, 1.0, 0.0)
for i in range(9):
    at = 15.2 + i * 0.55
    sfx.add(fx, sfx.step(0.11), at, 1.0, -0.35 + 0.7 * ((i % 3) / 2.0))
sfx.add(fx, sfx.rumble(1.10, 0.24), 21.10, 1.0, 0.0)

# 镜 3 确认成绩：三胶囊依次 + 确认
for i in range(3):
    sfx.add(fx, sfx.pop(0.20 + 0.03 * i), 22.6 + i * 0.32, 1.0, -0.2 + 0.2 * i)
sfx.add(fx, sfx.ding(0.20), 25.0, 1.0, 0.2)
sfx.add(fx, sfx.rumble(1.10, 0.24), 28.10, 1.0, 0.0)
for i in range(8):
    tick(fx, 28.12 + i * 0.16, 0.028 + 0.010 * i, -0.3 + 0.6 * (i / 7))

# 镜 4 成绩列表：行滑入
for i in range(16):
    at = 29.2 + i * 0.38
    if at > 35.3:
        break
    sfx.add(fx, sfx.step(0.11), at, 1.0, -0.35 + 0.7 * ((i % 3) / 2.0))
sfx.add(fx, sfx.ding(0.16), 33.0, 1.0, 0.2)
sfx.add(fx, sfx.rumble(1.10, 0.24), 35.10, 1.0, 0.0)

# 镜 5 趋势图：折线点逐个
for i in range(16):
    at = 36.2 + i * 0.30
    tick(fx, at, 0.030, -0.4 + 0.8 * (i / 16))
sfx.add(fx, sfx.ding(0.18), 40.9, 1.0, 0.15)
sfx.add(fx, sfx.whoosh(0.46, 0.40), 42.10, 1.0, 0.0)

# 镜 6 CFOP：面板升起 + 逐段点亮
sfx.add(fx, sfx.whoosh(0.46, 0.48), 43.05, 1.0, 0.0)
for i in range(8):
    at = 43.3 + i * 0.85
    sfx.add(fx, sfx.pop(0.16), at + 0.02, 1.0, -0.3 + 0.6 * (i / 7))
sfx.add(fx, sfx.rumble(1.20, 0.26), 50.10, 1.0, 0.0)
for i in range(8):
    tick(fx, 50.12 + i * 0.12, 0.026 + 0.010 * i, 0.3 - 0.6 * (i / 7))

# 镜 7 沉浸光感：开关 + 柔和推进
sfx.add(fx, sfx.whoosh(0.60, 0.34), 51.05, 1.0, 0.0)
sfx.add(fx, sfx.ding(0.22), 52.2, 1.0, 0.0)
for i in range(6):
    sfx.add(fx, sfx.pop(0.10), 53.0 + i * 0.9, 1.0, -0.3 + 0.6 * (i / 5))
sfx.add(fx, sfx.rumble(1.20, 0.24), 58.10, 1.0, 0.0)

# 镜 8 终卡收束
sfx.add(fx, sfx.thump(0.50, 55), 59.10, 1.0, 0.0)
sfx.add(fx, sfx.whoosh(0.40, 0.30), 59.10, 1.0, 0.0)
sfx.add(fx, sfx.ding(0.24), 60.4, 1.0, 0.0)


# ============================================================
# 3. 混音
# ============================================================
def music_gain(t):
    if t < 2.6:   return 0.70          # 标题光扫，轻
    if t < 7.0:   return 0.80          # 手机升起
    if t < 15.0:  return 0.95          # WCA 观察最满
    if t < 22.0:  return 0.82
    if t < 29.0:  return 0.86
    if t < 36.0:  return 0.88
    if t < 43.0:  return 0.94
    if t < 51.0:  return 1.00          # 求解器情绪高点
    if t < 59.0:  return 0.76          # 沉浸光感，柔下来
    return 0.84                        # 终卡

mg = np.array([music_gain(x) for x in np.linspace(0, DUR, N)])
k = int(0.12 * SR)
mg = np.convolve(mg, np.ones(k) / k, mode='same')

mix = music * mg[:, None] + fx * 0.92

mix[:, 0] = sfx.compress(mix[:, 0], thr=0.42, ratio=2.6, att=0.006, rel=0.14)
mix[:, 1] = sfx.compress(mix[:, 1], thr=0.42, ratio=2.6, att=0.006, rel=0.14)

# 淡出（最后一秒）
fo = np.ones(N)
fn = int(1.4 * SR)
fo[-fn:] = np.linspace(1, 0, fn) ** 1.4
mix *= fo[:, None]

# 边缘静音
rn = int(0.01 * SR)
mix[:rn] *= np.linspace(0, 1, rn)[:, None]
mix[-rn:] *= np.linspace(1, 0, rn)[:, None]

peak = np.abs(mix).max()
print(f'压缩前峰值: {peak:.4f}')
mix = mix / max(peak, 1e-9) * 0.89
mix = np.stack([sfx.limit(mix[:, 0], 0.94), sfx.limit(mix[:, 1], 0.94)], axis=1)

# 输出到本脚本同级的 out/ 目录，不写死本机绝对路径
out = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'out', 'mix.wav')
os.makedirs(os.path.dirname(out), exist_ok=True)
sf.write(out, mix.astype(np.float32), SR, subtype='PCM_16')

print(f'写入: {out}')
print(f'时长: {len(mix)/SR:.2f}s  采样率: {SR}  声道: 2')
# 逐秒 RMS，检查有没有断掉的静默段
for s in range(int(DUR)):
    seg = mix[s*SR:(s+1)*SR]
    rms = float(np.sqrt(np.mean(seg**2)))
    if rms < 0.06:
        print(f'  [低音量] {s}s rms={rms:.4f}')
