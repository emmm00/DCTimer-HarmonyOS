// Ported from scrambler/Scrambler.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Tools } from '../cs/min2phase/Tools';
import { Search as Search3 } from '../cs/min2phase/Search';
import { Search as Search4 } from '../cs/threephase/Search';
import { Search as SearchSq } from '../cs/sq12phase/Search';
import { Cube } from './Cube';
import { Clock } from './Clock';
import { Megaminx } from './Megaminx';
import { SQ1 } from './SQ1';
import { MegaScramble } from './MegaScramble';
import { LatchCube } from './LatchCube';
import { Redi } from './Redi';
import { MasterPyraminx } from './MasterPyraminx';
import { StringUtils } from '../util/StringUtils';
import { SmartCubeTraining } from '../model/SmartCubeTraining';
import { AppGlobals } from '../model/AppGlobals';
import { Cross } from '../solver/Cross';
import { EOline } from '../solver/EOline';
import { Roux } from '../solver/Roux';
import { Petrus } from '../solver/Petrus';
import { Sq1Shape } from '../solver/Sq1Shape';
import { Cube2Face } from '../solver/Cube2Face';
import { Cube2Layer } from '../solver/Cube2Layer';
import { PyraminxV } from '../solver/PyraminxV';
import { Cube222 } from '../solver/Cube222';
import { Pyraminx } from '../solver/Pyraminx';
import { Skewb } from '../solver/Skewb';
import { SkewbFCN } from '../solver/SkewbFCN';
import { Floppy } from '../solver/Floppy';
import { Domino } from '../solver/Domino';
import { Tower } from '../solver/Tower';
import { RTower } from '../solver/RTower';
import { Gear } from '../solver/Gear';
import { EightPuzzle } from '../solver/EightPuzzle';
import { FifteenPuzzle } from '../solver/FifteenPuzzle';
import { Maple } from '../solver/Maple';
import { CubeRU } from '../solver/CubeRU';
import { RouxMU } from '../solver/RouxMU';
import { HalfTurn } from '../solver/HalfTurn';
import { Utils as SolverUtils } from '../solver/Utils';

// ============ color constants (android.graphics.Color values) ============
export class ColorConst {
  static BLACK = 0xff000000;
  static WHITE = 0xffffffff;
  static RED = 0xffff0000;
  static YELLOW = 0xffffff00;
  static BLUE = 0xff0000ff;
  static GREEN = 0xff00ff00;
  static GRAY = 0xff808080;
}

export class PaintState {
  style = 0; // Paint.Style.FILL
  color = 0xff000000;
  textSize = 14;
  textAlign = 1; // Paint.Align.CENTER

  setColor(cl: number): void {
    this.color = cl;
  }

  setStyle(s: number): void {
    this.style = s;
  }

  setTextSize(s: number): void {
    this.textSize = s;
  }

  setTextAlign(a: number): void {
    this.textAlign = a;
  }
}

export interface ScrambleCanvas {
  drawRect(l: number, t: number, r: number, b: number, p: PaintState): void;
  drawCircle(cx: number, cy: number, rad: number, p: PaintState): void;
  drawPath(pts: number[][], p: PaintState): void;
  drawArc(l: number, t: number, r: number, b: number, startAngle: number, sweepAngle: number, p: PaintState): void;
  drawText(txt: string, x: number, y: number, p: PaintState): void;
  save(): void;
  restore(): void;
  rotate(deg: number, cx: number, cy: number): void;
}

export class Scrambler {
  static TYPE_SQ1 = 1;
  static TYPE_CLK = 12;
  static TYPE_MEGA = 18;
  static TYPE_PYR = 17;
  static TYPE_SKW = 16;
  static TYPE_133 = 13;
  static TYPE_233 = 14;
  static TYPE_223 = 15;
  static TYPE_224 = 19;
  static TYPE_334 = 20;
  static TYPE_335 = 21;
  static TYPE_336 = 22;
  static TYPE_337 = 23;
  static TYPE_GEAR = 24;
  static TYPE_15P = 25;
  static TYPE_15PB = 26;
  static TYPE_HLCT = 27;
  static TYPE_UFO = 28;
  static TYPE_REDI = 29;
  static TYPE_REL = 30;
  static TYPE_8PZ = 31;
  static TYPE_FTO = 32;
  static TYPE_MAPLE = 33;
  static TYPE_CTO = 34;

  static SCRAMBLE_NONE = 0;
  static SCRAMBLING = 1;
  static SCRAMBLING_NEXT = 2;
  static SCRAMBLE_DONE = 3;

