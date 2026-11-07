# DCTimer 魔方计时器 — 项目交接报告

> 本文档面向接管本项目的 AI 助手，目标是让你快速建立全局认知、精准索引功能代码位置、并避开已踩过的坑。
> 阅读顺序建议：第 1~3 章 → 第 7 章注意事项 → 按任务查阅第 5 章功能索引。
>
> **v2 更新（2026-08-22）：** 本版把交接范围从"计时 / 打乱 / 成绩"扩展为完整覆盖 **CFOP + 桥式多解求解引擎**。新增/改动的重点：多种 F2L 插入顺序可选、右桥剪枝表持久化、智能魔方 3D 跟随视图，以及本会话修复的"CFOP 求解闪退"与两类 UI 适配问题。求解引擎架构见 5.7，两个重大 bug 的根因与防回归要点见 7.3，近期改动见第 6 章。

---

## 1. 项目概况

| 项 | 内容 |
|---|---|
| 应用名 | DCTimer（魔方计时与训练工具） |
| 参考原型 | Android 版 DCTimer-BLE + cstimer.net，界面重绘、逻辑忠实移植 |
| 平台 | HarmonyOS（ArkTS / ArkUI 声明式开发） |
| 项目路径 | `D:\_PORJOCT\AI\trae\dc` |
| 开发工具 | DevEco Studio 6.1.1（SDK 位于 `D:\Program Files\Huawei\DevEco Studio\sdk`） |
| SDK 版本 | targetSdkVersion `6.1.1(24)`，compatibleSdkVersion `5.0.0(12)`（即 minAPI=12，刻意下调以覆盖全量设备，勿改回 24） |
| 模块结构 | 单模块 `entry`，单页面 `pages/Index`（约 3400 行，所有 UI 集中于此） |
| 第三方依赖 | 无（仅官方 kit；oh-package 依赖为空） |
| 数据 | 全部本地（RDB 数据库 + Preferences），**不联网、不上传**（隐私政策明确承诺） |

**核心功能**：触屏/WCA观察/手动/智能魔方四种计时方式、100+ 打乱类型生成、成绩管理（惩罚/备注/删除/导出CSV）、滚动统计、成绩趋势图、训练分组、背景图（含裁剪缩放）、浅色/深色/跟随系统三态主题、BLE 智能魔方（Giiker/GAN/Moyu/QiYi 协议）、十字求解器、打乱图案绘制、**CFOP / 桥式解法引擎**（多 F2L 插入顺序可选、右桥剪枝表持久化、解法可点按找出手法）、**智能魔方 3D 跟随视图**。

---

## 2. 构建与运行

```powershell
# 必须在项目根目录执行（脚本内部依赖 CWD）
powershell -ExecutionPolicy Bypass -File "D:\_PORJOCT\AI\trae\dc\build.ps1"
```

- `build.ps1` 做的事：设置 NODE_HOME/DEVECO_SDK_HOME/JAVA_HOME 环境变量 → 调 hvigorw.js 执行 `assembleHap` → 输出日志到 `C:\Users\52622\AppData\Local\Temp\opencode\build_out.log`。
- **路径硬编码**：DevEco 安装在 `D:\Program Files\Huawei\DevEco Studio`，换机器需改脚本前三行。
- **签名**：`build-profile.json5` 的 signingConfig 指向 `D:/dct.p12`、`D:/Download/dctimerRelease.p7b`、`D:/Download/dctimer.cer`（本机文件）。证书缺失时只能出 unsigned 包。
- 构建产物：`entry/build/default/outputs/default/entry-default-signed.hap`。
- **每次改动后必须跑一次 build.ps1 验证**（ArkTS 严格子集规则极多，肉眼检查不可靠）。

---

## 3. 目录结构与文件索引

```
dc/
├── build.ps1                        # 构建脚本（见第 2 章）
├── build-profile.json5              # 签名 + SDK 版本（compatibleSdkVersion=5.0.0(12) 勿动）
├── docs/privacy_policy.md           # 隐私政策原文
└── entry/src/main/
    ├── module.json5                 # 权限：VIBRATE、INTERNET（2026-08-29 已移除蓝牙/位置权限）
    ├── resources/
    │   ├── base/                    # 通用资源（图片、字符串、main_pages.json）
    │   ├── dark/                    # 深色模式资源
    │   └── rawfile/                 # 打包原始文件
    └── ets/
        ├── entryability/EntryAbility.ets     # 入口：系统深色状态监听与全局广播
        ├── pages/Index.ets                   # ★ 主页面（全部 UI + 业务编排，~3400 行）
        ├── model/                           # 数据模型
        │   ├── AppConfig.ets                # ★ 全局配置静态类（设置项 + 主题 + 颜色）
        │   ├── AppGlobals.ets               # 移植自 Android APP.java 的静态杂项状态
        │   ├── DCTTimer.ets                 # ★ 计时引擎（状态机 + 分段计时 + WCA观察）
        │   ├── Result.ets                   # 成绩条目 + DB 读写逻辑（ResultEntry/Result/ResultDB）
        │   ├── Session.ets                  # 训练分组模型
        │   └── SmartCubeTraining.ets        # 智能魔方训练组（OLL/PLL/ZBLL 等子集定义）
        ├── database/DBHelper.ets            # RDB 数据库（16 张成绩表 + sessiontb）
        ├── scrambler/                       # ★ 打乱生成器（对应 Android scramble 包）
        │   ├── Scrambler.ets                #   总入口，124KB，全部魔方类型的打乱算法
        │   ├── Cube.ets / Clock.ets / Megaminx.ets / MegaScramble.ets
        │   ├── Rand444.ets                  #   四阶 random-state 离线程生成（四速/四盲防闪退）
        │   ├── SQ1.ets / MasterPyraminx.ets / Redi.ets / LatchCube.ets
        ├── solver/                          # 求解引擎与各解法（详见第 5.7 章）
        │   ├── SolverCore.ets               # ★ CFOP/Roux 共享引擎（IDDFS、剪枝表、solver_core.dat 缓存、去重化简、旋转）
        │   ├── CfopSolver.ets               #   CFOP taskpool 入口（传 cacheDir 给 worker）
        │   ├── RouxSolver.ets               #   桥式 taskpool 入口（传 cacheDir 给 worker）
        │   ├── WarmCaches.ets               #   启动预热 taskpool 入口（首帧后延迟触发）
        │   ├── CfopSolve.ets / RouxSolve.ets#   求解实现（独立模块供 @Concurrent 任务 import）        │   ├── Cross.ets 等 20+ 个          #   其余解法库（多数已接入打乱生成）
        ├── cs/                              # 状态搜索核心（移植自 Kociemba/min2phase/threephase）
        │   ├── min2phase/                   #   3x3 两阶段（3x3 random state 打乱用）
        │   ├── threephase/                  #   4x4 三阶段
        │   └── sq12phase/                   #   SQ1 两阶段
        ├── util/
        │   ├── Stats.ets                    # ★ 统计计算（avg/best/mean，忠实移植 Stats.java）
        │   ├── ScrambleItems.ets            # 打乱项目菜单数据（23 组分类 → 子项）
        │   ├── StringUtils.ets              # 时间格式化等
        │   ├── BackgroundManager.ets        # 背景图 URI/透明度存取（本质是 AppConfig 包装）
        │   ├── ExportUtil.ets               # CSV 导出/导入
        │   ├── FileIO.ets                   # 文件读写封装
        │   ├── BleManager.ets               # BLE 扫描/连接/收发
        │   ├── SmartCubeProtocol.ets        # 智能魔方协议解析（4 品牌）
        │   ├── SmartCubeOrientation.ets     # 朝向转换
        │   └── CrossSolver.ets              # 十字求解逻辑
        └── view/                            # 自定义组件
            ├── LcdText.ets                  # 7 段数码管计时字体（Canvas 绘制）
            ├── StatsChartView.ets           # 成绩趋势折线图（Canvas）
            ├── ScrambleImageView.ets        # 打乱图案绘制（含大屏高度约束缩放）
            ├── ScrambleCanvasAdapter.ets    # 打乱绘制适配层
            ├── CrossSolverView.ets          # 十字求解器 UI
            ├── MethodSolverView.ets         # ★ 三页签解法弹窗（十字/CFOP/桥式）+ F2L 顺序选择
            ├── FaceChipsRow.ets             #   底色/前面色选择色块条（@Component+@Prop）
            ├── SmartCube3DView.ets          # ★ 智能魔方 3D 视图（54 面块坐标）
            ├── BleScanDialog.ets            # BLE 扫描对话框
            └── BgCropDialog.ets             # 背景图裁剪/缩放对话框（2026-08 新增）
```

