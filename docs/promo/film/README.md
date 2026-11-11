# 宣传片 · DCTimer 鸿蒙版

66 秒产品演示片，**真实界面实录版**：全部画面来自 DevEco 模拟器抓取的真机原生帧，页面只负责取景、极简文字浮层、光感渐变底与 UI 转场，不重绘任何 App 界面元素。无旁白、无字幕，只有程序化配乐与音效。

横屏 16:9，投 B 站 / 抖音。

## 成片在哪

**成片不进仓库**（体积大：1440p ~175 MB / 1080p ~75 MB，`.gitignore` 已忽略 `*.mp4`）。做完放在本地交付目录：

```
D:\_PORJOCT\AI\trae\DCTimer-宣传片交付\
├─ DCTimer-宣传片-1440p.mp4          2560×1440 / 24fps / 20.9 Mbps / ~175 MB   主交付
└─ DCTimer-宣传片-1080p-分享版.mp4    1920×1080 / 24fps / 8.8 Mbps  / ~75 MB    群聊/二次分发
```

音量归一到 −14 LUFS（流媒体标准），真峰 −1.2 dBFS，AAC 48kHz 立体声。两版时长均 66.00s。

想重新生成成片，按下面「怎么做出来的」跑一遍；`mux.mjs` 会输出 `DCTimer-宣传片-1440p.mp4`，1080p 分享版用 ffmpeg 从 1440p 转一次即可。

## 素材

`assets/` 里 12 张真实帧（1280×2832 JPEG），来自 `hdc snapshot_display` 抓的模拟器原生画面：

| 文件 | 内容 |
|---|---|
| `s1_timer.jpeg` | 浅色计时页，大字 18.71 + 打乱串 + 打乱图 + 左下统计 |
| `s2_confirm.jpeg` | 确认成绩弹窗，色调胶囊（确认 / +2 / DNF） |
| `s3_results.jpeg` | 16 行成绩列表 + 底部均值栏 |
| `s4_chart.jpeg` | 蓝色趋势折线 + 橙色平均虚线 |
| `s5_dropdown.jpeg` | 毛玻璃打乱下拉（22 组分类） |
| `s6_cfop.jpeg` | 求解器弹窗，总步数 57，五页签逐段解法 |
| `s7_settings_dark.jpeg` | 深色设置页，含「沉浸光感」开关与「光感配色」 |
| `s8_timer_dark.jpeg` | 深色计时页 |
| `motion1/3/8/12.jpeg` | WCA 观察倒计时 15→14→13→12 真实动态帧 |

## 分镜（9 镜 / 66s）

| # | 时间 | 真实画面 | 浮层文案 |
|---|---|---|---|
| 0 | 0–7s | 计时页（开场标题光扫 + 手机从底部升起） | DCTimer / 鸿蒙原生·魔方计时器 |
| 1 | 7–15s | WCA 观察 15→12 动态帧 | WCA 观察 / 15 秒倒计时·真实计时实录 |
| 2 | 15–22s | 打乱下拉 | 打乱 / 22 组分类·毛玻璃面板 |
| 3 | 22–29s | 确认成绩弹窗 | 确认成绩 / 色调胶囊·判罚一触即达 |
| 4 | 29–36s | 成绩列表 | 成绩管理 / 分组·均值·标准差 |
| 5 | 36–43s | 趋势折线图 | 趋势分析 / 折线生长·平均虚线 |
| 6 | 43–51s | CFOP 求解器 | 全场求解器 / 十字·CFOP·桥式·ZZ·Petrus |
| 7 | 51–59s | 深色设置页 | 沉浸光感 / 深色模式·光感配色 |
| 8 | 59–66s | 深色计时页 | DCTimer / 开源·HarmonyOS（收束） |

六个功能全覆盖：计时（起停 + WCA 15 秒观察）、打乱下拉 + 打乱图、成绩列表 + 统计栏、趋势折线图、求解器 CFOP 逐段解法、深色/沉浸光感主题切换。转场一律「截图在手机框内上滑换屏」，无淡入淡出、无黑帧。

## 怎么做出来的

