import { DCTTimer, TimerState } from '../model/DCTTimer';
import { AppConfig } from '../model/AppConfig';
import { Scrambler as DctScrambler } from '../scrambler/Scrambler';
import { AppGlobals } from '../model/AppGlobals';
import { Tools } from '../cs/min2phase/Tools';
import { Util } from '../cs/threephase/Util';
import { FileIO } from '../util/FileIO';
import { common } from '@kit.AbilityKit';
import { resourceManager } from '@kit.LocalizationKit';
import { Session } from '../model/Session';
import { Result, ResultEntry } from '../model/Result';
import { DBHelper } from '../database/DBHelper';
import { StringUtils } from '../util/StringUtils';
import { initScrambleItems } from '../util/ScrambleItems';
import { ScrambleImageView } from '../view/ScrambleImageView';
import { LcdText } from '../view/LcdText';
import { StatsChartView } from '../view/StatsChartView';
import { ExportUtil } from '../util/ExportUtil';
import { CrossSolverView } from '../view/CrossSolverView';
import { pasteboard } from '@kit.BasicServicesKit';
import { BleScanDialog } from '../view/BleScanDialog';
import { BackgroundManager } from '../util/BackgroundManager';
import { bleManager, BleCallbacks } from '../util/BleManager';
import { CubeConnectionState, CubeMove, CubeDeviceInfo } from '../util/SmartCubeProtocol';
import dataPreferences from '@ohos.data.preferences';
import promptAction from '@ohos.promptAction';
import { window } from '@kit.ArkUI';
import { vibrator } from '@kit.SensorServiceKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';

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
function themeTopBar(dark: boolean): string { return dark ? COLOR_PRIMARY_DARK : COLOR_PRIMARY; }

/** 内容区背景：有自定义背景时半透明，否则纯色 */
function contentBg(dark: boolean, hasBgImage: boolean): string {
  if (!hasBgImage) {
    return themeBg(dark);
  }
  return dark ? 'rgba(30,30,30,0.84)' : 'rgba(255,255,255,0.84)';
}

/** 按钮/行背景：有自定义背景时半透明 */
function itemBg(dark: boolean, hasBgImage: boolean): string {
  if (!hasBgImage) {
    return themeBg(dark);
  }
  return dark ? 'rgba(38,38,38,0.7)' : 'rgba(245,245,245,0.7)';
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
      { name: 'cross solved', code: 934 },
      { name: 'last layer', code: 935 },
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
    Util.dataPath = dir;
    try {
      const rm: resourceManager.ResourceManager = ctx.resourceManager;
      copyRawTableFile(rm, 'twophase.dat', dir + 'twophase.dat').then((): void => {
        Tools.init();
      });
      copyRawTableFile(rm, 'center.dat', dir + 'center.dat').then((): void => {
        copyRawTableFile(rm, 'edge.dat', dir + 'edge.dat').then((): void => {
          Util.init();
        });
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
    .backgroundColor(themeBg(AppConfig.darkMode))
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
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(themeText(AppConfig.darkMode))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 20, bottom: 12 });

      Text(this.formatDisplayTime())
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor(themeText(AppConfig.darkMode))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ bottom: 4 });

      Text(this.scramble)
        .fontSize(13)
        .fontColor(themeSubText(AppConfig.darkMode))
        .width('100%')
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .padding({ left: 16, right: 16, bottom: 12 });

      Row() {
        Button('确认')
          .fontSize(16)
          .fontColor('#ffffff')
          .backgroundColor(COLOR_ACCENT)
          .layoutWeight(1)
          .height(44)
          .onClick((): void => {
            this.onConfirm(this.resultPenalty);
            this.controller.close();
          });

        Button('+2')
          .fontSize(16)
          .fontColor('#ffffff')
          .backgroundColor('#FF9800')
          .layoutWeight(1)
          .height(44)
          .margin({ left: 8 })
          .onClick((): void => {
            this.onConfirm(1);
            this.controller.close();
          });

        Button('DNF')
          .fontSize(16)
          .fontColor('#ffffff')
          .backgroundColor('#f44336')
          .layoutWeight(1)
          .height(44)
          .margin({ left: 8 })
          .onClick((): void => {
            this.onConfirm(2);
            this.controller.close();
          });
      }
      .width('90%')
      .padding({ bottom: 16 });

      Button('取消')
        .fontSize(16)
        .fontColor(themeText(AppConfig.darkMode))
        .backgroundColor(themeBg(AppConfig.darkMode))
        .width('90%')
        .height(44)
        .margin({ bottom: 16 })
        .onClick((): void => {
          this.onCancel();
          this.controller.close();
        });
    }
    .width('100%')
    .backgroundColor(themeBg(AppConfig.darkMode))
    .borderRadius(12);
  }

  formatDisplayTime(): string {
    if (this.resultPenalty === 2) {
      return 'DNF';
    }
    return ResultEntry.formatMs(this.resultTime + (this.resultPenalty === 1 ? 2000 : 0), this.accuracy);
  }
}