---

## 4. 核心架构与数据流

### 4.1 状态管理三层结构

```
@State（Index.ets 组件内）  ←→  AppConfig（静态类，逻辑真值）  ←→  Preferences / RDB（持久化）
```

- **`AppConfig`（静态类）是所有设置项的唯一逻辑真值源**。界面读写设置时三处同步：
  `this.xxx = ...`（驱动刷新） + `AppConfig.xxx = ...`（逻辑层） + `saveToPreferences()`（持久化）。
- `BackgroundManager` 是 AppConfig 背景字段的薄封装，新代码可直接用 AppConfig，但保持现状不必合并。
- `AppGlobals` 是从 Android 移植的遗留静态状态（部分字段已废弃），改代码时优先用 AppConfig。

### 4.2 数据持久化（两套并存）

| 存储 | 内容 | 位置 |
|---|---|---|
| Preferences | 全部设置项 + 背景URI + 隐私同意标志 + 分组列表 | `loadFromPreferences()` / `saveToPreferences()`（Index.ets ~L1290/L1384） |
| RDB（spdcube.db） | 成绩数据：15 张成绩表（每个训练组一张）+ sessiontb | `DBHelper.ets`，经 `Result.ets` 的 `ResultDB` 接口读写 |

### 4.3 主页面结构（Index.ets）

```
build() 根 Stack
├── 背景图层 Image(bgImageUri).opacity(bgOpacity/100)   ← 全屏背景，Cover 填充
├── 主内容 Column
│   ├── 顶部 TabBar（计时器/成绩/设置三 Tab，计时中隐藏）
│   ├── TimerTab()      ← 计时器页（打乱栏+打乱图+计时器+统计条+滑动提示）
│   ├── ResultTab()     ← 成绩页（统计头+列表+底部均值栏）
│   └── SettingsTab()   ← 设置页（8 个分组，锚点滚动）
├── 求解器半屏弹窗（showSolver）
└── BgCropDialog 裁剪层（showBgCrop，全屏覆盖）
```

页面内对话框（@CustomDialog struct，均定义在 Index.ets 底部）：
`SessionSelectDialog`（L575）、`ResultConfirmDialog`（L653）、`ResultActionDialog`（L754）、`ManualInputDialog`（L840）、`NoteEditDialog`（~L3228）、隐私相关对话框（L56 起）。

### 4.4 主题系统（三态）

```
AppConfig.themeMode: 0=浅色  1=深色  2=跟随系统
AppConfig.darkMode:  当前生效明暗（所有 theme*() 颜色函数读这个）
AppConfig.systemDark: 系统当前是否深色
```

链路：EntryAbility `onCreate`/`onConfigurationUpdate` 检测系统 colorMode → 写入全局 `AppStorage` 键 `'dcSystemDark'` → Index 用 `@StorageProp('dcSystemDark') + @Watch('onSystemDarkChange')` 订阅 → `applyEffectiveDark()` 重算 `darkMode` 并刷新 `@State isDark`。

### 4.5 求解引擎架构（v2 新增，最重要）

```
Index.openMethodSolver
  └─ view/MethodSolverView.ets（三页签：十字 / CFOP / 桥式）
       ├─ solver/CfopSolver.ets   ─┐
       └─ solver/RouxSolver.ets   ─┴─→  solver/SolverCore.ets（共享引擎）
                                            ├─ 剪枝表 / IDDFS / 去重化简
                                            ├─ SolveOutput 契约
                                            └─ 协作式异步求解链
```

