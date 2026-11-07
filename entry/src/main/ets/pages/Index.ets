import { DCTTimer, TimerState } from '../model/DCTTimer';
import { AppConfig } from '../model/AppConfig';
import { Scrambler as DctScrambler } from '../scrambler/Scrambler';
import { AppGlobals } from '../model/AppGlobals';
import { Tools } from '../cs/min2phase/Tools';
import { FileIO } from '../util/FileIO';
import { setSbJointCacheDir } from '../solver/SolverCore';
import { warmSolverCachesOffThread } from '../solver/WarmCaches';
import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { SYSTEM_DARK_KEY, BOTTOM_INSET_KEY, TOP_INSET_KEY, MIN_BOTTOM_INSET_VP } from '../entryability/EntryAbility';
import { resourceManager } from '@kit.LocalizationKit';
import { Session } from '../model/Session';
import { Result, ResultEntry } from '../model/Result';
import { DBHelper } from '../database/DBHelper';
import { StringUtils } from '../util/StringUtils';
import { initScrambleItems } from '../util/ScrambleItems';
import { ScrambleImageView } from '../view/ScrambleImageView';
import { ColorSchemeEditor } from '../view/ColorSchemeEditor';
// SmartCube3DView 已从 UI 移除（智能魔方功能下线，组件文件保留后续再接）
import { LcdText } from '../view/LcdText';
import { StatsChartView } from '../view/StatsChartView';
import { ExportUtil } from '../util/ExportUtil';
import { MethodSolverView } from '../view/MethodSolverView';
import { hasSolver } from '../util/SolverRouting';
import { AppIcon } from '../view/AppIcons';
import { pasteboard } from '@kit.BasicServicesKit';
import { BleScanDialog } from '../view/BleScanDialog';
import { BgCropDialog } from '../view/BgCropDialog';
import { BackgroundManager } from '../util/BackgroundManager';
import { bleManager, BleCallbacks } from '../util/BleManager';
import { CubeConnectionState, CubeMove, CubeDeviceInfo } from '../util/SmartCubeProtocol';
import { SmartCubeOrientation } from '../util/SmartCubeOrientation';
import dataPreferences from '@ohos.data.preferences';
import promptAction from '@ohos.promptAction';
import { window } from '@kit.ArkUI';
import { vibrator } from '@kit.SensorServiceKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { uiMaterial } from '@kit.ArkUI';
import {
  GradientStops, GRADIENT_SCHEMES, findScheme, schemeColors, materialSupported, materialEnabled,
  barMaterial, pageSurface, blockSurface, dialogSurface, dialogBlurRadius
} from '../util/AmbientTheme';

interface PrivacySection {
  title: string;
  body: string;
}

// 隐私政策文字（与网页版一致）
const PRIVACY_SECTIONS: PrivacySection[] = [
  { title: '更新日期', body: '2026年8月29日' },
  { title: '', body: '本应用是一款魔方计时与训练工具。我们深知个人信息对您的重要性，并会尽全力保护您的个人信息安全可靠。' },
  { title: '一、我们收集的信息', body: '本应用不收集、不存储、不上传任何您的个人信息。您在使用本应用过程中产生的所有数据（包括但不限于计时成绩、训练分组、设置偏好等）均仅保存在您的设备本地，不会被传输至任何服务器。' },
  { title: '二、我们如何使用信息', body: '由于本应用不收集任何个人信息，因此不存在对您个人信息的使用、共享、转让或公开披露。' },
  { title: '三、权限说明', body: '本应用不申请任何涉及个人信息的敏感权限（如位置、通讯录、相机、麦克风、存储等）。所有功能均在本地完成，无需联网。' },
  { title: '四、数据安全', body: '您的所有数据仅存储在本地设备中，卸载本应用后数据将随之删除，请定期备份重要数据。' },
  { title: '五、未成年人保护', body: '本应用不收集任何个人信息，因此不存在未成年人个人信息处理的情形。' },
  { title: '六、联系我们', body: '如您对本隐私政策有任何疑问、意见或建议，可发送邮件至：2297005473@qq.com。' },
  { title: '七、政策更新', body: '本隐私政策可能会适时更新。更新后将在应用内公布，更新后的政策自公布之日起生效。' }
];

// ===== 颜色常量（与原版一致）=====
const COLOR_PRIMARY: string = '#3F51B5';
const COLOR_PRIMARY_DARK: string = '#2c2c2c';
const COLOR_ACCENT: string = '#448AFF';
const COLOR_BEST: string = '#ff00ff';
const COLOR_WORST: string = '#ee3333';
const COLOR_AVG_BEST: string = '#009900';
const COLOR_AVG_BEST_DARK: string = '#33cc33';
const COLOR_READY: string = '#00cc00';
const COLOR_INSPECTING: string = '#ff0000';
const COLOR_FREEZE: string = '#ff0000'; // 红色：按下后尚未就绪
const COLOR_ACCENT_BG: string = '#14448AFF';

// ===== 主题色（dark 参数从响应式状态或 AppConfig 传入）=====
function themeBg(dark: boolean): string { return dark ? '#1e1e1e' : '#ffffff'; }
function themeText(dark: boolean): string { return dark ? '#e8e8e8' : '#000000'; }
function themeSubText(dark: boolean): string { return dark ? '#9a9a9a' : '#666666'; }
function themeDivider(dark: boolean): string { return dark ? '#3a3a3a' : '#dddddd'; }
function themeRowAlt(dark: boolean): string { return dark ? '#262626' : '#f5f5f5'; }

function formatDateFull(ts: number): string {
  const d: Date = new Date(ts);
  if (isNaN(d.getTime())) {
    return '';
  }
  return d.getFullYear() + '-' + (d.getMonth() + 1).toString().padStart(2, '0') + '-' +
    d.getDate().toString().padStart(2, '0') + ' ' +
    d.getHours().toString().padStart(2, '0') + ':' +
    d.getMinutes().toString().padStart(2, '0') + ':' +
    d.getSeconds().toString().padStart(2, '0');
}

/**
 * 内容区背景。
 * 优先级：沉浸光感 > 自定义背景图 > 纯色。
 * 光感开启时直接全透明，让 build() 里铺的内置渐变透上来；此时即使设了背景图
 * 也不参与（两张底图叠一起只会互相污染，而且光感的观感本身就是渐变打底）。
 * 关闭光感时保持原有逻辑：有背景图按 bgOpacity 联动半透明，否则纯色。
 * ambient 缺省 false，老调用点行为不变。
 */
function contentBg(dark: boolean, hasBgImage: boolean, ambient: boolean = false): string {
  if (ambient) {
    return pageSurface(dark, true);
  }
  if (hasBgImage) {
    const a: number = Math.max(0.12, (100 - AppConfig.bgOpacity) / 100);
    return dark ? 'rgba(30,30,30,' + a + ')' : 'rgba(255,255,255,' + a + ')';
  }
  return pageSurface(dark, false);
}

/** 按钮/行背景：有自定义背景时按 bgOpacity 联动半透明 */
function itemBg(dark: boolean, hasBgImage: boolean, ambient: boolean = false): string {
  if (hasBgImage) {
    const a: number = Math.max(0.12, (100 - AppConfig.bgOpacity) / 100);
    return dark ? 'rgba(38,38,38,' + a + ')' : 'rgba(245,245,245,' + a + ')';
  }
  // 光感开启时用次级块表面，比内容底色再透一档，形成层次；关闭时保持原纯色
  if (ambient) {
    return blockSurface(dark, true);
  }
  return themeBg(dark);
}

// ===== 魔方类型（带分类）=====
interface PuzzleItem {
  name: string;
  code: number;
}

interface PuzzleCategory {
  name: string;
  items: PuzzleItem[];
}

const PUZZLE_CATEGORIES: PuzzleCategory[] = [
  {
    name: 'WCA',
    items: [
      { name: '三阶速拧', code: 33 },
      { name: '二阶速拧', code: 22 },
      { name: '四阶速拧', code: 44 },
      { name: '五阶速拧', code: 55 },
      { name: '六阶速拧', code: 66 },
      { name: '七阶速拧', code: 77 },
      { name: '三阶单手', code: 31 },
      { name: '三阶盲拧', code: 32 },
      { name: '四阶盲拧', code: 42 },
      { name: '五阶盲拧', code: 52 },
      { name: '三阶多盲', code: 34 },
      { name: '三阶最少步', code: 35 },
      { name: 'Pyraminx', code: 70 },
      { name: 'Megaminx', code: 50 },
      { name: 'Square-1', code: 40 },
      { name: 'Clock', code: 80 },
      { name: 'Skewb', code: 16 },
      { name: 'FTO', code: 82 },
    ]
  },
  {
    name: '2x2',
    items: [
      { name: 'random state', code: 900 },
      { name: '3-gen', code: 901 },
      { name: '6-gen', code: 902 },
      { name: 'CLL training', code: 903 },
      { name: 'EG1 training', code: 904 },
      { name: 'EG2 training', code: 905 },
      { name: 'PBL training', code: 906 },
      { name: 'EG training', code: 907 },
      { name: 'TCLL+ training', code: 908 },
      { name: 'TCLL- training', code: 909 },
      { name: 'No bar', code: 910 },
    ]
  },
  {
    name: '3x3',
    items: [
      { name: 'old style', code: 932 },
      { name: 'random state', code: 933 },
      // 934/935 底层就是 F2L / OLL 的打乱（见 Scrambler.generateScramble 的 case 34 / case 35），
      // 原名 cross solved / last layer 是 DCTimer 老叫法，这里改成玩家熟悉的名字，和下面的 PLL 连成一组。
      { name: 'F2L', code: 934 },
      { name: 'OLL', code: 935 },
      { name: 'PLL', code: 936 },
      { name: 'edges only', code: 937 },
      { name: 'corners only', code: 938 },
      { name: 'last slot+last layer', code: 939 },
      { name: 'ZBLL', code: 940 },
      { name: 'ELL', code: 941 },
      { name: 'CLL', code: 942 },
      { name: 'last six edges', code: 943 },
      { name: 'CMLL + LSE', code: 944 },
      { name: 'edges permutation', code: 945 },
      { name: 'edges orientation', code: 946 },
      { name: 'corners permutation', code: 947 },
      { name: 'corners orientation', code: 948 },
      { name: 'permutation only', code: 949 },
      { name: 'orientation only', code: 950 },
      { name: 'easy cross', code: 951 },
      { name: '2GLL', code: 952 },
      { name: 'ZBLS', code: 953 },
      { name: 'ZZLL', code: 954 },
      { name: '3-cycle edges', code: 955 },
      { name: '3-cycle corners', code: 956 },
      { name: '3x3 for noobs', code: 957 },
    ]
  },
  {
    name: '4x4',
    items: [
      { name: 'old style', code: 964 },
      { name: 'SiGN', code: 965 },
      { name: 'YJ', code: 966 },
      { name: 'edges', code: 967 },
      { name: 'R,r,U,u', code: 968 },
    ]
  },
  {
    name: '5x5',
    items: [
      { name: 'prefix', code: 996 },
      { name: 'SiGN', code: 997 },
      { name: 'edges', code: 998 },
    ]
  },
  {
    name: '6x6',
    items: [
      { name: 'prefix', code: 1028 },
      { name: 'SiGN', code: 1029 },
      { name: 'suffix', code: 1030 },
      { name: 'edges', code: 1031 },
    ]
  },
  {
    name: '7x7',
    items: [
      { name: 'prefix', code: 1060 },
      { name: 'SiGN', code: 1061 },
      { name: 'suffix', code: 1062 },
      { name: 'edges', code: 1063 },
    ]
  },
  {
    name: 'Megaminx',
    items: [
      { name: 'Pochmann', code: 1092 },
      { name: 'old style', code: 1093 },
    ]
  },
  {
    name: 'Pyraminx',
    items: [
      { name: 'random state', code: 1124 },
      { name: 'random moves', code: 1125 },
      { name: 'L4E', code: 1126 },
    ]
  },
  {
    name: 'Square-1',
    items: [
      { name: 'face turn metric', code: 1156 },
      { name: 'twist metric', code: 1157 },
      { name: 'random state', code: 1158 },
      { name: 'cube shape', code: 1159 },
      { name: 'PBL', code: 1160 },
    ]
  },
  {
    name: 'Clock',
    items: [
      { name: 'WCA', code: 1188 },
      { name: 'Jaap order', code: 1189 },
      { name: 'concise', code: 1190 },
      { name: 'efficient pin order', code: 1191 },
    ]
  },
  {
    name: 'Skewb',
    items: [
      { name: 'random state', code: 1220 },
      { name: 'U L R B', code: 1221 },
      { name: 'L2L', code: 1222 },
    ]
  },
  {
    name: 'LxMxN',
    items: [
      { name: '1x3x3', code: 352 },
      { name: 'Super 1x3x3', code: 353 },
      { name: '2x3x3', code: 354 },
      { name: '2x2x3', code: 355 },
      { name: '2x2x4', code: 356 },
      { name: '3x3x4', code: 357 },
      { name: '3x3x5', code: 358 },
      { name: '3x3x6', code: 359 },
      { name: '3x3x7', code: 360 },
      { name: '4x4x6', code: 361 },
      { name: '8x8x8', code: 362 },
      { name: '9x9x9', code: 363 },
      { name: '10x10x10', code: 364 },
      { name: '11x11x11', code: 365 },
    ]
  },
  {
    name: 'Cmetrick',
    items: [
      { name: 'normal', code: 1284 },
      { name: 'mini', code: 1285 },
    ]
  },
  {
    name: 'Gear Cube',
    items: [
      { name: 'random state', code: 416 },
      { name: '3-gen', code: 417 },
    ]
  },
  {
    name: 'Siamese Cube',
    items: [
      { name: '1x1x3 block', code: 1348 },
      { name: '1x2x3 block', code: 1349 },
      { name: '2x2x2 block', code: 1350 },
    ]
  },
  {
    name: '15 puzzle',
    items: [
      { name: 'piece moves', code: 480 },
      { name: 'blank moves', code: 481 },
    ]
  },
  {
    name: '异形',
    items: [
      { name: 'FTO', code: 517 },
      { name: 'Redi cube', code: 518 },
      { name: 'Master pyraminx', code: 519 },
      { name: 'Ivy Cube', code: 522 },
      { name: 'UFO', code: 516 },
      { name: 'Latch Cube', code: 512 },
      { name: 'Helicopter', code: 513 },
      { name: 'Square-2', code: 514 },
      { name: 'Super SQ1', code: 515 },
      { name: '8 puzzle', code: 520 },
      { name: 'CTO', code: 521 },
    ]
  },
  {
    name: '3x3 subsets',
    items: [
      { name: '2-gen R,U', code: 544 },
      { name: '2-gen L,U', code: 545 },
      { name: 'Roux-gen M,U', code: 546 },
      { name: '3-gen F,R,U', code: 547 },
      { name: '3-gen R,U,L', code: 548 },
      { name: '3-gen R,r,U', code: 549 },
      { name: 'half turns only', code: 550 },
      { name: 'LSLL(old)', code: 551 },
    ]
  },
  {
    name: 'Bandaged Cube',
    items: [
      { name: 'Bicube', code: 1476 },
      { name: 'SQ1 /,(1,0)', code: 1477 },
    ]
  },
  {
    name: 'Megaminx subsets',
    items: [
      { name: '2-gen R,U', code: 1508 },
      { name: 'LSLL', code: 1509 },
    ]
  },
  {
    name: 'Relay',
    items: [
      { name: 'lots of 3x3s', code: 640 },
      { name: '234 relay', code: 641 },
      { name: '2345 relay', code: 642 },
      { name: '23456 relay', code: 643 },
      { name: '234567 relay', code: 644 },
      { name: 'Guildford challenge', code: 645 },
      { name: 'Mini Guildford', code: 646 },
    ]
  }
];

/** 展平的项目索引 -> (分类索引, 项目索引) */
function flattenIndex(catIdx: number, itemIdx: number): number {
  let flat: number = 0;
  for (let i: number = 0; i < catIdx; i++) {
    flat += PUZZLE_CATEGORIES[i].items.length;
  }
  return flat + itemIdx;
}

/** 反扁平化返回类型 */
interface FlattenResult {
  catIdx: number;
  itemIdx: number;
}

/** 反扁平化: 扁平索引 -> (分类, 项目, 全局索引) */
function unflattenIndex(flatIdx: number): FlattenResult {
  let acc: number = 0;
  for (let i: number = 0; i < PUZZLE_CATEGORIES.length; i++) {
    if (flatIdx < acc + PUZZLE_CATEGORIES[i].items.length) {
      let r: FlattenResult = { catIdx: i, itemIdx: flatIdx - acc };
      return r;
    }
    acc += PUZZLE_CATEGORIES[i].items.length;
  }
  let def: FlattenResult = { catIdx: 0, itemIdx: 0 };
  return def;
}