页面 `index.html` 用 Canvas 2D 把真实截图装进圆角手机框，配合文字浮层与转场，用 [lemo-opuscar](https://github.com/lemomo-ai/lemo-opuscar) 的 `dark-keynote` 风格引擎逐帧渲染。渲染前设好环境：

```powershell
Set-Location 'C:\Users\Administrator\lemo-opuscar'
$env:PATH = 'C:\Users\Administrator\.dsh\tools\ffmpeg;' + $env:PATH
$env:PLAYWRIGHT_BROWSERS_PATH = "$env:LOCALAPPDATA\ms-playwright"
$proj = 'D:\_PORJOCT\AI\trae\dc\docs\promo\film'
$node = 'C:\Users\Administrator\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\node\bin\node.exe'

# 配乐（numpy 程序化合成，输出 out/mix.wav，66s）
& 'C:\Users\Administrator\lemo-opuscar\.venv\Scripts\python.exe' "$proj\make_audio.py"

# 静态评审帧（可选）
& $node core\render\still.mjs $proj 1.5 5 18 32 46 62 --size 2560x1440 --out "$proj\stills"

# 逐帧渲染（66×24 = 1584 帧，3 workers）
& $node core\render\video.mjs $proj --fps 24 --workers 3 --size 2560x1440 --out "$proj\out\video.mp4"

# 混流 + 响度归一 + 编码（产出 1440p 主交付）
& $node core\render\mux.mjs "$proj\out\video.mp4" "$proj\out\mix.wav" "$proj\DCTimer-宣传片-1440p.mp4" 24 2
```

`mux.mjs` 若打印 `... is under the 10 Mbps floor ... re-encoding at CRF 14` 且 exit code 1，是引擎自查码率不足后自动重编了一版，**不是失败**，以最终文件 ffprobe 为准。

1080p 分享版从 1440p 转：

```powershell
& 'C:\Users\Administrator\.dsh\tools\ffmpeg\ffmpeg.exe' -i "$proj\DCTimer-宣传片-1440p.mp4" `
  -vf "scale=1920:1080:flags=lanczos" -c:v libx264 -preset slow -b:v 9M `
  -minrate 9M -maxrate 13M -bufsize 18M -pix_fmt yuv420p -c:a copy `
  -movflags +faststart "$proj\DCTimer-宣传片-1080p-分享版.mp4" -y
```

## 验收

出片后用 ffprobe 自查（主人硬规矩）：2560×1440、码率 ≥10 Mbps、时长 ≥60s。

```powershell
& 'C:\Users\Administrator\.dsh\tools\ffmpeg\ffprobe.exe' -v error `
  -show_entries format=duration,bit_rate:stream=codec_type,width,height,bit_rate `
  -of default=noprint_wrappers=1 "$proj\DCTimer-宣传片-1440p.mp4"
```

再抽 t=5/18/32/46/62 五帧目检，每镜都要能认出真实 App 界面（不是重绘）。抽帧时 `ffmpeg -ss` 要放在 `-i` **之后**才帧精确。

## 设计说明

见 [TREATMENT.md](TREATMENT.md) —— 交付规格、素材清单、逐镜分镜、风格说明、版权、验收条目。

风格取自 `dark-keynote`（暗色科技发布）：近黑渐变、发丝网格、柔光、单一强调色（App 品牌蓝 `#448AFF`）、UI 以 snap-grid 精度运动、转场靠元素展开而非淡入淡出。**界面本身是主角**：所有 App 元素都是真实截图，页面绝不重绘按钮/文字/图表。

## 修改提示

- 页面只按 `innerWidth` / `innerHeight` 布局（全局尺度 `const S = H / 1440`），任何 `--size` 都能出正确构图。
- 中文字体用系统字体（`Microsoft YaHei`），引擎自带字体子集只有约 200 个汉字，标题一换字就会缺。
- 换素材只需替换 `assets/` 里的 jpeg 并保持 `index.html` 的 `SRC` 映射文件名一致；新增镜头改 `SHOTS` 数组并同步 `make_audio.py` 的段落时长。