- **三层职责**：`MethodSolverView` 只负责 UI 与状态（`@State cfopResult/rouxResult/cfopCands`）；两个 `*Solver.ets` 只做阶段编排（十字→F2L→OLL→PLL，或 FB→SB→CMLL→LSE）；`SolverCore.ets` 持有全部算法真值（状态编码、剪枝表、旋转、化简、验证）。
- **`SolveOutput` 契约**：`ok/error/totalSteps/stages/stageSteps/userMoves/userAlg/rotIdx`，CFOP 额外允许 `f2lAlternatives?: F2lAlternative[]`（每种 F2L 插入顺序的 `order/orderName/f2lSteps/f2lAlg`）。所有对外解法都转成**用户握姿坐标系**（`face*3+dir`，face 0-5 对应 UDLRFB + 中层切片），按握姿直接应用即可复原。
- **性能基准**（本机/模拟器）：冷启动 41ms；单次桥式求解 10–134ms；右桥联合剪枝表构建 6.3s；"一次性构建 4 张剪枝表"的旧方案需 69s，是反向教训。
- **2026-08-22 二轮优化（算法提速）**：① 全部热表（cornerMove/edgeMove/cross×4/pairPrun/LSE×2）由 `number[][]` 扁平化为 TypedArray（下标 `state*6+face`），IDA\* 逐节点查表实测提速 1.62×（Node 基准，ArkTS 收益更大）；② F2L 24 顺序枚举改**前缀树缓存**（同前缀只搜一次，96→64 次搜索，整体再省 ~20%，且同一共享预算下能完成更多顺序）；③ 新增**左桥 FB 联合剪枝表**（与右桥同构 8MB，`roux_fb_joint.dat` 落盘缓存，两表 taskpool 并行构建、墙钟≈单张），FB 求解实测提速 11×+；④ 修复 worker 缓存路径 bug（见 7.6 条目 12，桥式"依然很慢"的主因）。
- **2026-08-22 三轮优化（CFOP 提速主战役）**：新增 **F2L 两槽联合剪枝表 `pairJointT`**（`SolverCore.ets`，24⁴=331776 状态 × 6 槽组合 ≈ 1.9MB，构建 ~200ms）。`idaF2l` 在 n≥2 时改查 C(n,2) 个组合表（低槽号占键高位、targets 需归一化），单槽表仅 n=1 使用。实测（Node，12 随机打乱、24 顺序全枚举）：搜索节点 **2.8 亿 → 968 万（~29×）**、耗时 **9.2s → 0.4s（~23×）**，结果与单槽剪枝逐字节一致（可采纳剪枝不改 DFS 顺序）；真实 6M 共享预算下 24/24 顺序全部完成、零预算触发。瓶颈转移：n=1 首槽搜索（无组合可用）现占约六成节点，属正常量级。
- **2026-08-22 四轮优化（持久化 + 启动提速）**：① 新增 **`solver_core.dat` 磁盘缓存**（SolverCore.ets，~2.4MB 固定小端布局：cross×4/pairPrun/pairJoint/LSE×3/rotations/rotToUser；魔数+版本+长度+目标格四重校验，损坏即整体回落重建自愈）。`ensureCore`/`buildCoreAsync` 均**先读盘再建**、建完落盘；CFOP worker 任务显式传入 cacheDir（与 Roux 同法），**重启后首次 CFOP 求解从"worker 现建数秒"变为读盘几十 ms**。② **启动预热移出主线程**：旧版启动即在主线程分段建表（含 pairJoint 6 段 BFS）+ 同步读 16MB 联合表，首页 ~3s 才渲染完；现 `Index.initAlgorithmCache` 只设缓存目录，首帧后 1.2s 经 `solver/WarmCaches.ets` 的 `warmSolverCachesOffThread()` 在 taskpool 里预热（读盘/建表/落盘全在 worker，主线程零阻塞）。

### 4.6 协作式异步求解链（防主线程卡死的总方针）

求解是 CPU 密集的 IDDFS，而 ArkUI 主线程任何同步阻塞超过 6s 即被系统看门狗 `THREAD_BLOCK_6S` 杀掉。因此**所有求解入口都走"协作式让出"链路**：

- `ensureReadyAsync()`：首次求解把全部剪枝表 / OLL / PLL / 旋转表的构建拆成多个阶段，阶段之间 `await yieldToUi()` 让出主线程；同时 Index 启动期就用它**预温表格**，避免首次点"求解"时才在主线程同步建表。
- `idaF2l` 每次访问 `F2L_YIELD_EVERY`（2048）节点就 `await yieldToUi()` 让出；`solveF2lTargets` 每个深度层之间也让出。
- `F2L_NODE_BUDGET`（300 万）**节点预算**：单槽搜索超预算即置 `f2lBudgetExceeded` 并优雅返回 `null`，病态打乱被丢弃该顺序而不是在主线程无限分配临时数组引发 GC 风暴。
- 所有异步求解在 `MethodSolverView` 内用 `try/catch` 捕获，失败回落到错误文案，不抛未处理 Promise。

**改动求解逻辑时必须保持这条链路**：新增任何 `for/while` 重量循环都要考虑让出与预算，否则会在慢设备上复现闪退。

---

## 5. 功能模块索引（按任务查表）

### 5.1 计时器核心

| 功能 | 位置 |
|---|---|
| 计时状态机（READY/RUNNING/INSPECTING/STOP） | `model/DCTTimer.ets` |
| 触摸交互（按下/抬手、启动延时、分段） | Index.ets `onTimerTouchDown`(L1784) / `onTimerTouchUp`(L1819) / `startRunning`(L1854) |
| WCA 观察（15s，8s/12s 振动提醒） | DCTTimer 的 inspection 回调 + Index `vibrateOnStart/Stop`(L1267) |
| 计时精度（厘秒/毫秒） | `AppConfig.timerAccuracy`，显示在 `formatDisplayTime` 相关逻辑 |
| 手动输入成绩 | `showManualInput`(L1937) / `onManualInputConfirm`(L1949) + `ManualInputDialog` |
| LCD 数码管字体 | `view/LcdText.ets`；调用处判断 `LcdText.canRender(text)` 降级普通 Text |

### 5.2 打乱系统

| 功能 | 位置 |
|---|---|
| 打乱生成入口 | Index `generateScramble()`(L1601) → `scrambler/Scrambler.ets` |
| 项目选择菜单（23 组分类） | `util/ScrambleItems.ets`（数据）+ Index 魔方下拉面板（L1627~L1662 方法区，UI 在 TimerTab 内） |
| 打乱图案绘制 | `view/ScrambleImageView.ets` + `ScrambleCanvasAdapter.ets` |
| random-state 类打乱 | `cs/min2phase`（3x3）、`cs/threephase`（4x4）、`cs/sq12phase`（SQ1） |
| 打乱字号设置 | `AppConfig.scrambleFontSize` |

### 5.3 成绩与统计