/** 兼容旧逻辑：扁平项目名（保持原 PUZZLE_TYPES[].name 等价） */
function flatPuzzleName(flatIdx: number): string {
  let r: FlattenResult = unflattenIndex(flatIdx);
  return PUZZLE_CATEGORIES[r.catIdx].items[r.itemIdx].name;
}
function flatPuzzleCode(flatIdx: number): number {
  let r: FlattenResult = unflattenIndex(flatIdx);
  return PUZZLE_CATEGORIES[r.catIdx].items[r.itemIdx].code;
}
function flatPuzzleCount(): number {
  let n: number = 0;
  for (const c of PUZZLE_CATEGORIES) {
    n += c.items.length;
  }
  return n;
}

/** 魔方编码 -> 打乱图阶数（0=不支持展开图，负数=非NxN特殊拼图） */
function puzzleImageSize(code: number): number {
  switch (code) {
    case 22: case 23: return 2;
    case 33: case 31: case 32: case 34: case 35: return 3;
    case 44: case 42: return 4;
    case 55: case 52: return 5;
    case 66: return 6;
    case 77: return 7;
    case 70: return -70;
    case 50: return -50;
    case 80: return -80;
    case 40: return -40;
    case 16: return -16; // Skewb
    case 82: return 1; // FTO
    case 352: case 354: case 355: return 1; // 1x3x3 / 2x3x3 / 2x2x3
    case 362: return 8; // 8x8x8
    case 363: return 9; // 9x9x9
    case 364: return 10; // 10x10x10
    case 365: return 11; // 11x11x11
    case 480: case 481: return 1; // 15 puzzle
    case 517: return 1; // FTO (Other)
    case 518: return 1; // Redi cube
    case 520: return 1; // 8 puzzle
    case 521: return 1; // CTO
    case 522: return 1; // Ivy Cube
    case 544: case 545: case 546: case 547: case 548: case 549: case 550: case 551: return 3;
    case 640: case 641: case 642: case 643: case 644: case 645: case 646: return 1; // Relay
    case 1477: return -40; // Bandaged SQ1
    case 1092: return -50; // Megaminx Pochmann（1093 old style 无图）
    default:
      if (code >= 900 && code <= 910) return 2; // 2x2
      if (code >= 932 && code <= 957) return 3; // 3x3
      if (code >= 964 && code <= 968) return 4; // 4x4
      if (code >= 996 && code <= 998) return 5; // 5x5
      if (code >= 1028 && code <= 1031) return 6; // 6x6
      if (code >= 1060 && code <= 1063) return 7; // 7x7
      if (code >= 1124 && code <= 1126) return -70; // Pyraminx
      if (code >= 1156 && code <= 1160) return -40; // Square-1
      if (code >= 1188 && code <= 1191) return -80; // Clock
      if (code >= 1220 && code <= 1222) return -16; // Skewb
      if (code >= 1284 && code <= 1285) return 0; // Cmetrick (无图)
      if (code >= 1348 && code <= 1350) return 0; // Siamese (无图)
      if (code >= 1476 && code <= 1477) return 0; // Bandaged (577 有 SQ1 图)
      if (code >= 1508 && code <= 1509) return 0; // Megaminx subsets (无图)
      return 0;
  }
}

/** 是否是三阶项目（支持十字求解） */
function is333Puzzle(code: number): boolean {
  return code === 33 || code === 31 || code === 32 || code === 34 || code === 35;
}

/**
 * 是否能打开求解器弹窗（审核问题1：把 solver/ 里已有但未接 UI 的求解器用起来）。
 * 具体范围见 util/SolverRouting.ets —— 与求解弹窗的页签共用同一套判断。
 */
function hasSolverPuzzle(code: number): boolean {
  return hasSolver(code);
}

/** 项目编码 -> DCTimer 打乱分类（与原版 MainActivity 分类一致） */
function toDctimerCategory(code: number): number {
  switch (code) {
    case 33: return -32; // 三阶速拧
    case 22: return -29; // 二阶速拧
    case 44: return -31; // 四阶速拧
    case 55: return -30; // 五阶速拧
    case 66: return -19; // 六阶速拧
    case 77: return -18; // 七阶速拧
    case 31: return -27; // 三阶单手
    case 32: return -28; // 三阶盲拧
    case 42: return -17; // 四阶盲拧
    case 52: return -16; // 五阶盲拧
    case 34: return -15; // 三阶多盲
    case 35: return -26; // 三阶最少步
    case 70: return -23; // Pyraminx
    case 50: return -24; // Megaminx
    case 40: return -22; // Square-1
    case 80: return -21; // Clock
    case 16: return -20; // Skewb
    case 82: return 517; // FTO (WCA)
    default:
      if (code >= 900) return code - 900; // 子项组: category + 900（2x2/3x3/4x4/.../Bandaged/Megaminx subsets）
      return code >= 100 ? code : -32; // LxMxN/Gear/15puzzle/Other/subsets/Relay: code == category
  }
}

const gScrambler: DctScrambler = new DctScrambler();

/** 初始化算法缓存目录（twophase.dat / center.dat / edge.dat），缺失时从 rawfile 复制 */
function copyRawTableFile(rm: resourceManager.ResourceManager, name: string, dest: string): Promise<void> {
  return rm.getRawFileContent(name).then((data: Uint8Array): void => {
    FileIO.writeWhole(dest, data);
  });
}

function initAlgorithmCache(ctx: common.UIAbilityContext): void {
  try {
    const dir = ctx.filesDir + '/dctimer/';
    FileIO.mkdir(dir);
    AppGlobals.dataPath = dir;
    Tools.dataPath = dir;
    setSbJointCacheDir(dir);
    // 求解器表预热整体延迟且移出主线程：旧版启动即在主线程分段建表
    // （含 pairJoint 6 段 BFS）并同步读 16MB 左/右桥联合表缓存，首页要
    // ~3s 才渲染完。现改为首帧渲染后 1.2s 在 taskpool worker 里预热
    // （读盘/建表/落盘都在 worker，主线程零阻塞）；用户提前点求解也无妨，
    // 求解 worker 会按需读 solver_core.dat 或现建。
    setTimeout((): void => { warmSolverCachesOffThread(); }, 1200);
    try {
      const rm: resourceManager.ResourceManager = ctx.resourceManager;
      copyRawTableFile(rm, 'twophase.dat', dir + 'twophase.dat').then((): void => {
        Tools.init();
      });
    } catch (e) {
      // rawfile 缺失时回退到运行时计算（慢）
    }
  } catch (e) {
    // ignore
  }
}

// ===== 手势动作类型 =====
const SWIPE_DELETE_LAST: number = 1;
const SWIPE_NEW_SCRAMBLE: number = 2;
const SWIPE_CHANGE_PENALTY: number = 3;
const SWIPE_NOTHING: number = 4;
const SWIPE_MANUAL_INPUT: number = 5;

// ===== 设置项接口 =====
interface SettingItem {
  id: number;
  title: string;
  detail: string;
  type: number;
  value: boolean;
}

interface SettingSection {
  title: string;
  items: SettingItem[];
}

// ===== 会话选择对话框 =====
@CustomDialog
struct SessionSelectDialog {
  controller: CustomDialogController;
  sessions: Session[] = [];
  currentIdx: number = 0;
  bottomInset: number = 28;
  onSelect: (index: number) => void = (): void => {};
  onNew: () => void = (): void => {};

  build() {
    Column() {
      Text('选择训练组')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(themeText(AppConfig.darkMode))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 20, bottom: 12 });

      List() {
        ForEach(this.sessions, (session: Session, index: number) => {
          ListItem() {
            Row() {
              Text(session.name)
                .fontSize(16)
                .fontColor(this.currentIdx === index ? COLOR_ACCENT : themeText(AppConfig.darkMode))
                .layoutWeight(1)
                .padding({ left: 20, right: 20 });
              if (this.currentIdx === index) {
                Text('✓')
                  .fontSize(16)
                  .fontColor(COLOR_ACCENT)
                  .padding({ right: 20 });
              }
            }
            .width('100%')
            .height(48)
            .backgroundColor(this.currentIdx === index ? COLOR_ACCENT_BG : themeBg(AppConfig.darkMode))
            .onClick((): void => {
              this.onSelect(index);
              this.controller.close();
            });
          }
        }, (session: Session): string => session.id.toString())
      }
      .width('100%')
      .constraintSize({ maxHeight: 400 })
      .divider({ strokeWidth: 1, color: themeDivider(AppConfig.darkMode), startMargin: 20, endMargin: 0 });

      Row() {
        Text('+ 新建训练组')
          .fontSize(16)
          .fontColor(COLOR_ACCENT)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding(14)
          .onClick((): void => {
            this.onNew();
            this.controller.close();
          });
      }
      .width('100%');

      Button('取消')
        .fontSize(16)
        .fontColor(themeText(AppConfig.darkMode))
        .backgroundColor(themeBg(AppConfig.darkMode))
        .width('100%')
        .height(48)
        .margin({ top: 8 })
        .onClick((): void => { this.controller.close(); });
    }
    .width('100%')
    // 底部垫高安全区，避免「取消」按钮被手势条遮挡（审核问题2）
    .padding({ bottom: this.bottomInset })
    .backdropBlur(dialogBlurRadius(materialEnabled(AppConfig.ambientEnabled)))
    .backgroundColor(dialogSurface(AppConfig.darkMode, materialEnabled(AppConfig.ambientEnabled)))
    .borderRadius({ topLeft: 12, topRight: 12 });
  }
}

// ===== 成绩确认对话框 =====
@CustomDialog
struct ResultConfirmDialog {
  controller: CustomDialogController;
  resultTime: number = 0;
  resultPenalty: number = 0;
  scramble: string = '';
  accuracy: number = 0;
  onConfirm: (penalty: number) => void = (_p: number): void => {};
  onCancel: () => void = (): void => {};

  build() {
    Column() {
      Text('确认成绩')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(themeSubText(AppConfig.darkMode))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 22 });

      Text(this.formatDisplayTime())
        .fontSize(44)
        .fontWeight(FontWeight.Bold)
        .fontColor(themeText(AppConfig.darkMode))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 6, bottom: 2 });

      Scroll() {
        Column() {
          Text(this.scramble)
            .fontSize(12)
            .lineHeight(18)
            .fontColor(themeSubText(AppConfig.darkMode))
            .width('100%')
            .textAlign(TextAlign.Center)
            .maxLines(30);
        }
        .width('100%')
        .padding({ left: 24, right: 24 });
      }
      .width('100%')
      .constraintSize({ maxHeight: 78 })
      .scrollBar(BarState.Off)
      .padding({ top: 10, bottom: 18 });

      // 三个处罚选项统一成「淡色底 + 同色描边 + 彩色字」的色调按钮（tonal chip）。
      // 之前「确认」用的是 #448AFF 实心色，压在毛玻璃上就是一块不透明的蓝贴片，
      // 和 +2 / DNF 的淡色底也不一致。现在三者同一套视觉语言，主操作靠
      // 更浓的底色（0.26 vs 0.13）+ 加粗 + 亮一级的文字来区分，不再靠"实心"。
      Row({ space: 8 }) {
        this.ActionChip('确认', 'rgba(68,138,255,0.26)', 'rgba(68,138,255,0.55)',
          COLOR_ACCENT, true, this.resultPenalty);
        this.ActionChip('+2', 'rgba(255,152,0,0.13)', 'rgba(255,152,0,0.45)',
          '#F57C00', false, 1);
        this.ActionChip('DNF', 'rgba(244,67,54,0.13)', 'rgba(244,67,54,0.45)',
          '#E53935', false, 2);
      }
      .width('100%')
      .padding({ left: 16, right: 16 });

      // 取消只留文字：原来是一整条实心白底，叠在毛玻璃上像贴了张纸条
      Button('取消')
        .fontSize(15)
        .fontColor(themeSubText(AppConfig.darkMode))
        .backgroundColor(Color.Transparent)
        .width('100%')
        .height(46)
        .margin({ top: 6, bottom: 8 })
        .onClick((): void => {
          this.onCancel();
          this.controller.close();
        });
    }
    .width('100%')
    .backdropBlur(dialogBlurRadius(materialEnabled(AppConfig.ambientEnabled)))
    .backgroundColor(dialogSurface(AppConfig.darkMode, materialEnabled(AppConfig.ambientEnabled)))
    .borderRadius(20);
  }

  @Builder
  ActionChip(label: string, bgColor: string, strokeColor: string, fgColor: string,
    filled: boolean, penalty: number) {
    Button(label)
      .fontSize(16)
      .fontWeight(filled ? FontWeight.Medium : FontWeight.Normal)
      .fontColor(fgColor)
      .backgroundColor(bgColor)
      .border({ width: 1, color: strokeColor })
      .layoutWeight(1)
      .height(46)
      .borderRadius(23)
      .onClick((): void => {
        this.onConfirm(penalty);
        this.controller.close();
      });
  }

  formatDisplayTime(): string {
    if (this.resultPenalty === 2) {
      return 'DNF';
    }
    return ResultEntry.formatMs(this.resultTime + (this.resultPenalty === 1 ? 2000 : 0), this.accuracy);
  }
}

// ===== 成绩详情对话框（点开成绩列表项） =====
@CustomDialog
struct ResultDetailDialog {
  controller: CustomDialogController;
  resultIndex: number = 0;
  displayNo: number = 1;
  resultEntry: ResultEntry | null = null;
  puzzleCode: number = 33;
  puzzleSize: number = 3;
  schemeVersion: number = 0;
  onPenaltyChange: (index: number, penalty: number) => void = (): void => {};
  onNoteChange: (index: number, note: string) => void = (): void => {};
  onDelete: (index: number) => void = (): void => {};
  onCopyScramble: (scramble: string) => void = (): void => {};

  @State selectedPenalty: number = 0;
  @State noteText: string = '';

  aboutToAppear(): void {
    if (this.resultEntry) {
      this.selectedPenalty = this.resultEntry.penalty;
      this.noteText = this.resultEntry.note;
    }
  }

  private displayTime(): string {
    if (this.resultEntry === null) {
      return 'DNF';
    }
    if (this.selectedPenalty === 2) {
      return 'DNF';
    }
    return ResultEntry.formatMs(this.resultEntry.time + (this.selectedPenalty === 1 ? 2000 : 0),
      AppConfig.timerAccuracy);
  }

  @Builder PenaltyOption(label: string, value: number) {
    Row() {
      Circle({ width: 20, height: 20 })
        .fill(this.selectedPenalty === value ? COLOR_ACCENT : Color.Transparent)
        .stroke(themeSubText(AppConfig.darkMode))
        .strokeWidth(2);
      Text(label)
        .fontSize(15)
        .fontColor(themeText(AppConfig.darkMode))
        .margin({ left: 6 });
    }
    .padding(8)
    .onClick((): void => {
      this.selectedPenalty = value;
      this.onPenaltyChange(this.resultIndex, value);
    });
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          if (this.resultEntry) {
            Text('#' + this.displayNo)
              .fontSize(15)
              .fontColor(themeSubText(AppConfig.darkMode))
              .width('100%')
              .textAlign(TextAlign.Start)
              .margin({ bottom: 2 });

            Text(this.displayTime())
              .fontSize(48)
              .fontWeight(FontWeight.Bold)
              .fontColor(themeText(AppConfig.darkMode))
              .width('100%')
              .textAlign(TextAlign.Start)
              .margin({ bottom: 4 });

            Text(formatDateFull(this.resultEntry.date))
              .fontSize(14)
              .fontColor(themeSubText(AppConfig.darkMode))
              .width('100%')
              .textAlign(TextAlign.Start)
              .margin({ bottom: 12 });

            Text(this.resultEntry.scramble)
              .fontSize(16)
              .fontColor(themeText(AppConfig.darkMode))
              .width('100%')
              .textAlign(TextAlign.Start)
              .margin({ bottom: 12 });

            if (this.puzzleSize !== 0 && this.resultEntry.scramble.length > 0) {
              Row() {
                ScrambleImageView({
                  scramble: this.resultEntry.scramble,
                  puzzleSize: this.puzzleSize,
                  puzzleCode: this.puzzleCode,
                  schemeVersion: this.schemeVersion
                });
              }
              .width('100%')
              .height(220)
              .justifyContent(FlexAlign.Center)
              .margin({ bottom: 16 });
            }

            // 惩罚选择
            Row() {
              this.PenaltyOption('无惩罚', 0);
              this.PenaltyOption('+2', 1);
              this.PenaltyOption('DNF', 2);
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceEvenly)
            .margin({ bottom: 16 });

            // 备注输入
            Row() {
              AppIcon({
                iconId: 'note',
                color: themeSubText(AppConfig.darkMode),
                iconSize: 22
              });
              TextInput({ text: this.noteText, placeholder: '备注' })
                .layoutWeight(1)
                .height(44)
                .fontSize(15)
                .fontColor(themeText(AppConfig.darkMode))
                .placeholderColor(themeSubText(AppConfig.darkMode))
                .caretColor(themeText(AppConfig.darkMode))
                .backgroundColor(themeDivider(AppConfig.darkMode))
                .borderRadius(8)
                .margin({ left: 10 })
                .onChange((value: string): void => {
                  this.noteText = value;
                });
            }
            .width('100%')
            .margin({ bottom: 8 });
          }
        }
        .width('100%')
        .padding(20);
      }
      .width('100%')
      .layoutWeight(1);

      // 底部操作按钮
      Row() {
        Text('复制打乱')
          .fontSize(15)
          .fontColor(COLOR_ACCENT)
          .padding(8)
          .onClick((): void => {
            if (this.resultEntry) {
              this.onCopyScramble(this.resultEntry.scramble);
            }
          });

        Text('删除')
          .fontSize(15)
          .fontColor('#ff4444')
          .padding(8)
          .onClick((): void => {
            this.controller.close();
            this.onDelete(this.resultIndex);
          });

        Text('确定')
          .fontSize(15)
          .fontColor(COLOR_ACCENT)
          .padding(8)
          .onClick((): void => {
            if (this.resultEntry && this.noteText !== this.resultEntry.note) {
              this.onNoteChange(this.resultIndex, this.noteText);
            }
            this.controller.close();
          });
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 20 })
      .justifyContent(FlexAlign.SpaceBetween);
    }
    .width('90%')
    .constraintSize({ maxHeight: '85%' })
    .backdropBlur(dialogBlurRadius(materialEnabled(AppConfig.ambientEnabled)))
    .backgroundColor(dialogSurface(AppConfig.darkMode, materialEnabled(AppConfig.ambientEnabled)))
    .borderRadius(16);
  }
}