  private static defaultLength: number[][] = [
    [0, 15, 15, 0, 0, 0, 0, 0, 0, 0, 0], // 2x2
    [25, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 25], // 3x3
    [40, 40, 40, 8, 40, 0], // 4x4
    [60, 60, 8], // 5x5
    [80, 80, 80, 8], // 6x6
    [100, 100, 100, 8], // 7x7
    [70, 70], // mega
    [0, 15, 0], // pyr
    [40, 20, 0, 0, 0], // sq1
    [0, 0, 0, 0], // clock
    [0, 15, 0], // skewb
    [0, 25, 0, 0, 0, 40, 25, 40, 40, 40, 120, 140, 140, 140], // lmn
    [25, 25], // cmetrick
    [0, 10], // gear
    [25, 25, 25], // siamese
    [80, 80], // 15puzzle
    [25, 40, 20, 20, 25, 25, 8, 40, 0, 0, 0], // other
    [0, 0, 0, 25, 25, 25, 0, 15], // 3x3 subsets
    [30, 25], // bandage
    [30, 20], // mega subsets
    [5, 0, 0, 0, 0, 0, 0], // relay
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], // 3x3 CFOP
    [0, 0, 0], // 3x3 Roux
    [0, 0, -60, 0, 0, 0, 0, 0, -70, 0, 0, 0, 0, -80, -100, 0, -60, 5, 25] // wca
  ];
  private static rotate5: string[] = ['', '3Fw', "3Fw'", '3Fw 3Uw', '3Fw 3Uw2', "3Fw 3Uw'", "3Fw' 3Uw", "3Fw' 3Uw2", "3Fw' 3Uw'", '3Rw', '3Rw2', "3Rw'",
    '3Rw 3Uw', '3Rw 3Uw2', "3Rw 3Uw'", '3Rw2 3Uw', '3Rw2 3Uw2', "3Rw2 3Uw'", "3Rw' 3Uw", "3Rw' 3Uw2", "3Rw' 3Uw'", '3Uw', '3Uw2', "3Uw'"];
  private static rotateIdx: number[] = [-1, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0];
  static cubesuff: string[] = ['', '2', "'"];
  static cubesuff2: string[] = ['', "'"];

  private static FTO_CORN_FACELETS: number[] = [
    0, 54, 9, 63, 4, 53, 22, 62, 8, 67, 35, 49, 27, 36, 18, 45,
    13, 44, 31, 71, 26, 40, 17, 58
  ];
  private static FTO_EDGE_FACELETS: number[] = [
    1, 57, 3, 64, 6, 51, 28, 39, 21, 37, 15, 42,
    12, 55, 10, 66, 33, 69, 30, 46, 19, 48, 24, 60
  ];
  private static FTO_CTUF_FACELETS: number[] = [
    2, 5, 7, 11, 14, 16, 20, 23, 25, 29, 32, 34
  ];
  private static FTO_CTRL_FACELETS: number[] = [
    38, 41, 43, 47, 50, 52, 65, 68, 70, 56, 59, 61
  ];
  private static FTO_CTRL_COLORS: number[] = [4, 5, 7, 6];
  private static FTO_FACELET_DRAW_ORDER: number[][] = [
    [4, 5, 6, 7, 8, 1, 2, 3, 0],
    [8, 7, 3, 2, 0, 6, 5, 1, 4],
    [8, 7, 3, 2, 0, 6, 5, 1, 4],
    [4, 5, 6, 7, 8, 1, 2, 3, 0]
  ];
  private static CTO_FACELET_DRAW_ORDER: number[][] = [
    [0, 3, 5, 7, 8, 1, 4, 6, 2],
    [2, 4, 1, 3, 0, 6, 7, 5, 8],
    [2, 4, 1, 3, 0, 6, 7, 5, 8],
    [0, 3, 5, 7, 8, 1, 4, 6, 2]
  ];
  private static CTO_BOTTOM_FACELET_DRAW_ORDER: number[][] = [
    [2, 4, 6, 7, 8, 1, 3, 5, 0],
    [0, 3, 1, 4, 2, 5, 7, 6, 8],
    [0, 3, 1, 4, 2, 5, 7, 6, 8],
    [2, 4, 6, 7, 8, 1, 3, 5, 0]
  ];
  private static CTO_FACE_COLORS: number[] = [5, 3, 7, 0, 2, 4, 1, 6];
  private static CTO_MOVE_CYCLES: number[][][] = [
    [
      [5, 14, 23, 32], [6, 15, 24, 33], [7, 16, 25, 34], [8, 17, 26, 35]
    ],
    [
      [19, 60, 64, 33], [21, 58, 66, 31], [23, 55, 68, 28], [18, 56, 63, 29]
    ],
    [
      [64, 41, 1, 32], [67, 39, 4, 30], [69, 37, 6, 28], [65, 36, 2, 27]
    ],
    [
      [59, 50, 41, 68], [60, 51, 42, 69], [61, 52, 43, 70], [62, 53, 44, 71]
    ],
    [
      [1, 42, 46, 15], [3, 40, 48, 13], [5, 37, 50, 10], [0, 38, 45, 11]
    ],
    [
      [19, 14, 46, 59], [22, 12, 49, 57], [24, 10, 51, 55], [20, 9, 47, 54]
    ]
  ];
  private static FTO_MOVE_IDX: number[] = [0, 8, 2, 10, 14, 4, 12, 6];
  private static FTO_MOVE_CP: number[][] = [
    [1, 2, 0, 3, 4, 5], [4, 1, 2, 3, 5, 0],
    [0, 5, 2, 1, 4, 3], [0, 1, 3, 4, 2, 5],
    [0, 1, 2, 5, 3, 4], [0, 3, 1, 2, 4, 5],
    [5, 0, 2, 3, 4, 1], [2, 1, 4, 3, 0, 5]
  ];
  private static FTO_MOVE_CO: number[][] = [
    [0, 0, 0, 0, 0, 0], [1, 0, 0, 0, 1, 0],
    [0, 1, 0, 0, 0, 1], [0, 0, 1, 1, 0, 0],
    [0, 0, 0, 0, 0, 0], [0, 1, 1, 0, 0, 0],
    [1, 1, 0, 0, 0, 0], [1, 0, 1, 0, 0, 0]
  ];
  private static FTO_MOVE_EP: number[][] = [
    [2, 0, 1, 3, 4, 5, 6, 7, 8, 9, 10, 11],
    [0, 1, 2, 3, 4, 6, 7, 5, 8, 9, 10, 11],
    [0, 1, 2, 3, 10, 5, 6, 7, 8, 9, 11, 4],
    [0, 1, 2, 8, 4, 5, 6, 7, 9, 3, 10, 11],
    [0, 1, 2, 4, 5, 3, 6, 7, 8, 9, 10, 11],
    [0, 1, 10, 3, 4, 5, 6, 7, 8, 2, 9, 11],
    [6, 1, 2, 3, 4, 5, 11, 7, 8, 9, 10, 0],
    [0, 8, 2, 3, 4, 5, 6, 1, 7, 9, 10, 11]
  ];
  private static FTO_MOVE_UF: number[][] = [
    [1, 2, 0, 3, 4, 5, 6, 7, 8, 9, 10, 11],
    [0, 1, 2, 4, 5, 3, 6, 7, 8, 9, 10, 11],
    [0, 1, 2, 3, 4, 5, 7, 8, 6, 9, 10, 11],
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 9],
    [0, 1, 2, 3, 9, 10, 5, 7, 4, 8, 6, 11],
    [0, 6, 7, 3, 4, 5, 11, 9, 8, 2, 10, 1],
    [5, 3, 2, 8, 4, 7, 6, 0, 1, 9, 10, 11],
    [11, 1, 10, 2, 0, 5, 6, 7, 8, 9, 3, 4]
  ];
  private static FTO_MOVE_RL: number[][] = [
    [0, 1, 2, 3, 6, 7, 11, 9, 8, 5, 10, 4],
    [0, 9, 10, 3, 4, 5, 2, 7, 1, 8, 6, 11],
    [5, 3, 2, 11, 4, 10, 6, 7, 8, 9, 0, 1],
    [8, 1, 7, 2, 0, 5, 6, 3, 4, 9, 10, 11],
    [1, 2, 0, 3, 4, 5, 6, 7, 8, 9, 10, 11],
    [0, 1, 2, 4, 5, 3, 6, 7, 8, 9, 10, 11],
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 9],
    [0, 1, 2, 3, 4, 5, 7, 8, 6, 9, 10, 11]
  ];

  // color scheme (from SharedPreferences in Java; set by UI)
  static schemeN: number[] = [ColorConst.YELLOW, ColorConst.BLUE, ColorConst.RED, ColorConst.WHITE, 0xff009900, 0xffff9900];
  static schemeP: number[] = [ColorConst.RED, 0xff009900, ColorConst.BLUE, ColorConst.YELLOW];
  static schemeQ: number[] = [ColorConst.WHITE, ColorConst.BLUE, 0xffff9900, ColorConst.YELLOW, 0xff009900, ColorConst.RED];
  static schemeW: number[] = [ColorConst.YELLOW, ColorConst.BLUE, ColorConst.RED, ColorConst.WHITE, 0xff009900, 0xffff9900];
  static schemeFto: number[] = [ColorConst.WHITE, 0xff880088, 0xff00dd00, ColorConst.RED, ColorConst.BLUE, 0xffbbbbbb, ColorConst.YELLOW, 0xffff9900];

  private category = 0;
  private scramble = '';
  private scrambleList: string[] = [];
  private cubeState = '';
  private scrambleIdx = 0;
  private hint = '';
  imageType = 0;
  scrambleLen = 0;
  private cube3: Search3 = new Search3();
  private cube4: Search4 = new Search4();
  private cubesq: SearchSq = new SearchSq();
  private megaminx: Megaminx = new Megaminx();
  private clock: Clock = new Clock();

  getScramble(): string {
    return this.scramble;
  }

  getScrambleWithHint(landscape: boolean): string {
    if (this.scramble == null) {
      return 'error';
    }
    if (landscape) {
      return this.scramble.replace('\n', ' ') + this.hint;
    }
    return this.scramble + this.hint;
  }

  getHint(): string {
    return this.hint;
  }

  setScramble(scramble: string): void {
    this.scramble = scramble;
    this.hint = '';
    this.cubeState = '';
  }

  setScrambleState(cubeState: string): void {
    this.cubeState = cubeState;
  }

  setSingleScramble(category: number, scramble: string, cubeState: string, imageType: number): void {
    this.category = category;
    this.scramble = scramble;
    this.cubeState = cubeState;
    this.imageType = imageType;
    this.hint = '';
    this.scrambleIdx = 0;
    this.scrambleList = [scramble];
  }

  getCategory(): number {
    return this.category;
  }

  setCategory(category: number): void {
    this.category = category;
  }

  getScrambleLen(): number {
    return this.scrambleLen;
  }

  setScrambleLen(len: number): void {
    this.scrambleLen = len;
  }

  getCubeState(): string {
    if ((this.cubeState == null || this.cubeState.length == 0) && this.is333Scramble() && this.scramble != null && this.scramble.length > 0) {
      return Tools.fromScramble(this.scramble);
    }
    return this.cubeState;
  }

  getImageType(): number {
    if (this.category == 521) {
      return 0;
    }
    return this.imageType;
  }

  setImageType(imageType: number): void {
    this.imageType = imageType;
  }

  getScrambleListSize(): number {
    return this.scrambleList.length;
  }

  private static scrambleIndicator: string[][] = [
    ['(2x2)', '(3x3)', '(4x4)', '(5x5)', '(6x6)', '(7x7)', '(3OH)', '(3FT)', '(Pyraminx)', '(Square-1)', '(Skewb)', '(Clock)', '(Megaminx)'],
    ['(2x2)', '(3x3)', '(4x4)', '(5x5)', '(3OH)', '(Pyraminx)', '(Square-1)', '(Skewb)', '(Clock)', '(Megaminx)']
  ];

  getScrambleWithIndicator(landscape: boolean): string {
    if (this.scrambleIdx >= this.scrambleList.length) {
      this.scrambleIdx = this.scrambleList.length - 1;
    }
    let scramble = this.scrambleList[this.scrambleIdx];
    if (landscape) {
      scramble = scramble.replace('\n', ' ');
    }
    if (this.category > 640 && this.category < 646) {
      return Scrambler.scrambleIndicator[0][this.scrambleIdx] + '\n' + scramble;
    } else if (this.category == 646) {
      return Scrambler.scrambleIndicator[1][this.scrambleIdx] + '\n' + scramble;
    }
    return '(' + (this.scrambleIdx + 1) + '/' + this.scrambleList.length + ')\n' + scramble;
  }

  getNextScramble(landscape: boolean): string {
    this.scrambleIdx++;
    if (this.scrambleIdx >= this.scrambleList.length) {
      this.scrambleIdx = 0;
    }
    return this.getScrambleWithIndicator(landscape);
  }

  getLastScramble(landscape: boolean): string {
    this.scrambleIdx--;
    if (this.scrambleIdx < 0) {
      this.scrambleIdx = this.scrambleList.length - 1;
    }
    return this.getScrambleWithIndicator(landscape);
  }

  updateHint(idx: number): void {
    if (idx == 0) {
      this.hint = '';
    } else if (this.is333Scramble()) {
      switch (idx) {
        case 1:
          this.hint = Cross.solveCross(this.scramble, AppGlobals.solverType[1]);
          break;
        case 2:
          this.hint = Cross.solveXcross(this.scramble, AppGlobals.solverType[1]);
          break;
        case 3:
          this.hint = EOline.solveEoline(this.scramble, AppGlobals.solverType[1]);
          break;
        case 4:
          this.hint = Roux.solveRoux1(this.scramble, AppGlobals.solverType[3]);
          break;
        case 5:
          this.hint = Petrus.solvePetrus(this.scramble, AppGlobals.solverType[2]);
          break;
        case 6:
          this.hint = Cross.solveEofc(this.scramble, AppGlobals.solverType[1]);
          break;
      }
    } else if (this.isSqScramble()) {
      this.hint = Sq1Shape.solve(idx, this.scramble);
    } else if (this.is222Scramble()) {
      if (idx == 1) {
        this.hint = Cube2Face.solveFace(this.scramble, AppGlobals.solverType[4]);
      } else {
        this.hint = Cube2Layer.solveFirstLayer(this.scramble, AppGlobals.solverType[4]);
      }
    } else if (this.isPyrScramble()) {
      this.hint = PyraminxV.solveV(this.scramble, idx);
    }
  }

  parseScramble(category: number, scramble: string): void {
    this.category = category;
    this.scramble = scramble;
    if (category == -29 || (category >= 0 && category < 32)) { // 二阶
      this.imageType = StringUtils.getImageType1(scramble, 1);
    } else if (category == -32 || category == -27 || category == -25 || category == -28 || category == -26 ||
      (category > 31 && category < 64) || (category > 543 && category < 576) || SmartCubeTraining.isSmart333Training(category)) {
      this.imageType = StringUtils.getImageType1(scramble, 2);
    } else if (category == -31 || category == -17 || (category > 63 && category < 96)) { // 四阶
      this.imageType = StringUtils.getImageType1(scramble, 3);
    } else if (category == -30 || category == -16 || (category > 95 && category < 128)) { // 五阶
      this.imageType = StringUtils.getImageType1(scramble, 4);
    } else if (category == -19 || (category > 127 && category < 160)) { // 六阶
      this.imageType = StringUtils.getImageType1(scramble, 5);
    } else if (category == -18 || (category > 159 && category < 192)) { // 七阶
      this.imageType = StringUtils.getImageType1(scramble, 6);
    } else if (category == -23 || (category > 223 && category < 256)) { // 金字塔
      this.imageType = StringUtils.getImageType1(scramble, 7);
    } else if (category == -20 || (category > 319 && category < 352)) { // 斜转
      this.imageType = StringUtils.getImageType1(scramble, 8);
    } else if (category == -24 || (category > 191 && category < 224)) { // 五魔
      this.imageType = StringUtils.getImageType1(scramble, 10);
      if (this.imageType == Scrambler.TYPE_MEGA) {
        this.megaminx.image(scramble);
      }
    } else if (category == -22 || (category > 255 && category < 288)) { // SQ1
      this.imageType = StringUtils.getImageType1(scramble, 9);
    } else if (category == -21 || (category > 287 && category < 320)) { // 魔表
      this.imageType = StringUtils.getImageType1(scramble, 11);
      if (this.imageType == Scrambler.TYPE_CLK) {
        this.clock.image(scramble);
      }
    } else if (category == -14 || category == 517) { // FTO
      this.imageType = Scrambler.TYPE_FTO;
    } else if (category == 521) { // CTO
      this.imageType = Scrambler.TYPE_CTO;
    } else if (category == 522) { // 枫叶
      this.imageType = Scrambler.TYPE_MAPLE;
    }
  }

  generateScramble(category: number, resetLength: boolean): void {
    this.category = category;
    let scr = '';
    this.scrambleList = [];
    this.hint = '';
    this.cubeState = '';
    this.scrambleIdx = 0;
    if (resetLength) {
      if (category < 0) {
        this.scrambleLen = Scrambler.defaultLength[23][category & 31];
      } else {
        this.scrambleLen = Scrambler.defaultLength[category >> 5][category & 31];
      }
    }
    let sb = '';
    let s2 = '';
    let s3 = '';
    let s4 = '';
    let s5 = '';
    let s6 = '';
    let s7 = '';
    let oh = '';
    let ft = '';
    let pyr = '';
    let sq1 = '';
    let skw = '';
    let clk = '';
    let mega = '';
    switch (category) {
      case -32: // 三速
      case -27: // 三单
      case -25: // 脚拧
        scr = this.scramble333();
        this.imageType = 3;
        this.scrambleList.push(scr);
        this.hint = this.solve333(scr);
        break;
      case -31: // 四速
        scr = this.cube4.randomState(false);
        this.imageType = scr.startsWith('Error') ? 0 : 4;
        this.scrambleList.push(scr);
        break;
      case -30: // 五速
        scr = this.scrambleCube(5);
        this.imageType = 5;
        this.scrambleList.push(scr);
        break;
      case -29: // 二阶
        scr = Cube222.scrambleWCA();
        this.imageType = 2;
        this.scrambleList.push(scr);
        this.hint = this.solve222(scr);
        break;
      case -28: // 三盲
        {
          const cube = Tools.randomCube();
          scr = this.cube3.solution(cube, true, () => Math.random());
          this.imageType = scr.startsWith('Error') ? 0 : 3;
          this.scrambleList.push(scr);
        }
        break;
      case -26: // 最少步
        {
          let axis1 = 'F';
          let axis2 = 'F';
          let axis3 = 'R';
          let axis4 = 'R';
          do {
            scr = this.scramble333();
            const seq = scr.split(' ');
            if (seq.length < 2) {
              axis1 = 'F';
              axis2 = 'F';
              axis3 = 'R';
              axis4 = 'R';
            } else {
              axis1 = seq[0].charAt(0);
              axis2 = seq[1].charAt(0);
              axis3 = seq[seq.length - 1].charAt(0);
              axis4 = seq[seq.length - 2].charAt(0);
            }
          } while (axis1 == 'F' || (axis1 == 'B' && axis2 == 'F') || axis3 == 'R' || (axis3 == 'L' && axis4 == 'R'));
          scr = "R' U' F " + scr + "R' U' F";
          this.imageType = 3;
          this.scrambleList.push(scr);
        }
        break;
      case -24: // 五魔
        scr = this.megaminx.scramblestring(Math.abs(this.scrambleLen));
        this.imageType = Scrambler.TYPE_MEGA;
        this.scrambleList.push(scr);
        break;
      case -23: // 金字塔
        scr = Pyraminx.scrambleWCA();
        this.imageType = Scrambler.TYPE_PYR;
        this.scrambleList.push(scr);
        if (AppGlobals.solvePyr > 0) {
          this.hint = PyraminxV.solveV(scr, AppGlobals.solvePyr);
        }
        break;
      case -22: // SQ1
        scr = this.cubesq.scrambleWCA();
        this.imageType = Scrambler.TYPE_SQ1;
        this.scrambleList.push(scr);
        this.hint = Sq1Shape.solve(AppGlobals.solveSq1, scr);
        break;
      case -21: // 魔表
        scr = this.clock.scramble();
        this.imageType = Scrambler.TYPE_CLK;
        this.scrambleList.push(scr);
        break;
      case -20: // 斜转
        scr = Skewb.scrambleWCA();
        this.imageType = Scrambler.TYPE_SKW;
        this.scrambleList.push(scr);
        break;
      case -19: // 六阶
        scr = MegaScramble.megascramble2([['U', 'D', 'Uw', 'Dw', '3Uw'], ['R', 'L', 'Rw', 'Lw', '3Rw'], ['F', 'B', 'Fw', 'Bw', '3Fw']], Scrambler.cubesuff, Math.abs(this.scrambleLen));
        this.imageType = 6;
        this.scrambleList.push(scr);
        break;
      case -18: // 七阶
        scr = MegaScramble.megascramble2([['U', 'D', 'Uw', 'Dw', '3Uw', '3Dw'], ['R', 'L', 'Rw', 'Lw', '3Rw', '3Lw'], ['F', 'B', 'Fw', 'Bw', '3Fw', '3Bw']], Scrambler.cubesuff, Math.abs(this.scrambleLen));
        this.imageType = 7;
        this.scrambleList.push(scr);
        break;
      case -17: // 四盲
        scr = this.cube4.randomState(true);
        this.imageType = 4;
        this.scrambleList.push(scr);
        break;
      case -16: // 五盲
        scr = this.scrambleCube(5);
        {
          const moves = scr.split(' ');
          const lm = moves[moves.length - 1];
          let idx: number;
          if (lm.startsWith('Bw')) {
            idx = 2;
          } else if (lm.startsWith('Lw')) {
            idx = 1;
          } else if (lm.startsWith('Dw')) {
            idx = 0;
          } else {
            idx = 4;
          }
          let rot: number;
          do {
            rot = Math.floor(Math.random() * 24);
          } while (idx == Scrambler.rotateIdx[rot]);
          scr += ' ' + Scrambler.rotate5[rot];
        }
        this.imageType = 5;
        this.scrambleList.push(scr);
        break;
      case -15: // 多盲
        sb = '';
        for (let j = 1; j <= this.scrambleLen; j++) {
          const face = Tools.randomCube();
          const sol = this.cube3.solution(face, true, () => Math.random());
          sb += j + ') ' + sol;
          this.scrambleList.push(sol);
          if (j < this.scrambleLen) {
            sb += '\n';
          }
        }
        scr = sb;
        this.imageType = Scrambler.TYPE_REL;
        break;
      case -14: // WCA - FTO
        scr = MegaScramble.megascramble2([['U', 'D'], ['F', 'B'], ['L', 'BR'], ['R', 'BL']], Scrambler.cubesuff2, this.scrambleLen);
        this.imageType = Scrambler.TYPE_FTO;
        this.scrambleList.push(scr);
        break;
      case 0: // 2阶-随机状态
        scr = Cube222.scramble();
        this.imageType = 2;
        this.scrambleList.push(scr);
        this.hint = this.solve222(scr);
        break;
      case 1: // 3-gen
        scr = this.scrambleCube(2);
        this.imageType = 2;
        this.scrambleList.push(scr);
        this.hint = this.solve222(scr);
        break;
      case 2: // 6-gen
        scr = MegaScramble.megascramble3([[['U', 'D']], [['R', 'L']], [['F', 'B']]], Scrambler.cubesuff, this.scrambleLen);
        this.imageType = 2;
        this.scrambleList.push(scr);
        break;
      case 3: // CLL
      case 4: // EG1
      case 5: // EG2
        scr = Cube222.scrambleEG(category - 3);
        this.imageType = 2;
        this.scrambleList.push(scr);
        break;
      case 6: // PBL
        scr = Cube222.scramblePBL();
        this.imageType = 2;
        this.scrambleList.push(scr);
        break;
      case 7: // EG
        scr = Cube222.scrambleEG1(AppGlobals.egtype, AppGlobals.egolls);
        this.imageType = 2;
        this.scrambleList.push(scr);
        break;
      case 8: // TCLL+
        scr = Cube222.scrambleTCLL(1);
        this.imageType = 2;
        this.scrambleList.push(scr);
        break;
      case 9: // TCLL-
        scr = Cube222.scrambleTCLL(2);
        this.imageType = 2;
        this.scrambleList.push(scr);
        break;
      case 10: // 无连色
        scr = Cube222.scrambleNobar();
        this.imageType = 2;
        this.scrambleList.push(scr);
        break;
      case 11:
        scr = Cube222.scrambleTEG1(1);
        this.imageType = 2;
        this.scrambleList.push(scr);
        break;
      case 12:
        scr = Cube222.scrambleTEG1(2);
        this.imageType = 2;
        this.scrambleList.push(scr);
        break;
      case 13:
        scr = Cube222.scrambleTEG2(1);
        this.imageType = 2;
        this.scrambleList.push(scr);
        break;
      case 14:
        scr = Cube222.scrambleTEG2(2);
        this.imageType = 2;
        this.scrambleList.push(scr);
        break;
      case 32: // 3阶
        scr = this.scrambleCube(3);
        this.imageType = 3;
        this.scrambleList.push(scr);
        this.hint = this.solve333(scr);
        break;
      case 33:
        scr = this.scramble333();
        this.imageType = 3;
        this.scrambleList.push(scr);
        this.hint = this.solve333(scr);
        break;
      case 34: // F2L
        scr = this.cube3.solution1(this.cubeState = Tools.randomCrossSolved());
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case 35: // OLL
        scr = this.cube3.solution1(this.cubeState = Tools.randomLastLayer());
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case 36: // PLL
        do {
          scr = this.cube3.solution1(this.cubeState = Tools.randomPLL());
        } while (scr.length < 6);
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case 37:
        scr = this.cube3.solution1(this.cubeState = Tools.randomCornerSolved());
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case 38:
        scr = this.cube3.solution1(this.cubeState = Tools.randomEdgeSolved());
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case 39:
        scr = this.cube3.solution1(this.cubeState = Tools.randomLastSlot());
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case 40:
        scr = this.cube3.solution1(this.cubeState = Tools.randomZBLastLayer());
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case 41:
        scr = this.cube3.solution1(this.cubeState = Tools.randomEdgeOfLastLayer());
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case 42:
        scr = this.cube3.solution1(this.cubeState = Tools.randomCornerOfLastLayer());
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case 43:
        switch (Math.floor(Math.random() * 4)) {
          case 0:
            scr = this.cube3.solution1(this.cubeState = Tools.randomState([0, 1, 2, 3, 4, 5, 6, 7], [0, 0, 0, 0, 0, 0, 0, 0], [-1, -1, -1, -1, 4, -1, 6, -1, 8, 9, 10, 11], [-1, -1, -1, -1, 0, -1, 0, -1, 0, 0, 0, 0]));
            break;
          case 1:
            scr = this.cube3.solution1(this.cubeState = Tools.randomState([3, 2, 6, 7, 0, 1, 5, 4], [2, 1, 2, 1, 1, 2, 1, 2], [11, -1, 10, -1, 8, -1, 9, -1, 0, 2, -1, -1], [0, -1, 0, -1, 0, -1, 0, -1, 0, 0, -1, -1])) + "x'";
            break;
          case 2:
            scr = this.cube3.solution1(this.cubeState = Tools.randomState([7, 6, 5, 4, 3, 2, 1, 0], [0, 0, 0, 0, 0, 0, 0, 0], [4, -1, 6, -1, -1, -1, -1, -1, 11, 10, 9, 8], [0, -1, 0, -1, -1, -1, -1, -1, 0, 0, 0, 0])) + 'x2';
            break;
          default:
            scr = this.cube3.solution1(this.cubeState = Tools.randomState([4, 5, 1, 0, 7, 6, 2, 3], [2, 1, 2, 1, 1, 2, 1, 2], [8, -1, 9, -1, 11, -1, 10, -1, -1, -1, 2, 0], [0, -1, 0, -1, 0, -1, 0, -1, -1, -1, 0, 0])) + 'x';
            break;
        }
        this.imageType = scr.startsWith('Error') ? 0 : 3;
        this.scrambleList.push(scr);
        break;
      case 44:
        switch (Math.floor(Math.random() * 4)) {
          case 0:
            scr = this.cube3.solution1(this.cubeState = Tools.randomState([-1, -1, -1, -1, 4, 5, 6, 7], [-1, -1, -1, -1, 0, 0, 0, 0], [-1, -1, -1, -1, 4, -1, 6, -1, 8, 9, 10, 11], [-1, -1, -1, -1, 0, -1, 0, -1, 0, 0, 0, 0]));
            break;
          case 1:
            scr = this.cube3.solution1(this.cubeState = Tools.randomState([3, 2, -1, -1, 0, 1, -1, -1], [2, 1, -1, -1, 1, 2, -1, -1], [11, -1, 10, -1, 8, -1, 9, -1, 0, 2, -1, -1], [0, -1, 0, -1, 0, -1, 0, -1, 0, 0, -1, -1])) + "x'";
            break;
          case 2:
            scr = this.cube3.solution1(this.cubeState = Tools.randomState([7, 6, 5, 4, -1, -1, -1, -1], [0, 0, 0, 0, -1, -1, -1, -1], [4, -1, 6, -1, -1, -1, -1, -1, 11, 10, 9, 8], [0, -1, 0, -1, -1, -1, -1, -1, 0, 0, 0, 0])) + 'x2';
            break;
          default:
            scr = this.cube3.solution1(this.cubeState = Tools.randomState([-1, -1, 1, 0, -1, -1, 2, 3], [-1, -1, 2, 1, -1, -1, 1, 2], [8, -1, 9, -1, 11, -1, 10, -1, -1, -1, 2, 0], [0, -1, 0, -1, 0, -1, 0, -1, -1, -1, 0, 0])) + 'x';
            break;
        }
        this.imageType = scr.startsWith('Error') ? 0 : 3;
        this.scrambleList.push(scr);
        break;
      case 45:
        scr = this.cube3.solution1(this.cubeState = Tools.randomEdgePerm());
        this.imageType = scr.startsWith('Error') ? 0 : 3;
        this.scrambleList.push(scr);
        break;
      case 46:
        scr = this.cube3.solution1(this.cubeState = Tools.randomEdgeOri());
        this.imageType = scr.startsWith('Error') ? 0 : 3;
        this.scrambleList.push(scr);
        break;
      case 47:
        scr = this.cube3.solution1(this.cubeState = Tools.randomCornerPerm());
        this.imageType = scr.startsWith('Error') ? 0 : 3;
        this.scrambleList.push(scr);
        break;
      case 48:
        scr = this.cube3.solution1(this.cubeState = Tools.randomCornerOri());
        this.imageType = scr.startsWith('Error') ? 0 : 3;
        this.scrambleList.push(scr);
        break;
      case 49:
        scr = this.cube3.solution1(this.cubeState = Tools.randomPermutation());
        this.imageType = scr.startsWith('Error') ? 0 : 3;
        this.scrambleList.push(scr);
        break;
      case 50:
        scr = this.cube3.solution1(this.cubeState = Tools.randomOrientation());
        this.imageType = scr.startsWith('Error') ? 0 : 3;
        this.scrambleList.push(scr);
        break;
      case 51:
        scr = this.cube3.solution1(this.cubeState = Tools.randomEasyCross(this.scrambleLen));
        this.imageType = scr.startsWith('Error') ? 0 : 3;
        this.scrambleList.push(scr);
        this.hint = this.solve333(scr);
        break;
      case 52: // 2gll
        scr = this.cube3.solution1(this.cubeState = Scrambler.random2GLLState());
        this.imageType = scr.startsWith('Error') ? 0 : 3;
        this.scrambleList.push(scr);
        break;
      case 53: // zbls
        scr = this.cube3.solution1(this.cubeState = Tools.randomZBLastSlot());
        this.imageType = scr.startsWith('Error') ? 0 : 3;
        this.scrambleList.push(scr);
        break;
      case 54: // zzll
        scr = this.cube3.solution1(this.cubeState = Tools.randomZZLastLayer());
        this.imageType = scr.startsWith('Error') ? 0 : 3;
        this.scrambleList.push(scr);
        break;
      case 55: // 3循环棱块
        do {
          scr = this.cube3.solution1(this.cubeState = Tools.random3Edge());
        } while (scr.length < 6);
        this.imageType = scr.startsWith('Error') ? 0 : 3;
        this.scrambleList.push(scr);
        break;
      case 56: // 3循环角块
        do {
          scr = this.cube3.solution1(this.cubeState = Tools.random3Corner());
        } while (scr.length < 6);
        this.imageType = scr.startsWith('Error') ? 0 : 3;
        this.scrambleList.push(scr);
        break;
      case 57: // 傻瓜
        scr = MegaScramble.megascramble2([['turn the top face ', 'turn the bottom face '], ['turn the right face ', 'turn the left face '], ['turn the front face ', 'turn the back face ']], ['clockwise by 90 degrees', 'by 180 degrees', 'counterclockwise by 90 degrees'], this.scrambleLen);
        if (scr.charAt(0) == 't') {
          scr = 'T' + scr.substring(1);
        }
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case SmartCubeTraining.CATEGORY_333_CFOP_BASE + SmartCubeTraining.SUB_OLL:
        scr = this.cube3.solution1(this.cubeState = Tools.randomLastLayer());
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case SmartCubeTraining.CATEGORY_333_CFOP_BASE + SmartCubeTraining.SUB_PLL:
        do {
          scr = this.cube3.solution1(this.cubeState = Tools.randomPLL());
        } while (scr.length < 6);
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case SmartCubeTraining.CATEGORY_333_CFOP_BASE + SmartCubeTraining.SUB_LAST_LAYER:
        scr = this.cube3.solution1(this.cubeState = Tools.randomLastLayer());
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case SmartCubeTraining.CATEGORY_333_CFOP_BASE + SmartCubeTraining.SUB_F2L:
        scr = this.cube3.solution1(this.cubeState = Tools.randomCrossSolved());
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case SmartCubeTraining.CATEGORY_333_CFOP_BASE + SmartCubeTraining.SUB_ZBLL:
        scr = this.cube3.solution1(this.cubeState = Tools.randomZBLastLayer());
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case SmartCubeTraining.CATEGORY_333_CFOP_BASE + SmartCubeTraining.SUB_ZZLL:
        scr = this.cube3.solution1(this.cubeState = Tools.randomZZLastLayer());
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case SmartCubeTraining.CATEGORY_333_CFOP_BASE + SmartCubeTraining.SUB_2GLL:
        scr = this.cube3.solution1(this.cubeState = Scrambler.random2GLLState());
        this.imageType = scr.startsWith('Error') ? 0 : 3;
        this.scrambleList.push(scr);
        break;
      case SmartCubeTraining.CATEGORY_333_CFOP_BASE + SmartCubeTraining.SUB_ELL:
        scr = this.cube3.solution1(this.cubeState = Tools.randomEdgeOfLastLayer());
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case SmartCubeTraining.CATEGORY_333_CFOP_BASE + SmartCubeTraining.SUB_ZBLS:
        do {
          scr = this.cube3.solution1(this.cubeState = Tools.randomZBLastSlot());
        } while (SmartCubeTraining.isComplete(category, this.cubeState, 0));
        this.imageType = scr.startsWith('Error') ? 0 : 3;
        this.scrambleList.push(scr);
        break;
      case SmartCubeTraining.CATEGORY_333_CFOP_BASE + SmartCubeTraining.SUB_COLL:
        do {
          scr = this.cube3.solution1(this.cubeState = Scrambler.randomCOLLState());
        } while (SmartCubeTraining.isComplete(category, this.cubeState, 0));
        this.imageType = scr.startsWith('Error') ? 0 : 3;
        this.scrambleList.push(scr);
        break;
      case SmartCubeTraining.CATEGORY_333_CFOP_BASE + SmartCubeTraining.SUB_OLLCP:
        do {
          scr = this.cube3.solution1(this.cubeState = Tools.randomLastLayer());
        } while (SmartCubeTraining.isComplete(SmartCubeTraining.CATEGORY_333_CFOP_BASE + SmartCubeTraining.SUB_OLL, this.cubeState, 0));
        this.imageType = scr.startsWith('Error') ? 0 : 3;
        this.scrambleList.push(scr);
        break;
      case SmartCubeTraining.CATEGORY_333_CFOP_BASE + SmartCubeTraining.SUB_EOCP:
        do {
          scr = this.cube3.solution1(this.cubeState = Tools.randomLastLayer());
        } while (SmartCubeTraining.isComplete(SmartCubeTraining.CATEGORY_333_CFOP_BASE + SmartCubeTraining.SUB_OLL, this.cubeState, 0) ||
          SmartCubeTraining.isComplete(SmartCubeTraining.CATEGORY_333_CFOP_BASE + SmartCubeTraining.SUB_ZBLS, this.cubeState, 0));
        this.imageType = scr.startsWith('Error') ? 0 : 3;
        this.scrambleList.push(scr);
        break;
      case SmartCubeTraining.CATEGORY_333_CFOP_BASE + SmartCubeTraining.SUB_CLL:
        do {
          scr = this.cube3.solution1(this.cubeState = Tools.randomLastLayer());
        } while (SmartCubeTraining.isComplete(SmartCubeTraining.CATEGORY_333_CFOP_BASE + SmartCubeTraining.SUB_OLL, this.cubeState, 0) ||
          SmartCubeTraining.isComplete(category, this.cubeState, 0));
        this.imageType = scr.startsWith('Error') ? 0 : 3;
        this.scrambleList.push(scr);
        break;
      case SmartCubeTraining.CATEGORY_333_ROUX_BASE + SmartCubeTraining.SUB_ROUX_CMLL:
        do {
          scr = this.cube3.solution1(this.cubeState = Scrambler.randomRouxCMLLState());
        } while (SmartCubeTraining.isComplete(category, this.cubeState, 0));
        this.imageType = scr.startsWith('Error') ? 0 : 3;
        this.scrambleList.push(scr);
        break;
      case SmartCubeTraining.CATEGORY_333_ROUX_BASE + SmartCubeTraining.SUB_ROUX_LSE:
        do {
          scr = this.cube3.solution1(this.cubeState = Scrambler.randomRouxLSEState());
        } while (SmartCubeTraining.isComplete(category, this.cubeState, 0));
        this.imageType = scr.startsWith('Error') ? 0 : 3;
        this.scrambleList.push(scr);
        break;
      case SmartCubeTraining.CATEGORY_333_ROUX_BASE + SmartCubeTraining.SUB_ROUX_L10P:
        do {
          scr = this.cube3.solution1(this.cubeState = Scrambler.randomRouxCMLLState());
        } while (SmartCubeTraining.isComplete(category, this.cubeState, 0));
        this.imageType = scr.startsWith('Error') ? 0 : 3;
        this.scrambleList.push(scr);
        break;
      case 64: // 4阶
        scr = this.scrambleCube(4);
        this.imageType = 4;
        this.scrambleList.push(scr);
        break;
      case 65:
        scr = MegaScramble.megascramble2([['U', 'D', 'u'], ['R', 'L', 'r'], ['F', 'B', 'f']], Scrambler.cubesuff, this.scrambleLen);
        this.imageType = 4;
        this.scrambleList.push(scr);
        break;
      case 66:
        scr = MegaScramble.yj4x4(this.scrambleLen);
        this.imageType = 4;
        this.scrambleList.push(scr);
        break;
      case 67:
        scr = MegaScramble.edgescramble('Rw Bw2', ["Bw2 Rw'", 'Bw2 U2 Rw U2 Rw U2 Rw U2 Rw'], ['Uw'], this.scrambleLen);
        this.imageType = 4;
        this.scrambleList.push(scr);
        break;
      case 68:
        scr = MegaScramble.megascramble2([['U', 'u'], ['R', 'r']], Scrambler.cubesuff, this.scrambleLen);
        this.imageType = 4;
        this.scrambleList.push(scr);
        break;
      case 69: // TODO
        scr = this.cube4.randomCenter();
        this.imageType = 4;
        this.scrambleList.push(scr);
        break;
      case 96: // 5阶
        scr = this.scrambleCube(5);
        this.imageType = 5;
        this.scrambleList.push(scr);
        break;
      case 97:
        scr = MegaScramble.megascramble2([['U', 'D', 'u', 'd'], ['R', 'L', 'r', 'l'], ['F', 'B', 'f', 'b']], Scrambler.cubesuff, this.scrambleLen);
        this.imageType = 5;
        this.scrambleList.push(scr);
        break;
      case 98:
        scr = MegaScramble.edgescramble('Rw R Bw B', ["B' Bw' R' Rw'", "B' Bw' R' U2 Rw U2 Rw U2 Rw U2 Rw"], ['Uw', 'Dw'], this.scrambleLen);
        this.imageType = 5;
        this.scrambleList.push(scr);
        break;
      case 128: // 6阶
        scr = this.scrambleCube(6);
        this.imageType = 6;
        this.scrambleList.push(scr);
        break;
      case 129:
        scr = MegaScramble.megascramble2([['U', 'D', 'u', 'd', '3u'], ['R', 'L', 'r', 'l', '3r'], ['F', 'B', 'f', 'b', '3f']], Scrambler.cubesuff, this.scrambleLen);
        this.imageType = 6;
        this.scrambleList.push(scr);
        break;
      case 130:
        scr = MegaScramble.megascramble2([['U', 'D', 'U\u00B2', 'D\u00B2', 'U\u00B3'], ['R', 'L', 'R\u00B2', 'L\u00B2', 'R\u00B3'], ['F', 'B', 'F\u00B2', 'B\u00B2', 'F\u00B3']], Scrambler.cubesuff, this.scrambleLen);
        this.imageType = 6;
        this.scrambleList.push(scr);
        break;
      case 131:
        scr = MegaScramble.edgescramble('3r r 3b b', ["3b' b' 3r' r'", "3b' b' 3r' U2 r U2 r U2 r U2 r", "3b' b' r' U2 3r U2 3r U2 3r U2 3r", "3b' b' r2 U2 3r U2 3r U2 3r U2 3r U2 r"],
          ['u', '3u', 'd'], this.scrambleLen);
        this.imageType = 6;
        this.scrambleList.push(scr);
        break;
      case 160: // 7阶
        scr = this.scrambleCube(7);
        this.imageType = 7;
        this.scrambleList.push(scr);
        break;
      case 161:
        scr = MegaScramble.megascramble2([['U', 'D', 'u', 'd', '3u', '3d'], ['R', 'L', 'r', 'l', '3r', '3l'], ['F', 'B', 'f', 'b', '3f', '3b']], Scrambler.cubesuff, this.scrambleLen);
        this.imageType = 7;
        this.scrambleList.push(scr);
        break;
      case 162:
        scr = MegaScramble.megascramble2([['U', 'D', 'U\u00B2', 'D\u00B2', 'U\u00B3', 'D\u00B3'], ['R', 'L', 'R\u00B2', 'L\u00B2', 'R\u00B3', 'L\u00B3'], ['F', 'B', 'F\u00B2', 'B\u00B2', 'F\u00B3', 'B\u00B3']], Scrambler.cubesuff, this.scrambleLen);
        this.imageType = 7;
        this.scrambleList.push(scr);
        break;
      case 163:
        scr = MegaScramble.edgescramble('3r r 3b b', ["3b' b' 3r' r'", "3b' b' 3r' U2 r U2 r U2 r U2 r", "3b' b' r' U2 3r U2 3r U2 3r U2 3r", "3b' b' r2 U2 3r U2 3r U2 3r U2 3r U2 r"],
          ['u', '3u', '3d', 'd'], this.scrambleLen);
        this.imageType = 7;
        this.scrambleList.push(scr);
        break;
      case 192: // 五魔
        scr = this.megaminx.scramblestring(this.scrambleLen);
        this.imageType = Scrambler.TYPE_MEGA;
        this.scrambleList.push(scr);
        break;
      case 193:
        scr = MegaScramble.oldminxscramble(this.scrambleLen);
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 224: // 金字塔
        scr = Pyraminx.scramble();
        this.imageType = Scrambler.TYPE_PYR;
        this.scrambleList.push(scr);
        if (AppGlobals.solvePyr > 0) {
          this.hint = PyraminxV.solveV(scr, AppGlobals.solvePyr);
        }
        break;
      case 225:
        {
          const ss: string[][] = [['', 'b ', "b' "], ['', 'l ', "l' "], ['', 'u ', "u' "], ['', 'r ', "r' "]];
          let cnt = 0;
          const rnd: number[] = new Array<number>(4).fill(0);
          for (let i = 0; i < 4; i++) {
            rnd[i] = Math.floor(Math.random() * 3);
            if (rnd[i] > 0) {
              cnt++;
            }
            if (cnt >= this.scrambleLen) {
              break;
            }
          }
          this.scrambleLen -= cnt;
          scr = ss[0][rnd[0]] + ss[1][rnd[1]] + ss[2][rnd[2]] + ss[3][rnd[3]] +
            MegaScramble.megascramble2([['U'], ['L'], ['R'], ['B']], Scrambler.cubesuff2, this.scrambleLen);
          this.scrambleLen += cnt;
          this.imageType = Scrambler.TYPE_PYR;
          this.scrambleList.push(scr);
          if (AppGlobals.solvePyr > 0) {
            this.hint = PyraminxV.solveV(scr, AppGlobals.solvePyr);
          }
        }
        break;
      case 226: // L4E
        scr = Pyraminx.scrambleL4E();
        this.imageType = Scrambler.TYPE_PYR;
        this.scrambleList.push(scr);
        break;
      case 256: // SQ1
        scr = SQ1.scramblestring(this.scrambleLen);
        this.imageType = Scrambler.TYPE_SQ1;
        this.scrambleList.push(scr);
        this.hint = Sq1Shape.solve(AppGlobals.solveSq1, scr);
        break;
      case 257:
        scr = MegaScramble.sq1Scramble(0, this.scrambleLen);
        this.imageType = Scrambler.TYPE_SQ1;
        this.scrambleList.push(scr);
        this.hint = Sq1Shape.solve(AppGlobals.solveSq1, scr);
        break;
      case 258:
        scr = this.cubesq.scramble();
        this.imageType = Scrambler.TYPE_SQ1;
        this.scrambleList.push(scr);
        this.hint = Sq1Shape.solve(AppGlobals.solveSq1, scr);
        break;
      case 259:
        scr = this.cubesq.scramble1(1037);
        this.imageType = Scrambler.TYPE_SQ1;
        this.scrambleList.push(scr);
        break;
      case 260:
        scr = this.cubesq.scramblePBL(() => Math.random());
        this.imageType = Scrambler.TYPE_SQ1;
        this.scrambleList.push(scr);
        break;
      case 288: // 魔表
        scr = this.clock.scramble();
        this.imageType = Scrambler.TYPE_CLK;
        this.scrambleList.push(scr);
        break;
      case 289:
        scr = this.clock.scrambleJaap(false);
        this.imageType = Scrambler.TYPE_CLK;
        this.scrambleList.push(scr);
        break;
      case 290:
        scr = this.clock.scrambleJaap(true);
        this.imageType = Scrambler.TYPE_CLK;
        this.scrambleList.push(scr);
        break;
      case 291:
        scr = this.clock.scrambleEpo();
        this.imageType = Scrambler.TYPE_CLK;
        this.scrambleList.push(scr);
        break;
      case 320: // Skewb
        scr = Skewb.scramble();
        this.imageType = Scrambler.TYPE_SKW;
        this.scrambleList.push(scr);
        break;
      case 321:
        scr = MegaScramble.megascramble2([['R'], ['U'], ['L'], ['B']], Scrambler.cubesuff2, this.scrambleLen);
        this.imageType = Scrambler.TYPE_SKW;
        this.scrambleList.push(scr);
        break;
      case 322: // L2L
        scr = Skewb.scrambleL2L();
        this.imageType = Scrambler.TYPE_SKW;
        this.scrambleList.push(scr);
        break;
      case 352: // MxNxL
        scr = Floppy.scramble();
        this.imageType = Scrambler.TYPE_133;
        this.scrambleList.push(scr);
        break;
      case 353:
        scr = MegaScramble.megascramble2([['R', 'L'], ['U', 'D']], Scrambler.cubesuff, this.scrambleLen);
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 354:
        scr = Domino.scramble();
        this.imageType = Scrambler.TYPE_233;
        this.scrambleList.push(scr);
        break;
      case 355:
        scr = Tower.scramble();
        this.imageType = Scrambler.TYPE_223;
        this.scrambleList.push(scr);
        break;
      case 356:
        scr = RTower.scramble();
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 357: // 334
        scr = MegaScramble.megascramble3([[['U', "U'", 'U2'], ['u', "u'", 'u2']], [['R2', 'L2', 'M2']], [['F2', 'B2', 'S2']]], null, this.scrambleLen);
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 358: // 335
        scr = MegaScramble.megascramble3([[['U', "U'", 'U2'], ['D', "D'", 'D2']], [['R2'], ['L2']], [['F2'], ['B2']]], null, this.scrambleLen) +
          '/ ' + this.scramble333();
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 359: // 336
        scr = MegaScramble.megascramble3([[['U', "U'", 'U2'], ['u', "u'", 'u2'], ['3u', "3u'", '3u2']], [['R2', 'L2', 'M2']], [['F2', 'B2', 'S2']]], null, this.scrambleLen);
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 360: // 337
        scr = MegaScramble.megascramble3([[['U', "U'", 'U2'], ['u', "u'", 'u2'], ['D', "D'", 'D2'], ['d', "d'", 'd2']], [['R2'], ['L2']], [['F2'], ['B2']]], null, this.scrambleLen) +
          '/ ' + this.scramble333();
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 361: // 446
        scr = MegaScramble.megascramble3([[['U', "U'", 'U2'], ['D', "D'", 'D2']], [['R2', 'r2', 'L2']], [['F2', 'f2', 'B2']]], null, this.scrambleLen) +
          '/ ' + MegaScramble.megascramble2([['U', 'u', 'D'], ['R', 'r', 'L'], ['F', 'f', 'B']], Scrambler.cubesuff, this.scrambleLen);
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 362: // 8x8
        scr = this.scrambleCube(8);
        this.imageType = 8;
        this.scrambleList.push(scr);
        break;
      case 363: // 9x9
        scr = this.scrambleCube(9);
        this.imageType = 9;
        this.scrambleList.push(scr);
        break;
      case 364: // 10x10
        scr = this.scrambleCube(10);
        this.imageType = 10;
        this.scrambleList.push(scr);
        break;
      case 365: // 11x11
        scr = this.scrambleCube(11);
        this.imageType = 11;
        this.scrambleList.push(scr);
        break;
      case 384: // Cmetrick
        scr = MegaScramble.megascramble3([[['U<', 'U>', 'U2'], ['E<', 'E>', 'E2'], ['D<', 'D>', 'D2']], [['R^', 'Rv', 'R2'], ['M^', 'Mv', 'M2'], ['L^', 'Lv', 'L2']]], null, this.scrambleLen);
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 385:
        scr = MegaScramble.megascramble3([[['U<', 'U>', 'U2'], ['D<', 'D>', 'D2']], [['R^', 'Rv', 'R2'], ['L^', 'Lv', 'L2']]], null, this.scrambleLen);
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 416: // 齿轮
        scr = Gear.scramble();
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 417:
        scr = MegaScramble.megascramble2([['U'], ['R'], ['F']], ['', '2', '3', '4', '5', '6', "'", "2'", "3'", "4'", "5'"], this.scrambleLen);
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 448: // Siamese Cube
        {
          const turn: string[][] = [['U', 'u'], ['R', 'r']];
          scr = MegaScramble.megascramble2(turn, Scrambler.cubesuff, this.scrambleLen) + 'z2 ' + MegaScramble.megascramble2(turn, Scrambler.cubesuff, this.scrambleLen);
        }
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 449:
        {
          const turn: string[][] = [['R', 'r'], ['U']];
          scr = MegaScramble.megascramble2(turn, Scrambler.cubesuff, this.scrambleLen) + 'z2 ' + MegaScramble.megascramble2(turn, Scrambler.cubesuff, this.scrambleLen);
        }
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 450:
        {
          const turn: string[][] = [['U'], ['R'], ['F']];
          scr = MegaScramble.megascramble2(turn, Scrambler.cubesuff, this.scrambleLen) + 'z2 y ' + MegaScramble.megascramble2(turn, Scrambler.cubesuff, this.scrambleLen);
        }
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 480: // 15 puzzle
        scr = MegaScramble.do15puzzle(false, this.scrambleLen);
        this.imageType = Scrambler.TYPE_15P;
        this.scrambleList.push(scr);
        break;
      case 481:
        scr = MegaScramble.do15puzzle(true, this.scrambleLen);
        this.imageType = Scrambler.TYPE_15PB;
        this.scrambleList.push(scr);
        break;
      case 512: // Other
        scr = LatchCube.scramble(this.scrambleLen);
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 513:
        scr = MegaScramble.helicubescramble(this.scrambleLen);
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 514: // Sq2
        {
          let i = 0;
          sb = '';
          while (i < this.scrambleLen) {
            const rndu = Math.floor(Math.random() * 12) - 5;
            const rndd = Math.floor(Math.random() * 12) - 5;
            if (rndu != 0 || rndd != 0) {
              i++;
              sb += '(' + rndu + ',' + rndd + ') / ';
            }
          }
          scr = sb;
        }
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 515: // super sq1
        scr = MegaScramble.ssq1tScramble(this.scrambleLen);
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 516: // UFO
        scr = MegaScramble.megascramble3([[['A']], [['B']], [['C']], [['U', "U'", "U2'", 'U2', 'U3']]], null, this.scrambleLen);
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 517: // FTO
        scr = MegaScramble.megascramble2([['U', 'D'], ['F', 'B'], ['L', 'BR'], ['R', 'BL']], Scrambler.cubesuff2, this.scrambleLen);
        this.imageType = Scrambler.TYPE_FTO;
        this.scrambleList.push(scr);
        break;
      case 518: // Redi
        scr = MegaScramble.rediScramble(Scrambler.cubesuff2, this.scrambleLen);
        this.imageType = Scrambler.TYPE_REDI;
        this.scrambleList.push(scr);
        break;
      case 519: // Master pyraminx
        {
          const ss: string[][] = [['', 'l ', "l' "], ['', 'r ', "r' "], ['', 'b ', "b' "], ['', 'u ', "u' "]];
          const rnd: number[] = new Array<number>(4).fill(0);
          for (let i = 0; i < 4; i++) {
            rnd[i] = Math.floor(Math.random() * 3);
          }
          scr = MegaScramble.megascramble2([['U', 'Uw'], ['L', 'Lw'], ['R', 'Rw'], ['B', 'Bw']], Scrambler.cubesuff2, this.scrambleLen) +
            ss[0][rnd[0]] + ss[1][rnd[1]] + ss[2][rnd[2]] + ss[3][rnd[3]];
        }
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 520: // 8 puzzle
        scr = EightPuzzle.scramble(() => Math.random());
        this.imageType = Scrambler.TYPE_8PZ;
        this.scrambleList.push(scr);
        break;
      case 521: // CTO
        scr = this.scrambleCTO();
        this.imageType = Scrambler.TYPE_CTO;
        this.scrambleList.push(scr);
        break;
      case 522: // 枫叶
        scr = Maple.scramble();
        this.imageType = Scrambler.TYPE_MAPLE;
        this.scrambleList.push(scr);
        break;
      case 543: // Gigaminx
        scr = MegaScramble.gigascramble(this.scrambleLen);
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 544: // 3x3x3 subsets
        scr = CubeRU.scramble(false);
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case 545:
        scr = CubeRU.scramble(true);
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case 546:
        scr = RouxMU.scramble(() => Math.random());
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case 547:
        scr = MegaScramble.megascramble2([['U'], ['R'], ['F']], Scrambler.cubesuff, this.scrambleLen);
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case 548:
        scr = MegaScramble.megascramble2([['R', 'L'], ['U']], Scrambler.cubesuff, this.scrambleLen);
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case 549:
        scr = MegaScramble.megascramble2([['R', 'r'], ['U']], Scrambler.cubesuff, this.scrambleLen);
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case 550:
        scr = HalfTurn.scramble(() => Math.random());
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case 551: // LSLL
        scr = MegaScramble.megascramble3([[["R U R'", "R U2 R'", "R U' R'"]], [["F' U F", "F' U2 F", "F' U' F"]], [['U', 'U2', "U'"]]], null, this.scrambleLen);
        this.imageType = 3;
        this.scrambleList.push(scr);
        break;
      case 576: // Bandaged Cube
        scr = MegaScramble.bicube(this.scrambleLen);
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 577:
        scr = MegaScramble.sq1Scramble(2, this.scrambleLen);
        this.imageType = Scrambler.TYPE_SQ1;
        this.scrambleList.push(scr);
        break;
      case 608: // 五魔子集
        scr = MegaScramble.megascramble2([['U'], ['R']], ['', '2', "2'", "'"], this.scrambleLen);
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 609:
        scr = MegaScramble.megascramble3([[["R U R'", "R U2 R'", "R U' R'", "R U2' R'"]], [["F' U F", "F' U2 F", "F' U' F", "F' U2' F"]], [['U', 'U2', "U'", "U2'"]]], null, this.scrambleLen);
        this.imageType = 0;
        this.scrambleList.push(scr);
        break;
      case 640: // 连拧
        sb = '';
        for (let j = 1; j <= this.scrambleLen; j++) {
          const sol = this.scramble333();
          sb += j + ') ' + sol;
          this.scrambleList.push(sol);
          if (j < this.scrambleLen) {
            sb += '\n';
          }
        }
        scr = sb;
        this.imageType = Scrambler.TYPE_REL;
        break;
      case 641:
        s2 = Cube222.scramble();
        s3 = this.scramble333();
        s4 = this.scramble444();
        scr = '2) ' + s2 + '\n3) ' + s3 + '\n4) ' + s4;
        this.scrambleList.push(s2);
        this.scrambleList.push(s3);
        this.scrambleList.push(s4);
        this.imageType = Scrambler.TYPE_REL;
        break;
      case 642:
        s2 = Cube222.scramble();
        s3 = this.scramble333();
        s4 = this.scramble444();
        s5 = this.scramble555();
        scr = '2) ' + s2 + '\n3) ' + s3 + '\n4) ' + s4 + '\n5) ' + s5;
        this.scrambleList.push(s2);
        this.scrambleList.push(s3);
        this.scrambleList.push(s4);
        this.scrambleList.push(s5);
        this.imageType = Scrambler.TYPE_REL;
        break;
      case 643:
        s2 = Cube222.scramble();
        s3 = this.scramble333();
        s4 = this.scramble444();
        s5 = this.scramble555();
        s6 = this.scramble666();
        scr = '2) ' + s2 + '\n3) ' + s3 + '\n4) ' + s4 + '\n5) ' + s5 + '\n6) ' + s6;
        this.scrambleList.push(s2);
        this.scrambleList.push(s3);
        this.scrambleList.push(s4);
        this.scrambleList.push(s5);
        this.scrambleList.push(s6);
        this.imageType = Scrambler.TYPE_REL;
        break;
      case 644:
        s2 = Cube222.scramble();
        s3 = this.scramble333();
        s4 = this.scramble444();
        s5 = this.scramble555();
        s6 = this.scramble666();
        s7 = this.scramble777();
        scr = '2) ' + s2 + '\n3) ' + s3 + '\n4) ' + s4 + '\n5) ' + s5 + '\n6) ' + s6 + '\n7) ' + s7;
        this.scrambleList.push(s2);
        this.scrambleList.push(s3);
        this.scrambleList.push(s4);
        this.scrambleList.push(s5);
        this.scrambleList.push(s6);
        this.scrambleList.push(s7);
        this.imageType = Scrambler.TYPE_REL;
        break;
      case 645:
        s2 = Cube222.scramble();
        s3 = this.scramble333();
        s4 = this.scramble444();
        s5 = this.scramble555();
        s6 = this.scramble666();
        s7 = this.scramble777();
        oh = this.scramble333();
        ft = this.scramble333();
        pyr = Pyraminx.scramble();
        sq1 = this.cubesq.scramble();
        skw = Skewb.scramble();
        clk = this.clock.scramble();
        mega = this.megaminx.scramblestring(70);
        scr = '2x2) ' + s2 + '\n3x3) ' + s3 + '\n4x4) ' + s4 + '\n5x5) ' + s5 + '\n6x6) ' + s6 + '\n7x7) ' + s7 + '\n3OH) ' + oh + '\n3FT) ' + ft + '\nPyra) ' + pyr + '\nSQ1) ' + sq1 + '\nSkewb) ' + skw + '\nClock) ' + clk + '\nMega) ' + mega;
        this.scrambleList.push(s2);
        this.scrambleList.push(s3);
        this.scrambleList.push(s4);
        this.scrambleList.push(s5);
        this.scrambleList.push(s6);
        this.scrambleList.push(s7);
        this.scrambleList.push(oh);
        this.scrambleList.push(ft);
        this.scrambleList.push(pyr);
        this.scrambleList.push(sq1);
        this.scrambleList.push(skw);
        this.scrambleList.push(clk);
        this.scrambleList.push(mega);
        this.imageType = Scrambler.TYPE_REL;
        break;
      case 646:
        s2 = Cube222.scramble();
        s3 = this.scramble333();
        s4 = this.scramble444();
        s5 = this.scramble555();
        oh = this.scramble333();
        pyr = Pyraminx.scramble();
        sq1 = this.cubesq.scramble();
        skw = Skewb.scramble();
        clk = this.clock.scramble();
        mega = this.megaminx.scramblestring(70);
        scr = '2x2) ' + s2 + '\n3x3) ' + s3 + '\n4x4) ' + s4 + '\n5x5) ' + s5 + '\n3OH) ' + oh + '\nPyra) ' + pyr + '\nSQ1) ' + sq1 + '\nSkewb) ' + skw + '\nClock) ' + clk + '\nMega) ' + mega;
        this.scrambleList.push(s2);
        this.scrambleList.push(s3);
        this.scrambleList.push(s4);
        this.scrambleList.push(s5);
        this.scrambleList.push(oh);
        this.scrambleList.push(pyr);
        this.scrambleList.push(sq1);
        this.scrambleList.push(skw);
        this.scrambleList.push(clk);
        this.scrambleList.push(mega);
        this.imageType = Scrambler.TYPE_REL;
        break;
      default:
        scr = '';
    }
    this.scramble = scr;
  }

  private scrambleCube(n: number): string {
    return Cube.scramblestring(n, Math.abs(this.scrambleLen));
  }

  private scrambleCTO(): string {
    const axis: string[][] = [
      ['U', "U'", 'U2'], ['D', "D'", 'D2'], ['F', "F'", 'F2'],
      ['B', "B'", 'B2'], ['L', "L'", 'L2'], ['R', "R'", 'R2']
    ];
    const lower: string[][] = [
      ['u', "u'", 'u2'], ['d', "d'", 'd2'], ['f', "f'", 'f2'],
      ['b', "b'", 'b2'], ['l', "l'", 'l2'], ['r', "r'", 'r2']
    ];
    const len = 20 + Math.floor(Math.random() * 11);
    let sb = '';
    let last = -1;
    for (let i = 0; i < len; i++) {
      let ax: number;
      do {
        ax = Math.floor(Math.random() * axis.length);
      } while (ax == last);
      if (sb.length > 0) {
        sb += ' ';
      }
      sb += axis[ax][Math.floor(Math.random() * axis[ax].length)];
      last = ax;
    }
    const extra = Math.floor(Math.random() * 7);
    const used: boolean[] = new Array<boolean>(lower.length).fill(false);
    for (let i = 0; i < extra; i++) {
      let ax: number;
      do {
        ax = Math.floor(Math.random() * lower.length);
      } while (used[ax]);
      used[ax] = true;
      sb += ' ' + lower[ax][Math.floor(Math.random() * lower[ax].length)];
    }
    return sb;
  }

  private scramble333(): string {
    this.cubeState = Tools.randomCube();
    let scramble: string;
    do {
      scramble = this.cube3.solution5(this.cubeState, 21, 50000, 50, 2);
    } while (scramble.startsWith('Error'));
    return scramble;
  }

  static buildScrambleBetweenStates(startState: string, targetState: string): string | null {
    if (startState == null || startState.length == 0) {
      return new Search3().solution1(targetState);
    }
    const scrambleState = Tools.getScrambleFacelet(startState, targetState);
    if (scrambleState == null || scrambleState.length == 0) {
      return null;
    }
    return new Search3().solution1(scrambleState);
  }

  static random2GLLState(): string {
    return Tools.randomState(
      Tools.STATE_SOLVED,
      [-1, -1, -1, -1, 0, 0, 0, 0],
      [-1, -1, -1, -1, 4, 5, 6, 7, 8, 9, 10, 11],
      Tools.STATE_SOLVED);
  }

  static randomCOLLState(): string {
    return Tools.randomState(
      [-1, -1, -1, -1, 4, 5, 6, 7],
      [-1, -1, -1, -1, 0, 0, 0, 0],
      [-1, -1, -1, -1, 4, 5, 6, 7, 8, 9, 10, 11],
      Tools.STATE_SOLVED);
  }

  static randomRouxCMLLState(): string {
    return Tools.randomState(
      [-1, -1, -1, -1, 4, 5, 6, 7],
      [-1, -1, -1, -1, 0, 0, 0, 0],
      [-1, -1, -1, -1, 4, -1, 6, -1, 8, 9, 10, 11],
      [-1, -1, -1, -1, 0, -1, 0, -1, 0, 0, 0, 0]);
  }

  static randomRouxLSEState(): string {
    return Tools.randomState(
      Tools.STATE_SOLVED,
      Tools.STATE_SOLVED,
      [-1, -1, -1, -1, 4, -1, 6, -1, 8, 9, 10, 11],
      [-1, -1, -1, -1, 0, -1, 0, -1, 0, 0, 0, 0]);
  }

  private scramble444(): string {
    return MegaScramble.megascramble2([['U', 'D', 'Uw'], ['R', 'L', 'Rw'], ['F', 'B', 'Fw']], Scrambler.cubesuff, 40);
  }

  private scramble555(): string {
    return MegaScramble.megascramble2([['U', 'D', 'Uw', 'Dw'], ['R', 'L', 'Rw', 'Lw'], ['F', 'B', 'Fw', 'Bw']], Scrambler.cubesuff, 60);
  }

  private scramble666(): string {
    return MegaScramble.megascramble2([['U', 'D', 'Uw', 'Dw', '3Uw'], ['R', 'L', 'Rw', 'Lw', '3Rw'], ['F', 'B', 'Fw', 'Bw', '3Fw']], Scrambler.cubesuff, 80);
  }

  private scramble777(): string {
    return MegaScramble.megascramble2([['U', 'D', 'Uw', 'Dw', '3Uw', '3Dw'], ['R', 'L', 'Rw', 'Lw', '3Rw', '3Lw'], ['F', 'B', 'Fw', 'Bw', '3Fw', '3Bw']], Scrambler.cubesuff, 100);
  }

  is333Scramble(): boolean {
    const idx = this.category >> 5;
    const sub = this.category & 0x1f;
    return (idx == -1 && (sub == 0 || sub == 5 || sub == 7)) ||
      (idx == 1 && (sub == 0 || sub == 1 || sub == 19)) ||
      this.isSmart333TrainingScramble();
  }

  is333CfopScramble(): boolean {
    return SmartCubeTraining.is333Cfop(this.category);
  }

  isSmart333TrainingScramble(): boolean {
    return SmartCubeTraining.isSmart333Training(this.category);
  }

  isSqScramble(): boolean {
    const idx = this.category >> 5;
    const sub = this.category & 0x1f;
    return (idx == 8 && sub < 3) || (idx == -1 && sub == 10);
  }

  is222Scramble(): boolean {
    const idx = this.category >> 5;
    const sub = this.category & 0x1f;
    return (idx == 0 && sub < 2) || (idx == -1 && sub == 3);
  }

  is444Scramble(): boolean {
    const idx = this.category >> 5;
    const sub = this.category & 0x1f;
    return (idx == -1 && (sub == 1 || sub == 15)) || (idx == 2 && sub == 5);
  }

  isPyrScramble(): boolean {
    const idx = this.category >> 5;
    const sub = this.category & 0x1f;
    return (idx == -1 && sub == 9) || (idx == 7 && sub < 2);
  }

  isBlindfoldScramble(): boolean {
    const idx = this.category >> 5;
    const sub = this.category & 0x1f;
    return idx == -1 && (sub == 4 || sub == 15 || sub == 16 || sub == 17);
  }

  isFMCScramble(): boolean {
    const idx = this.category >> 5;
    const sub = this.category & 0x1f;
    return idx == -1 && sub == 6;
  }

  solve333(scramble: string): string {
    switch (AppGlobals.solve333) {
      case 1:
        return Cross.solveCross(scramble, AppGlobals.solverType[1]);
      case 2:
        return Cross.solveXcross(scramble, AppGlobals.solverType[1]);
      case 3:
        return EOline.solveEoline(scramble, AppGlobals.solverType[1]);
      case 4:
        return Roux.solveRoux1(scramble, AppGlobals.solverType[3]);
      case 5:
        return Petrus.solvePetrus(scramble, AppGlobals.solverType[2]);
      case 6:
        return Cross.solveEofc(scramble, AppGlobals.solverType[1]);
      default:
        return '';
    }
  }

  solve222(scramble: string): string {
    switch (AppGlobals.solve222) {
      case 1:
        return Cube2Face.solveFace(scramble, AppGlobals.solverType[4]);
      case 2:
        return Cube2Layer.solveFirstLayer(scramble, AppGlobals.solverType[4]);
      default:
        return '';
    }
  }

  // ===================== drawing (Paint/Canvas -> PaintState/ScrambleCanvas) =====================
  static drawPolygon(p: PaintState, c: ScrambleCanvas, cl: number, arx: number[], ary: number[], stroke: boolean): void {
    p.setColor(cl);
    const pts: number[][] = [];
    for (let idx = 0; idx < arx.length; idx++) {
      pts.push([arx[idx], ary[idx]]);
    }
    p.setStyle(0);
    c.drawPath(pts, p);
    if (stroke) {
      p.setStyle(1);
      p.setColor(ColorConst.BLACK);
      c.drawPath(pts, p);
    }
  }

  drawScramble(width: number, p: PaintState, c: ScrambleCanvas): void {
    const colors = Scrambler.schemeN;
    if (this.imageType == Scrambler.TYPE_MEGA) { // 五魔
      this.drawMega(width, p, c);
    } else if (this.imageType == Scrambler.TYPE_PYR) { // 金字塔
      this.drawPyra(this.scramble, width, p, c);
    } else if (this.imageType == Scrambler.TYPE_SQ1) { // SQ1
      this.drawSQ1(this.scramble, width, p, c);
    } else if (this.imageType == Scrambler.TYPE_CLK) { // 魔表
      this.drawClock(width, p, c);
    } else if (this.imageType == Scrambler.TYPE_133) { // 1x3x3
      const img = Floppy.image(this.scramble);
      const a = Math.floor((width * 92 / 100) / 8);
      let d = 0;
      const stx = Math.floor((width * 94 / 100 - 8 * a) / 2);
      const sty = Math.floor((width * 71 / 100 - 5 * a) / 2);
      const sp = Math.floor(width / 50);
      p.setStyle(0);
      for (let i = 0; i < 3; i++) {
        p.setStyle(0);
        p.setColor(colors[img[d++]]);
        c.drawRect(stx + sp + (i + 1) * a, sty, stx + sp + (i + 2) * a, sty + a, p);
        p.setStyle(1);
        p.setColor(ColorConst.BLACK);
        c.drawRect(stx + sp + (i + 1) * a, sty, stx + sp + (i + 2) * a, sty + a, p);
      }
      for (let i = 0; i < 3; i++) {
        for (let j = 0; j < 8; j++) {
          let offset = 0;
          if (j > 4) {
            offset = sp * 3;
          } else if (j > 3) {
            offset = sp * 2;
          } else if (j > 0) {
            offset = sp;
          }
          p.setStyle(0);
          p.setColor(colors[img[d++]]);
          c.drawRect(stx + offset + j * a, sty + sp + (i + 1) * a, stx + offset + (j + 1) * a, sty + sp + (i + 2) * a, p);
          p.setStyle(1);
          p.setColor(ColorConst.BLACK);
          c.drawRect(stx + offset + j * a, sty + sp + (i + 1) * a, stx + offset + (j + 1) * a, sty + sp + (i + 2) * a, p);
        }
      }
      for (let i = 0; i < 3; i++) {
        p.setStyle(0);
        p.setColor(colors[img[d++]]);
        c.drawRect(stx + sp + (i + 1) * a, sty + sp * 2 + 4 * a, stx + sp + (i + 2) * a, sty + sp * 2 + 5 * a, p);
        p.setStyle(1);
        p.setColor(ColorConst.BLACK);
        c.drawRect(stx + sp + (i + 1) * a, sty + sp * 2 + 4 * a, stx + sp + (i + 2) * a, sty + sp * 2 + 5 * a, p);
      }
    } else if (this.imageType == Scrambler.TYPE_233) { // 2x3x3
      const img = Domino.image(this.scramble);
      const a = Math.floor((width * 92 / 100) / 12);
      let d = 0;
      const stx = Math.floor((width * 94 / 100 - 12 * a) / 2);
      const sty = Math.floor((width * 71 / 100 - 8 * a) / 2);
      const sp = Math.floor(width / 50);
      p.setStyle(0);
      for (let i = 0; i < 3; i++) {
        for (let j = 0; j < 3; j++) {
          p.setStyle(0);
          p.setColor(colors[img[d++]]);
          c.drawRect(stx + sp + (j + 3) * a, sty + i * a, stx + sp + (j + 4) * a, sty + (i + 1) * a, p);
          p.setStyle(1);
          p.setColor(ColorConst.BLACK);
          c.drawRect(stx + sp + (j + 3) * a, sty + i * a, stx + sp + (j + 4) * a, sty + (i + 1) * a, p);
        }
      }
      for (let i = 0; i < 2; i++) {
        for (let j = 0; j < 12; j++) {
          let offset = 0;
          if (j >= 9) {
            offset = sp * 3;
          } else if (j >= 6) {
            offset = sp * 2;
          } else if (j >= 3) {
            offset = sp;
          }
          p.setStyle(0);
          p.setColor(colors[img[d++]]);
          c.drawRect(stx + offset + j * a, sty + sp + (i + 3) * a, stx + offset + (j + 1) * a, sty + sp + (i + 4) * a, p);
          p.setStyle(1);
          p.setColor(ColorConst.BLACK);
          c.drawRect(stx + offset + j * a, sty + sp + (i + 3) * a, stx + offset + (j + 1) * a, sty + sp + (i + 4) * a, p);
        }
      }
      for (let i = 0; i < 3; i++) {
        for (let j = 0; j < 3; j++) {
          p.setStyle(0);
          p.setColor(colors[img[d++]]);
          c.drawRect(stx + sp + (j + 3) * a, sty + sp * 2 + (i + 5) * a, stx + sp + (j + 4) * a, sty + sp * 2 + (i + 6) * a, p);
          p.setStyle(1);
          p.setColor(ColorConst.BLACK);
          c.drawRect(stx + sp + (j + 3) * a, sty + sp * 2 + (i + 5) * a, stx + sp + (j + 4) * a, sty + sp * 2 + (i + 6) * a, p);
        }
      }
    } else if (this.imageType == Scrambler.TYPE_223) { // 2x2x3
      const img = Tower.image(this.scramble);
      const a = Math.floor(width / 10);
      let d = 0;
      const stx = Math.floor((width * 94 / 100 - 8 * a) / 2);
      const sty = Math.floor((width * 71 / 100 - 7 * a) / 2);
      const sp = Math.floor(width / 50);
      p.setStyle(0);
      for (let i = 0; i < 2; i++) {
        for (let j = 0; j < 2; j++) {
          p.setStyle(0);
          p.setColor(colors[img[d++]]);
          c.drawRect(stx + sp + (j + 2) * a, sty + i * a, stx + sp + (j + 3) * a, sty + (i + 1) * a, p);
          p.setStyle(1);
          p.setColor(ColorConst.BLACK);
          c.drawRect(stx + sp + (j + 2) * a, sty + 1 + i * a, stx + sp + (j + 3) * a, sty + (i + 1) * a, p);
        }
      }
      for (let i = 0; i < 3; i++) {
        for (let j = 0; j < 8; j++) {
          let offset = 0;
          if (j > 5) {
            offset = sp * 3;
          } else if (j > 3) {
            offset = sp * 2;
          } else if (j > 1) {
            offset = sp;
          }
          p.setStyle(0);
          p.setColor(colors[img[d++]]);
          c.drawRect(stx + offset + j * a, sty + sp + (i + 2) * a, stx + offset + (j + 1) * a, sty + sp + (i + 3) * a, p);
          p.setStyle(1);
          p.setColor(ColorConst.BLACK);
          c.drawRect(stx + offset + j * a, sty + sp + (i + 2) * a, stx + offset + (j + 1) * a, sty + sp + (i + 3) * a, p);
        }
      }
      for (let i = 0; i < 2; i++) {
        for (let j = 0; j < 2; j++) {
          p.setStyle(0);
          p.setColor(colors[img[d++]]);
          c.drawRect(stx + sp + (j + 2) * a, sty + sp * 2 + (5 + i) * a, stx + sp + (j + 3) * a, sty + sp * 2 + (6 + i) * a, p);
          p.setStyle(1);
          p.setColor(ColorConst.BLACK);
          c.drawRect(stx + sp + (j + 2) * a, sty + sp * 2 + (5 + i) * a, stx + sp + (j + 3) * a, sty + sp * 2 + (6 + i) * a, p);
        }
      }
    } else if (this.imageType == Scrambler.TYPE_SKW) { // 斜转
      const img = SkewbFCN.image(this.scramble);
      if (img == null) {
        return;
      }
      this.drawSkewb(img, width, p, c);
    } else if (this.imageType == Scrambler.TYPE_MAPLE) { // 枫叶
      this.drawMaple(this.scramble, width, p, c);
    } else if (this.imageType == Scrambler.TYPE_FTO) { // FTO
      this.drawFto(this.scramble, width, p, c);
    } else if (this.imageType == Scrambler.TYPE_CTO) { // CTO
      this.drawCto(this.scramble, width, p, c);
    } else if (this.imageType == Scrambler.TYPE_15P || this.imageType == Scrambler.TYPE_15PB) { // 15 puzzle
      const img = FifteenPuzzle.image(this.scramble, this.imageType == Scrambler.TYPE_15P);
      const wid = Math.floor(width / 6);
      const stx = Math.floor((width - wid * 4) / 2);
      const sty = Math.floor((width * 3 / 4 - wid * 4) / 2);
      p.setTextSize(wid * 0.6);
      p.setTextAlign(1);
      for (let i = 0; i < 4; i++) {
        for (let j = 0; j < 4; j++) {
          const num = img[i * 4 + j];
          if (num != 15) {
            p.setStyle(0);
            if (num == 10 || num == 11 || num == 14) {
              p.setColor(0xffaaaa66);
            } else if (num == 5 || num == 6 || num == 7 || num == 9 || num == 13) {
              p.setColor(0xff9999ff);
            } else {
              p.setColor(0xffff6666);
            }
            c.drawArc(stx + wid * j + wid * 0.03, sty + wid * i + wid * 0.03, stx + wid * (j + 1) - wid * 0.03, sty + wid * (i + 1) - wid * 0.03, 0, 360, p);
            p.setColor(0xffffffff);
            c.drawText((num + 1).toString(), stx + wid * (j + 0.5), sty + wid * (i + 0.72), p);
            p.setStyle(1);
            p.setColor(0xdd000000);
            c.drawArc(stx + wid * j + wid * 0.03, sty + wid * i + wid * 0.03, stx + wid * (j + 1) - wid * 0.03, sty + wid * (i + 1) - wid * 0.03, 0, 360, p);
          }
        }
      }
    } else if (this.imageType == Scrambler.TYPE_REDI) { // Redi cube
      const img = Redi.image(this.scramble);
      const a = Math.floor((width * 92 / 100) / 12);
      let d = 0;
      const sp = Math.floor(width / 50);
      const imageWid = a * 12 + sp * 3;
      const imageHei = a * 9 + sp * 2;
      const stx = Math.floor((width - imageWid) / 2);
      const sty = Math.floor((width * 3 / 4 - imageHei) / 2);
      for (let i = 0; i < 3; i++) {
        for (let j = 0; j < 3; j++) {
          if (i == 1 || j == 1) {
            const arx: number[] = [stx + sp + (j + 3) * a, stx + sp + (j + 4) * a, stx + sp + (j + 4) * a, stx + sp + 4.5 * a, stx + sp + (j + 3) * a];
            const ary: number[] = [sty + i * a, sty + (i + 1) * a, sty + (i + 1) * a, sty + 1.5 * a, sty + i * a];
            if (i == 1) {
              if (j == 0) {
                arx[1] = arx[0];
                arx[4] = arx[2];
              } else {
                arx[0] = arx[1];
                arx[2] = arx[4];
              }
            }
            if (j == 1) {
              if (i == 0) {
                ary[1] = ary[0];
                ary[4] = ary[2];
              } else {
                ary[0] = ary[1];
                ary[2] = ary[4];
              }
            }
            if (i != 1 || j != 1) {
              Scrambler.drawPolygon(p, c, colors[img[d++]], arx, ary, true);
            }
          } else {
            p.setStyle(0);
            p.setColor(colors[img[d++]]);
            c.drawRect(stx + sp + (j + 3) * a, sty + i * a, stx + sp + (j + 4) * a, sty + (i + 1) * a, p);
            p.setStyle(1);
            p.setColor(ColorConst.BLACK);
            c.drawRect(stx + sp + (j + 3) * a, sty + i * a, stx + sp + (j + 4) * a, sty + (i + 1) * a, p);
          }
        }
      }
      for (let i = 0; i < 3; i++) {
        for (let j = 0; j < 12; j++) {
          if (i == 1 || j % 3 == 1) {
            const arx: number[] = [stx + j * a + sp * Math.floor(j / 3), stx + (j + 1) * a + sp * Math.floor(j / 3), stx + (j + 1) * a + sp * Math.floor(j / 3), stx + (Math.floor(j / 3) * 3 + 1.5) * a + sp * Math.floor(j / 3), stx + j * a + sp * Math.floor(j / 3)];
            const ary: number[] = [sty + sp + (i + 3) * a, sty + sp + (i + 4) * a, sty + sp + (i + 4) * a, sty + sp + 4.5 * a, sty + sp + (i + 3) * a];
            if (i == 1) {
              if (j % 3 == 0) {
                arx[1] = arx[0];
                arx[4] = arx[2];
              } else {
                arx[0] = arx[1];
                arx[2] = arx[4];
              }
            }
            if (j % 3 == 1) {
              if (i == 0) {
                ary[1] = ary[0];
                ary[4] = ary[2];
              } else {
                ary[0] = ary[1];
                ary[2] = ary[4];
              }
            }
            if (i != 1 || j % 3 != 1) {
              Scrambler.drawPolygon(p, c, colors[img[d++]], arx, ary, true);
            }
          } else {
            p.setStyle(0);
            p.setColor(colors[img[d++]]);
            c.drawRect(stx + j * a + sp * Math.floor(j / 3), sty + sp + (i + 3) * a, stx + (j + 1) * a + sp * Math.floor(j / 3), sty + sp + (i + 4) * a, p);
            p.setStyle(1);
            p.setColor(ColorConst.BLACK);
            c.drawRect(stx + j * a + sp * Math.floor(j / 3), sty + sp + (i + 3) * a, stx + (j + 1) * a + sp * Math.floor(j / 3), sty + sp + (i + 4) * a, p);
          }
        }
      }
      for (let i = 0; i < 3; i++) {
        for (let j = 0; j < 3; j++) {
          if (i == 1 || j == 1) {
            const arx: number[] = [stx + sp + (j + 3) * a, stx + sp + (j + 4) * a, stx + sp + (j + 4) * a, stx + sp + 4.5 * a, stx + sp + (j + 3) * a];
            const ary: number[] = [sty + sp * 2 + (i + 6) * a, sty + sp * 2 + (i + 7) * a, sty + sp * 2 + (i + 7) * a, sty + sp * 2 + 7.5 * a, sty + sp * 2 + (i + 6) * a];
            if (i == 1) {
              if (j == 0) {
                arx[1] = arx[0];
                arx[4] = arx[2];
              } else {
                arx[0] = arx[1];
                arx[2] = arx[4];
              }
            }
            if (j == 1) {
              if (i == 0) {
                ary[1] = ary[0];
                ary[4] = ary[2];
              } else {
                ary[0] = ary[1];
                ary[2] = ary[4];
              }
            }
            if (i != 1 || j != 1) {
              Scrambler.drawPolygon(p, c, colors[img[d++]], arx, ary, true);
            }
          } else {
            p.setStyle(0);
            p.setColor(colors[img[d++]]);
            c.drawRect(stx + sp + (j + 3) * a, sty + sp * 2 + (i + 6) * a, stx + sp + (j + 4) * a, sty + sp * 2 + (i + 7) * a, p);
            p.setStyle(1);
            p.setColor(ColorConst.BLACK);
            c.drawRect(stx + sp + (j + 3) * a, sty + sp * 2 + (i + 6) * a, stx + sp + (j + 4) * a, sty + sp * 2 + (i + 7) * a, p);
          }
        }
      }
    } else if (this.imageType == Scrambler.TYPE_REL) { // 连拧
      if (this.category == -15 || this.category == 640) {
        this.drawNNN(3, this.scrambleList[this.scrambleIdx], colors, width, p, c);
      } else if (this.category == 646) {
        if (this.scrambleIdx < 4) {
          this.drawNNN(this.scrambleIdx + 2, this.scrambleList[this.scrambleIdx], colors, width, p, c);
        } else if (this.scrambleIdx == 4) {
          this.drawNNN(3, this.scrambleList[this.scrambleIdx], colors, width, p, c);
        } else if (this.scrambleIdx == 5) {
          this.drawPyra(this.scrambleList[this.scrambleIdx], width, p, c);
        } else if (this.scrambleIdx == 6) {
          this.drawSQ1(this.scrambleList[this.scrambleIdx], width, p, c);
        } else if (this.scrambleIdx == 7) {
          const img = SkewbFCN.image(this.scrambleList[this.scrambleIdx]);
          if (img == null) {
            return;
          }
          this.drawSkewb(img, width, p, c);
        } else if (this.scrambleIdx == 8) {
          this.drawClock(width, p, c);
        } else if (this.scrambleIdx == 9) {
          this.drawMega(width, p, c);
        }
      } else if (this.scrambleIdx < 6) {
        this.drawNNN(this.scrambleIdx + 2, this.scrambleList[this.scrambleIdx], colors, width, p, c);
      } else if (this.scrambleIdx == 6 || this.scrambleIdx == 7) {
        this.drawNNN(3, this.scrambleList[this.scrambleIdx], colors, width, p, c);
      } else if (this.scrambleIdx == 8) {
        this.drawPyra(this.scrambleList[this.scrambleIdx], width, p, c);
      } else if (this.scrambleIdx == 9) {
        this.drawSQ1(this.scrambleList[this.scrambleIdx], width, p, c);
      } else if (this.scrambleIdx == 10) {
        const img = SkewbFCN.image(this.scrambleList[this.scrambleIdx]);
        if (img == null) {
          return;
        }
        this.drawSkewb(img, width, p, c);
      } else if (this.scrambleIdx == 11) {
        this.drawClock(width, p, c);
      } else if (this.scrambleIdx == 12) {
        this.drawMega(width, p, c);
      }
    } else if (this.imageType == Scrambler.TYPE_8PZ) {
      const img = EightPuzzle.image(this.scramble);
      const wid = Math.floor(width / 5);
      const stx = Math.floor((width - wid * 3) / 2);
      const sty = Math.floor((width * 3 / 4 - wid * 3) / 2);
      p.setTextSize(wid * 0.6);
      p.setTextAlign(1);
      for (let i = 0; i < 3; i++) {
        for (let j = 0; j < 3; j++) {
          const num = img[i * 3 + j];
          if (num != 8) {
            p.setStyle(0);
            if (num == 4 || num == 5 || num == 7) {
              p.setColor(0xff44aa55);
            } else {
              p.setColor(0xffff3333);
            }
            c.drawArc(stx + wid * j + wid * 0.03, sty + wid * i + wid * 0.03, stx + wid * (j + 1) - wid * 0.03, sty + wid * (i + 1) - wid * 0.03, 0, 360, p);
            p.setColor(0xffffffff);
            c.drawText((num + 1).toString(), stx + wid * (j + 0.5), sty + wid * (i + 0.72), p);
            p.setStyle(1);
            p.setColor(0xdd000000);
            c.drawArc(stx + wid * j + wid * 0.03, sty + wid * i + wid * 0.03, stx + wid * (j + 1) - wid * 0.03, sty + wid * (i + 1) - wid * 0.03, 0, 360, p);
          }
        }
      }
    } else { // NxNxN
      this.drawNNN(this.imageType, this.scramble, colors, width, p, c);
    }
  }

  private drawNNN(size: number, scramble: string, colors: number[], width: number, p: PaintState, c: ScrambleCanvas): void {
    let img: number[];
    if (AppGlobals.isImportScr) {
      img = Cube.image(scramble, size);
    } else if (size == 3 || size == 2) {
      img = Cube.image(scramble, size);
    } else if (size > 7) {
      img = Cube.imageFromSeq();
    } else if ((this.category & 0x1f) == 0) {
      img = Cube.imageFromSeq();
    } else {
      img = Cube.image(scramble, size);
    }
    const a = Math.floor((width * 92 / 100) / (size * 4));
    let d = 0;
    const b = size;
    const sp = Math.floor(width / 50);
    const imageWid = 4 * a * b + sp * 3;
    const imageHei = 3 * a * b + sp * 2;
    const stx = Math.floor((width - imageWid) / 2);
    const sty = Math.floor((width * 3 / 4 - imageHei) / 2);
    for (let i = 0; i < b; i++) {
      for (let j = 0; j < b; j++) {
        p.setStyle(0);
        p.setColor(colors[img[d++]]);
        c.drawRect(stx + sp + (j + b) * a, sty + i * a, stx + sp + (j + 1 + b) * a, sty + (i + 1) * a, p);
        p.setStyle(1);
        p.setColor(ColorConst.BLACK);
        c.drawRect(stx + sp + (j + b) * a, sty + i * a, stx + sp + (j + 1 + b) * a, sty + (i + 1) * a, p);
      }
    }
    for (let i = 0; i < b; i++) {
      for (let j = 0; j < b * 4; j++) {
        p.setStyle(0);
        p.setColor(colors[img[d++]]);
        let offset = 0;
        if (j >= b * 3) {
          offset = sp * 3;
        } else if (j >= b * 2) {
          offset = sp * 2;
        } else if (j >= b) {
          offset = sp;
        }
        c.drawRect(stx + j * a + offset, sty + sp + (i + b) * a, stx + (j + 1) * a + offset, sty + sp + (i + 1 + b) * a, p);
        p.setStyle(1);
        p.setColor(ColorConst.BLACK);
        c.drawRect(stx + j * a + offset, sty + sp + (i + b) * a, stx + (j + 1) * a + offset, sty + sp + (i + 1 + b) * a, p);
      }
    }
    for (let i = 0; i < b; i++) {
      for (let j = 0; j < b; j++) {
        p.setStyle(0);
        p.setColor(colors[img[d++]]);
        c.drawRect(stx + sp + (j + b) * a, sty + sp * 2 + (i + 2 * b) * a, stx + sp + (j + 1 + b) * a, sty + sp * 2 + (i + 1 + 2 * b) * a, p);
        p.setStyle(1);
        p.setColor(ColorConst.BLACK);
        c.drawRect(stx + sp + (j + b) * a, sty + sp * 2 + (i + 2 * b) * a, stx + sp + (j + 1 + b) * a, sty + sp * 2 + (i + 1 + 2 * b) * a, p);
      }
    }
  }

  private drawPyra(scramble: string, width: number, p: PaintState, c: ScrambleCanvas): void {
    const img = Pyraminx.image(scramble);
    const b = Math.floor((width * 72 / 100) / 6);
    const a = Math.floor(b * 2 / Math.sqrt(3));
    const d = Math.floor((width * 96 / 100 - a * 6) / 2);
    const sp = Math.floor(width / 50);
    const colors = Scrambler.schemeP;
    const layout: number[] = [
      1, 2, 1, 2, 1, 0, 2, 0, 1, 2, 1, 2, 1,
      0, 1, 2, 1, 0, 2, 1, 2, 0, 1, 2, 1, 0,
      0, 0, 1, 0, 2, 1, 2, 1, 2, 0, 1, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 1, 2, 1, 2, 1, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 1, 2, 1, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0
    ];
    const pos: number[] = [
      d, d + a / 2, d + a, d + 3 * a / 2, d + 2 * a, d + 5 * a / 2, d + sp + 5 * a / 2, d + sp + 3 * a, d + sp * 2 + 3 * a, d + sp * 2 + 7 * a / 2, d + sp * 2 + 4 * a, d + sp * 2 + 9 * a / 2, d + sp * 2 + 5 * a, d + sp * 2 + 11 * a / 2,
      d + a / 2, d + a, d + 3 * a / 2, d + 2 * a, d + sp + 2 * a, d + sp + 5 * a / 2, d + sp + 3 * a, d + sp + 7 * a / 2, d + sp * 2 + 7 * a / 2, d + sp * 2 + 4 * a, d + sp * 2 + 9 * a / 2, d + sp * 2 + 5 * a,
      0, 0, d + a, d + 3 * a / 2, d + sp + 3 * a / 2, d + sp + 2 * a, d + sp + 5 * a / 2, d + sp + 3 * a, d + sp + 7 * a / 2, d + sp + 4 * a, d + sp * 2 + 4 * a, d + sp * 2 + 9 * a / 2, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, d + sp + 3 * a / 2, d + sp + 2 * a, d + sp + 5 * a / 2, d + sp + 3 * a, d + sp + 7 * a / 2, d + sp + 4 * a, 0, 0, 0,
      0, 0, 0, 0, 0, d + sp + 2 * a, d + sp + 5 * a / 2, d + sp + 3 * a, d + sp + 7 * a / 2, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, d + sp + 5 * a / 2, d + sp + 3 * a, 0, 0, 0, 0, 0
    ];
    for (let y = 0; y < 7; y++) {
      for (let x = 0; x < 13; x++) {
        if (layout[y * 13 + x] == 1) {
          if (y < 3) {
            const arx: number[] = [pos[y * 13 + x] + x, pos[y * 13 + x] + a + x, pos[y * 13 + x + 1] + x];
            const ary: number[] = [y * b + 3 + y, y * b + 3 + y, (y + 1) * b + 3 + y];
            Scrambler.drawPolygon(p, c, colors[img[y * 13 + x]], arx, ary, true);
          } else if (y > 3) {
            const arx: number[] = [pos[y * 13 + x] + x, pos[y * 13 + x] + a + x, pos[y * 13 + x + 1] + x];
            const ary: number[] = [(y - 1) * b + 2 + sp + y, (y - 1) * b + 2 + sp + y, y * b + 2 + sp + y];
            Scrambler.drawPolygon(p, c, colors[img[y * 13 + x]], arx, ary, true);
          }
        } else if (layout[y * 13 + x] == 2) {
          if (y < 3) {
            const arx: number[] = [pos[y * 13 + x] + x, pos[y * 13 + x] + a + x, pos[y * 13 + x + 1] + x];
            const ary: number[] = [(y + 1) * b + 3 + y, (y + 1) * b + 3 + y, y * b + 3 + y];
            Scrambler.drawPolygon(p, c, colors[img[y * 13 + x]], arx, ary, true);
          } else if (y > 3) {
            const arx: number[] = [pos[y * 13 + x] + x, pos[y * 13 + x] + a + x, pos[y * 13 + x + 1] + x];
            const ary: number[] = [y * b + 2 + sp + y, y * b + 2 + sp + y, (y - 1) * b + 2 + sp + y];
            Scrambler.drawPolygon(p, c, colors[img[y * 13 + x]], arx, ary, true);
          }
        }
      }
    }
  }

  private drawMega(width: number, p: PaintState, c: ScrambleCanvas): void {
    let colors: number[];
    if (AppGlobals.megaColorScheme == 0) {
      colors = [ColorConst.WHITE, 0xff880088, 0xff008800, 0xff88ddff, 0xff882222, ColorConst.BLUE,
        ColorConst.RED, 0xffff9900, ColorConst.GREEN, 0xffff44ff, 0xff000088, ColorConst.YELLOW];
    } else {
      colors = [ColorConst.WHITE, ColorConst.RED, 0xff008800, 0xff880088, 0xffffdd00, ColorConst.BLUE,
        0xffffff99, 0xff88ddff, 0xffff9900, ColorConst.GREEN, 0xffff44ff, ColorConst.GRAY];
    }
    const edgeFrac = (1 + Math.sqrt(5)) / 4;
    const centerFrac = 0.5;
    const scale = width / 350;
    const dx = Math.floor((width - 350 * scale) / 2);
    const dy = Math.floor((width * 0.75 - 180 * scale) / 2);
    const majorR = 36 * scale;
    const minorR = majorR * edgeFrac;
    const pentR = minorR * 2;
    const cx1 = 92 * scale + dx;
    const cy1 = 80 * scale + dy;
    const cx2 = cx1 + this.c18(1) * 3 * pentR;
    const cy2 = cy1 + this.s18(1) * 1 * pentR;
    let aryx: number[];
    let aryy: number[];
    const trans: number[][] = [
      [0, cx1, cy1, 0, 0],
      [36, cx1, cy1, 1, 1],
      [36 + 72 * 1, cx1, cy1, 1, 5],
      [36 + 72 * 2, cx1, cy1, 1, 9],
      [36 + 72 * 3, cx1, cy1, 1, 13],
      [36 + 72 * 4, cx1, cy1, 1, 17],
      [0, cx2, cy2, 1, 7],
      [-72 * 1, cx2, cy2, 1, 3],
      [-72 * 2, cx2, cy2, 1, 19],
      [-72 * 3, cx2, cy2, 1, 15],
      [-72 * 4, cx2, cy2, 1, 11],
      [36 + 72 * 2, cx2, cy2, 0, 0]
    ];
    let d = 0;
    const d2x = majorR * (1 - centerFrac) / 2 / Math.tan(Math.PI / 5);
    const img = this.megaminx.getState();
    p.setStyle(0);
    for (let side = 0; side < 12; side++) {
      const a = trans[side][1] + trans[side][3] * this.c18(trans[side][4]) * pentR;
      const b = trans[side][2] + trans[side][3] * this.s18(trans[side][4]) * pentR;
      let arys: number[][];
      for (let i = 0; i < 5; i++) {
        aryx = [0, d2x, 0, -d2x];
        aryy = [-majorR, -majorR * (1 + centerFrac) / 2, -majorR * centerFrac, -majorR * (1 + centerFrac) / 2];
        arys = this.rotate(a, b, aryx, aryy, 72 * i + trans[side][0]);
        Scrambler.drawPolygon(p, c, colors[img[d++]], arys[0], arys[1], true);
      }
      for (let i = 0; i < 5; i++) {
        aryx = [this.c18(-1) * majorR - d2x, d2x, 0, this.s18(4) * centerFrac * majorR];
        aryy = [this.s18(-1) * majorR - majorR + majorR * (1 + centerFrac) / 2, -majorR * (1 + centerFrac) / 2, -majorR * centerFrac, -this.c18(4) * centerFrac * majorR];
        arys = this.rotate(a, b, aryx, aryy, 72 * i + trans[side][0]);
        Scrambler.drawPolygon(p, c, colors[img[d++]], arys[0], arys[1], true);
      }
      aryx = [this.s18(0) * centerFrac * majorR, this.s18(4) * centerFrac * majorR, this.s18(8) * centerFrac * majorR, this.s18(12) * centerFrac * majorR, this.s18(16) * centerFrac * majorR];
      aryy = [-this.c18(0) * centerFrac * majorR, -this.c18(4) * centerFrac * majorR, -this.c18(8) * centerFrac * majorR, -this.c18(12) * centerFrac * majorR, -this.c18(16) * centerFrac * majorR];
      arys = this.rotate(a, b, aryx, aryy, trans[side][0]);
      Scrambler.drawPolygon(p, c, colors[img[d++]], arys[0], arys[1], true);
    }
    p.setStyle(0);
    p.setTextAlign(1);
    p.setTextSize(width * 0.0593);
    c.drawText('U', width * 0.262, width * 0.367, p);
    c.drawText('F', width * 0.262, width * 0.535, p);
  }

  private drawSQ1(scramble: string, width: number, p: PaintState, c: ScrambleCanvas): void {
    const tb: string[] = ['3', '3', '3', '3', '3', '3', '3', '3', '0', '0', '0', '0', '0', '0', '0', '0'];
    const ty: string[] = ['c', 'e', 'c', 'e', 'c', 'e', 'c', 'e', 'e', 'c', 'e', 'c', 'e', 'c', 'e', 'c'];
    const col: string[] = ['51', '1', '12', '2', '24', '4', '45', '5', '5', '54', '4', '42', '2', '21', '1', '15'];
    const colors = Scrambler.schemeQ;
    const img = SQ1.image(scramble);
    const mis = img[24] != 0;
    const temp: number[] = new Array<number>(12).fill(0);
    for (let i = 0; i < 12; i++) {
      temp[i] = img[i];
    }
    const topSide = this.rd(temp);
    for (let i = 0; i < 6; i++) {
      temp[i] = img[i + 18];
    }
    for (let i = 6; i < 12; i++) {
      temp[i] = img[i + 6];
    }
    const botSide = this.rd(temp);
    const eido: number[] = new Array<number>(topSide.length + botSide.length).fill(0);
    for (let i = 0; i < topSide.length; i++) {
      eido[i] = topSide[i];
    }
    for (let i = topSide.length; i < topSide.length + botSide.length; i++) {
      eido[i] = botSide[i - topSide.length];
    }
    let a2 = '';
    let b2 = '';
    let c2 = '';
    for (let j = 0; j < 16; j++) {
      a2 += ty[eido[j]];
      b2 += tb[eido[j]];
      c2 += col[eido[j]];
    }
    const stickers = b2 + c2;
    const z = 1.366025; // sqrt(2)/sqrt(1^2+tan(15°)^2)
    let arrx: number[];
    let arry: number[];
    const sidewid = 10.98;
    let cx = 55;
    let cy = 50;
    const rd = (cx - 16) / z;
    const w = (sidewid + rd) / rd; // ratio btw total piece width and rd
    const ag: number[] = new Array<number>(24).fill(0);
    const ag2: number[] = new Array<number>(24).fill(0);
    for (let foo = 0; foo < 24; foo++) {
      ag[foo] = (17 - foo * 2) * Math.PI / 12;
      a2 += 'xxxxxxxxxxxxxxxx';
    }
    for (let foo = 0; foo < 24; foo++) {
      ag2[foo] = (19 - foo * 2) * Math.PI / 12;
      a2 += 'xxxxxxxxxxxxxxxx';
    }
    const a = a2;
    const h = this.sin1(1, ag, rd) * w * z - this.sin1(1, ag, rd) * z;
    if (mis) {
      arrx = [cx + this.cos1(1, ag, rd) * w * z, cx + this.cos1(4, ag, rd) * w * z, cx + this.cos1(7, ag, rd) * w * z, cx + this.cos1(10, ag, rd) * w * z];
      arry = [cy - this.sin1(1, ag, rd) * w * z, cy - this.sin1(4, ag, rd) * w * z, cy - this.sin1(7, ag, rd) * w * z, cy - this.sin1(10, ag, rd) * w * z];
      this.drawPolygonScaled(p, c, ColorConst.BLACK, width, arrx, arry);
      cy += 10;
      arrx = [cx + this.cos1(0, ag, rd) * w, cx + this.cos1(0, ag, rd) * w, cx + this.cos1(1, ag, rd) * w * z, cx + this.cos1(1, ag, rd) * w * z];
      arry = [cy - this.sin1(1, ag, rd) * w * z, cy - this.sin1(1, ag, rd) * z, cy - this.sin1(1, ag, rd) * z, cy - this.sin1(1, ag, rd) * w * z];
      this.drawPolygonScaled(p, c, colors[5], width, arrx, arry);
      arrx = [cx + this.cos1(0, ag, rd) * w, cx + this.cos1(0, ag, rd) * w, cx + this.cos1(10, ag, rd) * w * z, cx + this.cos1(10, ag, rd) * w * z];
      arry = [cy - this.sin1(1, ag, rd) * w * z, cy - this.sin1(1, ag, rd) * z, cy - this.sin1(1, ag, rd) * z, cy - this.sin1(1, ag, rd) * w * z];
      this.drawPolygonScaled(p, c, colors[5], width, arrx, arry);
      cy -= 10;
    } else {
      arrx = [cx + this.cos1(1, ag, rd) * w * z, cx + this.cos1(4, ag, rd) * w * z, cx + this.cos1(6, ag, rd) * w, cx + this.cos1(9, ag, rd) * w * z, cx + this.cos1(11, ag, rd) * w * z, cx + this.cos1(0, ag, rd) * w];
      arry = [cy - this.sin1(1, ag, rd) * w * z, cy - this.sin1(4, ag, rd) * w * z, cy - this.sin1(6, ag, rd) * w, cy + this.sin1(9, ag, rd) * w * z, cy - this.sin1(11, ag, rd) * w * z, cy - this.sin1(0, ag, rd) * w];
      this.drawPolygonScaled(p, c, ColorConst.BLACK, width, arrx, arry);
      arrx = [cx + this.cos1(9, ag, rd) * w * z, cx + this.cos1(11, ag, rd) * w * z, cx + this.cos1(11, ag, rd) * w * z, cx + this.cos1(9, ag, rd) * w * z];
      arry = [cy + this.sin1(9, ag, rd) * w * z - h, cy - this.sin1(11, ag, rd) * w * z - h, cy - this.sin1(11, ag, rd) * w * z, cy + this.sin1(9, ag, rd) * w * z];
      this.drawPolygonScaled(p, c, colors[4], width, arrx, arry);
      cy += 10;
      arrx = [cx + this.cos1(0, ag, rd) * w, cx + this.cos1(0, ag, rd) * w, cx + this.cos1(1, ag, rd) * w * z, cx + this.cos1(1, ag, rd) * w * z];
      arry = [cy - this.sin1(1, ag, rd) * w * z, cy - this.sin1(1, ag, rd) * z, cy - this.sin1(1, ag, rd) * z, cy - this.sin1(1, ag, rd) * w * z];
      this.drawPolygonScaled(p, c, colors[5], width, arrx, arry);
      arrx = [cx + this.cos1(0, ag, rd) * w, cx + this.cos1(0, ag, rd) * w, cx + this.cos1(11, ag, rd) * w * z, cx + this.cos1(11, ag, rd) * w * z];
      arry = [cy - this.sin1(1, ag, rd) * w * z, cy - this.sin1(1, ag, rd) * z, cy - this.sin1(11, ag, rd) * w * z + h, cy - this.sin1(11, ag, rd) * w * z];
      this.drawPolygonScaled(p, c, colors[2], width, arrx, arry);
      cy -= 10;
    }
    let sc = 0;
    let foo = 0;
    for (foo = 0; sc < 12; foo++) {
      if (a.length <= foo) {
        sc = 12;
      }
      if (a.charAt(foo) == 'x') {
        sc++;
      }
      if (a.charAt(foo) == 'c') {
        arrx = [cx, cx + this.cos1(sc, ag, rd), cx + this.cos1(sc + 1, ag, rd) * z, cx + this.cos1(sc + 2, ag, rd)];
        arry = [cy, cy - this.sin1(sc, ag, rd), cy - this.sin1(sc + 1, ag, rd) * z, cy - this.sin1(sc + 2, ag, rd)];
        this.drawPolygonScaled(p, c, colors[stickers.charCodeAt(foo) - 48], width, arrx, arry);
        arrx = [cx + this.cos1(sc, ag, rd), cx + this.cos1(sc + 1, ag, rd) * z, cx + this.cos1(sc + 1, ag, rd) * w * z, cx + this.cos1(sc, ag, rd) * w];
        arry = [cy - this.sin1(sc, ag, rd), cy - this.sin1(sc + 1, ag, rd) * z, cy - this.sin1(sc + 1, ag, rd) * w * z, cy - this.sin1(sc, ag, rd) * w];
        this.drawPolygonScaled(p, c, colors[stickers.charCodeAt(16 + sc) - 48], width, arrx, arry);
        arrx = [cx + this.cos1(sc + 2, ag, rd), cx + this.cos1(sc + 1, ag, rd) * z, cx + this.cos1(sc + 1, ag, rd) * w * z, cx + this.cos1(sc + 2, ag, rd) * w];
        arry = [cy - this.sin1(sc + 2, ag, rd), cy - this.sin1(sc + 1, ag, rd) * z, cy - this.sin1(sc + 1, ag, rd) * w * z, cy - this.sin1(sc + 2, ag, rd) * w];
        this.drawPolygonScaled(p, c, colors[stickers.charCodeAt(17 + sc) - 48], width, arrx, arry);
        sc += 2;
      }
      if (a.charAt(foo) == 'e') {
        arrx = [cx, cx + this.cos1(sc, ag, rd), cx + this.cos1(sc + 1, ag, rd)];
        arry = [cy, cy - this.sin1(sc, ag, rd), cy - this.sin1(sc + 1, ag, rd)];
        this.drawPolygonScaled(p, c, colors[stickers.charCodeAt(foo) - 48], width, arrx, arry);
        arrx = [cx + this.cos1(sc, ag, rd), cx + this.cos1(sc + 1, ag, rd), cx + this.cos1(sc + 1, ag, rd) * w, cx + this.cos1(sc, ag, rd) * w];
        arry = [cy - this.sin1(sc, ag, rd), cy - this.sin1(sc + 1, ag, rd), cy - this.sin1(sc + 1, ag, rd) * w, cy - this.sin1(sc, ag, rd) * w];
        this.drawPolygonScaled(p, c, colors[stickers.charCodeAt(16 + sc) - 48], width, arrx, arry);
        sc += 1;
      }
    }
    cx *= 3;
    cy += 10;
    if (mis) {
      arrx = [cx + this.cos1(1, ag, rd) * w * z, cx + this.cos1(4, ag, rd) * w * z, cx + this.cos1(7, ag, rd) * w * z, cx + this.cos1(10, ag, rd) * w * z];
      arry = [cy + this.sin1(1, ag, rd) * w * z, cy + this.sin1(4, ag, rd) * w * z, cy + this.sin1(7, ag, rd) * w * z, cy + this.sin1(10, ag, rd) * w * z];
      this.drawPolygonScaled(p, c, ColorConst.BLACK, width, arrx, arry);
      cy -= 10;
      arrx = [cx + this.cos1(0, ag, rd) * w, cx + this.cos1(0, ag, rd) * w, cx + this.cos1(1, ag, rd) * w * z, cx + this.cos1(1, ag, rd) * w * z];
      arry = [cy + this.sin1(1, ag, rd) * w * z, cy + this.sin1(1, ag, rd) * z, cy + this.sin1(1, ag, rd) * z, cy + this.sin1(1, ag, rd) * w * z];
      this.drawPolygonScaled(p, c, colors[5], width, arrx, arry);
      arrx = [cx + this.cos1(0, ag, rd) * w, cx + this.cos1(0, ag, rd) * w, cx + this.cos1(10, ag, rd) * w * z, cx + this.cos1(10, ag, rd) * w * z];
      arry = [cy + this.sin1(1, ag, rd) * w * z, cy + this.sin1(1, ag, rd) * z, cy + this.sin1(1, ag, rd) * z, cy + this.sin1(1, ag, rd) * w * z];
      this.drawPolygonScaled(p, c, colors[5], width, arrx, arry);
      cy += 10;
    } else {
      arrx = [cx + this.cos1(1, ag, rd) * w * z, cx + this.cos1(4, ag, rd) * w * z, cx + this.cos1(6, ag, rd) * w, cx + this.cos1(9, ag, rd) * w * z, cx + this.cos1(11, ag, rd) * w * z, cx + this.cos1(0, ag, rd) * w];
      arry = [cy + this.sin1(1, ag, rd) * w * z, cy + this.sin1(4, ag, rd) * w * z, cy + this.sin1(6, ag, rd) * w, cy - this.sin1(9, ag, rd) * w * z, cy + this.sin1(11, ag, rd) * w * z, cy + this.sin1(0, ag, rd) * w];
      this.drawPolygonScaled(p, c, ColorConst.BLACK, width, arrx, arry);
      arrx = [cx + this.cos1(9, ag, rd) * w * z, cx + this.cos1(11, ag, rd) * w * z, cx + this.cos1(11, ag, rd) * w * z, cx + this.cos1(9, ag, rd) * w * z];
      arry = [cy - this.sin1(9, ag, rd) * w * z - 10, cy + this.sin1(11, ag, rd) * w * z - 10, cy + this.sin1(11, ag, rd) * w * z, cy - this.sin1(9, ag, rd) * w * z];
      this.drawPolygonScaled(p, c, colors[4], width, arrx, arry);
      cy -= 10;
      arrx = [cx + this.cos1(0, ag, rd) * w, cx + this.cos1(0, ag, rd) * w, cx + this.cos1(1, ag, rd) * w * z, cx + this.cos1(1, ag, rd) * w * z];
      arry = [cy + this.sin1(1, ag, rd) * w * z, cy + this.sin1(1, ag, rd) * z, cy + this.sin1(1, ag, rd) * z, cy + this.sin1(1, ag, rd) * w * z];
      this.drawPolygonScaled(p, c, colors[5], width, arrx, arry);
      arrx = [cx + this.cos1(0, ag, rd) * w, cx + this.cos1(0, ag, rd) * w, cx + this.cos1(11, ag, rd) * w * z, cx + this.cos1(11, ag, rd) * w * z];
      arry = [cy + this.sin1(1, ag, rd) * w * z, cy + this.sin1(1, ag, rd) * z, cy + this.sin1(11, ag, rd) * w * z + 10, cy + this.sin1(11, ag, rd) * w * z];
      this.drawPolygonScaled(p, c, colors[2], width, arrx, arry);
      cy += 10;
    }
    for (sc = 0; sc < 12; foo++) {
      if (a.length <= foo) {
        sc = 12;
      }
      if (a.charAt(foo) == 'x') {
        sc++;
      }
      if (a.charAt(foo) == 'c') {
        arrx = [cx, cx + this.cos1(sc, ag2, rd), cx + this.cos1(sc + 1, ag2, rd) * z, cx + this.cos1(sc + 2, ag2, rd)];
        arry = [cy, cy - this.sin1(sc, ag2, rd), cy - this.sin1(sc + 1, ag2, rd) * z, cy - this.sin1(sc + 2, ag2, rd)];
        this.drawPolygonScaled(p, c, colors[stickers.charCodeAt(foo) - 48], width, arrx, arry);
        arrx = [cx + this.cos1(sc, ag2, rd), cx + this.cos1(sc + 1, ag2, rd) * z, cx + this.cos1(sc + 1, ag2, rd) * w * z, cx + this.cos1(sc, ag2, rd) * w];
        arry = [cy - this.sin1(sc, ag2, rd), cy - this.sin1(sc + 1, ag2, rd) * z, cy - this.sin1(sc + 1, ag2, rd) * w * z, cy - this.sin1(sc, ag2, rd) * w];
        this.drawPolygonScaled(p, c, colors[stickers.charCodeAt(28 + sc) - 48], width, arrx, arry);
        arrx = [cx + this.cos1(sc + 2, ag2, rd), cx + this.cos1(sc + 1, ag2, rd) * z, cx + this.cos1(sc + 1, ag2, rd) * w * z, cx + this.cos1(sc + 2, ag2, rd) * w];
        arry = [cy - this.sin1(sc + 2, ag2, rd), cy - this.sin1(sc + 1, ag2, rd) * z, cy - this.sin1(sc + 1, ag2, rd) * w * z, cy - this.sin1(sc + 2, ag2, rd) * w];
        this.drawPolygonScaled(p, c, colors[stickers.charCodeAt(29 + sc) - 48], width, arrx, arry);
        sc += 2;
      }
      if (a.charAt(foo) == 'e') {
        arrx = [cx, cx + this.cos1(sc, ag2, rd), cx + this.cos1(sc + 1, ag2, rd)];
        arry = [cy, cy - this.sin1(sc, ag2, rd), cy - this.sin1(sc + 1, ag2, rd)];
        this.drawPolygonScaled(p, c, colors[stickers.charCodeAt(foo) - 48], width, arrx, arry);
        arrx = [cx + this.cos1(sc, ag2, rd), cx + this.cos1(sc + 1, ag2, rd), cx + this.cos1(sc + 1, ag2, rd) * w, cx + this.cos1(sc, ag2, rd) * w];
        arry = [cy - this.sin1(sc, ag2, rd), cy - this.sin1(sc + 1, ag2, rd), cy - this.sin1(sc + 1, ag2, rd) * w, cy - this.sin1(sc, ag2, rd) * w];
        this.drawPolygonScaled(p, c, colors[stickers.charCodeAt(28 + sc) - 48], width, arrx, arry);
        sc += 1;
      }
    }
  }

  private drawClock(width: number, p: PaintState, c: ScrambleCanvas): void {
    const posit = this.clock.getPosit();
    const faceDist = 30;
    let cx = 55;
    const cy = 55;
    p.setColor(0xff2a2a2a);
    this.drawSideBackground(p, c, width, cx, cy, 53, 29, 19);
    p.setColor(0xff3366ff);
    this.drawSideBackground(p, c, width, cx, cy, 52, 29, 18);
    let i = 0;
    for (let y = cy - faceDist; y <= cy + faceDist; y += faceDist) {
      for (let x = cx - faceDist; x <= cx + faceDist; x += faceDist) {
        this.drawClockFace(p, c, width, x, y, 0xff88aaff, posit[i++]);
      }
    }
    const pegs = this.clock.getPegs();
    this.drawPeg(p, c, width, cx - faceDist / 2, cy - faceDist / 2, 1 - pegs[0]);
    this.drawPeg(p, c, width, cx + faceDist / 2, cy - faceDist / 2, 1 - pegs[1]);
    this.drawPeg(p, c, width, cx - faceDist / 2, cy + faceDist / 2, 1 - pegs[2]);
    this.drawPeg(p, c, width, cx + faceDist / 2, cy + faceDist / 2, 1 - pegs[3]);
    cx = 165;
    p.setColor(0xff2a2a2a);
    this.drawSideBackground(p, c, width, cx, cy, 53, 29, 19);
    p.setColor(0xff88aaff);
    this.drawSideBackground(p, c, width, cx, cy, 52, 29, 18);
    for (let y = cy - faceDist; y <= cy + faceDist; y += faceDist) {
      for (let x = cx - faceDist; x <= cx + faceDist; x += faceDist) {
        this.drawClockFace(p, c, width, x, y, 0xff3366ff, posit[i++]);
      }
    }
    this.drawPeg(p, c, width, cx + faceDist / 2, cy - faceDist / 2, pegs[0]);
    this.drawPeg(p, c, width, cx - faceDist / 2, cy - faceDist / 2, pegs[1]);
    this.drawPeg(p, c, width, cx + faceDist / 2, cy + faceDist / 2, pegs[2]);
    this.drawPeg(p, c, width, cx - faceDist / 2, cy + faceDist / 2, pegs[3]);
  }

  private drawSkewb(img: number[], width: number, p: PaintState, c: ScrambleCanvas): void {
    const colors = Scrambler.schemeW;
    const b = Math.floor(width / 4);
    const a = Math.floor(b * Math.sqrt(3) / 2);
    const stx = Math.floor((width - 4 * a) / 2);
    const sty = Math.floor((width * 3 / 4 - 3 * b) / 2);
    const sp = Math.floor(width / 50);
    const e = sp / Math.sqrt(3) / 2;
    const f = sp * Math.sqrt(3) / 2;
    const dx: number[] = [a * 2, a * 3 - sp, a + sp, a * 2, sp / 2, a - sp / 2, sp / 2, a - sp / 2, a + sp / 2, a * 2 - sp / 2, a + sp / 2, a * 2 - sp / 2,
      a * 2 + sp / 2, a * 3 - sp / 2, a * 2 + sp / 2, a * 3 - sp / 2, a * 3 + sp / 2, a * 4 - sp / 2, a * 3 + sp / 2, a * 4 - sp / 2, a + sp / 2, a * 2 - sp / 2, a + sp / 2, a * 2 - sp / 2];
    const dy: number[] = [e * 2, b / 2, b / 2, b - e * 2, f, b / 2 + e, b - e, b * 3 / 2 - f, b / 2 + f, b + e, b * 3 / 2 - e, b * 2 - f,
      b + e, b / 2 + f, b * 2 - f, b * 3 / 2 - e, b / 2 + e, f, b * 3 / 2 - f, b - e, b * 3 / 2 + f, b * 2 + e, b * 5 / 2 - e, b * 3 - f];
    let d = 0;
    for (let i = 0; i < 6; i++) {
      const dx0 = dx[i * 4];
      const dx1 = dx[i * 4 + 1];
      const dx2 = dx[i * 4 + 2];
      const dx3 = dx[i * 4 + 3];
      const dy0 = dy[i * 4];
      const dy1 = dy[i * 4 + 1];
      const dy2 = dy[i * 4 + 2];
      const dy3 = dy[i * 4 + 3];
      Scrambler.drawPolygon(p, c, colors[img[d++]],
        [stx + dx0, stx + (dx0 + dx1) / 2, stx + (dx0 + dx2) / 2],
        [sty + dy0, sty + (dy0 + dy1) / 2, sty + (dy0 + dy2) / 2], true);
      Scrambler.drawPolygon(p, c, colors[img[d++]],
        [stx + dx1, stx + (dx0 + dx1) / 2, stx + (dx1 + dx3) / 2],
        [sty + dy1, sty + (dy0 + dy1) / 2, sty + (dy1 + dy3) / 2], true);
      Scrambler.drawPolygon(p, c, colors[img[d++]],
        [stx + (dx0 + dx2) / 2, stx + (dx0 + dx1) / 2, stx + (dx1 + dx3) / 2, stx + (dx2 + dx3) / 2],
        [sty + (dy0 + dy2) / 2, sty + (dy0 + dy1) / 2, sty + (dy1 + dy3) / 2, sty + (dy2 + dy3) / 2], true);
      Scrambler.drawPolygon(p, c, colors[img[d++]],
        [stx + dx2, stx + (dx0 + dx2) / 2, stx + (dx2 + dx3) / 2],
        [sty + dy2, sty + (dy0 + dy2) / 2, sty + (dy2 + dy3) / 2], true);
      Scrambler.drawPolygon(p, c, colors[img[d++]],
        [stx + dx3, stx + (dx3 + dx2) / 2, stx + (dx1 + dx3) / 2],
        [sty + dy3, sty + (dy3 + dy2) / 2, sty + (dy1 + dy3) / 2], true);
    }
  }

  private drawMaple(scramble: string, width: number, p: PaintState, c: ScrambleCanvas): void {
    const img = Maple.image(scramble);
    const colors = Scrambler.schemeW;
    const b = Math.floor(width / 4);
    const a = Math.floor(b * Math.sqrt(3) / 2);
    const stx = Math.floor((width - 4 * a) / 2);
    const sty = Math.floor((width * 3 / 4 - 3 * b) / 2);
    const sp = Math.floor(width / 50);
    const e = sp / Math.sqrt(3) / 2;
    const f = sp * Math.sqrt(3) / 2;
    const strip = Math.max(1, sp / 3);
    const dx: number[] = [a * 2, a * 3 - sp, a + sp, a * 2, sp / 2, a - sp / 2, sp / 2, a - sp / 2, a + sp / 2, a * 2 - sp / 2, a + sp / 2, a * 2 - sp / 2,
      a * 2 + sp / 2, a * 3 - sp / 2, a * 2 + sp / 2, a * 3 - sp / 2, a * 3 + sp / 2, a * 4 - sp / 2, a * 3 + sp / 2, a * 4 - sp / 2, a + sp / 2, a * 2 - sp / 2, a + sp / 2, a * 2 - sp / 2];
    const dy: number[] = [e * 2, b / 2, b / 2, b - e * 2, f, b / 2 + e, b - e, b * 3 / 2 - f, b / 2 + f, b + e, b * 3 / 2 - e, b * 2 - f,
      b + e, b / 2 + f, b * 2 - f, b * 3 / 2 - e, b / 2 + e, f, b * 3 / 2 - f, b - e, b * 3 / 2 + f, b * 2 + e, b * 5 / 2 - e, b * 3 - f];
    let d = 0;
    for (let i = 0; i < 6; i++) {
      const x0 = stx + dx[i * 4];
      const x1 = stx + dx[i * 4 + 1];
      const x2 = stx + dx[i * 4 + 2];
      const x3 = stx + dx[i * 4 + 3];
      const y0 = sty + dy[i * 4];
      const y1 = sty + dy[i * 4 + 1];
      const y2 = sty + dy[i * 4 + 2];
      const y3 = sty + dy[i * 4 + 3];
      if (i == 0) {
        const dist = this.distance(dx[3], dy[3], dx[2], dy[2]);
        const dist3 = Math.sqrt(dist * dist + dist * dist);
        const dist4 = Math.abs(dx[1] - dx[2]);
        const height = dist * (dist / dist3);
        const height2 = dist * (dist4 / dist3);
        d++;
        Scrambler.drawPolygon(p, c, colors[img[d++]], [x1, x0, x3], [y1, y0, y3], true);
        const centerColor = d;
        this.drawArc(p, c, colors[img[d++]], [x2 - height2, x2 + height2], [y2 - height, y2 + height], -45, 90, true);
        Scrambler.drawPolygon(p, c, colors[img[d++]], [x2, x0, x3], [y2, y0, y3], true);
        this.drawArc(p, c, colors[img[centerColor]], [x1 - height2, x1 + height2], [y1 - height, y1 + height], 135, 90, true);
        Scrambler.drawPolygon(p, c, colors[img[centerColor]], [x0 - strip, x0 + strip, x3 + strip, x3 - strip], [y0, y0, y3, y3], false);
        d++;
      } else if (i == 1 || i == 3 || i == 5) {
        const dist = this.distance(dx[3], dy[3], dx[2], dy[2]);
        const dist3 = Math.sqrt(dist * dist + dist * dist);
        const dist4 = this.distance(dx[i * 4 + 1], dy[i * 4 + 1], dx[i * 4 + 2], dy[i * 4 + 2]);
        const height = dist * (this.distance(dx[i * 4 + 3], dy[i * 4 + 3], dx[i * 4], dy[i * 4]) / dist3);
        const height2 = dist * (dist4 / dist3);
        const firstRotation = i == 3 ? -60 : -30;
        const secondRotation = i == 3 ? 120 : 150;
        d++;
        Scrambler.drawPolygon(p, c, colors[img[d++]], [x1, x0, x3], [y1, y0, y3], true);
        const centerColor = d;
        this.drawRotatedArc(p, c, colors[img[d++]], x2, y2, firstRotation, height2, height, -45, 90, true);
        Scrambler.drawPolygon(p, c, colors[img[d++]], [x2, x0, x3], [y2, y0, y3], true);
        this.drawRotatedArc(p, c, colors[img[centerColor]], x1, y1, secondRotation, height2, height, -45, 90, true);
        Scrambler.drawPolygon(p, c, colors[img[centerColor]], [x0 - strip, x0 + strip, x3 + strip, x3 - strip], [y0, y0, y3, y3], false);
        d++;
      } else {
        const dist = this.distance(dx[3], dy[3], dx[2], dy[2]);
        const dist3 = Math.sqrt(dist * dist + dist * dist);
        const dist4 = this.distance(dx[i * 4], dy[i * 4], dx[i * 4 + 3], dy[i * 4 + 3]);
        const height = dist * (this.distance(dx[i * 4 + 2], dy[i * 4 + 2], dx[i * 4 + 1], dy[i * 4 + 1]) / dist3);
        const height2 = dist * (dist4 / dist3);
        const firstRotation = i == 2 ? -120 : -150;
        const secondRotation = i == 2 ? 60 : 30;
        Scrambler.drawPolygon(p, c, colors[img[d++]], [x0, x1, x2], [y0, y1, y2], true);
        d++;
        const centerColor = d;
        this.drawRotatedArc(p, c, colors[img[d++]], x3, y3, firstRotation, height2, height, -45, 90, true);
        d++;
        Scrambler.drawPolygon(p, c, colors[img[d++]], [x3, x2, x1], [y3, y2, y1], true);
        this.drawRotatedArc(p, c, colors[img[centerColor]], x0, y0, secondRotation, height2, height, -45, 90, true);
        Scrambler.drawPolygon(p, c, colors[img[centerColor]], [x1 - strip, x1 + strip, x2 + strip, x2 - strip], [y1, y1, y2, y2], false);
      }
    }
  }

  private distance(x1: number, y1: number, x2: number, y2: number): number {
    const dx = x1 - x2;
    const dy = y1 - y2;
    return Math.sqrt(dx * dx + dy * dy);
  }

  private drawRotatedArc(p: PaintState, c: ScrambleCanvas, color: number, cx: number, cy: number, rotation: number,
    halfWidth: number, halfHeight: number, startAngle: number, sweepAngle: number, stroke: boolean): void {
    c.save();
    c.rotate(rotation, cx, cy);
    this.drawArc(p, c, color, [-halfWidth, halfWidth], [-halfHeight, halfHeight], startAngle, sweepAngle, stroke);
    c.restore();
  }

  private drawArc(p: PaintState, c: ScrambleCanvas, cl: number, arx: number[], ary: number[],
    startAngle: number, sweepAngle: number, stroke: boolean): void {
    p.setStyle(0);
    p.setColor(cl);
    c.drawArc(arx[0], ary[0], arx[1], ary[1], startAngle, sweepAngle, p);
    if (stroke) {
      p.setStyle(1);
      p.setColor(ColorConst.BLACK);
      c.drawArc(arx[0], ary[0], arx[1], ary[1], startAngle, sweepAngle, p);
    }
  }

  private drawFto(scramble: string, width: number, p: PaintState, c: ScrambleCanvas): void {
    this.drawOctahedron(this.ftoImage(scramble), [7, 0, 6, 1],
      [2, 5, 3, 4], Scrambler.FTO_FACELET_DRAW_ORDER,
      Scrambler.FTO_FACELET_DRAW_ORDER, width, p, c);
  }

  private drawCto(scramble: string, width: number, p: PaintState, c: ScrambleCanvas): void {
    this.drawOctahedron(this.ctoImage(scramble), [1, 2, 3, 0],
      [7, 4, 5, 6], Scrambler.CTO_FACELET_DRAW_ORDER,
      Scrambler.CTO_BOTTOM_FACELET_DRAW_ORDER, width, p, c);
  }

  private drawOctahedron(img: number[], topFaces: number[], bottomFaces: number[],
    topDrawOrder: number[][], bottomDrawOrder: number[][],
    width: number, p: PaintState, c: ScrambleCanvas): void {
    const rawColors = Scrambler.schemeFto;
    const colors: number[] = [
      rawColors[0], rawColors[2], rawColors[5], rawColors[7],
      rawColors[6], rawColors[4], rawColors[3], rawColors[1]
    ];
    const sp = width / 60;
    const block = (width - sp * 3) / 4;
    const left = (width - block * 4 - sp) / 2;
    const top = (width * 3 / 4 - block * 2) / 2;
    this.drawOctahedronBlock(img, topFaces, topDrawOrder, left, top, block * 2, colors, p, c);
    this.drawOctahedronBlock(img, bottomFaces, bottomDrawOrder,
      left + block * 2 + sp, top, block * 2, colors, p, c);
  }

  private drawOctahedronBlock(img: number[], faces: number[], drawOrder: number[][],
    x: number, y: number, size: number, colors: number[], p: PaintState, c: ScrambleCanvas): void {
    const midX = x + size / 2;
    const midY = y + size / 2;
    const gap = Math.max(1, size / 80);
    this.drawOctahedronFace(img, faces[0], drawOrder[0],
      this.shrinkTriangle([x, midX, x], [y, midY, y + size], gap, true),
      this.shrinkTriangle([x, midX, x], [y, midY, y + size], gap, false),
      colors, p, c);
    this.drawOctahedronFace(img, faces[1], drawOrder[1],
      this.shrinkTriangle([x, x + size, midX], [y, y, midY], gap, true),
      this.shrinkTriangle([x, x + size, midX], [y, y, midY], gap, false),
      colors, p, c);
    this.drawOctahedronFace(img, faces[2], drawOrder[2],
      this.shrinkTriangle([x + size, x + size, midX], [y, y + size, midY], gap, true),
      this.shrinkTriangle([x + size, x + size, midX], [y, y + size, midY], gap, false),
      colors, p, c);
    this.drawOctahedronFace(img, faces[3], drawOrder[3],
      this.shrinkTriangle([x, midX, x + size], [y + size, midY, y + size], gap, true),
      this.shrinkTriangle([x, midX, x + size], [y + size, midY, y + size], gap, false),
      colors, p, c);
  }

  private shrinkTriangle(ax: number[], ay: number[], gap: number, xAxis: boolean): number[] {
    const cx = (ax[0] + ax[1] + ax[2]) / 3;
    const cy = (ay[0] + ay[1] + ay[2]) / 3;
    const out: number[] = new Array<number>(3).fill(0);
    for (let i = 0; i < 3; i++) {
      const dx = cx - ax[i];
      const dy = cy - ay[i];
      const len = Math.sqrt(dx * dx + dy * dy);
      const scale = len == 0 ? 0 : gap / len;
      out[i] = xAxis ? ax[i] + dx * scale : ay[i] + dy * scale;
    }
    return out;
  }

  private drawOctahedronFace(img: number[], face: number, order: number[], ax: number[], ay: number[],
    colors: number[], p: PaintState, c: ScrambleCanvas): void {
    let d = 0;
    const faceStart = face * 9;
    const px: number[][] = [];
    const py: number[][] = [];
    for (let i = 0; i <= 3; i++) {
      px.push(new Array<number>(4).fill(0));
      py.push(new Array<number>(4).fill(0));
    }
    for (let i = 0; i <= 3; i++) {
      for (let j = 0; j <= 3 - i; j++) {
        px[i][j] = (ax[0] * (3 - i - j) + ax[1] * i + ax[2] * j) / 3;
        py[i][j] = (ay[0] * (3 - i - j) + ay[1] * i + ay[2] * j) / 3;
      }
    }
    for (let row = 0; row < 3; row++) {
      for (let col = 0; col < 3 - row; col++) {
        Scrambler.drawPolygon(p, c, colors[img[faceStart + order[d++]]],
          [px[row][col], px[row + 1][col], px[row][col + 1]],
          [py[row][col], py[row + 1][col], py[row][col + 1]], true);
        if (row < 2 && col < 2 - row) {
          Scrambler.drawPolygon(p, c, colors[img[faceStart + order[d++]]],
            [px[row + 1][col], px[row + 1][col + 1], px[row][col + 1]],
            [py[row + 1][col], py[row + 1][col + 1], py[row][col + 1]], true);
        }
      }
    }
  }

  private ctoImage(scramble: string): number[] {
    const img: number[] = new Array<number>(72).fill(0);
    for (let face = 0; face < 8; face++) {
      for (let sticker = 0; sticker < 9; sticker++) {
        img[face * 9 + sticker] = Scrambler.CTO_FACE_COLORS[face];
      }
    }
    if (scramble == null || scramble.length == 0) {
      return img;
    }
    const moves = scramble.trim().split(/\s+/);
    for (const move of moves) {
      this.applyCtoMove(img, move);
    }
    return img;
  }

  private applyCtoMove(img: number[], move: string): void {
    if (move == null || move.length == 0) {
      return;
    }
    const face = move.charAt(0);
    let axis: number;
    switch (face.toUpperCase()) {
      case 'U': axis = 0; break;
      case 'F': axis = 1; break;
      case 'R': axis = 2; break;
      case 'D': axis = 3; break;
      case 'B': axis = 4; break;
      case 'L': axis = 5; break;
      default: return;
    }
    const turns = move.endsWith('2') ? 2 : move.endsWith("'") ? 3 : 1;
    const firstCycle = face == face.toLowerCase() ? Scrambler.CTO_MOVE_CYCLES[axis].length - 1 : 0;
    for (let turn = 0; turn < turns; turn++) {
      for (let cycle = firstCycle; cycle < Scrambler.CTO_MOVE_CYCLES[axis].length; cycle++) {
        this.cycleCtoFacelets(img, Scrambler.CTO_MOVE_CYCLES[axis][cycle]);
      }
    }
  }

  private cycleCtoFacelets(img: number[], cycle: number[]): void {
    const temp = img[cycle[0]];
    img[cycle[0]] = img[cycle[1]];
    img[cycle[1]] = img[cycle[2]];
    img[cycle[2]] = img[cycle[3]];
    img[cycle[3]] = temp;
  }

  private ftoImage(scramble: string): number[] {
    const cp: number[] = [0, 1, 2, 3, 4, 5];
    const co: number[] = [0, 0, 0, 0, 0, 0];
    const ep: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    const uf: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    const rl: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    if (scramble != null && scramble.length > 0) {
      const moves = scramble.trim().split(/\s+/);
      for (const move of moves) {
        const moveIdx = this.parseFtoMove(move);
        if (moveIdx < 0) {
          continue;
        }
        this.applyFtoMove(cp, co, ep, uf, rl, moveIdx);
      }
    }
    const img: number[] = new Array<number>(72).fill(0);
    for (let i = 0; i < 8; i++) {
      for (let j = 0; j < 9; j++) {
        img[i * 9 + j] = i;
      }
    }
    for (let i = 0; i < 6; i++) {
      const p = cp[i];
      const o = co[i] * 2;
      for (let j = 0; j < 4; j++) {
        img[Scrambler.FTO_CORN_FACELETS[i * 4 + (j + o) % 4]] = Math.floor(Scrambler.FTO_CORN_FACELETS[p * 4 + j] / 9);
      }
    }
    for (let i = 0; i < 12; i++) {
      const p = ep[i];
      img[Scrambler.FTO_EDGE_FACELETS[i * 2]] = Math.floor(Scrambler.FTO_EDGE_FACELETS[p * 2] / 9);
      img[Scrambler.FTO_EDGE_FACELETS[i * 2 + 1]] = Math.floor(Scrambler.FTO_EDGE_FACELETS[p * 2 + 1] / 9);
      img[Scrambler.FTO_CTUF_FACELETS[i]] = Math.floor(uf[i] / 3);
      img[Scrambler.FTO_CTRL_FACELETS[i]] = Scrambler.FTO_CTRL_COLORS[Math.floor(rl[i] / 3)];
    }
    return img;
  }

  private parseFtoMove(move: string): number {
    if (move == null || move.length == 0) {
      return -1;
    }
    const prime = move.endsWith("'");
    const base = prime ? move.substring(0, move.length - 1) : move;
    let face: number;
    switch (base) {
      case 'U': face = 0; break;
      case 'D': face = 1; break;
      case 'F': face = 2; break;
      case 'B': face = 3; break;
      case 'L': face = 4; break;
      case 'BR': face = 5; break;
      case 'R': face = 6; break;
      case 'BL': face = 7; break;
      default: return -1;
    }
    return Scrambler.FTO_MOVE_IDX[face] + (prime ? 1 : 0);
  }

  private applyFtoMove(cp: number[], co: number[], ep: number[], uf: number[], rl: number[], move: number): void {
    const idx = Math.floor(move / 2);
    this.applyFtoMoveOnce(cp, co, ep, uf, rl, idx);
    if ((move & 1) != 0) {
      this.applyFtoMoveOnce(cp, co, ep, uf, rl, idx);
    }
  }

  private applyFtoMoveOnce(cp: number[], co: number[], ep: number[], uf: number[], rl: number[], idx: number): void {
    const oldCp = cp.slice();
    const oldCo = co.slice();
    const oldEp = ep.slice();
    const oldUf = uf.slice();
    const oldRl = rl.slice();
    for (let i = 0; i < 6; i++) {
      cp[i] = oldCp[Scrambler.FTO_MOVE_CP[idx][i]];
      co[i] = oldCo[Scrambler.FTO_MOVE_CP[idx][i]] ^ Scrambler.FTO_MOVE_CO[idx][i];
    }
    for (let i = 0; i < 12; i++) {
      ep[i] = oldEp[Scrambler.FTO_MOVE_EP[idx][i]];
      uf[i] = oldUf[Scrambler.FTO_MOVE_UF[idx][i]];
      rl[i] = oldRl[Scrambler.FTO_MOVE_RL[idx][i]];
    }
  }

  private drawSideBackground(p: PaintState, c: ScrambleCanvas, width: number, cx: number, cy: number, clockRadius: number,
    faceBackgroundDist: number, faceBackgroundRadius: number): void {
    this.drawCircle(p, c, width, cx, cy, clockRadius);
    this.drawCircle(p, c, width, cx - faceBackgroundDist, cy - faceBackgroundDist, faceBackgroundRadius);
    this.drawCircle(p, c, width, cx - faceBackgroundDist, cy + faceBackgroundDist, faceBackgroundRadius);
    this.drawCircle(p, c, width, cx + faceBackgroundDist, cy - faceBackgroundDist, faceBackgroundRadius);
    this.drawCircle(p, c, width, cx + faceBackgroundDist, cy + faceBackgroundDist, faceBackgroundRadius);
  }

  private drawCircle(p: PaintState, c: ScrambleCanvas, w: number, cx: number, cy: number, rad: number): void {
    const scaledPoint = this.scalePoint(w, cx, cy);
    c.drawCircle(scaledPoint[0], scaledPoint[1], scaledPoint[2] * rad, p);
  }

  private scalePoint(width: number, cx: number, cy: number): number[] {
    const scale = width / 220;
    const x = cx * scale + (width - (220 * scale)) / 2;
    const y = cy * scale + (width * 3 / 4 - (110 * scale)) / 2;
    return [x, y, scale];
  }

  private drawClockFace(p: PaintState, cv: ScrambleCanvas, w: number, cx: number, cy: number, color: number,
    hour: number): void {
    const scaled = this.scalePoint(w, cx, cy);
    p.setColor(color);
    this.drawCircle(p, cv, w, cx, cy, 11);
    p.setColor(ColorConst.RED);
    this.drawCircle(p, cv, w, cx, cy, 3);
    const arx: number[] = [this.scalePoint(w, cx, cy - 10)[0], this.scalePoint(w, cx + 3, cy - 1)[0], this.scalePoint(w, cx - 3, cy - 1)[0]];
    const ary: number[] = [this.scalePoint(w, cx, cy - 10)[1], this.scalePoint(w, cx + 3, cy - 1)[1], this.scalePoint(w, cx - 3, cy - 1)[1]];
    p.setColor(color);
    cv.save();
    for (let i = 0; i < 12; i++) {
      this.drawCircle(p, cv, w, cx - 13, cy, 1);
      cv.rotate(30, scaled[0], scaled[1]);
    }
    cv.restore();
    cv.save();
    cv.rotate(30 * hour, scaled[0], scaled[1]);
    Scrambler.drawPolygon(p, cv, ColorConst.RED, arx, ary, false);
    cv.restore();
    p.setColor(ColorConst.YELLOW);
    this.drawCircle(p, cv, w, cx, cy, 2);
    const arx2: number[] = [this.scalePoint(w, cx, cy - 8)[0], this.scalePoint(w, cx + 2, cy - 0.5)[0], this.scalePoint(w, cx - 2, cy - 0.5)[0]];
    const ary2: number[] = [this.scalePoint(w, cx, cy - 8)[1], this.scalePoint(w, cx + 2, cy - 0.5)[1], this.scalePoint(w, cx - 2, cy - 0.5)[1]];
    cv.save();
    cv.rotate(30 * hour, scaled[0], scaled[1]);
    Scrambler.drawPolygon(p, cv, ColorConst.YELLOW, arx2, ary2, false);
    cv.restore();
  }

  private drawPeg(p: PaintState, c: ScrambleCanvas, w: number, cx: number, cy: number, pegValue: number): void {
    const color = pegValue == 1 ? ColorConst.YELLOW : 0xff444400;
    p.setColor(0xff2a2a2a);
    this.drawCircle(p, c, w, cx, cy, 5);
    p.setColor(color);
    this.drawCircle(p, c, w, cx, cy, 4);
  }

  private drawPolygonScaled(p: PaintState, c: ScrambleCanvas, cl: number, w: number, arx: number[], ary: number[]): void {
    p.setColor(cl);
    const pts: number[][] = [];
    for (let idx = 0; idx < arx.length; idx++) {
      const d = this.scalePoint(w, arx[idx], ary[idx]);
      pts.push([d[0], d[1]]);
    }
    p.setStyle(0);
    c.drawPath(pts, p);
    p.setStyle(1);
    p.setColor(ColorConst.BLACK);
    c.drawPath(pts, p);
  }

  private s18(i: number): number {
    return Math.sin(Math.PI * i / 10);
  }

  private c18(i: number): number {
    return Math.cos(Math.PI * i / 10);
  }

  private rotate(a: number, b: number, x: number[], y: number[], i: number): number[][] {
    const ary: number[][] = [new Array<number>(x.length).fill(0), new Array<number>(y.length).fill(0)];
    for (let j = 0; j < x.length; j++) {
      ary[0][j] = x[j] * Math.cos(Math.PI * i / 180) - y[j] * Math.sin(Math.PI * i / 180) + a;
      ary[1][j] = x[j] * Math.sin(Math.PI * i / 180) + y[j] * Math.cos(Math.PI * i / 180) + b;
    }
    return ary;
  }

  private cos1(index: number, ag: number[], rd: number): number {
    return Math.cos(ag[index]) * rd;
  }

  private sin1(index: number, ag: number[], rd: number): number {
    return Math.sin(ag[index]) * rd;
  }

  private rd(arr: number[]): number[] {
    const out: number[] = new Array<number>(arr.length).fill(0);
    let j = 0;
    for (let i = 0; i < arr.length; i++) {
      if (i == 0 || arr[i] != arr[i - 1]) {
        out[j++] = arr[i];
      }
    }
    const temp: number[] = new Array<number>(j).fill(0);
    for (let i = 0; i < j; i++) {
      temp[i] = out[i];
    }
    return temp;
  }
}