| 功能 | 位置 |
|---|---|
| 成绩保存（含惩罚判定） | Index `saveResult`(L1971) / `discardPendingResult`(L2002) / `showResultConfirmDialog`(L2011) |
| 成绩操作（+2/DNF/撤销/删除/备注/详情） | Index `showResultAction`(L2037) 起的一组方法（L2091~L2193） |
| 清空成绩 | `clearAllResults`(L2194) |
| 滚动统计（ao5/ao12/mo/…） | `util/Stats.ets`（忠实移植）+ Index `updateStats`(L1566) |
| 成绩颜色计算（最好/最差/平均高亮） | Index `calcAvg`/`getResultNumColor`/`getResultTimeColor`/`getAvgColor`（L2429~L2482） |
| 趋势折线图 | `view/StatsChartView.ets` |
| CSV 导出/导入 | `util/ExportUtil.ets` + Index `showExportDialog`(L2124)（导出走 pasteboard 复制） |
| 训练分组（15 组） | Index `initDefaultSessions`(L1496)/`switchSession`(L1506)/`createNewSession`(L1529)/`showSessionDialog`(L1550) + `model/Session.ets` |

### 5.4 界面与主题

| 功能 | 位置 |
|---|---|
| 设置页 8 分组/锚点滚动 | Index `initSettings()`(L2325，**设置项 id 表见下**)/`scrollToSettingSection`(L3203) |
| 设置页顶部导航高亮自动居中 | Index `onSettingSectionChange`(L3180)，依赖 `tabCenterXs`/`navWidth`/`navContentWidth`(L1033~1042) 的 onAreaChange 测量，详见 7.3 条目 7 |
| 主题三态切换 | Index `applyEffectiveDark`(L1202)/`themeModeDesc`(L1216)/`onSystemDarkChange`(L1232) |
| 颜色函数 | Index 顶部 `themeText/themeBg/themeDivider/itemBg/contentBg/themeTopBar/themeSubText` 等 |
| 背景图选择/裁剪/清除 | Index `pickBackgroundImage`(L1738)/`onBgCropConfirm`(L1757)/`clearBackgroundImage`(L1768) + `view/BgCropDialog.ets` |
| 背景透明度滑条 | Index `onBgOpacityChange`(L1776)，设置项 id=44 type=2 |

**设置项 id 表（initSettings，改设置必看）**：

| 分组 | id | 含义 | type |
|---|---|---|---|
| 计时器 | 1/2/3/4/6/7/8 | WCA观察/观察振动/计时精度/计时方式/启动延时/分段计时/显示统计 | 1=开关,0=点击弹窗,2=滑条 |
| 打乱 | 21/22 | 打乱字号/显示打乱图 | |
| 统计 | 31/32 | 滚动平均1/2 | |
| 界面 | 41/42/43/44/45 | 计时器字体/计时器大小/背景图片/背景透明度/深色模式 | |
| 手势 | 51~54 | 左/右/上/下滑动作绑定 | |
| 硬件 | 61/62/63 | 屏幕常亮/触感反馈/智能魔方 | |
| 求解器 | 71 | 默认十字底面 | |
| 关于 | 50 | 隐私政策 | |

设置交互入口：`onSettingToggle`(L2310，开关类) / `onSettingTextClick`(L2326，点击类，内部按 id 分发到各弹窗)。

### 5.5 手势

`handleSwipeGesture`(L1868) → `performSwipeAction`(L1889)。四方向动作绑定存于 `AppConfig.swipeType[4]`（1=删除末次成绩 2=+2 3=弹出操作面板 5=…，描述见 `getSwipeDesc` L2300）。

### 5.6 BLE 智能魔方

| 功能 | 位置 |
|---|---|
| 扫描/连接/断开 UI | `view/BleScanDialog.ets` + Index `openBleScanner`(L1683)/`disconnectBle`(L1702) |
| 协议解析（Giiker/GAN/Moyu/QiYi） | `util/SmartCubeProtocol.ets` |
| 转动事件 → 计时 | Index `initBleCallbacks`(L1665)/`onCubeMove`(L1671) |
| 训练组定义 | `model/SmartCubeTraining.ets` |
| **状态** | **2026-08-29 已从 UI/权限中下线**（保留代码与组件文件，后续可再接入）。已从 `module.json5` 移除蓝牙/位置权限，隐私政策已同步删除相关说明 |

### 5.7 求解器

- 入口：Index `openMethodSolver`(L ~L2670) 打开 `view/MethodSolverView.ets`（十字/CFOP/桥式三页签）；十字也可单开 `CrossSolverView.ets`。
- 十字求解：`view/CrossSolverView.ets` + `util/CrossSolver.ets` + `solver/Cross.ets`。
- **CFOP 多 F2L 顺序**：`solver/CfopSolver.ets` 用常量表 `F2L_ORDERS`（24 种插入顺序的字典序排列）枚举所有插入顺序，选出步数最短者作默认；结果经 `SolveOutput.f2lAlternatives` 返回 `MethodSolverView`，UI 提供可滚动的"F2L 插入顺序"列表，点选后 `runCfop(forcedOrder)` 强制以该顺序重解。重解受 `F2L_NODE_BUDGET` 约束（见 4.6）。
- **桥式左/右桥联合剪枝表持久化**：`RouxSolver.ets` + `SolverCore.ets` 的 `JointTableState`（左桥 `roux_fb_joint.dat` + 右桥 `roux_sb_joint.dat`，各约 7.6MB）落盘到 `Tools.dataPath`，重启后加载复用，不再每次重新构建。首次构建走 taskpool 并行（两表同时建，墙钟≈单张 ≈6s）。`warmJointCaches()` 为统一预热入口（`Index.initAlgorithmCache` 启动即调，worker 进任务后也调）。
- 解法校验：CFOP/Roux 均用 `SolverCore` 的 `verifyMoves/isSolvedCube` 验证整条解法并化简。
- `solver/` 目录其余文件（Petrus/EOline/Skewb/222…）为移植的算法库，多数已接入打乱生成，少量仅算法就绪。

### 5.8 隐私政策（合规硬性要求）

| 功能 | 位置 |
|---|---|
| 政策文字常量 | Index.ets 顶部 `PRIVACY_SECTIONS`(L43) + `PRIVACY_URL`(L35) |
| 首次启动强制同意 | `checkPrivacyAgreement`(L1157)/`onPrivacyAgree`(L1164)/`exitApp`(L1170)，`AppConfig.privacyAgreed` 持久化 |
| 设置页入口 | 设置项 id=50 → 文字版对话框（含"查看网页版"超链接）→ `PrivacyWebDialog`(L56，WebView) |
| 原文备份 | `docs/privacy_policy.md` |