// ===== 手动输入对话框 =====
@CustomDialog
struct ManualInputDialog {
  controller: CustomDialogController;
  onConfirm: (timeStr: string) => void = (): void => {};
  @State inputValue: string = '';

  build() {
    Column() {
      Text('手动输入时间')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(themeText(AppConfig.darkMode))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 20, bottom: 12 });

      Text('格式: 秒.厘秒 (如 12.34) 或 分:秒.厘秒')
        .fontSize(14)
        .fontColor(themeSubText(AppConfig.darkMode))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ bottom: 12 });

      TextInput({ placeholder: '12.34' })
        .width('80%')
        .height(42)
        .fontSize(18)
        .fontColor(themeText(AppConfig.darkMode))
        .placeholderColor(themeSubText(AppConfig.darkMode))
        .caretColor(themeText(AppConfig.darkMode))
        .backgroundColor(themeDivider(AppConfig.darkMode))
        .margin({ bottom: 16 })
        .onChange((value: string): void => {
          this.inputValue = value;
        });

      Row() {
        Button('取消')
          .fontSize(16)
          .fontColor(themeText(AppConfig.darkMode))
          .backgroundColor(themeDivider(AppConfig.darkMode))
          .layoutWeight(1)
          .height(42)
          .onClick((): void => { this.controller.close(); });
        Button('确认')
          .fontSize(16)
          .fontColor('#ffffff')
          .backgroundColor(COLOR_ACCENT)
          .layoutWeight(1)
          .height(42)
          .margin({ left: 12 })
          .onClick((): void => {
            this.onConfirm(this.inputValue);
            this.controller.close();
          });
      }
      .width('80%')
      .padding({ bottom: 16 });
    }
    .width('100%')
    .backdropBlur(dialogBlurRadius(materialEnabled(AppConfig.ambientEnabled)))
    .backgroundColor(dialogSurface(AppConfig.darkMode, materialEnabled(AppConfig.ambientEnabled)))
    .borderRadius(12);
  }
}