// ===== 成绩操作对话框 =====
@CustomDialog
struct ResultActionDialog {
  controller: CustomDialogController;
  resultIndex: number = 0;
  resultEntry: ResultEntry | null = null;
  onViewDetail: (index: number) => void = (): void => {};
  onPlusTwo: (index: number) => void = (): void => {};
  onDNF: (index: number) => void = (): void => {};
  onUndoPenalty: (index: number) => void = (): void => {};
  onDelete: (index: number) => void = (): void => {};
  onEditNote: (index: number) => void = (): void => {};

  build() {
    Column() {
      // 当前状态摘要
      if (this.resultEntry) {
        Text(this.resultEntry.getDisplayTime(AppConfig.timerAccuracy))
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor(themeText(AppConfig.darkMode))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 16, bottom: 4 });
        Text(this.resultEntry.scramble)
          .fontSize(13)
          .fontColor(themeSubText(AppConfig.darkMode))
          .width('100%')
          .textAlign(TextAlign.Center)
          .maxLines(2)
          .padding({ left: 16, right: 16, bottom: 8 });
      }

      Column() {
        this.ActionButton('查看详情', (): void => {
          this.onViewDetail(this.resultIndex);
          this.controller.close();
        });
        this.ActionButton('+2', (): void => {
          this.onPlusTwo(this.resultIndex);
          this.controller.close();
        });
        this.ActionButton('DNF', (): void => {
          this.onDNF(this.resultIndex);
          this.controller.close();
        });
        this.ActionButton('取消惩罚', (): void => {
          this.onUndoPenalty(this.resultIndex);
          this.controller.close();
        });
        this.ActionButton('编辑备注', (): void => {
          this.controller.close();
          this.onEditNote(this.resultIndex);
        });
        this.ActionButton('删除', (): void => {
          this.controller.close();
          this.onDelete(this.resultIndex);
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
    .backgroundColor(themeBg(AppConfig.darkMode))
    .borderRadius({ topLeft: 12, topRight: 12 });
  }

  @Builder ActionButton(label: string, action: () => void) {
    Text(label)
      .fontSize(16)
      .fontColor(label === '删除' ? '#ff4444' : themeText(AppConfig.darkMode))
      .width('100%')
      .textAlign(TextAlign.Center)
      .padding({ top: 14, bottom: 14 })
      .onClick((): void => { action(); });
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
    .backgroundColor(themeBg(AppConfig.darkMode))
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
  @State phaseHint: string = '';
  // 主题与字号（响应式，切换时驱动界面刷新）
  @State isDark: boolean = false;
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
  @State currentSettingSection: number = 0;
  // 背景主题
  @State bgImageUri: string = '';
  @State bgOpacity: number = 80;
  // BLE 智能魔方
  @State bleConnected: boolean = false;
  @State bleDeviceName: string = '';
  @State bleStatusText: string = '未连接';
  // 求解器
  @State showSolver: boolean = false;
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
      onSelect: (_index: number): void => {},
      onNew: (): void => {}
    }),
    autoCancel: true,
    alignment: DialogAlignment.Bottom,
    customStyle: true
  });
  private resultActionDialog: CustomDialogController = new CustomDialogController({
    builder: ResultActionDialog({
      resultIndex: 0,
      resultEntry: null,
      onViewDetail: (_index: number): void => {},
      onPlusTwo: (_index: number): void => {},
      onDNF: (_index: number): void => {},
      onUndoPenalty: (_index: number): void => {},
      onDelete: (_index: number): void => {},
      onEditNote: (_index: number): void => {}
    }),
    autoCancel: true,
    alignment: DialogAlignment.Bottom,
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
  private noteEditDialog: CustomDialogController = new CustomDialogController({
    builder: NoteEditDialog({
      currentNote: '',
      onSave: (_note: string): void => {}
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

  aboutToAppear(): void {
    initAlgorithmCache(getContext(this) as common.UIAbilityContext);
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
      this.phaseHint = '第' + (phaseIndex + 2) + '/' + AppConfig.multiPhase + '段';
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

    // 初始化背景设置
    this.bgImageUri = BackgroundManager.getImageUri();
    this.bgOpacity = BackgroundManager.getOpacity();

    // 初始化 BLE 智能魔方
    this.initBleCallbacks();
    if (AppConfig.bleDeviceAddress.length > 0) {
      this.bleDeviceName = AppConfig.bleDeviceName;
    }

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
    });
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
    AppConfig.darkMode = prefs.getSync('darkMode', false) as boolean;
    AppConfig.bgImageUri = prefs.getSync('bgImageUri', '') as string;
    AppConfig.bgOpacity = prefs.getSync('bgOpacity', 80) as number;
    this.bgImageUri = AppConfig.bgImageUri;
    this.bgOpacity = AppConfig.bgOpacity;
    AppConfig.timerFont = prefs.getSync('timerFont', 0) as number;
    AppConfig.fontSize = prefs.getSync('fontSize', 72) as number;
    AppConfig.keepScreenOn = prefs.getSync('keepScreenOn', true) as boolean;
    AppConfig.vibrateType = prefs.getSync('vibrateType', 1) as number;
    AppConfig.defaultCrossBottom = prefs.getSync('defaultCrossBottom', 1) as number;
    AppConfig.avg1Type = prefs.getSync('avg1Type', 0) as number;
    AppConfig.avg1Len = prefs.getSync('avg1Len', 5) as number;
    AppConfig.avg2Type = prefs.getSync('avg2Type', 0) as number;
    AppConfig.avg2Len = prefs.getSync('avg2Len', 12) as number;
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
    prefs.putSync('bgImageUri', AppConfig.bgImageUri);
    prefs.putSync('bgOpacity', AppConfig.bgOpacity);
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
    prefs.putSync('currentSessionIndex', this.currentSessionIndex);

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
      await this.result.insert(e.time, e.penalty, e.scramble, false, null, null);
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
      this.statText = '0/0)\n最佳: --\n' + this.getAvgLabel(AppConfig.avg1Type, AppConfig.avg1Len) + ': --\n' +
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
    this.sessionMeanText = '平均(' + this.result.getSessionMean() + ')';
    this.statText = len + '/' + len + ')\n最佳: ' + this.bestText + '\n' +
      this.getAvgLabel(AppConfig.avg1Type, AppConfig.avg1Len) + ': ' + this.avg1Text + '\n' +
      this.getAvgLabel(AppConfig.avg2Type, AppConfig.avg2Len) + ': ' + this.avg2Text;
  }

  getAvgLabel(avgType: number, avgLen: number): string {
    return (avgType === 0 ? '平均' : '均值') + avgLen;
  }

  // ===== 打乱生成 =====
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
        this.phaseHint = '';
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
          AppConfig.bleDeviceAddress = address;
          AppConfig.bleDeviceName = name;
          this.saveToPreferences();
          this.initSettings();
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
  /** 把选中的图片复制到应用沙箱，返回沙箱路径（相册 URI 授权在退出应用后失效） */
  copyBgImageToSandbox(uri: string): string {
    try {
      const srcFile: fileIo.File = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const destPath: string = getContext(this).filesDir + '/bg_image';
      const dstFile: fileIo.File = fileIo.openSync(destPath,
        fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      fileIo.copyFileSync(srcFile.fd, dstFile.fd);
      fileIo.closeSync(srcFile);
      fileIo.closeSync(dstFile);
      return 'file://' + destPath;
    } catch (err) {
      return '';
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
        const localPath: string = this.copyBgImageToSandbox(result.photoUris[0]);
        if (localPath.length === 0) {
          promptAction.showToast({ message: '背景图片读取失败', duration: 2000 });
          return;
        }
        this.bgImageUri = localPath;
        BackgroundManager.setImageUri(localPath);
        AppConfig.bgImageUri = localPath;
        this.initSettings();
        this.saveToPreferences();
      }
    } catch (err) {
      // 用户取消
    }
  }

  clearBackgroundImage(): void {
    this.bgImageUri = '';
    BackgroundManager.clearImage();
    AppConfig.bgImageUri = '';
    try {
      fileIo.unlinkSync(getContext(this).filesDir + '/bg_image');
    } catch (err) {
      // 文件不存在时忽略
    }
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
        this.phaseHint = '';
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
    if (AppConfig.multiPhase > 0) {
      this.phaseHint = '第1/' + AppConfig.multiPhase + '段';
    }
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
    this.result.insert(timeMs, 0, this.scramble, AppConfig.multiPhase > 0, null, null).then((): void => {
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
    this.result.insert(this.dct.time, penalty, this.scramble, AppConfig.multiPhase > 0, null, null).then((): void => {
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
    this.phaseHint = '';
    this.dct.reset();
    this.timerState = TimerState.READY;
    this.generateScramble();
  }

  discardPendingResult(): void {
    this.dct.reset();
    this.timerState = TimerState.READY;
    this.timerText = '0.00';
    this.timerColor = themeText(this.isDark);
    this.phaseHint = '';
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
    this.resultActionDialog = new CustomDialogController({
      builder: ResultActionDialog({
        resultIndex: realIdx,
        resultEntry: this.results[displayIndex],
        onViewDetail: (index: number): void => { this.onViewResultDetail(index); },
        onPlusTwo: (index: number): void => { this.onResultPlusTwo(index); },
        onDNF: (index: number): void => { this.onResultDNF(index); },
        onUndoPenalty: (index: number): void => { this.onResultUndoPenalty(index); },
        onDelete: (index: number): void => { this.onResultDelete(index); },
        onEditNote: (index: number): void => { this.onEditResultNote(index); }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Bottom,
      customStyle: true
    });
    this.resultActionDialog.open();
  }

  onViewResultDetail(index: number): void {
    if (this.result === null) {
      return;
    }
    let detailMsg: string = '时间: ' + this.result.getTimeAt(index, true) +
      '\n打乱: ' + this.result.getString(index, 4) +
      '\n日期: ' + this.result.getString(index, 5);
    const note: string = this.result.getString(index, 6);
    if (note.length > 0) {
      detailMsg += '\n备注: ' + note;
    }
    if (AppConfig.multiPhase > 0) {
      const phaseStrs: string[] = [];
      for (let i: number = 0; i < 6; i++) {
        const p: number = this.result.getMulTime(i, index);
        if (p > 0) {
          phaseStrs.push(StringUtils.timeToString(p));
        }
      }
      if (phaseStrs.length > 1) {
        detailMsg += '\n分段: ' + phaseStrs.join(' / ');
      }
    }
    AlertDialog.show({
      title: '成绩详情',
      message: detailMsg,
      confirm: { value: '确定', action: (): void => {} },
      alignment: DialogAlignment.Center
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

  onEditResultNote(index: number): void {
    if (this.result === null) {
      return;
    }
    this.noteEditDialog = new CustomDialogController({
      builder: NoteEditDialog({
        currentNote: this.result.getString(index, 6),
        onSave: (note: string): void => {
          if (this.result !== null) {
            this.result.updateNote(index, note).then((): void => {
              this.refreshResultsDisplay();
            });
          }
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      customStyle: true
    });
    this.noteEditDialog.open();
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
        title: '界面', items: [
          { id: 41, title: '计时器字体', detail: AppConfig.timerFont === 0 ? 'LCD 数码管' : '系统字体', type: 0, value: false },
          { id: 42, title: '计时器大小', detail: AppConfig.fontSize + 'sp', type: 0, value: false },
          { id: 43, title: '选择背景图片', detail: AppConfig.bgImageUri.length > 0 ? '已设置' : '未设置', type: 0, value: false },
          { id: 44, title: '背景透明度', detail: AppConfig.bgOpacity + '%', type: 2, value: false },
          { id: 45, title: '深色模式', detail: '', type: 1, value: AppConfig.darkMode }
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
          { id: 62, title: '触感反馈', detail: this.getVibrateDesc(), type: 0, value: false },
          { id: 63, title: '智能魔方', detail: AppConfig.bleDeviceName.length > 0 ? ('已连接: ' + AppConfig.bleDeviceName) : '未连接', type: 0, value: false }
        ]
      },
      {
        title: '求解器', items: [
          { id: 71, title: '默认十字底面', detail: this.getCrossBottomDesc(), type: 0, value: false }
        ]
      }
    ];
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
      case 45:
        AppConfig.darkMode = value;
        this.isDark = value;
        if (this.timerState === TimerState.READY || this.timerState === TimerState.STOP) {
          this.timerColor = themeText(this.isDark);
        }
        break;
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
      case 63:
        if (AppConfig.bleDeviceAddress.length > 0) {
          this.disconnectBle();
        } else {
          this.openBleScanner();
        }
        return; // BLE dialog 自己处理
      case 71:
        AppConfig.defaultCrossBottom = (AppConfig.defaultCrossBottom + 1) % 6;
        break;
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
      return contentBg(this.isDark, this.bgImageUri.length > 0);
    }
    return itemBg(this.isDark, this.bgImageUri.length > 0);
  }

  // ===== 主界面构建 =====
  build() {
    Stack() {
      // 背景图层
      if (this.bgImageUri.length > 0) {
        Image(this.bgImageUri)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .opacity(this.bgOpacity / 100);
      }

      // 主内容
      Column() {
        // 顶部 TabBar — 计时运行时隐藏
        if (this.timerState !== TimerState.RUNNING) {
          Row() {
            TabButton({ label: '计时器', selected: this.currentTab === 0, onTabClick: (): void => { this.currentTab = 0; } })
            TabButton({ label: '成绩', selected: this.currentTab === 1, onTabClick: (): void => { this.currentTab = 1; } })
            TabButton({ label: '设置', selected: this.currentTab === 2, onTabClick: (): void => { this.currentTab = 2; } })
          }
          .width('100%')
          .height(48)
          .backgroundColor(themeTopBar(this.isDark));
        }

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
      .height('100%');

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
            Text('十字求解器')
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
          .margin({ bottom: 12 });

          // 使用求解器组件
          CrossSolverView({
            scramble: this.scramble,
            isDark: this.isDark
          });
        }
        .width('100%')
        .backgroundColor(this.isDark ? '#1e1e1e' : '#ffffff')
        .borderRadius({ topLeft: 16, topRight: 16 })
        .padding(20);
      }
    }
    .width('100%')
    .height('100%');
  }

  // ===== 计时器页面 =====
  @Builder TimerTab() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // 顶部魔方类型下拉栏 — 计时运行时隐藏
        if (this.timerState !== TimerState.RUNNING) {
          Row() {
            Text('🧊')
              .fontSize(16)
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
          .backgroundColor(itemBg(this.isDark, this.bgImageUri.length > 0))
          .border({ width: { bottom: 1 }, color: themeDivider(this.isDark) })
          .onClick((): void => { this.togglePuzzleDropdown(); });
        }

        // 打乱公式 — 计时运行时隐藏
        if (this.timerState !== TimerState.RUNNING) {
          Text(this.scramble)
            .fontSize(this.scrambleFontSize)
            .fontColor(themeSubText(this.isDark))
            .maxLines(3)
            .textAlign(TextAlign.Center)
            .lineHeight(this.scrambleFontSize * 1.3)
            .padding({ top: 24, left: 10, right: 10, bottom: 12 })
            .width('100%')
            .onClick((): void => { this.generateScramble(); });
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
          if (this.phaseHint.length > 0) {
            Text(this.phaseHint)
              .fontSize(15)
              .fontColor(themeSubText(this.isDark))
              .margin({ top: 6 });
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
              .fontSize(15)
              .fontColor(themeSubText(this.isDark))
              .textAlign(TextAlign.Start)
              .lineHeight(21)
              .width('100%')
              .padding({ left: 10, bottom: 4 });
          }

          Row() {
            Button(this.bleConnected ? '🔗 ' + this.bleDeviceName : '📡 连接魔方')
              .fontSize(11)
              .fontColor(this.bleConnected ? '#00cc00' : themeSubText(this.isDark))
              .backgroundColor(itemBg(this.isDark, this.bgImageUri.length > 0))
              .border({ width: 1, color: themeDivider(this.isDark), radius: 6 })
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .onClick((): void => { this.openBleScanner(); });

            if (is333Puzzle(flatPuzzleCode(this.currentPuzzleIndex))) {
              Button('🔧 十字求解')
                .fontSize(11)
                .fontColor(themeSubText(this.isDark))
                .backgroundColor(itemBg(this.isDark, this.bgImageUri.length > 0))
                .border({ width: 1, color: themeDivider(this.isDark), radius: 6 })
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .margin({ left: 8 })
                .onClick((): void => { this.openCrossSolver(); });
            }
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ left: 10, right: 10, bottom: 8 });
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(contentBg(this.isDark, this.bgImageUri.length > 0))

      // 右下角打乱状态图 — 计时运行时隐藏
      if (this.timerState !== TimerState.RUNNING &&
        AppConfig.showScrambleImage &&
        puzzleImageSize(flatPuzzleCode(this.currentPuzzleIndex)) !== 0) {
        ScrambleImageView({
          scramble: this.scramble,
          puzzleSize: puzzleImageSize(flatPuzzleCode(this.currentPuzzleIndex)),
          puzzleCode: flatPuzzleCode(this.currentPuzzleIndex)
        })
          .width(152)
          .height(114)
          .margin({ right: 6, bottom: 92 });
      }

      // 下拉面板（悬浮覆盖，不挤压其他UI）
      if (this.showPuzzleDropdown && this.timerState !== TimerState.RUNNING) {
        Column() {
          Row() {
            Column() {
              ForEach(PUZZLE_CATEGORIES, (cat: PuzzleCategory, catIdx: number) => {
                Text(cat.name)
                  .fontSize(15)
                  .fontWeight(this.dropdownCategoryIdx === catIdx ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor(this.dropdownCategoryIdx === catIdx ? '#ffffff' : themeText(this.isDark))
                  .backgroundColor(this.dropdownCategoryIdx === catIdx ? COLOR_ACCENT : itemBg(this.isDark, this.bgImageUri.length > 0))
                  .width('100%')
                  .height(44)
                  .textAlign(TextAlign.Center)
                  .onClick((): void => { this.selectCategory(catIdx); });
              });
            }
            .width(100)
            .backgroundColor(itemBg(this.isDark, this.bgImageUri.length > 0))
            .border({ width: { right: 1 }, color: themeDivider(this.isDark) });

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
                .backgroundColor(itemBg(this.isDark, this.bgImageUri.length > 0))
                .onClick((): void => {
                  this.selectPuzzleItem(this.dropdownCategoryIdx, itemIdx);
                });
              });
            }
            .layoutWeight(1)
            .backgroundColor(itemBg(this.isDark, this.bgImageUri.length > 0));
          }
          .width('100%')
          .backgroundColor(itemBg(this.isDark, this.bgImageUri.length > 0));

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
          .backgroundColor(themeBg(this.isDark))
          .fontColor(themeSubText(this.isDark))
          .fontSize(16)
          .onClick((): void => { this.createNewSession(); });

        Text(this.sessionName)
          .height(38)
          .backgroundColor(themeBg(this.isDark))
          .fontColor(themeText(this.isDark))
          .fontSize(15)
          .layoutWeight(1)
          .maxLines(1)
          .textAlign(TextAlign.Center)
          .onClick((): void => { this.showSessionDialog(); });

        Button('✕')
          .width(50)
          .height(38)
          .backgroundColor(themeBg(this.isDark))
          .fontColor(themeSubText(this.isDark))
          .fontSize(16)
          .onClick((): void => { this.clearAllResults(); });

        Button('⬇')
          .width(50)
          .height(38)
          .backgroundColor(themeBg(this.isDark))
          .fontColor(themeSubText(this.isDark))
          .fontSize(16)
          .onClick((): void => { this.showExportDialog(); });

        Button(this.showResultChart ? '≡' : '📈')
          .width(50)
          .height(38)
          .backgroundColor(themeBg(this.isDark))
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
            darkMode: this.isDark
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
        .maxLines(2)
        .padding({ left: 10, right: 10, top: 8, bottom: 8 });
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(contentBg(this.isDark, this.bgImageUri.length > 0));
  }

  // ===== 设置页面 =====
  private settingScroller: Scroller = new Scroller();

  getSectionScrollIndex(sectionIdx: number): number {
    let idx: number = 0;
    for (let i: number = 0; i < sectionIdx; i++) {
      idx += this.settingSections[i].items.length + 1; // +1 for header
    }
    return idx;
  }

  scrollToSettingSection(sectionIdx: number): void {
    this.currentSettingSection = sectionIdx;
    let targetIdx: number = this.getSectionScrollIndex(sectionIdx);
    this.settingScroller.scrollToIndex(targetIdx, true, ScrollAlign.START);
  }

  @Builder SettingsTab() {
    Column() {
      // 分区标签（书签定位）
      Scroll() {
        Row() {
          ForEach(this.settingSections, (section: SettingSection, index: number) => {
            Text(section.title)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentSettingSection === index ? COLOR_ACCENT : themeSubText(this.isDark))
              .backgroundColor(this.currentSettingSection === index ? COLOR_ACCENT_BG : themeBg(this.isDark))
              .padding({ left: 16, right: 16 })
              .height(48)
              .textAlign(TextAlign.Center)
              .onClick((): void => { this.scrollToSettingSection(index); });
          }, (section: SettingSection): string => section.title)
        }
        .height(48)
        .padding({ left: 12, right: 12 });
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .height(48);

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
              .backgroundColor(themeBg(this.isDark));
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
      .onScrollIndex((first: number): void => {
        // 根据滚动位置更新当前标签
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
    .height('100%')
    .backgroundColor(contentBg(this.isDark, this.bgImageUri.length > 0));
  }
}

// ===== Tab按钮组件 =====
@Component
struct TabButton {
  @Prop label: string;
  @Prop selected: boolean;
  onTabClick: () => void = (): void => {};

  build() {
    Column() {
      Text(this.label)
        .fontSize(14)
        .fontWeight(this.selected ? FontWeight.Bold : FontWeight.Normal)
        .fontColor('#ffffff')
        .textAlign(TextAlign.Center);
    }
    .layoutWeight(1)
    .height(48)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick((): void => { this.onTabClick(); });
  }
}

// ===== 备注编辑对话框 =====
@CustomDialog
struct NoteEditDialog {
  controller: CustomDialogController;
  currentNote: string = '';
  onSave: (note: string) => void = (): void => {};
  @State noteText: string = '';

  aboutToAppear(): void {
    this.noteText = this.currentNote;
  }

  build() {
    Column() {
      Text('编辑备注')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(themeText(AppConfig.darkMode))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 20, bottom: 12 });

      TextInput({ text: this.noteText, placeholder: '输入备注...' })
        .width('100%')
        .height(48)
        .fontSize(15)
        .fontColor(themeText(AppConfig.darkMode))
        .placeholderColor(themeSubText(AppConfig.darkMode))
        .caretColor(themeText(AppConfig.darkMode))
        .padding({ left: 12, right: 12 })
        .backgroundColor(themeDivider(AppConfig.darkMode))
        .borderRadius(8)
        .onChange((value: string): void => {
          this.noteText = value;
        });

      Row() {
        Button('取消')
          .fontSize(15)
          .fontColor(themeSubText(AppConfig.darkMode))
          .backgroundColor(themeBg(AppConfig.darkMode))
          .layoutWeight(1)
          .height(42)
          .onClick((): void => { this.controller.close(); });

        Button('保存')
          .fontSize(15)
          .fontColor('#ffffff')
          .backgroundColor(COLOR_PRIMARY)
          .layoutWeight(1)
          .height(42)
          .borderRadius(8)
          .onClick((): void => {
            this.onSave(this.noteText);
            this.controller.close();
          });
      }
      .width('100%')
      .margin({ top: 16 });
    }
    .width('90%')
    .backgroundColor(themeBg(AppConfig.darkMode))
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
    .backgroundColor(themeBg(AppConfig.darkMode))
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