**硬性规则**：首次启动必须读并同意才能进入；「不同意并退出」按钮直接退出应用；设置里必须能再次查看。

### 5.9 智能魔方 3D 跟随视图

- `view/SmartCube3DView.ets`：54 面块坐标的 3D 魔方，接收智能魔方转动事件后实时重绘。
- 数据链路：`BleManager` 订阅 GATT 特征收到转动 → `parseGiikerMove` 解析为 `face/axis` → `BleScanDialog.onCubeMove` 上抛 → Index 维护 `smartCubeConnected` / `smartCubeFacelets` 两个 `@State` → 触发 `SmartCube3DView.rot3(...)` 更新 54 面块。
- `util/SmartCubeOrientation.ets` 的 `rotateMoveFacelets` 负责单层转动下 54 面块坐标的旋转换算。
- **实现注意**：`SmartCube3DView` 内命名 `rotate` 会与基类 `CustomComponent` 方法冲突，故该方法叫 `rot3`；`Length` 解析封装为 `lenToNum`。
- **已知限制**：GAN 魔方采用 AES 加密的 GATT 通知，当前实现无法解析；目前仅支持未加密的 Giiker 数据，转动方向可能需真机标定。

---

## 6. git 历史与功能演进

```
b8327ba  背景配置同步读取，消除冷启动闪烁     （未提交的新改动还在工作区，见下）
b3c92d3  隐私政策改为文字版 + 网页超链接
a205737  minAPI 降到 12 + 隐私政策首次同意流程
390c5d4  修复：成绩页底部截断 / 深色备注输入 / 背景持久化
af95044  清理无用资源与死代码（约 -54MB）
d42783f  基线：完整可用版本
```

**当前工作区有未提交改动**（延续 2026-08 的多轮功能，需验证后尽快分批 commit）：
- 背景与主题：`EntryAbility.ets` / `AppConfig.ets` / `Index.ets` 修改 + 新文件 `view/BgCropDialog.ets`（对话模式"跟随系统"三态；背景图唯一文件名即时刷新；背景裁剪/缩放）。
- 求解引擎（v2）：新增 `view/MethodSolverView.ets` / `view/FaceChipsRow.ets` / `view/SmartCube3DView.ets`，新增 `solver/SolverCore.ets` / `solver/CfopSolver.ets` / `solver/RouxSolver.ets`，`cs/min2phase/CubieCube.ets` 等被复用。
- 求解引擎二轮性能优化（2026-08-22 晚）：`SolverCore.ets`（热表全部扁平化为 TypedArray；`JointTableState` 统一管理左/右桥联合剪枝表；修复 `getSbJointCacheDir` 返回文件路径导致 worker 缓存永不命中的 bug）、`CfopSolve.ets`（F2L 枚举前缀树缓存）、`RouxSolve.ets`/`RouxSolver.ets`/`Index.ets`（两表预热接入）、`MethodSolverView.ets`（文案）。已过 build.ps1 + Node 离线全流程回归（12 随机打乱 CFOP/Roux 全部复原，缓存/朴素枚举结果一致，扁平化 1.62×、FB 联合表 11×+）。
- 本会话早前修复：`SolverCore.ets`（`ensureReadyAsync` 异步分段建表 + F2L 节点预算）、`CfopSolver.ets` / `RouxSolver.ets`（改走异步建表）、`Index.ets`（启动预温表格）、`MethodSolverView.ets`（去掉嵌套 Scroll）、`ScrambleImageView.ets`（大屏高度约束缩放）。

---

## 7. ★ 注意事项与踩坑记录（最重要的一章）

### 7.1 ArkTS 严格子集规则（每次写代码都要遵守）

1. **禁用 `any`/`unknown`**，所有变量显式类型。
2. **对象字面量不能直接当类型用**：需要 `{title: string}` 这类结构时，必须先 `interface` 声明，或用 `Record<string, Object>`。
3. **组件成员命名避开基类属性**：`@Component` struct 的成员不能叫 `scale`、`width`、`height` 等（会报 "not assignable to the same property in base type 'CustomComponent'"，本项目已在 BgCropDialog 上踩过 `scale` → 改名 `zoomScale`）。
4. 静态成员一律 `ClassName.member` 访问。
5. 子类方法名避免与基类冲突。

### 7.2 SDK/API 相关坑

| 坑 | 正确做法 |
|---|---|
| `AppStorage` 不能从 `@kit.ArkUI` import（报 no exported member） | V1 AppStorage 是**全局内置对象**，直接用，不 import |
| `getContext(this)` 返回基类 Context，没有 `.config` | 强转 `(getContext(this) as common.UIAbilityContext).config`（import { common } from '@kit.AbilityKit'） |
| WebView 控制器 import 报错 | 用 `import webview from '@ohos.web.webview'`，然后 `webview.WebviewController` |
| Text 下划线 `.decoration()` 参数类型不符 | 必须传对象：`.decoration({ type: TextDecorationType.Underline, color: xxx })` |
| Canvas 绘制坐标系 | LcdText 的结论：onAreaChange 拿到的 vp 值直接用于 Canvas 绘制即可（内部缓冲与 vp 一致），不要自行转 px |
| **`as XxxOptions` 断言掩盖必填参数缺失（2026-08-29，血泪）** | ArkUI 大量 Options 接口**必填项很多**（如 `ScrollOptions` 的 `xOffset` **和** `yOffset` 都是必填）。用 `as ScrollOptions` 断言能绕过编译检查，但缺失字段在运行时是 `undefined`，API 往往**静默失效**（不报错、不生效），极难排查。**规则：给官方 Options 传对象字面量时禁止加 `as` 断言；如果去掉 `as` 就报错，说明你漏了必填项，去补全它而不是加回断言。** 编译期报错是好事，运行时静默不生效才是灾难 |

### 7.3 UI / 交互坑（本项目实测教训）