// ===== 主页面 =====
@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  // 计时器状态
  @State timerText: string = '0.00';
  @State timerColor: string = '#000000';
  @State timerState: TimerState = TimerState.READY;
  @State scramble: string = '';
  @State statText: string = '';
  @State inspectionText: string = '';
  @State currentPuzzleIndex: number = 0;
  @State puzzleButtonText: string = '3x3';
  // 主题与字号（响应式，切换时驱动界面刷新）
  @State isDark: boolean = false;
  // 跟随系统：系统深色变化时自动刷新（由 EntryAbility 写入全局存储）
  @StorageProp('dcSystemDark')
  @Watch('onSystemDarkChange')
  sysDark: boolean = true;
  @State timerFontSize: number = 72;
  @State scrambleFontSize: number = 16;
  // 成绩数据
  @State results: ResultEntry[] = [];
  @State sessions: Session[] = [];
  @State currentSessionIndex: number = 0;
  @State sessionName: string = '组 1';
  @State showResultChart: boolean = false;
  @State sessionMeanText: string = '';
  @State bestText: string = '--';
  @State avg1Text: string = '--';
  @State avg2Text: string = '--';
  @State minIdx: number = -1;
  @State maxIdx: number = -1;
  // 设置数据
  @State settingSections: SettingSection[] = [];
  @State @Watch('onSettingSectionChange') currentSettingSection: number = 0;
  // 点击顶部导航跳转期间，抑制 onScrollIndex 对高亮的改写，避免被底部反推抢走
  private suppressScrollHighlight: boolean = false;
  // 设置导航横向 Scroll 的控制器与标签宽度缓存
  private navScroller: Scroller = new Scroller();
  // 导航栏左右内边距；测量与布局共用此值，避免两边漂移
  private navPad: number = 12;
  // 各分区标签宽度（vp），中心位置由宽度累加推算（不依赖 onAreaChange 的 position）
  private tabWidths: number[] = [];
  @State navWidth: number = 0;
  // 导航栏内容总宽（vp），用于计算最大可滚动偏移
  @State navContentWidth: number = 0;
  // 底部系统安全区高度（手势条/导航栏避让），主内容区据此留白
  @State bottomSafeInset: number = MIN_BOTTOM_INSET_VP;
  // 顶部状态栏高度，沉浸式布局下顶部栏需要自己垫高
  @State topSafeInset: number = 0;
  // 背景主题
  @State bgImageUri: string = '';
  @State bgOpacity: number = 80;
  // 沉浸光感：设备能力 + 用户开关 + 打底渐变
  @State ambientUsable: boolean = false;
  @State ambientOn: boolean = true;
  @State gradientId: string = 'aurora';
  // 背景图裁剪
  @State showBgCrop: boolean = false;
  @State bgCropSrcUri: string = '';
  // BLE 智能魔方
  @State bleConnected: boolean = false;
  @State bleDeviceName: string = '';
  @State bleStatusText: string = '未连接';
  // 智能魔方 3D 同步状态
  @State smartCubeConnected: boolean = false;
  @State smartCubeFacelets: string = SmartCubeOrientation.SOLVED_FACELET;
  // 求解器
  @State showSolver: boolean = false;
  // 打乱图配色编辑器（kind: 0=NxNxN 1=金字塔 2=斜转 3=五魔方）
  @State showColorScheme: boolean = false;
  @State schemeKind: number = 0;
  // 配色变更版本号：bump 后驱动 ScrambleImageView 重绘（scheme 是静态表，
  // @Prop scramble 不变时组件不会自行刷新）
  @State schemeVersion: number = 0;
  // 魔方类型下拉
  @State showPuzzleDropdown: boolean = false;
  @State dropdownCategoryIdx: number = 0;
  // 确认后的惩罚标记（0=无,1=+2,2=DNF），-1=未确认
  @State resultPenalty: number = -1;
  // 触摸位置
  private touchStartX: number = 0;
  private touchStartY: number = 0;
  private stoppedOnThisTouch: boolean = false;
  // 计时器引擎
  private dct: DCTTimer = new DCTTimer();
  private freezeTimerId: number = -1;
  // 持久化
  private dataPrefs: dataPreferences.Preferences | null = null;
  // 数据库与成绩模型（忠实移植 Result.java / Stats.java）
  private db: DBHelper = new DBHelper();
  private result: Result | null = null;
  // 对话框控制器
  private confirmDialog: CustomDialogController = new CustomDialogController({
    builder: ResultConfirmDialog({
      resultTime: 0,
      resultPenalty: 0,
      scramble: '',
      accuracy: 0,
      onConfirm: (_p: number): void => {},
      onCancel: (): void => {}
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  });
  private sessionDialog: CustomDialogController = new CustomDialogController({
    builder: SessionSelectDialog({
      sessions: [],
      currentIdx: 0,
      bottomInset: this.bottomSafeInset,
      onSelect: (_index: number): void => {},
      onNew: (): void => {}
    }),
    autoCancel: true,
    alignment: DialogAlignment.Bottom,
    customStyle: true
  });
  private resultDetailDialog: CustomDialogController = new CustomDialogController({
    builder: ResultDetailDialog({
      resultIndex: 0,
      displayNo: 1,
      resultEntry: null,
      puzzleCode: 33,
      puzzleSize: 3,
      onPenaltyChange: (_index: number, _penalty: number): void => {},
      onNoteChange: (_index: number, _note: string): void => {},
      onDelete: (_index: number): void => {},
      onCopyScramble: (_scramble: string): void => {}
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  });
  private manualInputDialog: CustomDialogController = new CustomDialogController({
    builder: ManualInputDialog({
      onConfirm: (_timeStr: string): void => {}
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  });
  private exportDialog: CustomDialogController = new CustomDialogController({
    builder: ExportDialog({
      csvData: '',
      sessionName: ''
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  });
  private bleDialog: CustomDialogController | null = null;
  // 隐私政策对话框：首次启动需同意；设置页可查看
  private privacyDialog: CustomDialogController = new CustomDialogController({
    builder: PrivacyDialog({
      mode: 0,
      onAgree: (): void => { this.onPrivacyAgree(); },
      onExit: (): void => { this.exitApp(); }
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    customStyle: true
  });
  private privacyViewDialog: CustomDialogController = new CustomDialogController({
    builder: PrivacyDialog({
      mode: 1,
      onAgree: (): void => {},
      onExit: (): void => {}
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  aboutToAppear(): void {
    initAlgorithmCache(getContext(this) as common.UIAbilityContext);
    this.loadBottomSafeInset();
    this.initAmbient();
    this.dct.setCallback((time: number, state: TimerState): void => {
      this.timerState = state;
      this.timerText = StringUtils.timeToString(time);
      if (state === TimerState.STOP) {
        this.timerColor = themeText(this.isDark);
        // 停表后自动生成新打乱
        this.generateScramble();
      }
    });

    this.dct.setInspectionCallback((state: number, remaining: number): void => {
      if (state === 1) {
        this.inspectionText = remaining.toString();
        this.timerColor = COLOR_INSPECTING;
      } else if (state === 2) {
        this.inspectionText = '+2';
        this.timerColor = COLOR_INSPECTING;
      } else if (state === 3) {
        this.inspectionText = 'DNF';
        this.timerColor = COLOR_INSPECTING;
      }
    });

    this.dct.setPhaseCallback((phaseIndex: number, phaseTime: number): void => {
      promptAction.showToast({
        message: '第' + (phaseIndex + 1) + '段: ' + StringUtils.timeToString(phaseTime),
        duration: 1500
      });
    });

    this.dct.setInspectAlertCallback((elapsedSec: number): void => {
      if (AppConfig.inspectionAlert) {
        this.vibrate(elapsedSec === 8 ? 150 : 250);
      }
    });

    // 同步读取背景/主题配置，避免冷启动首帧先显示默认界面、稍后才切换
    try {
      const sprefs: dataPreferences.Preferences =
        dataPreferences.getPreferencesSync(getContext(this), { name: 'dctimer_data' });
      const uri: string = sprefs.getSync('bgImageUri', '') as string;
      const op: number = sprefs.getSync('bgOpacity', 80) as number;
      BackgroundManager.setImageUri(uri);
      BackgroundManager.setOpacity(op);
      // 主题模式（无 themeMode 时从旧 darkMode 迁移）
      const mt: number = sprefs.getSync('themeMode', -1) as number;
      if (mt === -1) {
        AppConfig.themeMode = (sprefs.getSync('darkMode', false) as boolean) ? 1 : 0;
      } else {
        AppConfig.themeMode = mt;
      }
    } catch (e) {
      // 首次启动无配置文件时忽略，使用默认值
    }
    // 初始化背景设置
    this.bgImageUri = BackgroundManager.getImageUri();
    this.bgOpacity = BackgroundManager.getOpacity();
    // 依据主题模式计算生效明暗，使首帧即为正确主题
    this.refreshSystemDark();
    this.applyEffectiveDark(false);

    this.initSettings();
    initScrambleItems();

    let ctx: Context = getContext(this);
    dataPreferences.getPreferences(ctx, 'dctimer_data', (err: Error, prefs: dataPreferences.Preferences): void => {
      if (!err) {
        this.dataPrefs = prefs;
        this.loadFromPreferences();
      } else {
        this.initDefaultSessions();
        this.generateScramble();
      }
      this.initDatabase();
      this.checkPrivacyAgreement();
    });
  }

  // ===== 隐私政策 =====
  /** 首次启动且未同意隐私政策时，弹出必须同意的对话框 */
  checkPrivacyAgreement(): void {
    if (!AppConfig.privacyAgreed) {
      this.privacyDialog.open();
    }
  }

  /** 首次同意回调：标记已同意并持久化 */
  onPrivacyAgree(): void {
    AppConfig.privacyAgreed = true;
    this.saveToPreferences();
  }

  /** 不同意时退出应用 */
  exitApp(): void {
    try {
      const abilityCtx = getContext(this) as common.UIAbilityContext;
      abilityCtx.terminateSelf();
    } catch (e) {
      // 退出失败时静默（模拟器/异常场景）
    }
  }

  /** 设置页查看隐私政策 */
  openPrivacyPolicy(): void {
    this.privacyViewDialog.open();
  }

  /** 底部避让最小值（vp）：手势条避让区换算后可能小于 28vp，测试标准要求至少 28vp */
  private static readonly MIN_BOTTOM_SAFE_VP: number = MIN_BOTTOM_INSET_VP;

  /** 从全局存储读取顶部/底部安全区（沉浸式布局下由 EntryAbility 统一写入并实时更新）。
   *  底部按 28vp 兜底，保证底栏控件距屏幕底边不小于 28vp（审核问题2 的硬指标）。 */
  loadBottomSafeInset(): void {
    this.refreshSafeInset();
    // 双保险：EntryAbility 在窗口尺寸/导航方式变化时也会写 AppStorage，
    // 这里再主动读一次窗口，防止首帧时 AppStorage 尚未写入。
    window.getLastWindow(getContext(this)).then((win: window.Window): void => {
      try {
        const indicator: window.AvoidArea =
          win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
        const sysBar: window.AvoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        const bottomPx: number = Math.max(indicator.bottomRect.height, sysBar.bottomRect.height);
        const topPx: number = Math.max(indicator.topRect.height, sysBar.topRect.height);
        this.bottomSafeInset = Math.max(px2vp(bottomPx), Index.MIN_BOTTOM_SAFE_VP);
        this.topSafeInset = px2vp(topPx);
        win.on('avoidAreaChange', (data: window.AvoidAreaOptions) => {
          if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR ||
            data.type === window.AvoidAreaType.TYPE_SYSTEM) {
            this.refreshSafeInset();
          }
        });
      } catch (e) {
        this.bottomSafeInset = Index.MIN_BOTTOM_SAFE_VP;
      }
    }).catch((): void => {
      this.bottomSafeInset = Index.MIN_BOTTOM_SAFE_VP;
    });
  }

  /** 从 AppStorage 同步安全区（EntryAbility 的 avoidAreaChange 已折算成 vp 写入） */
  refreshSafeInset(): void {
    const b: number | undefined = AppStorage.get<number>(BOTTOM_INSET_KEY);
    const t: number | undefined = AppStorage.get<number>(TOP_INSET_KEY);
    if (b !== undefined) {
      this.bottomSafeInset = Math.max(b, Index.MIN_BOTTOM_SAFE_VP);
    }
    if (t !== undefined) {
      this.topSafeInset = t;
    }
  }

  // ===== 沉浸光感 =====
  /**
   * 初始化光感能力。
   * 关键：设备不支持时必须退回普通不透明栏，否则会得到「没有内容却半透明」
   * 的怪效果，文字可读性反而变差。
   */
  initAmbient(): void {
    this.ambientUsable = materialSupported();
    this.ambientOn = AppConfig.ambientEnabled;
    this.gradientId = AppConfig.gradientId;
  }

  /** 当前是否真的要套材质（设备支持 + 用户开启） */
  ambientActive(): boolean {
    return this.ambientUsable && this.ambientOn;
  }

  /** 用户没设自定义背景时才用内置渐变打底 —— 材质模糊需要有内容 */
  showAmbientBackdrop(): boolean {
    return this.bgImageUri.length === 0;
  }

  /** 当前打底渐变的色段 */
  ambientColors(): GradientStops {
    return schemeColors(findScheme(this.gradientId), this.isDark);
  }

  ambientAngle(): number {
    return findScheme(this.gradientId).angle;
  }


  /**
   * 读取当前系统是否为深色。
   * 权威来源 = AppStorage['dcSystemDark']（EntryAbility 的应用级环境回调实时写入，
   * 前台/后台都准确）。getContext().config.colorMode 在 setColorMode(NOT_SET) 下
   * 可能返回 -1 或滞后值，只作兜底，绝不能再覆盖正确值。
   */
  refreshSystemDark(): void {
    const v: boolean | undefined = AppStorage.get<boolean>(SYSTEM_DARK_KEY);
    if (v !== undefined) {
      AppConfig.systemDark = v;
      return;
    }
    try {
      AppConfig.systemDark =
        (getContext(this) as common.UIAbilityContext).config.colorMode ===
        ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    } catch (e) {
      // 读取失败时保留上一次值
    }
  }

  /** 依据主题模式计算生效明暗并刷新界面 */
  applyEffectiveDark(updateTimer: boolean): void {
    if (AppConfig.themeMode === 2) {
      this.refreshSystemDark();
      AppConfig.darkMode = AppConfig.systemDark;
    } else {
      AppConfig.darkMode = AppConfig.themeMode === 1;
    }
    this.isDark = AppConfig.darkMode;
    if (updateTimer && (this.timerState === TimerState.READY || this.timerState === TimerState.STOP)) {
      this.timerColor = themeText(this.isDark);
    }
  }

  /** 设置项当前主题描述 */
  themeModeDesc(): string {
    if (AppConfig.themeMode === 2) {
      return '跟随系统';
    }
    return AppConfig.themeMode === 1 ? '深色' : '浅色';
  }

  /** 页面每次显示时若处于“跟随系统”，校正到当前系统主题 */
  onPageShow(): void {
    if (AppConfig.themeMode === 2) {
      this.refreshSystemDark();
      this.applyEffectiveDark(true);
    }
  }

  /** 系统深色模式变化（跟随系统时）自动刷新界面 */
  onSystemDarkChange(): void {
    if (AppConfig.themeMode === 2) {
      // AppStorage 刚由环境回调写入权威值，refreshSystemDark 直接读取它
      this.applyEffectiveDark(true);
    }
  }

  /** 初始化数据库并加载当前训练组成绩 */
  async initDatabase(): Promise<void> {
    this.result = new Result(this.db);
    try {
      await this.db.initialize(getContext(this));
    } catch (e) {
      promptAction.showToast({ message: '数据库初始化失败', duration: 2000 });
    }
    await this.loadSessionResults();
    this.generateScramble();
  }

  aboutToDisappear(): void {
    this.dct.reset();
    this.saveToPreferences();
  }

  // ===== 振动 =====
  async vibrate(duration: number): Promise<void> {
    try {
      let effect: vibrator.VibrateEffect = { type: 'time', duration: duration };
      let attr: vibrator.VibrateAttribute = { usage: 'touch' };
      await vibrator.startVibration(effect, attr);
    } catch (err) {
      // 设备不支持振动时静默失败
    }
  }

  vibrateOnStart(): void {
    if (AppConfig.vibrateType === 1 || AppConfig.vibrateType === 3) {
      this.vibrate(AppConfig.vibrateDuration);
    }
  }

  vibrateOnStop(): void {
    if (AppConfig.vibrateType === 2 || AppConfig.vibrateType === 3) {
      this.vibrate(AppConfig.vibrateDuration);
    }
  }

  // ===== 屏幕常亮 =====
  async applyKeepScreenOn(): Promise<void> {
    try {
      let win: window.Window = await window.getLastWindow(getContext(this));
      await win.setWindowKeepScreenOn(AppConfig.keepScreenOn);
    } catch (err) {
      // 忽略失败
    }
  }

  // ===== 数据持久化 =====
  loadFromPreferences(): void {
    if (this.dataPrefs === null) {
      return;
    }
    let prefs: dataPreferences.Preferences = this.dataPrefs;
    AppConfig.wcaInspection = prefs.getSync('wcaInspection', true) as boolean;
    AppConfig.inspectionAlert = prefs.getSync('inspectionAlert', true) as boolean;
    AppConfig.timerAccuracy = prefs.getSync('timerAccuracy', 0) as number;
    AppConfig.enterTime = prefs.getSync('enterTime', 0) as number;
    AppConfig.freezeTime = prefs.getSync('freezeTime', 0) as number;
    AppConfig.multiPhase = prefs.getSync('multiPhase', 0) as number;
    AppConfig.showStats = prefs.getSync('showStats', true) as boolean;
    AppConfig.showScrambleImage = prefs.getSync('showScrambleImage', true) as boolean;
    AppConfig.scrambleFontSize = prefs.getSync('scrambleFontSize', 16) as number;
    // 主题模式（无 themeMode 时从旧 darkMode 迁移）
    const thm: number = prefs.getSync('themeMode', -1) as number;
    if (thm === -1) {
      AppConfig.themeMode = (prefs.getSync('darkMode', false) as boolean) ? 1 : 0;
    } else {
      AppConfig.themeMode = thm;
    }
    this.refreshSystemDark();
    this.applyEffectiveDark(true);
    AppConfig.bgImageUri = prefs.getSync('bgImageUri', '') as string;
    AppConfig.bgOpacity = prefs.getSync('bgOpacity', 80) as number;
    AppConfig.privacyAgreed = prefs.getSync('privacyAgreed', false) as boolean;
    AppConfig.ambientEnabled = prefs.getSync('ambientEnabled', true) as boolean;
    AppConfig.gradientId = prefs.getSync('gradientId', 'aurora') as string;
    this.bgImageUri = AppConfig.bgImageUri;
    this.bgOpacity = AppConfig.bgOpacity;
    this.ambientOn = AppConfig.ambientEnabled;
    this.gradientId = findScheme(AppConfig.gradientId).id;
    AppConfig.timerFont = prefs.getSync('timerFont', 0) as number;
    AppConfig.fontSize = prefs.getSync('fontSize', 72) as number;
    AppConfig.keepScreenOn = prefs.getSync('keepScreenOn', true) as boolean;
    AppConfig.vibrateType = prefs.getSync('vibrateType', 1) as number;
    AppConfig.defaultCrossBottom = prefs.getSync('defaultCrossBottom', 1) as number;
    AppConfig.avg1Type = prefs.getSync('avg1Type', 0) as number;
    AppConfig.avg1Len = prefs.getSync('avg1Len', 5) as number;
    AppConfig.avg2Type = prefs.getSync('avg2Type', 0) as number;
    AppConfig.avg2Len = prefs.getSync('avg2Len', 12) as number;
    this.loadColorSchemes(prefs);
    let swipeStr: string = prefs.getSync('swipeType', '1,2,3,5') as string;
    let swipeParts: string[] = swipeStr.split(',');
    for (let i: number = 0; i < 4 && i < swipeParts.length; i++) {
      let v: number = parseInt(swipeParts[i]);
      if (!isNaN(v) && v >= 1 && v <= 5) {
        AppConfig.swipeType[i] = v;
      }
    }

    this.isDark = AppConfig.darkMode;
    this.timerFontSize = AppConfig.fontSize;
    this.scrambleFontSize = AppConfig.scrambleFontSize;
    this.timerColor = themeText(this.isDark);

    // 训练组
    let sessionsJson: string = prefs.getSync('sessions', '') as string;
    if (sessionsJson.length > 0) {
      try {
        let arr: Object[] = JSON.parse(sessionsJson) as Object[];
        this.sessions = [];
        for (let i: number = 0; i < arr.length; i++) {
          this.sessions.push(Session.fromJSON(arr[i] as Record<string, Object>));
        }
      } catch (e) {
        this.sessions = [];
      }
    }
    if (this.sessions.length === 0) {
      this.initDefaultSessions();
    }
    let savedSessionIdx: number = prefs.getSync('currentSessionIndex', 0) as number;
    if (savedSessionIdx < 0 || savedSessionIdx >= this.sessions.length) {
      savedSessionIdx = 0;
    }
    this.currentSessionIndex = savedSessionIdx;
    this.sessionName = this.sessions[savedSessionIdx].name;

    // 魔方类型跟随训练组
    let puzzleCode: number = this.sessions[savedSessionIdx].puzzle;
    let pIdx: number = -1;
    for (let i: number = 0; i < flatPuzzleCount(); i++) {
      if (flatPuzzleCode(i) === puzzleCode) {
        pIdx = i;
        break;
      }
    }
    this.currentPuzzleIndex = pIdx >= 0 ? pIdx : 0;
    this.puzzleButtonText = flatPuzzleName(this.currentPuzzleIndex);

    // 同步显示精度（StringUtils 读取 AppGlobals）
    AppGlobals.timerAccuracy = AppConfig.timerAccuracy;

    this.generateScramble();
    this.initSettings();
    this.applyKeepScreenOn();
  }

  saveToPreferences(): void {
    if (this.dataPrefs === null) {
      return;
    }
    let prefs: dataPreferences.Preferences = this.dataPrefs;
    prefs.putSync('wcaInspection', AppConfig.wcaInspection);
    prefs.putSync('inspectionAlert', AppConfig.inspectionAlert);
    prefs.putSync('timerAccuracy', AppConfig.timerAccuracy);
    prefs.putSync('enterTime', AppConfig.enterTime);
    prefs.putSync('freezeTime', AppConfig.freezeTime);
    prefs.putSync('multiPhase', AppConfig.multiPhase);
    prefs.putSync('showStats', AppConfig.showStats);
    prefs.putSync('showScrambleImage', AppConfig.showScrambleImage);
    prefs.putSync('scrambleFontSize', AppConfig.scrambleFontSize);
    prefs.putSync('darkMode', AppConfig.darkMode);
    prefs.putSync('themeMode', AppConfig.themeMode);
    prefs.putSync('bgImageUri', AppConfig.bgImageUri);
    prefs.putSync('bgOpacity', AppConfig.bgOpacity);
    prefs.putSync('privacyAgreed', AppConfig.privacyAgreed);
    prefs.putSync('timerFont', AppConfig.timerFont);
    prefs.putSync('fontSize', AppConfig.fontSize);
    prefs.putSync('keepScreenOn', AppConfig.keepScreenOn);
    prefs.putSync('vibrateType', AppConfig.vibrateType);
    prefs.putSync('defaultCrossBottom', AppConfig.defaultCrossBottom);
    prefs.putSync('avg1Type', AppConfig.avg1Type);
    prefs.putSync('avg1Len', AppConfig.avg1Len);
    prefs.putSync('avg2Type', AppConfig.avg2Type);
    prefs.putSync('avg2Len', AppConfig.avg2Len);
    prefs.putSync('swipeType', AppConfig.swipeType.join(','));
    prefs.putSync('schemeN', DctScrambler.schemeN.join(','));
    prefs.putSync('schemeP', DctScrambler.schemeP.join(','));
    prefs.putSync('schemeW', DctScrambler.schemeW.join(','));
    prefs.putSync('schemeM', DctScrambler.schemeM.join(','));
    prefs.putSync('currentSessionIndex', this.currentSessionIndex);
    prefs.putSync('ambientEnabled', AppConfig.ambientEnabled);
    prefs.putSync('gradientId', AppConfig.gradientId);

    let sessionObjs: Record<string, Object>[] = [];
    for (let i: number = 0; i < this.sessions.length; i++) {
      sessionObjs.push(this.sessions[i].toJSON());
    }
    prefs.putSync('sessions', JSON.stringify(sessionObjs));
    prefs.flush();
  }

  /** 加载当前训练组成绩（数据库） */
  async loadSessionResults(): Promise<void> {
    if (this.result === null || this.sessions.length === 0) {
      this.results = [];
      this.updateStats();
      return;
    }
    const sid: number = this.sessions[this.currentSessionIndex].id;
    const mp: boolean = AppConfig.multiPhase > 0;
    await this.result.init(mp, sid);
    // 首次迁移：Preferences 旧数据 -> 数据库
    await this.migratePrefsResults(sid);
    this.refreshResultsDisplay();
    this.updateStats();
  }

  /** 从 Preferences JSON 迁移旧成绩到数据库（只执行一次） */
  async migratePrefsResults(sid: number): Promise<void> {
    if (this.dataPrefs === null || this.result === null || this.result.getLength() > 0) {
      return;
    }
    const key: string = 'results_' + sid;
    const json: string = this.dataPrefs.getSync(key, '') as string;
    if (json.length === 0) {
      return;
    }
    let arr: Object[] = [];
    try {
      arr = JSON.parse(json) as Object[];
    } catch (e) {
      return;
    }
    // Preferences 中索引 0 为最新成绩，逆序插入以保持时间顺序
    for (let i: number = arr.length - 1; i >= 0; i--) {
      const e: ResultEntry = ResultEntry.fromJSON(arr[i] as Record<string, Object>);
      await this.result.insert(e.time, e.penalty, e.scramble, false, null, null, 0);
      if (e.note.length > 0) {
        await this.result.updateNote(this.result.getLength() - 1, e.note);
      }
    }
    this.dataPrefs.deleteSync(key);
    this.dataPrefs.flush();
  }

  /** 由 Result（数据库源）重建 UI 展示数组（最新在前） */
  refreshResultsDisplay(): void {
    if (this.result === null) {
      this.results = [];
      return;
    }
    const arr: ResultEntry[] = [];
    for (let i: number = this.result.getLength() - 1; i >= 0; i--) {
      const e: ResultEntry = new ResultEntry();
      e.id = this.result.getId(i);
      e.time = this.result.getResultAt(i);
      e.penalty = this.result.getPenalty(i);
      e.scramble = this.result.getString(i, 4);
      e.date = ResultEntry.parseDate(this.result.getString(i, 5));
      e.note = this.result.getString(i, 6);
      e.puzzle = this.result.getPuzzle(i);
      if (AppConfig.multiPhase > 0) {
        for (let j: number = 0; j < 6; j++) {
          const p: number = this.result.getMulTime(j, i);
          if (p > 0) {
            e.phases.push(p);
          }
        }
      }
      arr.push(e);
    }
    this.results = arr;
  }

  // ===== 训练组管理 =====
  initDefaultSessions(): void {
    this.sessions = [];
    let s: Session = new Session(1);
    s.name = '组 1';
    s.puzzle = flatPuzzleCode(0);
    this.sessions.push(s);
    this.currentSessionIndex = 0;
    this.sessionName = s.name;
  }

  switchSession(index: number): void {
    if (index < 0 || index >= this.sessions.length || index === this.currentSessionIndex) {
      return;
    }
    this.currentSessionIndex = index;
    this.sessionName = this.sessions[index].name;
    // 训练组各自保存魔方类型
    let pIdx: number = -1;
    for (let i: number = 0; i < flatPuzzleCount(); i++) {
      if (flatPuzzleCode(i) === this.sessions[index].puzzle) {
        pIdx = i;
        break;
      }
    }
    if (pIdx >= 0) {
      this.currentPuzzleIndex = pIdx;
      this.puzzleButtonText = flatPuzzleName(pIdx);
    }
    this.loadSessionResults();
    this.generateScramble();
    this.saveToPreferences();
  }

  createNewSession(): void {
    if (this.sessions.length >= 15) {
      promptAction.showToast({ message: '最多支持15个训练组', duration: 2000 });
      return;
    }
    let maxId: number = 0;
    for (let i: number = 0; i < this.sessions.length; i++) {
      if (this.sessions[i].id > maxId) {
        maxId = this.sessions[i].id;
      }
    }
    let newSession: Session = new Session(maxId + 1);
    newSession.name = '组 ' + (maxId + 1);
    newSession.puzzle = flatPuzzleCode(this.currentPuzzleIndex);
    this.sessions.push(newSession);
    this.currentSessionIndex = this.sessions.length - 1;
    this.sessionName = newSession.name;
    this.loadSessionResults();
    this.saveToPreferences();
  }

  showSessionDialog(): void {
    this.sessionDialog = new CustomDialogController({
      builder: SessionSelectDialog({
        sessions: this.sessions,
        currentIdx: this.currentSessionIndex,
        bottomInset: this.bottomSafeInset,
        onSelect: (index: number): void => { this.switchSession(index); },
        onNew: (): void => { this.createNewSession(); }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Bottom,
      customStyle: true
    });
    this.sessionDialog.open();
  }

  // ===== 统计更新（忠实移植 Stats.java）=====
  updateStats(): void {
    if (this.result === null) {
      return;
    }
    let len: number = this.result.getLength();
    if (len === 0) {
      this.bestText = '--';
      this.avg1Text = '--';
      this.avg2Text = '--';
      this.sessionMeanText = '平均(0/0): -- (σ = --)';
      this.statText = '(0/0)\n最佳: --\n' + this.getAvgLabel(AppConfig.avg1Type, AppConfig.avg1Len) + ': --\n' +
        this.getAvgLabel(AppConfig.avg2Type, AppConfig.avg2Len) + ': --';
      this.minIdx = -1;
      this.maxIdx = -1;
      return;
    }

    this.result.calcAvg();
    this.result.getSessionMean();
    this.minIdx = this.result.getMinIdx();
    this.maxIdx = this.result.getMaxIdx();
    this.bestText = this.result.getBestTime();
    this.avg1Text = this.result.getRollingAvg1(len - 1);
    this.avg2Text = this.result.getRollingAvg2(len - 1);
    this.sessionMeanText = '平均' + this.result.getSessionMean();
    this.statText = '(' + len + '/' + len + ')\n最佳: ' + this.bestText + '\n' +
      this.getAvgLabel(AppConfig.avg1Type, AppConfig.avg1Len) + ': ' + this.avg1Text + '\n' +
      this.getAvgLabel(AppConfig.avg2Type, AppConfig.avg2Len) + ': ' + this.avg2Text;
  }

  getAvgLabel(avgType: number, avgLen: number): string {
    return (avgType === 0 ? '平均' : '均值') + avgLen;
  }

  // ===== 打乱生成 =====
  // 四阶（四速/四盲）已改用与五阶同思路的随机步生成（scramble444，瞬时完成）；
  // threephase random-state 三阶段在 ArkTS 上需数十秒，已弃用（详见 HANDOVER 7.6-19）。
  generateScramble(): void {
    const puzzleCode: number = flatPuzzleCode(this.currentPuzzleIndex);
    const category: number = toDctimerCategory(puzzleCode);
    gScrambler.generateScramble(category, true);
    this.scramble = gScrambler.getScramble();
  }

  switchPuzzle(delta: number): void {
    let newIdx: number = this.currentPuzzleIndex + delta;
    if (newIdx < 0) {
      newIdx = flatPuzzleCount() - 1;
    }
    if (newIdx >= flatPuzzleCount()) {
      newIdx = 0;
    }
    this.currentPuzzleIndex = newIdx;
    this.puzzleButtonText = flatPuzzleName(newIdx);
    // 记录到当前训练组
    if (this.sessions.length > 0) {
      this.sessions[this.currentSessionIndex].puzzle = flatPuzzleCode(newIdx);
    }
    this.generateScramble();
    this.saveToPreferences();
  }

  // ===== 魔方类型下拉面板 =====
  togglePuzzleDropdown(): void {
    this.showPuzzleDropdown = !this.showPuzzleDropdown;
    if (this.showPuzzleDropdown) {
      // 默认显示当前选中项所在的分类
      const cur: FlattenResult = unflattenIndex(this.currentPuzzleIndex);
      this.dropdownCategoryIdx = cur.catIdx;
    }
  }

  closePuzzleDropdown(): void {
    this.showPuzzleDropdown = false;
  }

  selectCategory(catIdx: number): void {
    this.dropdownCategoryIdx = catIdx;
  }

  selectPuzzleItem(catIdx: number, itemIdx: number): void {
    const flatIdx: number = flattenIndex(catIdx, itemIdx);
    this.currentPuzzleIndex = flatIdx;
    this.puzzleButtonText = flatPuzzleName(flatIdx);
    if (this.sessions.length > 0) {
      this.sessions[this.currentSessionIndex].puzzle = flatPuzzleCode(flatIdx);
    }
    this.showPuzzleDropdown = false;
    this.generateScramble();
    this.saveToPreferences();
  }

  currentPuzzleCategoryIdx(): number {
    return unflattenIndex(this.currentPuzzleIndex).catIdx;
  }

  currentPuzzleItemIdxInCategory(): number {
    return unflattenIndex(this.currentPuzzleIndex).itemIdx;
  }

  // ===== BLE 智能魔方 ====
  initBleCallbacks(): void {
    bleManager.setMoveCallback((move: CubeMove): void => {
      this.onCubeMove(move);
    });
  }

  onCubeMove(move: CubeMove): void {
    if (this.timerState === TimerState.RUNNING) {
      this.dct.count();
      if (this.dct.state === TimerState.STOP) {
        this.vibrateOnStop();
        let penalty: number = this.dct.isDNF ? 2 : (this.dct.penaltyTime > 0 ? 1 : 0);
        this.saveResult(penalty);
      }
    }
  }

  openBleScanner(): void {
    this.bleDialog = new CustomDialogController({
      builder: BleScanDialog({
        onConnected: (address: string, name: string): void => {
          this.bleConnected = true;
          this.bleDeviceName = name;
          this.bleStatusText = '已连接: ' + name;
          this.smartCubeConnected = true;
          this.smartCubeFacelets = SmartCubeOrientation.SOLVED_FACELET;
          AppConfig.bleDeviceAddress = address;
          AppConfig.bleDeviceName = name;
          this.saveToPreferences();
          this.initSettings();
        },
        onCubeMove: (move: CubeMove): void => {
          if (!this.smartCubeConnected) {
            return;
          }
          this.smartCubeFacelets = SmartCubeOrientation.rotateMoveFacelets(
            this.smartCubeFacelets, move.face, move.direction);
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center
    });
    this.bleDialog.open();
  }

  disconnectBle(): void {
    bleManager.disconnect();
    this.bleConnected = false;
    this.bleDeviceName = '';
    this.bleStatusText = '未连接';
    this.smartCubeConnected = false;
    this.smartCubeFacelets = SmartCubeOrientation.SOLVED_FACELET;
    AppConfig.bleDeviceAddress = '';
    AppConfig.bleDeviceName = '';
    this.saveToPreferences();
    this.initSettings();
  }

  // ===== 十字求解器 =====
  openCrossSolver(): void {
    this.showSolver = true;
  }

  closeSolver(): void {
    this.showSolver = false;
  }

  // ===== 背景图片选择 =====
  /** 删除沙箱内旧背景文件（仅限应用 filesDir 下的 bg_image 前缀文件） */
  deleteBgFile(uri: string): void {
    if (uri.length === 0) {
      return;
    }
    try {
      const prefix: string = 'file://' + getContext(this).filesDir + '/bg_image';
      if (uri.startsWith(prefix)) {
        fileIo.unlinkSync(uri.substring('file://'.length));
      }
    } catch (err) {
      // 文件不存在时忽略
    }
  }

  async pickBackgroundImage(): Promise<void> {
    try {
      const photoPicker: photoAccessHelper.PhotoViewPicker =
        new photoAccessHelper.PhotoViewPicker();
      const result: photoAccessHelper.PhotoSelectResult = await photoPicker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      });
      if (result && result.photoUris && result.photoUris.length > 0) {
        // 打开裁剪对话框：拖动定位 + 双指缩放，确认后生效
        this.bgCropSrcUri = result.photoUris[0];
        this.showBgCrop = true;
      }
    } catch (err) {
      // 用户取消
    }
  }

  /** 裁剪确认：使用唯一文件名保存，URI 变化驱动界面立即刷新 */
  onBgCropConfirm(path: string): void {
    this.deleteBgFile(AppConfig.bgImageUri);
    const localPath: string = 'file://' + path;
    this.bgImageUri = localPath;
    BackgroundManager.setImageUri(localPath);
    AppConfig.bgImageUri = localPath;
    this.showBgCrop = false;
    this.initSettings();
    this.saveToPreferences();
  }

  clearBackgroundImage(): void {
    this.deleteBgFile(this.bgImageUri);
    this.bgImageUri = '';
    BackgroundManager.clearImage();
    AppConfig.bgImageUri = '';
    this.saveToPreferences();
  }

  onBgOpacityChange(value: number): void {
    this.bgOpacity = value;
    BackgroundManager.setOpacity(value);
    AppConfig.bgOpacity = value;
    this.saveToPreferences();
  }

  // ===== 计时器触摸交互 =====
  onTimerTouchDown(event: TouchEvent): void {
    let touch: TouchObject = event.touches[0];
    this.touchStartX = touch.x;
    this.touchStartY = touch.y;
    this.stoppedOnThisTouch = false;

    if (this.timerState === TimerState.RUNNING) {
      this.dct.count();
      if (this.dct.state === TimerState.STOP) {
        this.vibrateOnStop();
        this.stoppedOnThisTouch = true;
        this.timerColor = themeText(this.isDark);
        this.timerState = TimerState.STOP;
        this.showResultConfirmDialog();
      }
    } else if (this.timerState === TimerState.READY) {
      if (AppConfig.wcaInspection) {
        this.dct.startInspection();
        this.timerState = TimerState.INSPECTING;
        this.timerColor = COLOR_INSPECTING;
        this.timerText = '15';
        this.inspectionText = '15';
      } else {
        this.timerColor = COLOR_READY;
        this.dct.canStart = true;
      }
    } else if (this.timerState === TimerState.INSPECTING) {
      this.timerColor = COLOR_READY;
      this.dct.canStart = true;
    } else if (this.timerState === TimerState.STOP) {
      // 等待确认对话框，不响应触摸
    }
  }

  onTimerTouchUp(event: TouchEvent): void {
    if (this.freezeTimerId !== -1) {
      clearTimeout(this.freezeTimerId);
      this.freezeTimerId = -1;
    }

    let changedList: TouchObject[] = event.changedTouches;
    if (changedList.length === 0) {
      return;
    }
    let touch: TouchObject = changedList[0];
    let deltaX: number = touch.x - this.touchStartX;
    let deltaY: number = touch.y - this.touchStartY;

    if (this.timerState === TimerState.READY && this.dct.canStart) {
      if (Math.abs(deltaX) > 40 || Math.abs(deltaY) > 40) {
        this.handleSwipeGesture(deltaX, deltaY);
        return;
      }
      this.startRunning();
    } else if (this.timerState === TimerState.INSPECTING && this.dct.canStart) {
      if (Math.abs(deltaX) > 40 || Math.abs(deltaY) > 40) {
        this.handleSwipeGesture(deltaX, deltaY);
        return;
      }
      this.startRunning();
    } else {
      if (this.timerState === TimerState.READY || this.timerState === TimerState.INSPECTING) {
        this.timerColor = themeText(this.isDark);
        this.dct.canStart = false;
      }
    }
    this.stoppedOnThisTouch = false;
  }

  startRunning(): void {
    this.dct.reset();
    this.dct.setPhases(AppConfig.multiPhase);
    this.dct.count();
    this.timerState = TimerState.RUNNING;
    this.timerColor = themeText(this.isDark);
    this.inspectionText = '';
    this.resultPenalty = -1;
    this.vibrateOnStart();
  }

  handleSwipeGesture(deltaX: number, deltaY: number): void {
    let absX: number = Math.abs(deltaX);
    let absY: number = Math.abs(deltaY);

    if (absX > absY) {
      if (deltaX < 0) {
        this.performSwipeAction(AppConfig.swipeType[0]); // 左滑
      } else {
        this.performSwipeAction(AppConfig.swipeType[1]); // 右滑
      }
    } else {
      if (deltaY < 0) {
        this.performSwipeAction(AppConfig.swipeType[2]); // 上滑
      } else {
        this.performSwipeAction(AppConfig.swipeType[3]); // 下滑
      }
    }
    this.dct.canStart = false;
    this.timerColor = themeText(this.isDark);
  }

  performSwipeAction(actionType: number): void {
    switch (actionType) {
      case SWIPE_DELETE_LAST:
        this.deleteLastResult();
        break;
      case SWIPE_NEW_SCRAMBLE:
        this.generateScramble();
        break;
      case SWIPE_CHANGE_PENALTY:
        this.changeLastPenalty();
        break;
      case SWIPE_MANUAL_INPUT:
        this.showManualInput();
        break;
      default:
        break;
    }
  }

  deleteLastResult(): void {
    if (this.result !== null && this.result.getLength() > 0) {
      this.result.delete(this.result.getLength() - 1).then((): void => {
        this.refreshResultsDisplay();
        this.updateStats();
      });
      promptAction.showToast({ message: '已删除上次成绩', duration: 1500 });
    }
  }

  changeLastPenalty(): void {
    if (this.result === null || this.result.getLength() === 0) {
      return;
    }
    const lastIdx: number = this.result.getLength() - 1;
    const next: number = (this.result.getPenalty(lastIdx) + 1) % 3;
    this.result.updatePenalty(lastIdx, next).then((): void => {
      this.refreshResultsDisplay();
      this.updateStats();
      let msg: string = '已标记 +2';
      if (next === 2) {
        msg = '已标记 DNF';
      } else if (next === 0) {
        msg = '已取消惩罚';
      }
      promptAction.showToast({ message: msg, duration: 1500 });
    });
  }

  showManualInput(): void {
    this.manualInputDialog = new CustomDialogController({
      builder: ManualInputDialog({
        onConfirm: (timeStr: string): void => { this.onManualInputConfirm(timeStr); }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      customStyle: true
    });
    this.manualInputDialog.open();
  }

  onManualInputConfirm(timeStr: string): void {
    // 忠实移植：StringUtils.parseManualInputTime（毫秒）
    const timeMs: number = StringUtils.parseManualInputTime(timeStr);
    if (timeMs < 0) {
      promptAction.showToast({ message: '格式错误，请使用 秒.厘秒 格式', duration: 2000 });
      return;
    }
    if (this.result === null) {
      return;
    }
    this.result.insert(timeMs, 0, this.scramble, AppConfig.multiPhase > 0, null, null,
      flatPuzzleCode(this.currentPuzzleIndex)).then((): void => {
      this.refreshResultsDisplay();
      this.updateStats();
      this.dct.reset();
      this.timerState = TimerState.READY;
      this.timerText = '0.00';
      this.timerColor = themeText(this.isDark);
      this.generateScramble();
    });
  }

  // ===== 保存成绩 =====
  saveResult(penalty: number): void {
    if (this.result === null) {
      return;
    }
    // 分段计时：multemp[j] = 前 j 段累计用时（addResult 取差值即各段时长）
    if (AppConfig.multiPhase > 0 && this.dct.phaseTimes.length > 0) {
      Result.multemp[0] = 0;
      for (let i: number = 0; i < this.dct.phaseTimes.length; i++) {
        Result.multemp[i + 1] = Result.multemp[i] + this.dct.phaseTimes[i];
      }
    }
    this.result.insert(this.dct.time, penalty, this.scramble, AppConfig.multiPhase > 0, null, null,
      flatPuzzleCode(this.currentPuzzleIndex)).then((): void => {
      this.refreshResultsDisplay();
      this.updateStats();
    });
    // 保留计时器显示最终成绩
    this.resultPenalty = penalty;
    if (penalty === 2) {
      this.timerText = 'DNF';
    } else if (penalty === 1) {
      this.timerText = StringUtils.timeToString(this.dct.time + 2000);
    } else {
      this.timerText = StringUtils.timeToString(this.dct.time);
    }
    this.timerColor = themeText(this.isDark);
    this.dct.reset();
    this.timerState = TimerState.READY;
    this.generateScramble();
  }

  discardPendingResult(): void {
    this.dct.reset();
    this.timerState = TimerState.READY;
    this.timerText = '0.00';
    this.timerColor = themeText(this.isDark);
    this.resultPenalty = -1;
  }

  showResultConfirmDialog(): void {
    let initialPenalty: number = this.dct.isDNF ? 2 : (this.dct.penaltyTime > 0 ? 1 : 0);
    this.confirmDialog = new CustomDialogController({
      builder: ResultConfirmDialog({
        resultTime: this.dct.time,
        resultPenalty: initialPenalty,
        scramble: this.scramble,
        accuracy: AppConfig.timerAccuracy,
        onConfirm: (penalty: number): void => {
          this.saveResult(penalty);
        },
        onCancel: (): void => {
          this.discardPendingResult();
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      customStyle: true,
      cancel: (): void => {
        this.discardPendingResult();
      }
    });
    this.confirmDialog.open();
  }

  // ===== 成绩操作 =====
  showResultAction(displayIndex: number): void {
    let realIdx: number = this.results.length - 1 - displayIndex;
    if (realIdx < 0 || realIdx >= this.results.length) {
      return;
    }
    // 使用成绩自身记录的项目绘制打乱图；旧数据无记录(0)时回退到当前项目
    const entryPuzzle: number = this.results[displayIndex].puzzle;
    const code: number = entryPuzzle > 0 ? entryPuzzle : flatPuzzleCode(this.currentPuzzleIndex);
    this.resultDetailDialog = new CustomDialogController({
      builder: ResultDetailDialog({
        resultIndex: realIdx,
        displayNo: displayIndex + 1,
        resultEntry: this.results[displayIndex],
        puzzleCode: code,
        puzzleSize: puzzleImageSize(code),
        schemeVersion: this.schemeVersion,
        onPenaltyChange: (index: number, penalty: number): void => {
          if (this.result === null) {
            return;
          }
          this.result.updatePenalty(index, penalty).then((): void => {
            this.refreshResultsDisplay();
            this.updateStats();
          });
        },
        onNoteChange: (index: number, note: string): void => {
          if (this.result === null) {
            return;
          }
          this.result.updateNote(index, note).then((): void => {
            this.refreshResultsDisplay();
          });
        },
        onDelete: (index: number): void => { this.onResultDelete(index); },
        onCopyScramble: (scramble: string): void => { this.copyScrambleToClipboard(scramble); }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      customStyle: true
    });
    this.resultDetailDialog.open();
  }

  copyScrambleToClipboard(scramble: string): void {
    const pb: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
    pb.setData(pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, scramble)).then((): void => {
      promptAction.showToast({ message: '已复制打乱', duration: 1500 });
    }).catch((): void => {
      promptAction.showToast({ message: '复制失败', duration: 1500 });
    });
  }

  onResultPlusTwo(index: number): void {
    if (this.result === null) {
      return;
    }
    const newP: number = this.result.getPenalty(index) === 2 ? 2 : 1;
    this.result.updatePenalty(index, newP).then((): void => {
      this.refreshResultsDisplay();
      this.updateStats();
    });
  }

  showExportDialog(): void {
    if (this.results.length === 0) {
      AlertDialog.show({
        title: '提示',
        message: '暂无成绩可导出',
        confirm: { value: '确定', action: (): void => {} },
        alignment: DialogAlignment.Center
      });
      return;
    }
    let csvData: string = ExportUtil.toCsv(this.results, this.sessionName);
    this.exportDialog = new CustomDialogController({
      builder: ExportDialog({
        csvData: csvData,
        sessionName: this.sessionName
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      customStyle: true
    });
    this.exportDialog.open();
  }

  onResultDNF(index: number): void {
    if (this.result === null) {
      return;
    }
    this.result.updatePenalty(index, 2).then((): void => {
      this.refreshResultsDisplay();
      this.updateStats();
    });
  }

  onResultUndoPenalty(index: number): void {
    if (this.result === null) {
      return;
    }
    this.result.updatePenalty(index, 0).then((): void => {
      this.refreshResultsDisplay();
      this.updateStats();
    });
  }

  onResultDelete(index: number): void {
    if (this.result === null) {
      return;
    }
    AlertDialog.show({
      title: '确认删除',
      message: '确定要删除这条成绩吗？',
      primaryButton: {
        value: '取消',
        action: (): void => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: COLOR_WORST,
        action: (): void => {
          if (this.result !== null) {
            this.result.delete(index).then((): void => {
              this.refreshResultsDisplay();
              this.updateStats();
            });
          }
        }
      },
      alignment: DialogAlignment.Center
    });
  }

  clearAllResults(): void {
    if (this.result === null || this.result.getLength() === 0) {
      return;
    }
    AlertDialog.show({
      title: '确认清除',
      message: '确定要清除当前训练组的所有成绩吗？',
      primaryButton: {
        value: '取消',
        action: (): void => {}
      },
      secondaryButton: {
        value: '清除',
        fontColor: COLOR_WORST,
        action: (): void => {
          if (this.result !== null) {
            this.result.clear().then((): void => {
              this.refreshResultsDisplay();
              this.updateStats();
            });
          }
        }
      },
      alignment: DialogAlignment.Center
    });
  }

  // ===== 设置 =====
  initSettings(): void {
    this.settingSections = [
      {
        title: '计时器', items: [
          { id: 1, title: 'WCA 观察', detail: '', type: 1, value: AppConfig.wcaInspection },
          { id: 2, title: '观察振动提醒', detail: '8秒/12秒时振动提醒', type: 1, value: AppConfig.inspectionAlert },
          { id: 3, title: '计时精度', detail: AppConfig.timerAccuracy === 0 ? '厘秒 (0.00)' : '毫秒 (0.000)', type: 0, value: false },
          { id: 4, title: '计时方式', detail: this.getEnterTimeDesc(), type: 0, value: false },
          { id: 6, title: '启动延时', detail: AppConfig.freezeTime === 0 ? '无' : (AppConfig.freezeTime * 50 + 'ms'), type: 0, value: false },
          { id: 7, title: '分段计时', detail: AppConfig.multiPhase === 0 ? '关' : (AppConfig.multiPhase + '段'), type: 0, value: false },
          { id: 8, title: '显示统计', detail: '', type: 1, value: AppConfig.showStats }
        ]
      },
      {
        title: '打乱', items: [
          { id: 21, title: '打乱字体大小', detail: AppConfig.scrambleFontSize + 'sp', type: 0, value: false },
          { id: 22, title: '显示打乱图', detail: '', type: 1, value: AppConfig.showScrambleImage }
        ]
      },
      {
        title: '统计', items: [
          { id: 31, title: '滚动平均1', detail: this.getAvgDesc(AppConfig.avg1Type, AppConfig.avg1Len), type: 0, value: false },
          { id: 32, title: '滚动平均2', detail: this.getAvgDesc(AppConfig.avg2Type, AppConfig.avg2Len), type: 0, value: false }
        ]
      },
      {
        title: '配色', items: [
          { id: 81, title: 'NxNxN 魔方', detail: '打乱图配色', type: 0, value: false },
          { id: 82, title: '金字塔', detail: '打乱图配色', type: 0, value: false },
          { id: 83, title: '斜转', detail: '打乱图配色', type: 0, value: false },
          { id: 84, title: '五魔方', detail: '打乱图配色', type: 0, value: false }
        ]
      },
      {
        title: '界面', items: [
          { id: 41, title: '计时器字体', detail: AppConfig.timerFont === 0 ? 'LCD 数码管' : '系统字体', type: 0, value: false },
          { id: 42, title: '计时器大小', detail: AppConfig.fontSize + 'sp', type: 0, value: false },
          { id: 43, title: '选择背景图片', detail: AppConfig.bgImageUri.length > 0 ? '已设置' : '未设置', type: 0, value: false },
          { id: 44, title: '背景透明度', detail: AppConfig.bgOpacity + '%', type: 2, value: false },
          { id: 45, title: '深色模式', detail: this.themeModeDesc(), type: 0, value: false },
          // 沉浸光感（HarmonyOS 7 系统材质）。设备不支持时置灰不可点，避免用户开了没反应。
          { id: 46, title: '沉浸光感', detail: this.ambientUsable ? '顶栏/弹窗半透明模糊' : '当前设备不支持',
            type: 1, value: AppConfig.ambientEnabled && this.ambientUsable },
          { id: 47, title: '光感配色', detail: findScheme(AppConfig.gradientId).name, type: 0, value: false }
        ]
      },
      {
        title: '手势', items: [
          { id: 51, title: '左滑手势', detail: this.getSwipeDesc(AppConfig.swipeType[0]), type: 0, value: false },
          { id: 52, title: '右滑手势', detail: this.getSwipeDesc(AppConfig.swipeType[1]), type: 0, value: false },
          { id: 53, title: '上滑手势', detail: this.getSwipeDesc(AppConfig.swipeType[2]), type: 0, value: false },
          { id: 54, title: '下滑手势', detail: this.getSwipeDesc(AppConfig.swipeType[3]), type: 0, value: false }
        ]
      },
      {
        title: '硬件', items: [
          { id: 61, title: '屏幕常亮', detail: '', type: 1, value: AppConfig.keepScreenOn },
          { id: 62, title: '触感反馈', detail: this.getVibrateDesc(), type: 0, value: false }
          // 智能魔方(id=63)已从设置中移除，保留代码后续再接入
        ]
      },
      {
        title: '求解器', items: [
          { id: 71, title: '默认十字底面', detail: this.getCrossBottomDesc(), type: 0, value: false }
        ]
      },
      {
        title: '关于', items: [
          { id: 50, title: '隐私政策', detail: '', type: 0, value: false }
        ]
      }
    ];
  }

  // 从 Preferences 恢复打乱图配色（逗号分隔 ARGB，长度不符/为空则保留默认）
  loadColorSchemes(prefs: dataPreferences.Preferences): void {
    const apply = (key: string, arr: number[]): void => {
      const raw: string = prefs.getSync(key, '') as string;
      if (raw.length === 0) {
        return;
      }
      const parts: string[] = raw.split(',');
      for (let i = 0; i < arr.length && i < parts.length; i++) {
        const v: number = parseInt(parts[i]);
        if (!isNaN(v)) {
          arr[i] = v;
        }
      }
    };
    apply('schemeN', DctScrambler.schemeN);
    apply('schemeP', DctScrambler.schemeP);
    apply('schemeW', DctScrambler.schemeW);
    apply('schemeM', DctScrambler.schemeM);
  }

  // 配色编辑器确定回调：写回 Scrambler 静态配色表（打乱图立即生效），
  // bump schemeVersion 驱动所有 ScrambleImageView 重绘，并持久化。
  onSchemeConfirm(kind: number, colors: number[]): void {
    if (kind === 0) {
      for (let i = 0; i < 6 && i < colors.length; i++) {
        DctScrambler.schemeN[i] = colors[i];
      }
    } else if (kind === 1) {
      for (let i = 0; i < 4 && i < colors.length; i++) {
        DctScrambler.schemeP[i] = colors[i];
      }
    } else if (kind === 2) {
      for (let i = 0; i < 6 && i < colors.length; i++) {
        DctScrambler.schemeW[i] = colors[i];
      }
    } else {
      for (let i = 0; i < 12 && i < colors.length; i++) {
        DctScrambler.schemeM[i] = colors[i];
      }
    }
    this.schemeVersion++;
    this.saveToPreferences();
  }

  getEnterTimeDesc(): string {
    let descs: string[] = ['触屏', '手动', 'Stackmat', '智能魔方'];
    return descs[AppConfig.enterTime];
  }

  getCrossBottomDesc(): string {
    const descs: string[] = ['白底', '黄底', '橙底', '红底', '绿底', '蓝底'];
    const idx: number = Math.max(0, Math.min(5, AppConfig.defaultCrossBottom));
    return descs[idx];
  }

  getAvgDesc(avgType: number, avgLen: number): string {
    let prefix: string = avgType === 0 ? '平均' : '均值';
    return prefix + avgLen;
  }

  getSwipeDesc(swipeType: number): string {
    let descs: string[] = ['无', '删除上次', '新打乱', '改惩罚', '无', '手动输入'];
    return descs[swipeType];
  }

  getVibrateDesc(): string {
    let descs: string[] = ['关', '开始', '停止', '都开'];
    return descs[AppConfig.vibrateType];
  }

  onSettingToggle(id: number, value: boolean): void {
    switch (id) {
      case 1: AppConfig.wcaInspection = value; break;
      case 2: AppConfig.inspectionAlert = value; break;
      case 8: AppConfig.showStats = value; break;
      case 22: AppConfig.showScrambleImage = value; break;
      case 61:
        AppConfig.keepScreenOn = value;
        this.applyKeepScreenOn();
        break;
      default: break;
    }
    this.initSettings();
    this.saveToPreferences();
  }

  onSettingTextClick(id: number): void {
    switch (id) {
      case 3:
        AppConfig.timerAccuracy = AppConfig.timerAccuracy === 0 ? 1 : 0;
        AppGlobals.timerAccuracy = AppConfig.timerAccuracy;
        this.timerText = StringUtils.timeToString(this.dct.time);
        this.updateStats();
        break;
      case 4:
        AppConfig.enterTime = (AppConfig.enterTime + 1) % 2; // 触屏/手动循环（Stackmat/智能魔方需硬件）
        break;
      case 6:
        AppConfig.freezeTime = (AppConfig.freezeTime + 1) % 4;
        break;
      case 7:
        AppConfig.multiPhase = (AppConfig.multiPhase + 1) % 4;
        this.loadSessionResults();
        break;
      case 21: {
        let sizes: number[] = [12, 14, 16, 18, 20, 24];
        let idx: number = sizes.indexOf(AppConfig.scrambleFontSize);
        AppConfig.scrambleFontSize = sizes[(idx + 1) % sizes.length];
        this.scrambleFontSize = AppConfig.scrambleFontSize;
        break;
      }
      case 31: {
        // 长度循环 3/5/12/50/100，到头后切换 ao/mo
        let lens: number[] = [3, 5, 12, 50, 100];
        let idx: number = lens.indexOf(AppConfig.avg1Len);
        if (idx === lens.length - 1) {
          AppConfig.avg1Len = lens[0];
          AppConfig.avg1Type = AppConfig.avg1Type === 0 ? 1 : 0;
        } else {
          AppConfig.avg1Len = lens[(idx + 1) % lens.length];
        }
        this.updateStats();
        break;
      }
      case 32: {
        let lens: number[] = [3, 5, 12, 50, 100];
        let idx: number = lens.indexOf(AppConfig.avg2Len);
        if (idx === lens.length - 1) {
          AppConfig.avg2Len = lens[0];
          AppConfig.avg2Type = AppConfig.avg2Type === 0 ? 1 : 0;
        } else {
          AppConfig.avg2Len = lens[(idx + 1) % lens.length];
        }
        this.updateStats();
        break;
      }
      case 41:
        AppConfig.timerFont = AppConfig.timerFont === 0 ? 1 : 0;
        break;
      case 42: {
        let sizes: number[] = [48, 60, 72, 84, 96, 110];
        let idx: number = sizes.indexOf(AppConfig.fontSize);
        AppConfig.fontSize = sizes[(idx + 1) % sizes.length];
        this.timerFontSize = AppConfig.fontSize;
        break;
      }
      case 51:
        AppConfig.swipeType[0] = (AppConfig.swipeType[0] % 5) + 1;
        break;
      case 52:
        AppConfig.swipeType[1] = (AppConfig.swipeType[1] % 5) + 1;
        break;
      case 53:
        AppConfig.swipeType[2] = (AppConfig.swipeType[2] % 5) + 1;
        break;
      case 54:
        AppConfig.swipeType[3] = (AppConfig.swipeType[3] % 5) + 1;
        break;
      case 62:
        AppConfig.vibrateType = (AppConfig.vibrateType + 1) % 4;
        break;
      case 43:
        this.pickBackgroundImage(); // 异步
        return; // pickBG 自己会调 initSettings
      case 71:
        AppConfig.defaultCrossBottom = (AppConfig.defaultCrossBottom + 1) % 6;
        break;
      case 45:
        AppConfig.themeMode = (AppConfig.themeMode + 1) % 3;
        this.applyEffectiveDark(true);
        break;
      case 46:
        // 开关：点一下切换，不支持材质的设备不允许开
        if (!this.ambientUsable) {
          return;
        }
        AppConfig.ambientEnabled = !AppConfig.ambientEnabled;
        this.ambientOn = AppConfig.ambientEnabled;
        break;
      case 47:
        // 循环切换内置渐变
        for (let i = 0; i < GRADIENT_SCHEMES.length; i++) {
          if (GRADIENT_SCHEMES[i].id === AppConfig.gradientId) {
            AppConfig.gradientId = GRADIENT_SCHEMES[(i + 1) % GRADIENT_SCHEMES.length].id;
            break;
          }
        }
        this.gradientId = findScheme(AppConfig.gradientId).id;
        break;
      case 81:
      case 82:
      case 83:
      case 84:
        this.schemeKind = id - 81;
        this.showColorScheme = true;
        return; // 配色编辑器自己管理（确定时才持久化）
      case 50:
        this.openPrivacyPolicy();
        return; // 隐私政策对话框自己管理
      default:
        return;
    }
    this.initSettings();
    this.saveToPreferences();
  }

  // ===== 成绩颜色计算 =====
  calcAvg(which: number, displayIdx: number): string {
    if (this.result === null) {
      return '--';
    }
    const realIdx: number = this.result.getLength() - 1 - displayIdx;
    if (which === 0) {
      return this.result.getRollingAvg1(realIdx);
    }
    return this.result.getRollingAvg2(realIdx);
  }

  getResultNumColor(displayIdx: number): string {
    let realIdx: number = this.results.length - 1 - displayIdx;
    if (realIdx === this.minIdx) {
      return COLOR_BEST;
    }
    if (realIdx === this.maxIdx && this.results.length > 1) {
      return COLOR_WORST;
    }
    return themeText(this.isDark);
  }

  getResultTimeColor(displayIdx: number, item: ResultEntry): string {
    let realIdx: number = this.results.length - 1 - displayIdx;
    if (item.isDnf()) {
      return COLOR_WORST;
    }
    if (item.penalty === 1) {
      return COLOR_WORST;
    }
    if (realIdx === this.minIdx) {
      return COLOR_BEST;
    }
    if (realIdx === this.maxIdx && this.results.length > 1) {
      return COLOR_WORST;
    }
    return themeText(this.isDark);
  }

  getAvgColor(displayIdx: number): string {
    let realIdx: number = this.results.length - 1 - displayIdx;
    if (realIdx === this.minIdx) {
      return this.isDark ? COLOR_AVG_BEST_DARK : COLOR_AVG_BEST;
    }
    return themeText(this.isDark);
  }

  getResultRowBg(displayIdx: number): string {
    let hasBg: boolean = this.bgImageUri.length > 0;
    if (displayIdx % 2 === 0) {
      return contentBg(this.isDark, hasBg, this.ambientActive());
    }
    return itemBg(this.isDark, hasBg, this.ambientActive());
  }

  // ===== 主界面构建 =====
  build() {
    Stack() {
      // 打底（光感的必要性）：系统材质是靠模糊「背后的内容」出效果的，
      // 纯色背景模糊出来还是一块纯色，等于没开。所以没设自定义背景时，
      // 铺一层内置渐变当素材，让顶栏/底部栏/弹窗有东西可模糊。
      if (this.showAmbientBackdrop()) {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({ angle: this.ambientAngle(), colors: this.ambientColors() })
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
      }

      // 背景图层 — 沉浸式下铺满整个屏幕（含状态栏与手势条区域）
      if (this.bgImageUri.length > 0) {
        Image(this.bgImageUri)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .opacity(this.bgOpacity / 100)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
      }

      // 主内容
      Column() {
        // 顶部 TabBar — 计时运行时隐藏
        if (this.timerState !== TimerState.RUNNING) {
          Row() {
            TabButton({ iconId: 'stopwatch', selected: this.currentTab === 0, isDark: this.isDark, onTabClick: (): void => { this.currentTab = 0; } })
            TabButton({ iconId: 'list', selected: this.currentTab === 1, isDark: this.isDark, onTabClick: (): void => { this.currentTab = 1; } })
            TabButton({ iconId: 'gear', selected: this.currentTab === 2, isDark: this.isDark, onTabClick: (): void => { this.currentTab = 2; } })
          }
          .width('100%')
          .height(48)
          .systemMaterial(this.ambientActive() ? barMaterial(true) : undefined)
          // 注意：材质生效时不能写 backgroundColor（连 Transparent 也不行），
          // 否则会把材质盖掉、变成完全透视。只有回退纯色时才给底色。
          .backgroundColor(this.ambientActive() ? undefined : contentBg(this.isDark, this.bgImageUri.length > 0));        }

        // 内容区域
        if (this.currentTab === 0) {
          this.TimerTab()
        } else if (this.currentTab === 1) {
          this.ResultTab()
        } else {
          this.SettingsTab()
        }
      }
      .width('100%')
      .height('100%')
      // 沉浸式布局：顶部避开状态栏、底部避开手势条/导航栏。
      // 底部按 28vp 兜底，保证底栏控件距屏幕底边不小于 28vp（审核问题2）。
      .padding({ top: this.topSafeInset, bottom: this.bottomSafeInset });

      // 求解器半屏弹窗
      if (this.showSolver) {
        Column() {
          // 遮罩
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.4)')
        .onClick((): void => { this.closeSolver(); });
        Column() {
          Row() {
            Text('魔方求解器')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isDark ? '#e8e8e8' : '#000000')
              .layoutWeight(1);
            Button('关闭')
              .fontSize(14)
              .fontColor(COLOR_ACCENT)
              .backgroundColor(Color.Transparent)
              .onClick((): void => { this.closeSolver(); });
          }
          .width('100%')
          .margin({ bottom: 8 });

          // 求解器（三阶：十字/CFOP/桥式/ZZ/Petrus；二阶/金字塔/SQ1 各自页签）：
          // 填满弹窗剩余高度，组件内部按该高度自适应滚动
          MethodSolverView({
            scramble: this.scramble,
            isDark: this.isDark,
            puzzleCode: flatPuzzleCode(this.currentPuzzleIndex)
          })
            .layoutWeight(1);
        }
        // 弹窗整体限高 80%，内部组件按剩余高度滚动；此前弹窗随内容无限增高，
        // 超出屏幕的底部（完整解法公式）被直接裁掉，导致"公式显示不全"。
        .width('100%')
        .height('80%')
        .borderRadius({ topLeft: 16, topRight: 16 })
        // 底部垫高安全区，避免弹窗内容被手势条遮挡（审核问题2）
        .padding({ left: 20, right: 20, top: 20, bottom: 20 + this.bottomSafeInset })
        // 弹窗用 backdropBlur + 显式半透明底色，而不是 systemMaterial / backgroundBlurStyle：
        // - systemMaterial 与 backgroundColor 互斥，写在一起弹窗会变全透视、内容重叠（实测）；
        // - backgroundBlurStyle 的 COMPONENT_* 档位自带浅色材质，深色模式下弹窗会变浅灰
        //   （实测 rgb(199,199,201)），跟着主题走的前提是自己掌握底色。
        // backdropBlur 只负责「模糊背后的东西」，底色由 backgroundColor 决定，能跟随深浅色。
        .backdropBlur(this.ambientActive() ? 28 : 0)
        .backgroundColor(this.ambientActive()
          ? (this.isDark ? 'rgba(26,26,30,0.82)' : 'rgba(255,255,255,0.82)')
          : (this.isDark ? '#1e1e1e' : '#ffffff'));
      }

      // 背景图裁剪层（全屏覆盖）
      if (this.showBgCrop) {
        BgCropDialog({
          srcUri: this.bgCropSrcUri,
          isDark: this.isDark,
          onConfirm: (path: string): void => { this.onBgCropConfirm(path); },
          onCancel: (): void => { this.showBgCrop = false; }
        })
      }
      if (this.showColorScheme) {
        ColorSchemeEditor({
          kind: this.schemeKind,
          isDark: this.isDark,
          editing: $showColorScheme,
          bottomInset: this.bottomSafeInset,
          onConfirm: (kind: number, colors: number[]): void => { this.onSchemeConfirm(kind, colors); }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(themeBg(this.isDark));
  }

  // ===== 计时器页面 =====
  @Builder TimerTab() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // 顶部魔方类型下拉栏 — 计时运行时隐藏
        if (this.timerState !== TimerState.RUNNING) {
          Row() {
            AppIcon({ iconId: 'cube', color: themeSubText(this.isDark), iconSize: 18 })
              .margin({ right: 6 });
            Text(PUZZLE_CATEGORIES[this.currentPuzzleCategoryIdx()].name + ' · ' + this.puzzleButtonText)
              .fontSize(14)
              .fontColor(themeText(this.isDark))
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
            Text(this.showPuzzleDropdown ? '▴' : '▾')
              .fontSize(14)
              .fontColor(themeSubText(this.isDark));
          }
          .width('100%')
          .height(40)
          .padding({ left: 16, right: 16 })
          .backgroundColor(itemBg(this.isDark, this.bgImageUri.length > 0, this.ambientActive()))
          .border({ width: { bottom: 1 }, color: themeDivider(this.isDark) })
          .onClick((): void => { this.togglePuzzleDropdown(); });
        }

        // 打乱公式 — 计时运行时隐藏；公式较长（如多盲）时区域内可滚动查看
        if (this.timerState !== TimerState.RUNNING) {
          Scroll() {
            Column() {
              Text(this.scramble)
                .fontSize(this.scrambleFontSize)
                .fontColor(themeSubText(this.isDark))
                .maxLines(30)
                .textAlign(TextAlign.Center)
                .lineHeight(this.scrambleFontSize * 1.3)
                .width('100%')
                .onClick((): void => { this.generateScramble(); });
            }
            .width('100%');
          }
          .width('100%')
          .constraintSize({ maxHeight: 110 })
          .scrollBar(BarState.Off)
          .padding({ top: 24, left: 10, right: 10, bottom: 12 });
        }

        // 计时器大字（LCD 数码管或系统字体）
        Column() {
          if (this.inspectionText.length > 0) {
            if (AppConfig.timerFont === 0 && LcdText.canRender(this.inspectionText)) {
              LcdText({ text: this.inspectionText, color: this.timerColor })
                .width('100%')
                .height(this.timerFontSize * 1.3);
            } else {
              Text(this.inspectionText)
                .fontSize(this.timerFontSize)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.timerColor)
                .textAlign(TextAlign.Center);
            }
          } else {
            if (AppConfig.timerFont === 0 && LcdText.canRender(this.timerText)) {
              LcdText({ text: this.timerText, color: this.timerColor })
                .width('100%')
                .height(this.timerFontSize * 1.3);
            } else {
              Text(this.timerText)
                .fontSize(this.timerFontSize)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.timerColor)
                .textAlign(TextAlign.Center);
            }
          }
          // 惩罚标记
          if (this.resultPenalty === 1) {
            Text('+2')
              .fontSize(this.timerFontSize * 0.3)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF9800')
              .margin({ top: 4 });
          } else if (this.resultPenalty === 2) {
            Text('DNF')
              .fontSize(this.timerFontSize * 0.3)
              .fontWeight(FontWeight.Bold)
              .fontColor('#f44336')
              .margin({ top: 4 });
          }
          if (this.timerState === TimerState.STOP) {
            Text('等待确认成绩…')
              .fontSize(12)
              .fontColor(themeSubText(this.isDark))
              .margin({ top: 12 })
              .opacity(0.6);
          }
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onTouch((event: TouchEvent): void => {
          if (this.showPuzzleDropdown) {
            return;
          }
          if (event.type === TouchType.Down) {
            this.onTimerTouchDown(event);
          } else if (event.type === TouchType.Up) {
            this.onTimerTouchUp(event);
          }
        });

        // 统计/按钮 — 计时运行时隐藏
        if (this.timerState !== TimerState.RUNNING) {
          if (AppConfig.showStats) {
            Text(this.statText)
              .fontSize(14)
              .fontColor(themeSubText(this.isDark))
              .textAlign(TextAlign.Start)
              .lineHeight(20)
              .width('48%')
              .alignSelf(ItemAlign.Start)
              .padding({ left: 10, bottom: 4 });
          }

          Row() {
            // 求解按钮对三阶与二阶/金字塔/SQ1 都显示（审核问题1：丰富使用场景）；
            // 具体页签由 MethodSolverView 按 puzzleCode 决定。
            if (hasSolverPuzzle(flatPuzzleCode(this.currentPuzzleIndex))) {
              Button() {
                Row({ space: 4 }) {
                  AppIcon({ iconId: 'wrench', color: themeSubText(this.isDark), iconSize: 15 });
                  Text('求解')
                    .fontSize(11)
                    .fontColor(themeSubText(this.isDark));
                }
              }
              .fontColor(themeSubText(this.isDark))
              .backgroundColor(itemBg(this.isDark, this.bgImageUri.length > 0, this.ambientActive()))
              .border({ width: 1, color: themeDivider(this.isDark), radius: 6 })
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .margin({ left: 8 })
              .onClick((): void => { this.openCrossSolver(); });
            }
          }
          .width('48%')
          .alignSelf(ItemAlign.Start)
          .justifyContent(FlexAlign.Center)
          .padding({ left: 10, right: 4, bottom: 8 });
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(contentBg(this.isDark, this.bgImageUri.length > 0, this.ambientActive()))

      // 右下角打乱图（智能魔方 3D 同步已移除，保留代码后续再接）
      if (this.timerState !== TimerState.RUNNING && AppConfig.showScrambleImage) {
        if (puzzleImageSize(flatPuzzleCode(this.currentPuzzleIndex)) !== 0) {
          ScrambleImageView({
            scramble: this.scramble,
            puzzleSize: puzzleImageSize(flatPuzzleCode(this.currentPuzzleIndex)),
            puzzleCode: flatPuzzleCode(this.currentPuzzleIndex),
            schemeVersion: this.schemeVersion
          })
            .width('58%')
            .aspectRatio(1.176)
            .constraintSize({ maxHeight: '34%' })
            .margin({ right: 2, bottom: 0 });
        }
      }

      // 下拉面板（悬浮覆盖，不挤压其他UI）
      if (this.showPuzzleDropdown && this.timerState !== TimerState.RUNNING) {
        Column() {
          Row() {
            Scroll() {
              Column() {
                ForEach(PUZZLE_CATEGORIES, (cat: PuzzleCategory, catIdx: number) => {
                  Text(cat.name)
                    .fontSize(15)
                    .fontWeight(this.dropdownCategoryIdx === catIdx ? FontWeight.Bold : FontWeight.Normal)
                    .fontColor(this.dropdownCategoryIdx === catIdx ? '#ffffff' : themeText(this.isDark))
                    .backgroundColor(this.dropdownCategoryIdx === catIdx ? COLOR_ACCENT : Color.Transparent)
                    .width('100%')
                    .height(44)
                    .textAlign(TextAlign.Center)
                    .onClick((): void => { this.selectCategory(catIdx); });
                });
              }
              .width('100%')
            }
            .width(100)
            .height('100%')
            .scrollBar(BarState.Off)
            .border({ width: { right: 1 }, color: themeDivider(this.isDark) });

            Scroll() {
              Column() {
                ForEach(PUZZLE_CATEGORIES[this.dropdownCategoryIdx].items,
                  (item: PuzzleItem, itemIdx: number) => {
                  Row() {
                    Text(item.name)
                      .fontSize(14)
                      .fontColor(themeText(this.isDark))
                      .layoutWeight(1);
                    if (this.currentPuzzleCategoryIdx() === this.dropdownCategoryIdx &&
                      this.currentPuzzleItemIdxInCategory() === itemIdx) {
                      Text('✓')
                        .fontSize(14)
                        .fontColor(COLOR_ACCENT)
                        .fontWeight(FontWeight.Bold);
                    }
                  }
                  .width('100%')
                  .height(44)
                  .padding({ left: 16, right: 16 })
                  .onClick((): void => {
                    this.selectPuzzleItem(this.dropdownCategoryIdx, itemIdx);
                  });
                });
              }
              .width('100%')
            }
            .layoutWeight(1)
            .height('100%')
            .scrollBar(BarState.Off);
          }
          .width('100%')
          .height('72%')
          // 下拉面板只在这里上底色，左右两列不再各铺一层。
          // 之前三层 rgba(...,0.45) 叠起来等效不透明度 ~0.83，看上去就是一块纯白，
          // 光感全被吃掉；现在面板单层 + backdropBlur，才是一块真的毛玻璃浮层。
          .backdropBlur(this.ambientActive() ? 20 : 0)
          .backgroundColor(this.ambientActive()
            ? blockSurface(this.isDark, true)
            : themeBg(this.isDark))
          .borderRadius(14)
          .clip(true)
          .border({ width: this.ambientActive() ? 0 : 1, color: themeDivider(this.isDark) });

          Column()
            .width('100%')
            .layoutWeight(1)
            .onClick((): void => { this.closePuzzleDropdown(); });
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.3)')
      }
    }
    .width('100%')
    .layoutWeight(1);
  }

  // ===== 成绩页面 =====
  @Builder ResultTab() {
    Column() {
      // 会话栏
      Row() {
        Button('＋')
          .width(50)
          .height(38)
          .backgroundColor(itemBg(this.isDark, this.bgImageUri.length > 0, this.ambientActive()))
          .fontColor(themeSubText(this.isDark))
          .fontSize(16)
          .onClick((): void => { this.createNewSession(); });

        Text(this.sessionName)
          .height(38)
          .backgroundColor(itemBg(this.isDark, this.bgImageUri.length > 0, this.ambientActive()))
          .fontColor(themeText(this.isDark))
          .fontSize(15)
          .layoutWeight(1)
          .maxLines(1)
          .textAlign(TextAlign.Center)
          .onClick((): void => { this.showSessionDialog(); });

        Button('✕')
          .width(50)
          .height(38)
          .backgroundColor(itemBg(this.isDark, this.bgImageUri.length > 0, this.ambientActive()))
          .fontColor(themeSubText(this.isDark))
          .fontSize(16)
          .onClick((): void => { this.clearAllResults(); });

        Button('⬇')
          .width(50)
          .height(38)
          .backgroundColor(itemBg(this.isDark, this.bgImageUri.length > 0, this.ambientActive()))
          .fontColor(themeSubText(this.isDark))
          .fontSize(16)
          .onClick((): void => { this.showExportDialog(); });

        Button() {
          if (this.showResultChart) {
            Text('≡')
              .fontSize(16)
              .fontColor(themeSubText(this.isDark));
          } else {
            AppIcon({ iconId: 'chart', color: themeSubText(this.isDark), iconSize: 18 });
          }
        }
        .width(50)
        .height(38)
        .backgroundColor(itemBg(this.isDark, this.bgImageUri.length > 0, this.ambientActive()))
        .fontColor(themeSubText(this.isDark))
        .fontSize(16)
        .onClick((): void => {
          this.showResultChart = !this.showResultChart;
        });
      }
      .width('100%')
      .height(38);

      // 分割线
      Row().width('100%').height(1).backgroundColor(themeDivider(this.isDark));

      if (this.showResultChart) {
        // 图表视图
        Column() {
          StatsChartView({
            results: this.results,
            darkMode: this.isDark,
            transparentBg: this.ambientActive()
          })
            .width('100%')
            .layoutWeight(1);
        }
        .width('100%')
        .layoutWeight(1);
      } else {
      // 标题栏
      Row() {
        Text('#')
          .fontSize(16)
          .fontColor(themeText(this.isDark))
          .fontWeight(FontWeight.Bold)
          .width(44)
          .textAlign(TextAlign.Center);
        Text('时间')
          .fontSize(16)
          .fontColor(themeText(this.isDark))
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center);
        Text(this.getAvgLabel(AppConfig.avg1Type, AppConfig.avg1Len))
          .fontSize(16)
          .fontColor(themeText(this.isDark))
          .fontWeight(FontWeight.Bold)
          .width(70)
          .textAlign(TextAlign.Center);
        Text(this.getAvgLabel(AppConfig.avg2Type, AppConfig.avg2Len))
          .fontSize(16)
          .fontColor(themeText(this.isDark))
          .fontWeight(FontWeight.Bold)
          .width(70)
          .textAlign(TextAlign.Center);
      }
      .width('100%')
      .height(32);

      // 分割线
      Row().width('100%').height(1).backgroundColor(themeDivider(this.isDark));

      // 成绩列表
      if (this.results.length === 0) {
        Column() {
          Text('暂无成绩')
            .fontSize(16)
            .fontColor(themeSubText(this.isDark))
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ top: 40 });
        }
        .width('100%')
        .layoutWeight(1);
      } else {
        List() {
          ForEach(this.results, (item: ResultEntry, index: number) => {
            ListItem() {
              Row() {
                // 序号
                Text((this.results.length - index).toString())
                  .fontSize(16)
                  .fontColor(this.getResultNumColor(index))
                  .width(44)
                  .textAlign(TextAlign.Center);

                // 时间
                Text(item.getDisplayTime(AppConfig.timerAccuracy))
                  .fontSize(16)
                  .fontColor(this.getResultTimeColor(index, item))
                  .layoutWeight(1)
                  .textAlign(TextAlign.Center);

                // ao/mo 1
                Text(this.calcAvg(0, index))
                  .fontSize(16)
                  .fontColor(this.getAvgColor(index))
                  .width(70)
                  .textAlign(TextAlign.Center);

                // ao/mo 2
                Text(this.calcAvg(1, index))
                  .fontSize(16)
                  .fontColor(this.getAvgColor(index))
                  .width(70)
                  .textAlign(TextAlign.Center);
              }
              .width('100%')
              .height(32)
              .backgroundColor(this.getResultRowBg(index))
              .onClick((): void => { this.showResultAction(index); });
            }
          }, (item: ResultEntry, index: number): string => item.date.toString() + '_' + index)
        }
        .width('100%')
        .layoutWeight(1)
        .constraintSize({ minHeight: '25%' })
        .padding({ bottom: 6 })
        .divider({ strokeWidth: 1, color: themeDivider(this.isDark), startMargin: 0, endMargin: 0 });
      }

      // 分割线
      Row().width('100%').height(1).backgroundColor(themeDivider(this.isDark));

      // 底部均值栏
      Text(this.sessionMeanText)
        .width('100%')
        .constraintSize({ minHeight: 38 })
        .fontSize(15)
        .fontColor(themeText(this.isDark))
        .textAlign(TextAlign.Center)
        .padding({ left: 10, right: 10, top: 8, bottom: 8 });
      }
    }
    .width('100%')
    // 用 layoutWeight 而非 height('100%')：后者按父容器总高计算，
    // 会吃掉父级的安全区 padding，导致底栏被顶出屏幕（审核问题2）
    .layoutWeight(1)
    .backgroundColor(contentBg(this.isDark, this.bgImageUri.length > 0, this.ambientActive()));
  }

  // ===== 设置页面 =====
  private settingScroller: Scroller = new Scroller();

  /** 第 index 个标签中心在滚动内容里的 x 偏移（vp）；宽度尚未测到时返回 -1 */
  private tabCenterX(index: number): number {
    let x: number = this.navPad;
    for (let i: number = 0; i < this.settingSections.length; i++) {
      const w: number | undefined = this.tabWidths[i];
      if (w === undefined || w <= 0) {
        return -1; // 还没测到，等下次布局回调
      }
      if (i === index) {
        return x + w / 2;
      }
      x += w;
    }
    return -1;
  }

  /** 内容总宽：优先用测量值，测不到时按标签宽度累加兜底 */
  private navTotalWidth(): number {
    if (this.navContentWidth > 0) {
      return this.navContentWidth;
    }
    let w: number = this.navPad * 2;
    for (let i: number = 0; i < this.settingSections.length; i++) {
      const tw: number | undefined = this.tabWidths[i];
      if (tw !== undefined) {
        w += tw;
      }
    }
    return w;
  }

  /** 高亮标签变化时，横向导航自动滚动让高亮项尽量居中；无法居中则贴边保持可见 */
  onSettingSectionChange(): void {
    if (this.suppressScrollHighlight) {
      return;
    }
    const navW: number = this.navWidth;
    const cx: number = this.tabCenterX(this.currentSettingSection);
    const contentW: number = this.navTotalWidth();
    if (navW <= 0 || cx < 0 || contentW <= navW) {
      return;
    }
    // 目标偏移 = 标签中心 - 视口一半；再按可滚动范围夹取，
    // 不足半屏无法居中时就贴边（左端/右端），保证高亮项始终完整可见
    const ideal: number = cx - navW / 2;
    const maxScroll: number = contentW - navW;
    const target: number = Math.min(Math.max(0, ideal), maxScroll);
    // ScrollOptions 的 xOffset / yOffset 都是必填项：漏掉 yOffset 会让 scrollTo 静默失效，
    // 且不能用 `as ScrollOptions` 断言绕过——那正是这个 bug 当初能编译通过的原因
    this.navScroller.scrollTo({ xOffset: target, yOffset: 0, animation: { duration: 250 } });
  }

  getSectionScrollIndex(sectionIdx: number): number {
    let idx: number = 0;
    for (let i: number = 0; i < sectionIdx; i++) {
      idx += this.settingSections[i].items.length + 1; // +1 for header
    }
    return idx;
  }

  scrollToSettingSection(sectionIdx: number): void {
    // 重复点击同一标签时 @Watch 不会触发，需手动补一次居中（否则标签被划出视野后点不回来）
    const sameSection: boolean = this.currentSettingSection === sectionIdx;
    // 先解锁再赋值：否则上一次跳转的抑制窗口内再次点击时，@Watch(onSettingSectionChange)
    // 会被 suppressScrollHighlight 挡掉，顶部导航无法把新标签滚进视野
    this.suppressScrollHighlight = false;
    this.currentSettingSection = sectionIdx;
    if (sameSection) {
      this.onSettingSectionChange();
    }
    this.suppressScrollHighlight = true; // 点击跳转期间锁定高亮，防止被滚动回调抢改写
    let targetIdx: number = this.getSectionScrollIndex(sectionIdx);
    // 延迟到 List 布局稳定后再滚动，避免首次进入时定位偏移到上一区
    setTimeout((): void => {
      this.settingScroller.scrollToIndex(targetIdx, true, ScrollAlign.START);
    }, 60);
    // 等滚动动画结束后恢复由滚动回调接管高亮
    setTimeout((): void => {
      this.suppressScrollHighlight = false;
    }, 700);
  }

  @Builder SettingsTab() {
    Column() {
      // 分区标签（书签定位）
      Scroll(this.navScroller) {
        Row() {
          ForEach(this.settingSections, (section: SettingSection, index: number) => {
            Text(section.title)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentSettingSection === index ? COLOR_ACCENT : themeSubText(this.isDark))
              .backgroundColor(this.currentSettingSection === index
                ? COLOR_ACCENT_BG
                : (this.ambientActive() ? Color.Transparent : themeBg(this.isDark)))
              .padding({ left: 16, right: 16 })
              .height(48)
              .textAlign(TextAlign.Center)
              .onAreaChange((_oldValue: Area, newValue: Area): void => {
                // 只记宽度（vp）：中心位置由宽度累加推算，比读 position 更可靠
                this.tabWidths[index] = Number(newValue.width);
              })
              .onClick((): void => { this.scrollToSettingSection(index); });
          }, (section: SettingSection): string => section.title)
        }
        .height(48)
        .padding({ left: this.navPad, right: this.navPad })
        .onAreaChange((_oldValue: Area, newValue: Area): void => {
          // 记录内容总宽，用于计算横向滚动上限
          this.navContentWidth = Number(newValue.width);
        });
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .height(48)
      .onAreaChange((_oldValue: Area, newValue: Area): void => {
        this.navWidth = Number(newValue.width);
      });

      // 分割线
      Row().width('100%').height(1).backgroundColor(themeDivider(this.isDark));

      // 全部设置项（一个列表，书签定位）
      List({ scroller: this.settingScroller }) {
        ForEach(this.settingSections, (section: SettingSection, sectionIdx: number) => {
          // 分区标题
          ListItem() {
            Text(section.title)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(COLOR_ACCENT)
              .width('100%')
              .padding({ left: 15, right: 15, top: 20, bottom: 5 })
              // 光感开启时让分区标题透出底层渐变，避免一条条纯色横块打断画面
              .backgroundColor(this.ambientActive() ? Color.Transparent : themeBg(this.isDark));
          }

          // 分区项目
          ForEach(section.items, (item: SettingItem) => {
            ListItem() {
              Row() {
                Column() {
                  Text(item.title)
                    .fontSize(17)
                    .fontColor(themeText(this.isDark))
                    .width('100%');
                  if (item.detail.length > 0) {
                    Text(item.detail)
                      .fontSize(15)
                      .fontColor(themeSubText(this.isDark))
                      .width('100%');
                  }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start);

                if (item.type === 1) {
                  Toggle({ type: ToggleType.Switch, isOn: item.value })
                    .selectedColor(COLOR_ACCENT)
                    .onChange((v: boolean): void => { this.onSettingToggle(item.id, v); });
                } else if (item.type === 2) {
                  // 滑块类型（透明度等）
                  Slider({
                    value: AppConfig.bgOpacity,
                    min: 0,
                    max: 100,
                    step: 5
                  })
                    .width('40%')
                    .trackColor(themeDivider(this.isDark))
                    .selectedColor(COLOR_ACCENT)
                    .blockColor(COLOR_ACCENT)
                    .onChange((v: number): void => {
                      this.onBgOpacityChange(v);
                      this.initSettings(); // 刷新 detail
                    });
                }
              }
              .width('100%')
              .padding({ left: 15, right: 15, top: 14, bottom: 14 })
              .onClick((): void => {
                if (item.type === 0) {
                  this.onSettingTextClick(item.id);
                }
              });
            }
          }, (item: SettingItem): string => item.id.toString())
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ bottom: 24 })
      .divider({ strokeWidth: 1, color: themeDivider(this.isDark), startMargin: 15, endMargin: 0 })
      .onScrollIndex((first: number, _last: number): void => {
        // 点击顶部导航跳转期间不改写高亮，等滚动动画结束后再接管
        if (this.suppressScrollHighlight) {
          return;
        }
        // 必须以视口【顶部】第一个可见项 first 反推高亮：书签定位用的是 ScrollAlign.START
        // （目标分区标题对齐视口顶部）。若按 last（视口底部）反推，高亮会恒定滞后整个视口高度，
        // 点击"打乱"会跳到"界面"（实测偏移约 4 个分区）。防回归：此处不可用 last。
        let count: number = 0;
        for (let i: number = 0; i < this.settingSections.length; i++) {
          let sectionSize: number = this.settingSections[i].items.length + 1;
          if (first < count + sectionSize) {
            this.currentSettingSection = i;
            break;
          }
          count += sectionSize;
        }
      });
    }
    .width('100%')
    // 同 ResultTab：用 layoutWeight 保留父级安全区 padding（审核问题2）
    .layoutWeight(1)
    .backgroundColor(contentBg(this.isDark, this.bgImageUri.length > 0, this.ambientActive()));
  }
}

// ===== Tab按钮组件 =====
@Component
struct TabButton {
  @Prop iconId: string;
  @Prop selected: boolean;
  @Prop isDark: boolean;
  onTabClick: () => void = (): void => {};

  build() {
    Column({ space: 3 }) {
      AppIcon({
        iconId: this.iconId,
        color: this.selected ? COLOR_ACCENT : themeText(this.isDark),
        iconSize: 24
      })
      // 选中指示条
      Row()
        .width(this.selected ? 18 : 0)
        .height(2.5)
        .borderRadius(1.25)
        .backgroundColor(COLOR_ACCENT)
    }
    .layoutWeight(1)
    .height(48)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick((): void => { this.onTabClick(); });
  }
}

// ===== 隐私政策对话框 =====
@CustomDialog
struct PrivacyDialog {
  controller: CustomDialogController;
  // 0=首次同意模式, 1=仅查看模式
  mode: number = 0;
  onAgree: () => void = (): void => {};
  onExit: () => void = (): void => {};
  @State agreed: boolean = false;

  build() {
    Column() {
      Text('隐私政策')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(themeText(AppConfig.darkMode))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 16, bottom: 10 });

      // 政策文字内容
      Scroll() {
        Column() {
          ForEach(PRIVACY_SECTIONS, (section: PrivacySection) => {
            Column() {
              if (section.title.length > 0) {
                Text(section.title)
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(themeText(AppConfig.darkMode))
                  .width('100%')
                  .margin({ bottom: 4 });
              }
              Text(section.body)
                .fontSize(14)
                .fontColor(themeText(AppConfig.darkMode))
                .width('100%')
                .lineHeight(22);
            }
            .width('100%')
            .margin({ bottom: section.title.length > 0 ? 12 : 8 });
          }, (section: PrivacySection): string => section.title + '_' + section.body.length)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start);
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off);

      if (this.mode === 0) {
        // 首次同意模式
        Row() {
          Checkbox({ name: 'privacyAgree', group: 'privacy' })
            .select(this.agreed)
            .selectedColor(COLOR_ACCENT)
            .onChange((checked: boolean): void => { this.agreed = checked; });
          Text('我已阅读并同意《隐私政策》')
            .fontSize(14)
            .fontColor(themeText(AppConfig.darkMode))
            .onClick((): void => { this.agreed = !this.agreed; });
        }
        .width('100%')
        .margin({ top: 6 });

        Row() {
          Button('不同意并退出')
            .fontSize(15)
            .fontColor(themeText(AppConfig.darkMode))
            .backgroundColor(themeDivider(AppConfig.darkMode))
            .layoutWeight(1)
            .height(44)
            .onClick((): void => { this.onExit(); });
          Button('同意并继续')
            .fontSize(15)
            .fontColor('#ffffff')
            .backgroundColor(this.agreed ? COLOR_ACCENT : themeDivider(AppConfig.darkMode))
            .enabled(this.agreed)
            .layoutWeight(1)
            .height(44)
            .margin({ left: 12 })
            .onClick((): void => {
              this.onAgree();
              this.controller.close();
            });
        }
        .width('100%')
        .margin({ top: 12 });
      } else {
        // 仅查看模式
        Button('关 闭')
          .fontSize(15)
          .fontColor('#ffffff')
          .backgroundColor(COLOR_ACCENT)
          .width('100%')
          .height(44)
          .margin({ top: 12 })
          .onClick((): void => { this.controller.close(); });
      }
    }
    .width('90%')
    .height('82%')
    .backdropBlur(dialogBlurRadius(materialEnabled(AppConfig.ambientEnabled)))
    .backgroundColor(dialogSurface(AppConfig.darkMode, materialEnabled(AppConfig.ambientEnabled)))
    .borderRadius(16)
    .padding(16);
  }
}

// ===== 导出对话框 =====
@CustomDialog
struct ExportDialog {
  controller: CustomDialogController;
  csvData: string = '';
  sessionName: string = '';
  @State copied: boolean = false;

  build() {
    Column() {
      Text('导出成绩')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(themeText(AppConfig.darkMode))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 20, bottom: 4 });

      Text(`${this.sessionName} (共 ${this.csvData.split('\n').length - 1} 条)`)
        .fontSize(13)
        .fontColor(themeSubText(AppConfig.darkMode))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ bottom: 12 });

      // CSV 预览 (最多5行)
      Scroll() {
        Text(this.getPreview())
          .fontSize(12)
          .fontColor(themeText(AppConfig.darkMode))
          .width('100%')
          .fontFamily('monospace')
          .padding(8);
      }
      .width('100%')
      .height(120)
      .backgroundColor(themeBg(AppConfig.darkMode))
      .borderRadius(8)
      .margin({ bottom: 12 });

      Row() {
        Button(this.copied ? '已复制 ✓' : '复制到剪贴板')
          .fontSize(14)
          .fontColor('#ffffff')
          .backgroundColor(COLOR_PRIMARY)
          .layoutWeight(1)
          .height(42)
          .borderRadius(8)
          .onClick((): void => {
            this.copyToClipboard();
          });

        Button('关闭')
          .fontSize(14)
          .fontColor(themeSubText(AppConfig.darkMode))
          .backgroundColor(themeBg(AppConfig.darkMode))
          .layoutWeight(1)
          .height(42)
          .borderRadius(8)
          .onClick((): void => { this.controller.close(); });
      }
      .width('100%');
    }
    .width('90%')
    .backdropBlur(dialogBlurRadius(materialEnabled(AppConfig.ambientEnabled)))
    .backgroundColor(dialogSurface(AppConfig.darkMode, materialEnabled(AppConfig.ambientEnabled)))
    .borderRadius(16)
    .padding(16);
  }

  private getPreview(): string {
    const lines: string[] = this.csvData.split('\n');
    const maxLines: number = Math.min(lines.length, 6);
    let preview: string = '';
    for (let i: number = 0; i < maxLines; i++) {
      preview += lines[i] + '\n';
    }
    if (lines.length > 6) {
      preview += `... 共 ${lines.length - 1} 条`;
    }
    return preview;
  }

  private copyToClipboard(): void {
    try {
      let pb: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      let data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.csvData);
      pb.setData(data);
      this.copied = true;
      setTimeout((): void => { this.copied = false; }, 2000);
    } catch (e) {
      AlertDialog.show({
        title: '错误',
        message: '复制失败，请重试',
        confirm: { value: '确定', action: (): void => {} },
        alignment: DialogAlignment.Center
      });
    }
  }
}