1. **`Image` 组件按 URI 缓存**：同一个 file:// 路径写入了新图片不会刷新显示。背景图必须每次保存用**唯一文件名**（`bg_image_${Date.now()}.jpg`），靠 URI 变化驱动刷新。
2. **相册 URI 是临时授权**：photoAccessHelper 选图返回的 URI 退出应用即失效，**必须复制进应用沙箱**（`getContext().filesDir`）再引用。
3. **系统深色模式下输入组件文字不可见**：TextInput 必须显式设置 `.fontColor/.placeholderColor/.caretColor` 跟随应用主题（AppConfig.darkMode），不能依赖默认。
4. **固定高度 + 系统大字体 = 文字截断**：底部栏、列表项等文字容器用 `minHeight` 而非固定 `height`（成绩页底部均值栏已因此改过）。
5. **冷启动顿挫**：背景 URI/透明度若在首帧后异步读取，会先闪默认界面再切背景。`loadFromPreferences` 中相关项用同步 `getSync` 且在 `aboutToAppear` 最前段执行。
6. **下拉菜单过长**：任何可能超出屏幕的列表（如打乱项目菜单）必须包 `Scroll` 并给容器限高，左右两列分别可滚。
7. **设置页顶部导航高亮居中（2026-08-29）**：9 个分区标签在横向 `Scroll` 里（总宽约 620vp，远超手机视口，必然溢出可滚），高亮项要"尽量居中、不能居中就贴边保持可见"。实现要点与四个坑：
   - **`scrollTo` 的 `yOffset` 是必填项（本次"完全没效果"的根因）**：`ScrollOptions` 的 `xOffset` / `yOffset` **都是必填**。原代码写 `{ xOffset: target, animation: {...} } as ScrollOptions`，`as` 断言把缺参的编译错误压掉了，运行时 `yOffset` 为 `undefined`，整个 `scrollTo` **静默失效**（不报错、不动）。正确写法 `scrollTo({ xOffset: target, yOffset: 0, animation: { duration: 250 } })`，补全后**不再需要任何 `as` 断言**（见 7.2 新增行）。
   - **只测宽度，不读 `position`**：标签中心改由宽度累加推算（`tabWidths` 累加 + `navPad`），不再用 `onAreaChange` 的 `position.x` —— `Position.x` 是可选属性，某些情况下为 undefined，`Number(undefined)` = NaN 会让夹取算出 NaN 并再次静默失效。内容总宽同理：优先用 Row 的测量值，测不到时按标签宽度累加兜底（`navTotalWidth`）。
   - **几何**：`target = clamp(cx - navW/2, 0, contentW - navW)`。夹取后 cx 必落在 `[0, navW]` 内 —— 这就是"不能居中仍保持可见"的数学保证，改动时别把上下界丢了。
   - **`@Watch` 对同值不触发**：点击"当前已高亮"的标签时 `currentSettingSection` 未变，回调不跑、标签被划出视野后点不回来。修法是在 `scrollToSettingSection` 里检测 `sameSection` 并手动补调一次 `onSettingSectionChange()`。
   - **抑制标志的时序**：`suppressScrollHighlight` 必须在手动补调**之后**再置 true（`onSettingSectionChange` 开头会检查它并提前 return），置 true 是为了防止 List 的 `onScrollIndex` 在跳转动画期间把高亮反推改写。

### 7.4 业务/合规硬约束

1. **UI 改版必须 100% 还原设计稿/原版布局**，不自作主张加留白、改层级。
2. **隐私政策流程不可弱化**（首次强制同意、不同意即退出、设置可再次查看——三条都是验收项）。
3. compatibleSdkVersion 保持 `5.0.0(12)`（曾为 24，因 HarmonyOS 6.1.1(24) 仅部分机型可装而下调）。
4. 时间单位**全链路毫秒**（+2 惩罚 = 2000ms），移植自 Android 原版，勿混用秒。
5. 数据库 15 张成绩表对应 15 个训练组，表名 `resulttb`~`result15` 不可改名（兼容已发布版本）。

### 7.5 工程习惯

- 改动后必须 `build.ps1` 验证；失败时看 `C:\Users\52622\AppData\Local\Temp\opencode\build_out.log`。
- Index.ets 超 64KB，读文件必须用 offset/limit 分段或先 grep 行号再读。
- 遵循既有代码风格：中文注释、方法级 `/** */`、回调参数显式类型、`(param): void => {}` 箭头函数签名带返回类型。

### 7.6 求解引擎专项坑（v2 实测，防回归）

1. **CFOP 求解闪退（THREAD_BLOCK_6S）——本会话根因**：首次求解时 `ensureReady()` 在**主线程同步**把全部剪枝表 + OLL/PLL 表建完，慢设备上一个 handler 就超 6s 看门狗；叠加 F2L 24 顺序枚举的海量临时数组分配，触发 GC 风暴。修复 = 4.6 的协作式异步建表 + 启动预温 + F2L 节点预算。**不要**为了省事改回同步建表。
2. **状态驱动 UI 必须用 `@Component` + `@Prop`，不要用带参数的 `@Builder` 传值刷状态**：解法选色/选面若用参数化 `@Builder`，切换状态时不会刷新（曾导致"颜色锁死"）。修法是独立 `@Component FaceChipsRow.ets` 并用 `@Prop` 做状态同步。
3. **mimer 方向 bug 会静默产生"看似已解实则未解"的魔方**：cross 求解镜像之前用错目标排列秩（1656 而非 1670），导致得到物理上未复原的解法。改排列/镜像逻辑务必对照物理真实旋转自测。
4. **同步 BFS / 大数组分配是主线程杀手**：桥式右桥曾因同步 BFS 5.32 亿状态阻塞 14.7s（Node）/30s+（ArkTS）触发 ANR；32MB 队列又致低端机 OOM。改用了**层级扫描式 BFS + 仅 8MB 距离表**，并放 taskpool 工作线程（`buildSbJointAsync`），首建 6.3s 后落盘缓存。新增任何全状态遍历都沿用此模式。
5. **嵌套垂直 Scroll 吞掉外滚手势**：CFOP 结果区曾因"外层 Scroll + 阶段卡片内层 Scroll + F2L 选择器内层 Scroll"三层嵌套，导致底部完整解法划不到（显示不全）。修法：去掉内层 Scroll，铺进**单层外层 Scroll**。新增大列表时避免多层嵌套 Scroll。
6. **F2L 24 顺序枚举与长公式展示**：枚举必须带 `F2L_NODE_BUDGET` 预算并每 2048 节点让出（见 4.6）；顶部打乱公式与多盲等长公式需放可滚动容器（`constraintSize({maxHeight})`）防截断。
7. **打乱图大屏适配与右下角布局（2026-08-23 定稿）**：打乱图绘制统一按 `dw = min(宽, 高/0.85)` 缩放并横向居中（`view/ScrambleImageView.ets`）。主界面右下角图**贴底贴右**：`.width('58%').aspectRatio(1.176).constraintSize({maxHeight:'34%'}).margin({right:2, bottom:0})`——**纯百分比、零测量**（曾两轮尝试 onAreaChange 动态测量（globalPosition.y 法与局部高度链法），设备上均未生效、图停在 152×114，最终放弃测量方案，勿再回头）。配套：底部统计文字与 BLE/求解按钮行收窄为 `width('48%')`（左半区），与右下 58% 的图结构上互不遮挡；`aspectRatio(1.176)` 与内部绘制比 0.85 互为倒数，正常情况下无留白，maxHeight 触发时横向居中留白不裁剪。

8. **`@Component` 成员命名冲突**：`SmartCube3DView` 的方法 `rotate` 与基类 `CustomComponent` 冲突，改名 `rot3`；颜色 `scale` 曾与基类冲突改名 `zoomScale`。凡自定义组件成员，先避开基类已有属性名。
9. **GAN 魔方 AES 加密通知无法解析**：目前智能魔方仅支持未加密的 Giiker 数据（GATT 订阅见 `BleManager.ets`）。接入新品牌协议前先确认加密方式。
10. **F2L 24 顺序共享预算不能每迭代重置（防回归，2026-08-22）**：`CfopSolve.enumerateF2l` 原在循环内每轮 `setF2lSharedBudget(pi > 0)`，把共享预算池每轮**重设为 1.5M**，实际变成了"每顺序各 1.5M × 23 ≈ 34M+ 节点"，病态打乱下可跑数分钟并触发 ANR/OOM（重启后仍闪退的残留根因）。正确姿势：仅在 `pi===1` 播种一次共享池，`pi>=2` 继续消耗同一池子；`pi===0`（默认顺序）走独立 per-call 预算保证必出解。`pi===1` 且仅在 `pi===1` 处播种这条逻辑是本次修复核心。
11. **工作线程读不到主线程模块状态（右桥剪枝表被反复重建，2026-08-22）**：`sbJointCachePath` 是模块级变量，taskpool worker 各自持有独立模块实例，桥式求解任务若不在 worker 内显式 `setSbJointCacheDir` + 预热，就永远读不到磁盘缓存，每次 Roux 求解都在 worker 里现场重建 8MB `roux_sb_joint.dat`（桥式慢的根因）。修法：`RouxSolver.rouxSolveTask` 接收主线程传来的 `cacheDir`，进入 worker 先 `setSbJointCacheDir(cacheDir)` 再 `warmJointCaches()`。左右桥两张联合表统一由 `JointTableState`（SolverCore）管理：内存→磁盘→在途构建三级去重，`ensureRouxJointsAsync()` 并行确保两表就绪（首建墙钟≈单张）。新增任何"主线程建表/读缓存"能力若要在 worker 复用，都必须显式把路径/数据传进去。
12. **`getSbJointCacheDir` 必须返回目录而不是完整文件路径（2026-08-22 修复）**：旧版该函数返回 `dir + '/roux_sb_joint.dat'` 完整路径，而 worker 侧 `setSbJointCacheDir` 会把它当目录再拼一次文件名，得到 `.../roux_sb_joint.dat/roux_sb_joint.dat` 这种必然不存在的路径 → worker 磁盘缓存永远不命中 → **每次桥式求解都在 worker 现场重建 8MB 表（约 6s），是"桥式依然很慢"的主因**。现 `jointCacheDir` 只存目录，两表文件名由 `JointTableState.filePath()` 拼接。改缓存路径逻辑时记住：跨线程传递的永远是目录。
13. **热表扁平化 TypedArray（2026-08-22）**：`cornerMoveT/edgeMoveT/crossEpmT/crossEomT/crossEpdT/crossEodT/pairPrunT/lsePermMoveT/lseOriMoveT` 全部是一维 TypedArray（下标 `state*6+face` 或 `slot*576+c*24+e`）。`Utils.createPrun3` 只吃 `number[]/number[][]`，所以 cross 表先建普通数组再拷入 TypedArray。新增查表代码请直接用扁平下标，勿再引入 `number[][]` 行索引。
14. **F2L 前缀树缓存的预算语义（2026-08-22）**：`CfopSolve.enumerateF2l` 按插入前缀（如 "0,2"）缓存逐槽搜索结果（`F2lPrefixNode.moves/after`），同前缀顺序复用、不消耗共享预算。副作用（良性）：同一 `F2L_SOLVE_BUDGET` 下缓存版能完成**更多**顺序（旧朴素版会因预算耗尽丢顺序）。`after` 魔方状态是跨顺序共享的只读对象，勿原地修改。
15. **pairJointT 两槽联合剪枝（2026-08-22，CFOP 提速核心）**：`idaF2l` n≥2 时用 6 张 331k 组合表取代单槽表 max（联合下界严格更强）。两个易错点：a) **targets 无序**（顺序是任意排列），查表必须按槽号归一化——低槽号占据键高位 `(cs[低]*24+es[低])*576 + cs[高]*24+es[高]`，`PAIR_JOINT_COMBO[低*4+高]`，否则组合索引算出 -1、剪枝静默失效（曾实测变慢 0.6×）；b) 剪枝只砍 `下界 > d` 的子树，**不改变 DFS 顺序与首解**——等价性验证靠"无限预算下与单槽剪枝候选逐字节一致"（Node 回归已固化）。表随 `ensureReadyAsync` 分段构建（每组合一让出），worker 走 `ensureReadyAsync` 自动获得。
16. **@Concurrent 函数只能引用 import/局部变量，不能调用同模块顶层函数（2026-08-22）**：es2abc 报 "Concurrent function should only use import variable or local variable"。这就是 CfopSolve/RouxSolve/WarmCaches 独立成模块的原因——凡要进 taskpool 的任务函数，其调用的逻辑必须放在**别的模块**里 import 进来；SolverCore 不回引这些任务模块（避免循环依赖）。
17. **solver_core.dat 布局与兼容（2026-08-22）**：固定小端布局、总长 `CC_TOTAL=2444940` 常量即文档（`CC_OFF_*` 段偏移见 SolverCore）。**改任何被缓存的表的结构/大小/语义时必须 bump `CORE_CACHE_VERSION`**，否则旧文件会被静默加载（目标格校验只防损坏不防语义变更）。加载用元素级解码（免对齐依赖），先解局部、校验过再原子提交。`PAIR_JOINT_COMBO` 在模块加载即填充（从缓存恢复不经过 buildPairJoint*，若只在 builder 里填会得到全 -1 索引）。
18. **启动预热必须离线程 + 延迟（2026-08-22）**：主线程启动期做任何建表/大文件同步读都会拖慢首帧（曾致首页 ~3s）。现在 `Index.initAlgorithmCache` 只 `setSbJointCacheDir` + `setTimeout(1200ms)` 后调 `WarmCaches.warmSolverCachesOffThread()`（taskpool 内预热）。新增启动期初始化逻辑时遵循同样模式，勿改回主线程同步预热。
19. **四阶打乱必须用随机步生成，勿再接回 threephase random-state（2026-08-23 定论）**：`case -31 四速 / -17 四盲 / 69` 曾走 threephase 三阶段求解——Node 实测表齐时 1.24s 且结果正确（移植无 bug），但 **ArkTS（x86_64 模拟器）要 30-120s**：主线程同步跑直接 THREAD_BLOCK_6S 闪退；挪进 taskpool worker 则表现为"永远生成中"（worker 无看门狗）；带超时保底则永远降级。最终按用户要求改为**随机步生成**（`this.scramble444()`，megascramble2 40 步，与五阶/多盲等大项目同思路，瞬时完成）。连带清理：`scrambler/Rand444.ets` 已删除；启动不再拷贝 center.dat/edge.dat（12MB，threephase 专用，现为死资源但保留在 rawfile 备用）；`Scrambler.generateScramble` 回到同步签名。threephase 移植代码仍在 `cs/threephase/` 可用——若未来 ArkTS 性能足够或做了 TypedArray 级优化，可按"离线程 + 超时保底"模式重新接入。**新增 random-state 类打乱前先想清楚 ArkTS 性能预算**。
20. **打乱图配色（2026-08-23 新功能）**：设置页新增"配色"分组（id 81-84：NxNxN/金字塔/斜转/五魔方），点击打开 `view/ColorSchemeEditor.ets`（底部弹层）：顶部分面色块（点击选面）→ 中部 HSV 选色板（Canvas 三层渐变绘 SV 板 + 彩虹色相条，onTouch 拖动）→ hex 码 + 8 快捷色 → 恢复默认/取消/确定。**配色真值 = `Scrambler.schemeN/P/W/M` 静态数组**（schemeN 面序 U R F D L B；schemeM 为五魔方 12 色，从 drawMega 硬编码提取，megaColorScheme 分支已移除；schemeW 为斜转+枫叶共用）；确定时 Index.onSchemeConfirm 写回数组 + `schemeVersion++` 驱动 ScrambleImageView 重绘（scheme 是静态表，组件 @Prop 不变不会自刷，故组件加了 `@Prop @Watch schemeVersion`，主界面与成绩详情两处都要传）+ Preferences 持久化（key `schemeN/P/W/M`，逗号分隔 ARGB，空/长度不符则保留默认）。**ArkTS 陷阱**：struct 字段禁止下标访问（`this.colors[i]` 不行，需局部变量中转的 colorsGet/Set helper）；连 `string[i]` 也禁（hex 转换用 toString(16)）；@Link 传值必须 `$var`。

---

## 8. 已知未完成 / 待办

1. **真机验证求解引擎（最高优先级）**：CFOP/Roux 多解、F2L 顺序切换、智能魔方 3D 跟随、大屏打乱图缩放、四阶随机步打乱（瞬时，同五阶思路），需真机复测。
2. **BLE 智能魔方真机联调**：代码框架完整，Giiker/GAN 协议解析未经硬件实测（GAN 走 AES 加密当前不支持，见 5.9），需抓包修正。
3. **右桥剪枝表进一步优化（可选，已部分完成）**：左/右桥两表已并行构建+持久化；可选进一步压缩 2×7.6MB 缓存文件（如 4bit 距离打包，需先确认表直径 ≤15 并加回退）。
4. **min2phase 语义核对（遗留）**：v1 遗留项，部分移动方向的 min2phase 语义与物理旋转需在真机最终确认。
5. **solver/ 目录部分求解器**（Petrus、Roux 之外的边缘魔方求解）算法已移植，但部分未接入 UI 入口。
6. **AppGlobals.ets** 存在大量移植遗留的未用静态字段，可继续瘦身（上次清理已删 54MB 资源与死代码，此文件是残留）。
7. **未提交改动分批 commit**：见第 6 章，验证后按背景/主题、求解引擎、本会话修复三批提交。

---

## 9. 快速定位速查

| 要改什么 | 去 which 文件找 |
|---|---|
| 任何设置项行为 | Index.ets `initSettings`(id 表) → `onSettingToggle`/`onSettingTextClick` → `AppConfig` |
| 计时逻辑/精度 | `model/DCTTimer.ets` |
| 新增打乱类型 | `util/ScrambleItems.ets`（菜单）+ `scrambler/Scrambler.ets`（算法） |
| 统计口径 | `util/Stats.ets` |
| 某个对话框样式 | Index.ets 底部 @CustomDialog 区 / `view/` 目录 |
| 数据库字段 | `database/DBHelper.ets` + `model/Result.ets` |
| 颜色/主题 | Index.ets 顶部 theme* 函数 + `AppConfig.colors` |
| 隐私合规 | Index.ets 顶部常量区 + L1155~L1188 方法 |
| CFOP/桥式求解算法 | `solver/CfopSolver.ets` / `solver/RouxSolver.ets` / `solver/SolverCore.ets` |
| 求解 UI / F2L 顺序选择 | `view/MethodSolverView.ets` + `view/FaceChipsRow.ets` |
| 智能魔方 3D 视图 | `view/SmartCube3DView.ets` + `util/SmartCubeOrientation.ets` |
| 打乱图缩放 | `view/ScrambleImageView.ets`（`dw = min(宽, 高/0.85)`） |
| 主线程卡死/闪退排查 | 见 4.6 协作式异步链路 + 7.6；定位到 `yieldToUi` / 节点预算 |

---

*报告生成：2026-08-22，v2 更新，基于"计时 / 打乱 / 成绩 + CFOP/桥式求解引擎 + 智能魔方 3D"的当前项目状态（含工作区未提交改动与本会话修复）。*
