// SolverCore — CFOP + Roux solver shared engine (ArkTS port of dc-solver-dev/solver.js)
// All semantics: min2phase/physical (U = clockwise viewed from U face).
import { CubieCube } from '../cs/min2phase/CubieCube';
import { Utils as SolverUtils } from './Utils';
import { taskpool } from '@kit.ArkTS';
import { FileIO } from '../util/FileIO';

// ============================================================================
// shared result / data types
// ============================================================================
export interface CrossState {
  ep: number;
  eo: number;
}

export interface PairState {
  c: number;
  e: number;
}

export interface StageResult {
  name: string;
  moves: number[];
}

export interface SolveOutput {
  ok: boolean;
  error: string;
  totalSteps: number;
  stages: StageResult[];
  // per-stage display step counts after per-stage simplify
  stageSteps: number[];
  // full simplified solution in the USER'S GRIP frame (face*3+dir, faces 0-5 UDLRFB + slices).
  // 握姿 = 所选底面朝下、前面/左侧朝自己；按此握姿直接应用即可复原。
  userMoves: number[];
  userAlg: string;
  rotIdx: number;
  // optional CFOP-only: alternative F2L insertion orders for the user to pick.
  // Absent/omitted for Roux and for forced-order CFOP re-solves.
  f2lAlternatives?: F2lAlternative[];
}

// One candidate F2L insertion order. Emitted by the CFOP solver so the UI can
// show the user several alternative F2L solutions and let them pick one.
export interface F2lAlternative {
  // slot order in this candidate (each entry in 0..3 -> SLOT_NAMES)
  order: number[];
  // human label, e.g. "FR→FL→BL→BR"
  orderName: string;
  // total simplified F2L step count for this order
  f2lSteps: number;
  // the F2L algorithm of this order (solver grip frame)
  f2lAlg: string;
  // 枚举时逐槽求解得到的原始（未化简）步序。枚举选中的最优顺序直接复用这份
  // 结果，无需对同一顺序再做一次整段搜索（旧实现会重搜一遍，纯浪费）。
  slotMoves: number[][];
}

export interface ParsedToken {
  face: number;
  dir: number;
}

export interface AlgHit {
  alg: string;
  auf: number;
}

export interface PllHit {
  alg: string;
  pre: number;
  post: number;
}

export class Tables {
  oll: Record<string, AlgHit> = {};
  pll: Record<string, PllHit> = {};
  cmllOri: Record<string, AlgHit> = {};
  cmllPer: Record<string, AlgHit> = {};
}

// ============================================================================
// constants
// ============================================================================
const MOVE_MAP: number[] = [0, 9, 12, 3, 6, 15]; // UDLRFB -> moveCube(indexes) order URFDLB
const FACE_NAMES: string[] = ['U', 'D', 'L', 'R', 'F', 'B', 'M', 'E', 'S', 'u', 'd', 'l', 'r', 'f', 'b'];
const SLOT_CORNER = [4, 5, 6, 7]; // DFR, DFL, DBL, DBR
const SLOT_EDGE = [8, 9, 10, 11]; // FR, FL, BL, BR
const SLOT_NAMES: string[] = ['FR', 'FL', 'BL', 'BR'];
const CROSS_GOAL_EP = 1670;
const CROSS_GOAL_EO = 1104;

// face name -> moveCube base index for face moves
const FACE_MOVE: Record<string, number> = { 'U': 0, 'R': 3, 'F': 6, 'D': 9, 'L': 12, 'B': 15 };
const TOKEN_FACE: Record<string, number> = {
  'U': 0, 'D': 1, 'L': 2, 'R': 3, 'F': 4, 'B': 5, 'M': 6, 'E': 7, 'S': 8,
  'u': 9, 'd': 10, 'l': 11, 'r': 12, 'f': 13, 'b': 14
};
const TOK_SUFFIX: string[] = ['', '2', "'"];

// cross edges DF(5), DL(6), DB(7), DR(4)
const EDGE_CYCLES: number[][] = [
  [0, 1, 2, 3],   // U  pieces UR->UF->UL->UB
  [5, 4, 7, 6],   // D  pieces DF->DR->DB->DL
  [2, 9, 6, 10],  // L  pieces UL->FL->DL->BL
  [0, 11, 4, 8],  // R  pieces UR->BR->DR->FR
  [1, 8, 5, 9],   // F  pieces UF->FR->DF->FL (flips)
  [3, 10, 7, 11]  // B  pieces UB->BL->DB->BR (flips)
];
const FLIP_FACES: boolean[] = [false, false, false, false, true, true];

// slice definitions (position ids, a<-b<-c<-d<-a cycle)
const SLICE_M: number[] = [7, 5, 1, 3];
const SLICE_M_FLIP: number[] = [1, 3, 5, 7];
const SLICE_E: number[] = [11, 8, 9, 10];
const SLICE_E_FLIP: number[] = [8, 9, 10, 11];
const SLICE_S: number[] = [4, 0, 2, 6];
const SLICE_S_FLIP: number[] = [0, 2, 4, 6];

// rotation generator material face maps: mat[f] = position face f moves to
const ROT_X: number[] = [5, 4, 2, 3, 0, 1];
const ROT_Y: number[] = [0, 1, 5, 4, 2, 3];
const ROT_Z: number[] = [3, 2, 0, 1, 4, 5];

const CORNER_FACES: number[][] = [
  [0, 3, 4], [0, 4, 2], [0, 2, 5], [0, 5, 3],
  [1, 4, 3], [1, 2, 4], [1, 5, 2], [1, 3, 5]
];
const EDGE_FACES: number[][] = [
  [0, 3], [0, 4], [0, 2], [0, 5], [1, 3], [1, 4], [1, 2], [1, 5],
  [4, 3], [4, 2], [5, 2], [5, 3]
];

// ============================================================================
// move application on CubieCube (face / slice / wide / rotation)
// ============================================================================
function copyCube(dst: CubieCube, src: CubieCube): void {
  for (let i = 0; i < 8; i++) {
    dst.cp[i] = src.cp[i];
    dst.co[i] = src.co[i];
  }
  for (let i = 0; i < 12; i++) {
    dst.ep[i] = src.ep[i];
    dst.eo[i] = src.eo[i];
  }
}

function applySlice(cc: CubieCube, cyc: number[], flips: number[], dir: number): void {
  for (let rep = 0; rep < dir; rep++) {
    const t = cc.ep[cyc[0]];
    const to = cc.eo[cyc[0]];
    cc.ep[cyc[0]] = cc.ep[cyc[1]];
    cc.eo[cyc[0]] = cc.eo[cyc[1]];
    cc.ep[cyc[1]] = cc.ep[cyc[2]];
    cc.eo[cyc[1]] = cc.eo[cyc[2]];
    cc.ep[cyc[2]] = cc.ep[cyc[3]];
    cc.eo[cyc[2]] = cc.eo[cyc[3]];
    cc.ep[cyc[3]] = t;
    cc.eo[cyc[3]] = to;
    for (let fi = 0; fi < flips.length; fi++) {
      cc.eo[flips[fi]] ^= 1;
    }
  }
}

// apply a token (already parsed to char + dir 1/2/3) to a cube in place
function applyTokFace(cc: CubieCube, base: string, dir: number): void {
  if ('URFDLB'.indexOf(base) >= 0) {
    copyCube(cc, cc.move(FACE_MOVE[base] + (dir - 1)));
  } else if (base === 'M') {
    applySlice(cc, SLICE_M, SLICE_M_FLIP, dir);
  } else if (base === 'E') {
    applySlice(cc, SLICE_E, SLICE_E_FLIP, dir);
  } else if (base === 'S') {
    applySlice(cc, SLICE_S, SLICE_S_FLIP, dir);
  } else {
    // wide moves r=RM' l=LM u=UE' d=DE f=FS b=BS'
    // NOTE: the outer dir (1/2/3 quarter-turns) MUST be honored — apply the
    // single wide turn `dir` times, otherwise r2/r' silently degrade to r.
    for (let rep = 0; rep < dir; rep++) {
      if (base === 'r') {
        copyCube(cc, cc.move(FACE_MOVE['R']));
        applySlice(cc, SLICE_M, SLICE_M_FLIP, 3);
      } else if (base === 'l') {
        copyCube(cc, cc.move(FACE_MOVE['L']));
        applySlice(cc, SLICE_M, SLICE_M_FLIP, 1);
      } else if (base === 'u') {
        copyCube(cc, cc.move(FACE_MOVE['U']));
        applySlice(cc, SLICE_E, SLICE_E_FLIP, 3);
      } else if (base === 'd') {
        copyCube(cc, cc.move(FACE_MOVE['D']));
        applySlice(cc, SLICE_E, SLICE_E_FLIP, 1);
      } else if (base === 'f') {
        copyCube(cc, cc.move(FACE_MOVE['F']));
        applySlice(cc, SLICE_S, SLICE_S_FLIP, 1);
      } else if (base === 'b') {
        copyCube(cc, cc.move(FACE_MOVE['B']));
        applySlice(cc, SLICE_S, SLICE_S_FLIP, 3);
      }
    }
  }
}

// rotation axis composition: x = R M' L' ; y = U E' D' ; z = F S B'
// (applied `dir` times; dir 3 = three 90deg applications = the inverse rotation)
function applyAxis(cc: CubieCube, axis: string, dir: number): void {
  for (let rep = 0; rep < dir; rep++) {
    if (axis === 'x') {
      copyCube(cc, cc.move(FACE_MOVE['R']));
      applySlice(cc, SLICE_M, SLICE_M_FLIP, 3);
      copyCube(cc, cc.move(FACE_MOVE['L'] + 2));
    } else if (axis === 'y') {
      copyCube(cc, cc.move(FACE_MOVE['U']));
      applySlice(cc, SLICE_E, SLICE_E_FLIP, 3);
      copyCube(cc, cc.move(FACE_MOVE['D'] + 2));
    } else if (axis === 'z') {
      copyCube(cc, cc.move(FACE_MOVE['F']));
      applySlice(cc, SLICE_S, SLICE_S_FLIP, 1);
      copyCube(cc, cc.move(FACE_MOVE['B'] + 2));
    }
  }
}

// apply a full move token string like "R'", "U2", "M", "r" to a cube in place
export function applyToken(cc: CubieCube, tok: string): void {
  const m = /^([RULFDBMESrlufdbxyz])([2']?)$/.exec(tok);
  if (m == null) {
    return;
  }
  const base = m[1];
  let dir = 1;
  if (m[2] === '2') {
    dir = 2;
  } else if (m[2] === "'") {
    dir = 3;
  }
  if (base === 'R' || base === 'L' || base === 'U' || base === 'D' || base === 'F' || base === 'B' ||
    base === 'M' || base === 'E' || base === 'S' || base === 'r' || base === 'l' ||
    base === 'u' || base === 'd' || base === 'f' || base === 'b') {
    applyTokFace(cc, base, dir);
  } else if (base === 'x') {
    applyAxis(cc, 'x', dir);
  } else if (base === 'y') {
    applyAxis(cc, 'y', dir);
  } else if (base === 'z') {
    applyAxis(cc, 'z', dir);
  }
}

export function isSolvedCube(cc: CubieCube): boolean {
  for (let i = 0; i < 8; i++) {
    if (cc.cp[i] !== i || cc.co[i] !== 0) {
      return false;
    }
  }
  for (let i = 0; i < 12; i++) {
    if (cc.ep[i] !== i || cc.eo[i] !== 0) {
      return false;
    }
  }
  return true;
}

// ============================================================================
// single-piece move tables
// ============================================================================
// 扁平化 TypedArray（下标 = state*6+face，值 < 24）：IDA* 内层每个节点都要查
// 这些表，number[][] 的双重索引（两次边界检查 + 行对象寻址）比一维 TypedArray
// 慢数倍，是 CFOP/桥式逐节点开销的大头。所有热路径（idaF2l/idaSB/BlockSolver
// 的 moveC/moveE/建表 BFS）统一改读扁平表。
let cornerMoveT: Uint8Array = new Uint8Array(0);
let edgeMoveT: Uint8Array = new Uint8Array(0);

function buildPieceTables(): void {
  const cm: Uint8Array = new Uint8Array(24 * 6);
  const em: Uint8Array = new Uint8Array(24 * 6);
  for (let s = 0; s < 24; s++) {
    for (let f = 0; f < 6; f++) {
      const pos = Math.floor(s / 3);
      const ori = s % 3;
      const cp: number[] = [0, 1, 2, 3, 4, 5, 6, 7];
      const co: number[] = [0, 0, 0, 0, 0, 0, 0, 0];
      cp[pos] = 0;
      co[pos] = ori;
      if (pos !== 0) {
        cp[0] = pos;
      }
      const moved = new CubieCube(cp, co, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
        new Array<number>(12).fill(0)).move(MOVE_MAP[f]);
      let np = -1;
      for (let i = 0; i < 8; i++) {
        if (moved.cp[i] === 0) {
          np = i;
          break;
        }
      }
      cm[s * 6 + f] = np * 3 + (moved.co[np] % 3);
      // edge
      const epos = Math.floor(s / 2);
      const eori = s % 2;
      const ep: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
      const eo: number[] = new Array<number>(12).fill(0);
      ep[epos] = 0;
      eo[epos] = eori;
      if (epos !== 0) {
        ep[0] = epos;
      }
      const m3 = new CubieCube([0, 1, 2, 3, 4, 5, 6, 7], [0, 0, 0, 0, 0, 0, 0, 0], ep, eo).move(MOVE_MAP[f]);
      let enp = -1;
      for (let i = 0; i < 12; i++) {
        if (m3.ep[i] === 0) {
          enp = i;
          break;
        }
      }
      em[s * 6 + f] = enp * 2 + (m3.eo[enp] % 2);
    }
  }
  cornerMoveT = cm;
  edgeMoveT = em;
}

// ============================================================================
// cross machinery
// ============================================================================
function crossCircle(arr: number[], a: number, b: number, c: number, d: number, ori: number): void {
  const t = arr[a];
  arr[a] = arr[d] ^ ori;
  arr[d] = arr[c] ^ ori;
  arr[c] = arr[b] ^ ori;
  arr[b] = t ^ ori;
}

function idxToComb(arr: number[], s: number[], c: number, o: number): void {
  let q = 4;
  for (let i = 0; i < 12; i++) {
    if (c >= SolverUtils.Cnk[11 - i][q]) {
      c -= SolverUtils.Cnk[11 - i][q--];
      arr[i] = (s[q] << 1) | (o & 1);
      o >>= 1;
    } else {
      arr[i] = -1;
    }
  }
}

function edgemv(arr: number[], m: number): void {
  const c = EDGE_CYCLES[m];
  crossCircle(arr, c[0], c[1], c[2], c[3], FLIP_FACES[m] ? 1 : 0);
}

// 扁平化后的十字移动/距离表（下标 = state*6+face / state）。createPrun3 需要
// number[]/number[][] 入参，因此先用普通数组构建，构建完成后拷入 TypedArray，
// 之后所有热路径只读 TypedArray。
let crossEpmT: Uint16Array = new Uint16Array(0);
let crossEomT: Uint16Array = new Uint16Array(0);
let crossEpdT: Int8Array = new Int8Array(0);
let crossEodT: Int8Array = new Int8Array(0);

function buildCrossTables(): void {
  const epm: number[][] = new Array<number>(11880).fill(0).map(() => new Array<number>(6).fill(0));
  const eom: number[][] = new Array<number>(7920).fill(0).map(() => new Array<number>(6).fill(0));
  const epd: number[] = new Array<number>(11880).fill(-1);
  const eod: number[] = new Array<number>(7920).fill(-1);
  const getmv = (c: number, po: number, f: number): number => {
    const arr: number[] = new Array<number>(12).fill(0);
    const ps: number[] = new Array<number>(4).fill(0);
    SolverUtils.idxToPerm(ps, po, 4, false);
    idxToComb(arr, ps, c, po);
    edgemv(arr, f);
    let cc = 0;
    let pp = 0;
    let q = 4;
    for (let t = 0; t < 12; t++) {
      if (arr[t] >= 0) {
        cc += SolverUtils.Cnk[11 - t][q--];
        ps[q] = arr[t] >> 1;
        pp |= (arr[t] & 1) << (3 - q);
      }
    }
    const i = SolverUtils.permToIdx(ps, 4, false);
    return ((24 * cc + i) << 4) | pp;
  };
  for (let a = 0; a < 495; a++) {
    for (let b = 0; b < 24; b++) {
      for (let c = 0; c < 6; c++) {
        const d = getmv(a, b, c);
        epm[24 * a + b][c] = d >> 4;
        if (b < 16) {
          eom[16 * a + b][c] = ((Math.floor(d / 384)) << 4) | (d & 15);
        }
      }
    }
  }
  epd[69 * 24 + 14] = 0;
  SolverUtils.createPrun3(epd, 6, epm, 3);
  eod[69 * 16] = 0;
  SolverUtils.createPrun3(eod, 7, eom, 3);
  crossEpmT = new Uint16Array(11880 * 6);
  crossEomT = new Uint16Array(7920 * 6);
  for (let st = 0; st < 11880; st++) {
    for (let f = 0; f < 6; f++) {
      crossEpmT[st * 6 + f] = epm[st][f];
    }
  }
  for (let st = 0; st < 7920; st++) {
    for (let f = 0; f < 6; f++) {
      crossEomT[st * 6 + f] = eom[st][f];
    }
  }
  crossEpdT = new Int8Array(11880);
  crossEodT = new Int8Array(7920);
  for (let i = 0; i < 11880; i++) {
    crossEpdT[i] = epd[i];
  }
  for (let i = 0; i < 7920; i++) {
    crossEodT[i] = eod[i];
  }
}

export function extractCrossState(cc: CubieCube): CrossState {
  const pieces: number[] = [5, 6, 7, 4];
  let c = 0;
  let po = 0;
  let q = 4;
  let oc = 0;
  const ps: number[] = new Array<number>(4).fill(0);
  for (let t = 0; t < 12; t++) {
    const p = pieces.indexOf(cc.ep[t]);
    if (p >= 0) {
      c += SolverUtils.Cnk[11 - t][q--];
      ps[3 - oc] = p;
      po |= (cc.eo[t] & 1) << oc;
      oc++;
    }
  }
  const pi = SolverUtils.permToIdx(ps, 4, false);
  return { ep: 24 * c + pi, eo: 16 * c + po };
}

const crossSeq: number[] = new Array<number>(20).fill(0);
function idaCross(ep: number, eo: number, d: number, lm: number): boolean {
  if (d === 0) {
    return ep === CROSS_GOAL_EP && eo === CROSS_GOAL_EO;
  }
  if (crossEpdT[ep] > d || crossEodT[eo] > d) {
    return false;
  }
  for (let i = 0; i < 6; i++) {
    if (i !== lm) {
      let epx = ep;
      let eox = eo;
      for (let j = 0; j < 3; j++) {
        epx = crossEpmT[epx * 6 + i];
        eox = crossEomT[eox * 6 + i];
        if (idaCross(epx, eox, d - 1, i)) {
          crossSeq[d] = i * 3 + j;
          return true;
        }
      }
    }
  }
  return false;
}

export async function solveCrossState(ep: number, eo: number): Promise<number[] | null> {
  if (ep === CROSS_GOAL_EP && eo === CROSS_GOAL_EO) {
    return [];
  }
  for (let d = 0; d < 9; d++) {
    await yieldToUi();
    if (idaCross(ep, eo, d, -1)) {
      const out: number[] = [];
      for (let i = d; i > 0; i--) {
        out.push(crossSeq[i]);
      }
      return out;
    }
  }
  return null;
}

// ============================================================================
// F2L slot solver
// ============================================================================
// 四个槽的成对剪枝表扁平化为一张 Int8Array（下标 = slot*576 + c*24 + e）。
let pairPrunT: Int8Array = new Int8Array(0);

function buildPairPrun(): void {
  const prun: Int8Array = new Int8Array(4 * 576).fill(-1);
  const queue: number[] = [];
  for (let k = 0; k < 4; k++) {
    const goal = SLOT_CORNER[k] * 3 * 24 + SLOT_EDGE[k] * 2;
    const st = k * 576 + goal;
    prun[st] = 0;
    queue.push(st);
  }
  let head = 0;
  while (head < queue.length) {
    const st = queue[head++];
    const k = Math.floor(st / 576);
    const local = st % 576;
    const c = Math.floor(local / 24);
    const e = local % 24;
    const d = prun[st];
    for (let f = 0; f < 6; f++) {
      let nc = c;
      let ne = e;
      for (let t = 0; t < 3; t++) {
        nc = cornerMoveT[nc * 6 + f];
        ne = edgeMoveT[ne * 6 + f];
        const nst = k * 576 + nc * 24 + ne;
        if (prun[nst] < 0) {
          prun[nst] = d + 1;
          queue.push(nst);
        }
      }
    }
  }
  pairPrunT = prun;
}

// F2L 两槽联合剪枝表：对任意两个目标槽 (i,j) 的 4 块组合状态给出精确下界，
// 严格强于单槽表 max（单槽各自近家但互相纠缠时差距最大，恰是搜索爆炸的场景）。
// 24^4 = 331776 状态/组合 × C(4,2)=6 组合 ≈ 1.9MB；构建 ~200ms(Node)。
// 实测（12 随机打乱全 24 顺序枚举）：节点 2.8 亿 → 968 万（~29×），结果与
// 单槽剪枝逐字节一致（可采纳剪枝，不改变 DFS 顺序与首解）。
const PAIR_JOINT_SIZE: number = 331776; // 24^4
const PAIR_JOINT_COMBO: number[] = new Array<number>(16).fill(-1);
// 组合映射是静态的，模块加载即填好——从磁盘缓存恢复 pairJointT 时不会经过
// buildPairJoint*，若只在那里填表会得到全 -1 的索引、剪枝静默失效。
{
  let pci = 0;
  for (let pi = 0; pi < 4; pi++) {
    for (let pj = pi + 1; pj < 4; pj++) {
      PAIR_JOINT_COMBO[pi * 4 + pj] = pci;
      pci++;
    }
  }
}
let pairJointT: Int8Array = new Int8Array(0);

// 构建单个槽组合的 BFS（goal = 两槽 pair 状态同时就位）
function buildPairJointCombo(ci: number, i: number, j: number, tab: Int8Array): void {
  const base = ci * PAIR_JOINT_SIZE;
  const goal = ((SLOT_CORNER[i] * 3) * 24 + SLOT_EDGE[i] * 2) * 576 +
    (SLOT_CORNER[j] * 3) * 24 + SLOT_EDGE[j] * 2;
  tab[base + goal] = 0;
  const queue: number[] = [goal];
  let head = 0;
  while (head < queue.length) {
    const st = queue[head++];
    const d = tab[base + st];
    const ca = Math.floor(st / 13824);
    const remA = st % 13824;
    const ea = Math.floor(remA / 576);
    const remB = remA % 576;
    const cb = Math.floor(remB / 24);
    const eb = remB % 24;
    for (let f = 0; f < 6; f++) {
      let xa = ca;
      let ya = ea;
      let xb = cb;
      let yb = eb;
      for (let t = 0; t < 3; t++) {
        xa = cornerMoveT[xa * 6 + f];
        ya = edgeMoveT[ya * 6 + f];
        xb = cornerMoveT[xb * 6 + f];
        yb = edgeMoveT[yb * 6 + f];
        const nl = (xa * 24 + ya) * 576 + xb * 24 + yb;
        if (tab[base + nl] < 0) {
          tab[base + nl] = d + 1;
          queue.push(nl);
        }
      }
    }
  }
}

async function buildPairJointAsync(): Promise<void> {
  const tab: Int8Array = new Int8Array(6 * PAIR_JOINT_SIZE).fill(-1);
  let ci = 0;
  for (let i = 0; i < 4; i++) {
    for (let j = i + 1; j < 4; j++) {
      buildPairJointCombo(ci, i, j, tab);
      PAIR_JOINT_COMBO[i * 4 + j] = ci;
      ci++;
      // 每个组合（约 331k 状态 BFS）之间让出，主线程回退路径不会连续阻塞过久
      await yieldToUi();
    }
  }
  pairJointT = tab;
}

function buildPairJointSync(): void {
  const tab: Int8Array = new Int8Array(6 * PAIR_JOINT_SIZE).fill(-1);
  let ci = 0;
  for (let i = 0; i < 4; i++) {
    for (let j = i + 1; j < 4; j++) {
      buildPairJointCombo(ci, i, j, tab);
      PAIR_JOINT_COMBO[i * 4 + j] = ci;
      ci++;
    }
  }
  pairJointT = tab;
}

const slotSeq: number[] = new Array<number>(16).fill(0);
function idaSlot(ep: number, eo: number, cs: number[], es: number[], d: number, lm: number, k: number): boolean {
  if (d === 0) {
    if (ep !== CROSS_GOAL_EP || eo !== CROSS_GOAL_EO) {
      return false;
    }
    for (let j = 0; j <= k; j++) {
      if (cs[j] !== SLOT_CORNER[j] * 3 || es[j] !== SLOT_EDGE[j] * 2) {
        return false;
      }
    }
    return true;
  }
  if (crossEpdT[ep] > d || crossEodT[eo] > d) {
    return false;
  }
  for (let j = 0; j <= k; j++) {
    if (pairPrunT[j * 576 + cs[j] * 24 + es[j]] > d) {
      return false;
    }
  }
  for (let i = 0; i < 6; i++) {
    if (i !== lm) {
      let epx = ep;
      let eox = eo;
      const cx: number[] = cs.slice();
      const ex: number[] = es.slice();
      for (let j = 0; j < 3; j++) {
        epx = crossEpmT[epx * 6 + i];
        eox = crossEomT[eox * 6 + i];
        for (let p = 0; p <= k; p++) {
          cx[p] = cornerMoveT[cx[p] * 6 + i];
          ex[p] = edgeMoveT[ex[p] * 6 + i];
        }
        if (idaSlot(epx, eox, cx, ex, d - 1, i, k)) {
          slotSeq[d] = i * 3 + j;
          return true;
        }
      }
    }
  }
  return false;
}

export function pairStateOf(cc: CubieCube, k: number): PairState {
  let c = -1;
  let e = -1;
  for (let i = 0; i < 8; i++) {
    if (cc.cp[i] === SLOT_CORNER[k]) {
      c = i * 3 + (cc.co[i] % 3);
      break;
    }
  }
  for (let i = 0; i < 12; i++) {
    if (cc.ep[i] === SLOT_EDGE[k]) {
      e = i * 2 + (cc.eo[i] % 2);
      break;
    }
  }
  return { c: c, e: e };
}

export async function solveSlot(cc: CubieCube, k: number): Promise<number[] | null> {
  const cs: number[] = [];
  const es: number[] = [];
  for (let j = 0; j <= k; j++) {
    const st = pairStateOf(cc, j);
    cs.push(st.c);
    es.push(st.e);
  }
  const csState = extractCrossState(cc);
  let done = csState.ep === CROSS_GOAL_EP && csState.eo === CROSS_GOAL_EO;
  if (done) {
    for (let j = 0; j <= k; j++) {
      if (cs[j] !== SLOT_CORNER[j] * 3 || es[j] !== SLOT_EDGE[j] * 2) {
        done = false;
        break;
      }
    }
  }
  if (done) {
    return [];
  }
  for (let d = 0; d < 15; d++) {
    await yieldToUi();
    if (idaSlot(csState.ep, csState.eo, cs, es, d, -1, k)) {
      const out: number[] = [];
      for (let i = d; i > 0; i--) {
        out.push(slotSeq[i]);
      }
      return out;
    }
  }
  return null;
}

// Generalized F2L search over an arbitrary target set of slot indices.
// goals/targets: the exact slots that must end at their solved pair states
// (preserves previously placed pairs in multi-order insertion). Params:
//   cs/es  — length-4 arrays indexed by slot id; only targets entries are used.
//   n      — number of slots in `targets`.
// Reuses slotSeq so it must not run concurrently with solveSlot/idaSlot, which
// is guaranteed (all CFOP slot stages are awaited sequentially).
//
// 性能（2026-08 优化）：内层 IDA* 改为完全同步 + 零分配。旧实现是 async 递归，
// 且每个节点对 cs/es 各做一次 slice() 拷贝——每节点的 Promise/微任务调度与临时
// 数组 GC 压力比查表本身贵 10~50 倍，是 CFOP 求解慢的主因。现改为原地改写
// cs/es + 按深度索引的保存/恢复缓冲，节点开销只剩查表。主线程看门狗安全改由
// "节点预算（每次调用硬上限）+ solveF2lTargets 每个深度层之间让出"保证——
// 单次深度迭代被节点预算封顶，不会无限阻塞。
let f2lNodes: number = 0;
let f2lBudgetExceeded: boolean = false;
// 每次 solveF2lTargets 调用的节点硬上限（保底路径：默认顺序 + 强制顺序重解）。
// 工作线程里用更大的上限（那里没有 UI 可阻塞，且同步搜索单节点开销低得多）；
// 主线程用较小上限，保证单个深度迭代在慢速设备上也远低于 6s 看门狗
// （仅 taskpool 不可用时的回退路径会走主线程）。
const F2L_NODE_BUDGET: number = 2000000;
const F2L_NODE_BUDGET_MAIN: number = 1000000;

// Shared, solve-scoped F2L budget: the 24-order enumeration must not be allowed
// to spend unlimited nodes finding near-optimal insertion orders on every
// scramble (measured up to 77s on Node for one scramble before budgets existed).
// When `f2lSharedMode` is on, ALL solveF2lTargets calls together may spend at
// most F2L_SOLVE_BUDGET nodes; once exhausted, remaining orders bail immediately
// so the whole solve returns the best-found result in bounded time. The
// guaranteed default order and the final solve of the chosen order run OUTSIDE
// shared mode so a valid result is always produced.
const F2L_SOLVE_BUDGET: number = 6000000;
let f2lSharedMode: boolean = false;
let f2lSharedRemaining: number = 0;

export function setF2lSharedBudget(on: boolean): void {
  f2lSharedMode = on;
  f2lSharedRemaining = on ? F2L_SOLVE_BUDGET : 0;
}

// 按深度索引的保存缓冲：搜索原地改写 cs/es 后按 d*4+t 存旧值、回溯时恢复，
// 避免每节点分配（最大深度 15、目标数 ≤4，索引上界 14*4+3 < 64）。
const f2lSaveC: number[] = new Array<number>(64).fill(0);
const f2lSaveE: number[] = new Array<number>(64).fill(0);

function idaF2l(ep: number, eo: number, cs: number[], es: number[], d: number, lm: number,
  targets: number[], n: number, nodeCap: number): boolean {
  f2lNodes++;
  if (f2lSharedMode && f2lSharedRemaining > 0 && (f2lSharedRemaining - f2lNodes) <= 0) {
    f2lBudgetExceeded = true;
    return false;
  }
  if (f2lNodes > nodeCap) {
    f2lBudgetExceeded = true;
    return false;
  }
  if (d === 0) {
    if (ep !== CROSS_GOAL_EP || eo !== CROSS_GOAL_EO) {
      return false;
    }
    for (let t = 0; t < n; t++) {
      const j = targets[t];
      if (cs[j] !== SLOT_CORNER[j] * 3 || es[j] !== SLOT_EDGE[j] * 2) {
        return false;
      }
    }
    return true;
  }
  if (crossEpdT[ep] > d || crossEodT[eo] > d) {
    return false;
  }
  if (n >= 2) {
    // 两槽联合下界严格覆盖单槽下界：n≥2 时查 C(n,2) 个组合表即可。
    // 槽号归一化：低槽号占据键高位，与建表编码一致（targets 无序）。
    for (let a = 0; a < n; a++) {
      const ta = targets[a];
      for (let b = a + 1; b < n; b++) {
        const tb = targets[b];
        if (ta < tb) {
          const key = (cs[ta] * 24 + es[ta]) * 576 + cs[tb] * 24 + es[tb];
          if (pairJointT[PAIR_JOINT_COMBO[ta * 4 + tb] * PAIR_JOINT_SIZE + key] > d) {
            return false;
          }
        } else {
          const key = (cs[tb] * 24 + es[tb]) * 576 + cs[ta] * 24 + es[ta];
          if (pairJointT[PAIR_JOINT_COMBO[tb * 4 + ta] * PAIR_JOINT_SIZE + key] > d) {
            return false;
          }
        }
      }
    }
  } else if (pairPrunT[targets[0] * 576 + cs[targets[0]] * 24 + es[targets[0]]] > d) {
    return false;
  }
  const base = d * 4;
  for (let i = 0; i < 6; i++) {
    if (i !== lm) {
      let epx = ep;
      let eox = eo;
      // 每个面先保存一次原始状态；j=0/1/2 对同一面逐次累积转动
      // （状态依次为 +move、+move²、+move³），三面循环结束后统一恢复。
      for (let t = 0; t < n; t++) {
        const s = targets[t];
        f2lSaveC[base + t] = cs[s];
        f2lSaveE[base + t] = es[s];
      }
      for (let j = 0; j < 3; j++) {
        epx = crossEpmT[epx * 6 + i];
        eox = crossEomT[eox * 6 + i];
        for (let t = 0; t < n; t++) {
          const s = targets[t];
          cs[s] = cornerMoveT[cs[s] * 6 + i];
          es[s] = edgeMoveT[es[s] * 6 + i];
        }
        if (idaF2l(epx, eox, cs, es, d - 1, i, targets, n, nodeCap)) {
          slotSeq[d] = i * 3 + j;
          return true;
        }
      }
      for (let t = 0; t < n; t++) {
        const s = targets[t];
        cs[s] = f2lSaveC[base + t];
        es[s] = f2lSaveE[base + t];
      }
    }
  }
  return false;
}

// Solve F2L so that exactly the given `targets` slot indices are solved
// (cross already solved). Returns the move list, or null if unsolvable within
// the depth bound / node budget. Used for arbitrary insertion orders.
export async function solveF2lTargets(cc: CubieCube, targets: number[]): Promise<number[] | null> {
  // 保底路径（默认顺序 / 强制顺序重解）每次调用独立预算；共享模式下整个枚举
  // 只有一个总预算池（见 setF2lSharedBudget），池子耗尽后直接放弃剩余顺序。
  let nodeCap: number = yieldInWorker ? F2L_NODE_BUDGET : F2L_NODE_BUDGET_MAIN;
  if (f2lSharedMode) {
    if (f2lSharedRemaining <= 0) {
      f2lBudgetExceeded = true;
      return null;
    }
    if (f2lSharedRemaining < nodeCap) {
      nodeCap = f2lSharedRemaining;
    }
  }
  f2lNodes = 0;
  f2lBudgetExceeded = false;
  const n = targets.length;
  const cs: number[] = [-1, -1, -1, -1];
  const es: number[] = [-1, -1, -1, -1];
  try {
    for (let t = 0; t < n; t++) {
      const st = pairStateOf(cc, targets[t]);
      cs[targets[t]] = st.c;
      es[targets[t]] = st.e;
    }
    const csState = extractCrossState(cc);
    let done = csState.ep === CROSS_GOAL_EP && csState.eo === CROSS_GOAL_EO;
    if (done) {
      for (let t = 0; t < n; t++) {
        const j = targets[t];
        if (cs[j] !== SLOT_CORNER[j] * 3 || es[j] !== SLOT_EDGE[j] * 2) {
          done = false;
          break;
        }
      }
    }
    if (done) {
      return [];
    }
    for (let d = 0; d < 15; d++) {
      // 同步内层搜索被节点预算封顶，不会无限阻塞；仅在深度层之间让出主线程。
      await yieldToUi();
      if (f2lBudgetExceeded) {
        break;
      }
      if (idaF2l(csState.ep, csState.eo, cs, es, d, -1, targets, n, nodeCap)) {
        const out: number[] = [];
        for (let i = d; i > 0; i--) {
          out.push(slotSeq[i]);
        }
        return out;
      }
      if (f2lBudgetExceeded) {
        break;
      }
    }
    return null;
  } finally {
    if (f2lSharedMode) {
      f2lSharedRemaining -= f2lNodes;
      if (f2lSharedRemaining < 0) {
        f2lSharedRemaining = 0;
      }
    }
  }
}

// ============================================================================
// generic block solver (Roux FB / SB)
// ============================================================================
// 块求解（左桥）单次调用的节点硬上限：有角块/棱块两个独立剪枝表护航，
// 正常打乱远低于此值；仅用于兜住极端情况，避免同步搜索长时间阻塞工作线程。
const BLOCK_NODE_CAP: number = 4000000;

export class BlockSolver {
  nC: number;
  nE: number;
  cSize: number;
  eSize: number;
  cGoal: number;
  eGoal: number;
  cP: number[];
  eP: number[];
  cornerPieces: number[];
  edgePieces: number[];
  private seq: number[] = new Array<number>(18).fill(0);
  // 节点预算：同步块求解（左桥）在病态打乱下可能深度迭代很久，
  // 超预算即放弃本次求解（返回"无解"），避免长时间阻塞调用线程。
  // 右桥走 idaSB + 联合剪枝表（每节点有强剪枝），不受此限制。
  private nodes: number = 0;
  private capExceeded: boolean = false;
  // 可选联合剪枝表：对 (cSt,eSt) 组合给出精确下界，严格强于分体表 max(cP,eP)。
  // 由 JointTableState 在建表/磁盘加载后注入；为空时回退到分体剪枝。
  // 左桥（FB）注入后 IDA* 最后一层迭代从潜在数百万节点降到接近线性。
  private joint: Int8Array | null = null;

  setJoint(t: Int8Array): void {
    this.joint = t;
  }

  hasJoint(): boolean {
    return this.joint != null;
  }

  constructor(cornerPieces: number[], edgePieces: number[]) {
    this.cornerPieces = cornerPieces;
    this.edgePieces = edgePieces;
    this.nC = cornerPieces.length;
    this.nE = edgePieces.length;
    this.cSize = Math.pow(24, this.nC);
    this.eSize = Math.pow(24, this.nE);
    const cP: number[] = new Array<number>(this.cSize).fill(-1);
    const eP: number[] = new Array<number>(this.eSize).fill(-1);
    let cGoal = 0;
    for (let i = 0; i < this.nC; i++) {
      cGoal = cGoal * 24 + cornerPieces[i] * 3;
    }
    let eGoal = 0;
    for (let i = 0; i < this.nE; i++) {
      eGoal = eGoal * 24 + edgePieces[i] * 2;
    }
    // corner BFS
    cP[cGoal] = 0;
    const qc: number[] = [cGoal];
    let hc = 0;
    while (hc < qc.length) {
      const st = qc[hc++];
      const d = cP[st];
      for (let f = 0; f < 6; f++) {
        let ns = st;
        for (let t = 0; t < 3; t++) {
          ns = this.moveC(ns, f);
          if (cP[ns] < 0) {
            cP[ns] = d + 1;
            qc.push(ns);
          }
        }
      }
    }
    // edge BFS
    eP[eGoal] = 0;
    const qe: number[] = [eGoal];
    let he = 0;
    while (he < qe.length) {
      const st = qe[he++];
      const d = eP[st];
      for (let f = 0; f < 6; f++) {
        let ns = st;
        for (let t = 0; t < 3; t++) {
          ns = this.moveE(ns, f);
          if (eP[ns] < 0) {
            eP[ns] = d + 1;
            qe.push(ns);
          }
        }
      }
    }
    this.cP = cP;
    this.eP = eP;
    this.cGoal = cGoal;
    this.eGoal = eGoal;
  }

  moveC(st: number, f: number): number {
    // fast path: 2 corners — no per-call allocation (Roux FB/SB all use 2 corners)
    if (this.nC === 2) {
      const hi = Math.floor(st / 24);
      const lo = st % 24;
      return cornerMoveT[hi * 6 + f] * 24 + cornerMoveT[lo * 6 + f];
    }
    let s = st;
    const digs: number[] = [];
    for (let i = 0; i < this.nC; i++) {
      digs.push(s % 24);
      s = Math.floor(s / 24);
    }
    for (let i = this.nC - 1; i >= 0; i--) {
      digs[i] = cornerMoveT[digs[i] * 6 + f];
    }
    let r = 0;
    for (let i = this.nC - 1; i >= 0; i--) {
      r = r * 24 + digs[i];
    }
    return r;
  }

  moveE(st: number, f: number): number {
    // fast path: 3 edges — no per-call allocation (Roux FB/SB all use 3 edges)
    if (this.nE === 3) {
      const a = Math.floor(st / 576);
      const rem1 = st % 576;
      const b = Math.floor(rem1 / 24);
      const c = rem1 % 24;
      return edgeMoveT[a * 6 + f] * 576 + edgeMoveT[b * 6 + f] * 24 + edgeMoveT[c * 6 + f];
    }
    let s = st;
    const digs: number[] = [];
    for (let i = 0; i < this.nE; i++) {
      digs.push(s % 24);
      s = Math.floor(s / 24);
    }
    for (let i = this.nE - 1; i >= 0; i--) {
      digs[i] = edgeMoveT[digs[i] * 6 + f];
    }
    let r = 0;
    for (let i = this.nE - 1; i >= 0; i--) {
      r = r * 24 + digs[i];
    }
    return r;
  }

  extract(cc: CubieCube): PairState | null {
    let cSt = 0;
    for (let i = 0; i < this.nC; i++) {
      const piece = this.cornerPieces[i];
      let found = false;
      for (let p = 0; p < 8; p++) {
        if (cc.cp[p] === piece) {
          cSt = cSt * 24 + (p * 3 + (cc.co[p] % 3));
          found = true;
          break;
        }
      }
      if (!found) {
        return null;
      }
    }
    let eSt = 0;
    for (let i = 0; i < this.nE; i++) {
      const piece = this.edgePieces[i];
      let found = false;
      for (let p = 0; p < 12; p++) {
        if (cc.ep[p] === piece) {
          eSt = eSt * 24 + (p * 2 + (cc.eo[p] % 2));
          found = true;
          break;
        }
      }
      if (!found) {
        return null;
      }
    }
    return { c: cSt, e: eSt };
  }

  isSolved(cSt: number, eSt: number): boolean {
    return cSt === this.cGoal && eSt === this.eGoal;
  }

  private ida(cSt: number, eSt: number, d: number, lm: number): boolean {
    this.nodes++;
    if (this.nodes > BLOCK_NODE_CAP) {
      this.capExceeded = true;
      return false;
    }
    if (d === 0) {
      return cSt === this.cGoal && eSt === this.eGoal;
    }
    if (this.joint != null) {
      // 联合表下界 >= max(cP,eP)，一步到位只查一次表
      if (this.joint[cSt * this.eSize + eSt] > d) {
        return false;
      }
    } else if (this.cP[cSt] > d || this.eP[eSt] > d) {
      return false;
    }
    for (let i = 0; i < 6; i++) {
      if (i !== lm) {
        let cs = cSt;
        let es = eSt;
        for (let j = 0; j < 3; j++) {
          cs = this.moveC(cs, i);
          es = this.moveE(es, i);
          if (this.ida(cs, es, d - 1, i)) {
            this.seq[d] = i * 3 + j;
            return true;
          }
          if (this.capExceeded) {
            return false;
          }
        }
      }
    }
    return false;
  }

  solve(cSt: number, eSt: number, maxDepth: number): number[] | null {
    this.nodes = 0;
    this.capExceeded = false;
    if (cSt === this.cGoal && eSt === this.eGoal) {
      return [];
    }
    for (let d = 0; d <= maxDepth; d++) {
      if (this.ida(cSt, eSt, d, -1)) {
        const out: number[] = [];
        for (let i = d; i > 0; i--) {
          out.push(this.seq[i]);
        }
        return out;
      }
      if (this.capExceeded) {
        break;
      }
    }
    return null;
  }
}

export function buildBlockSolver(cornerPieces: number[], edgePieces: number[]): BlockSolver {
  return new BlockSolver(cornerPieces, edgePieces);
}

// single-piece tables must be ready before the FB/SB pruning BFS runs
buildPieceTables();

// Roux blocks: FB corners{5,6} edges{6,9,10}; SB corners{4,7} edges{4,8,11}
export const FB = buildBlockSolver([5, 6], [6, 9, 10]);
export const SB = buildBlockSolver([4, 7], [4, 8, 11]);

// cooperative yield so a long build never blocks the UI (ArkTS-safe Promise)
let yieldInWorker: boolean = false;

// CFOP/Roux worker wrappers set this BEFORE calling into the solver so the
// per-node yields become no-op microtasks instead of setTimeout round-trips.
// Inside a taskpool/@Concurrent task there is no UI to yield to, and a
// setTimeout callback may never fire in the worker's task context — which
// would hang the whole CFOP solve forever (perceived as "闪退"). On the main
// thread (fallback path) this stays false so real UI yielding is preserved.
export function setSolverInWorker(v: boolean): void {
  yieldInWorker = v;
}

function yieldToUi(): Promise<void> {
  if (yieldInWorker) {
    return Promise.resolve();
  }
  return new Promise<void>((resolve: () => void): void => {
    setTimeout((): void => { resolve(); }, 0);
  });
}

// 联合剪枝表（FB/SB 各一张，~7.96M 状态）：对 (cSt,eSt) 组合给出精确下界，
// 严格强于分体表 max(cP,eP)。表在 taskpool 工作线程构建（层级扫描式 BFS），
// 构建结果落盘缓存、重启后直接加载；本线程分块构建仅作无 taskpool 设备的兜底。
let jointCacheDir: string = '';

class JointTableState {
  solver: BlockSolver;
  fileName: string;
  dist: Int8Array | null = null;
  private building: Promise<void> | null = null;

  constructor(solver: BlockSolver, fileName: string) {
    this.solver = solver;
    this.fileName = fileName;
  }

  private filePath(): string {
    return jointCacheDir.length === 0 ? '' : jointCacheDir + this.fileName;
  }

  // 唯一共享入口：内存已就绪 → 磁盘缓存命中 → 在途构建复用 → 才现场构建。
  // 保证主线程预热 / 各求解任务对同一份表最多只发起一次构建。
  ensureReady(): Promise<void> {
    if (this.dist != null) {
      return Promise.resolve();
    }
    const path = this.filePath();
    if (path.length > 0) {
      const raw = FileIO.readWhole(path);
      if (raw != null && raw.length === this.solver.cSize * this.solver.eSize) {
        const view = new Int8Array(raw.buffer);
        if (view[this.solver.cGoal * this.solver.eSize + this.solver.eGoal] === 0) {
          this.dist = view;
          this.solver.setJoint(view);
          return Promise.resolve();
        }
      }
    }
    if (this.building != null) {
      return this.building;
    }
    const p: Promise<void> = this.build();
    this.building = p;
    // 完成/失败都清掉在途标记；失败不缓存 rejection，让下一次求解可以重试
    p.then((): void => {
      this.building = null;
    }, (): void => {
      this.building = null;
    });
    return p;
  }

  // 启动/进 worker 时的预热：缓存命中同步加载，未命中则后台构建（fire-and-forget）
  warm(): void {
    this.ensureReady();
  }

  private async build(): Promise<void> {
    if (cornerMoveT.length === 0) {
      buildPieceTables();
    }
    // @Concurrent 任务不能引用模块状态：把单块移动表平摊为普通数组传入
    const cmFlat: number[] = new Array<number>(144).fill(0);
    const emFlat: number[] = new Array<number>(144).fill(0);
    for (let i = 0; i < 144; i++) {
      cmFlat[i] = cornerMoveT[i];
      emFlat[i] = edgeMoveT[i];
    }
    try {
      const buf = await taskpool.execute(buildJointTableTask, cmFlat, emFlat,
        this.solver.cornerPieces, this.solver.edgePieces) as ArrayBuffer;
      this.dist = new Int8Array(buf);
    } catch (e) {
      // taskpool 不可用/失败 —— 回退到分块让出的本线程构建（安全网）
      await this.buildMainThread();
    }
    this.solver.setJoint(this.dist!);
    const path = this.filePath();
    if (path.length > 0) {
      FileIO.writeWhole(path, new Uint8Array(this.dist!.buffer));
    }
  }

  // 兜底：本线程层级扫描式 BFS，分块之间让出（保留给无 taskpool 的设备）
  private async buildMainThread(): Promise<void> {
    const bs = this.solver;
    const eSize = bs.eSize;
    const total = bs.cSize * eSize;
    const tab = new Int8Array(total).fill(-1);
    tab[bs.cGoal * eSize + bs.eGoal] = 0;
    let d = 0;
    let changed = true;
    const CHUNK = 30000; // scan positions per UI-slice before yielding
    while (changed) {
      changed = false;
      let st = 0;
      while (st < total) {
        const end = Math.min(st + CHUNK, total);
        while (st < end) {
          if (tab[st] === d) {
            const c = Math.floor(st / eSize);
            const e = st % eSize;
            for (let f = 0; f < 6; f++) {
              let cc = c;
              let ce = e;
              for (let t = 0; t < 3; t++) {
                cc = bs.moveC(cc, f);
                ce = bs.moveE(ce, f);
                const ns = cc * eSize + ce;
                if (tab[ns] < 0) {
                  tab[ns] = d + 1;
                  changed = true;
                }
              }
            }
          }
          st++;
        }
        await yieldToUi();
      }
      d++;
    }
    this.dist = tab;
  }
}

const sbJointState: JointTableState = new JointTableState(SB, 'roux_sb_joint.dat');
const fbJointState: JointTableState = new JointTableState(FB, 'roux_fb_joint.dat');

// 应用启动时调用（见 Index.initAlgorithmCache）：设置两张联合剪枝表的缓存目录，
// 使构建结果跨重启持久化。主线程与 worker 各持有一份模块状态，worker 侧必须
// 显式再调一次本函数（见 RouxSolver.rouxSolveTask）。
export function setSbJointCacheDir(dir: string): void {
  if (dir.length === 0) {
    jointCacheDir = '';
    return;
  }
  jointCacheDir = dir.endsWith('/') || dir.endsWith('\\') ? dir : dir + '/';
}

// 返回缓存目录本身（不带文件名）。worker 侧 setSbJointCacheDir 会自行拼接
// 各表文件名 —— 旧版这里误返回完整文件路径，worker 再拼一次文件名后路径永远
// 不命中，磁盘缓存形同虚设，每次桥式求解都在 worker 现场重建 8MB 表
// （桥式"依然很慢"的主因，勿改回返回完整路径）。
export function getSbJointCacheDir(): string {
  return jointCacheDir;
}

export function ensureSbJointReady(): Promise<void> {
  return sbJointState.ensureReady();
}

export function ensureFbJointReady(): Promise<void> {
  return fbJointState.ensureReady();
}

// 左桥 + 右桥两张联合表一起就绪：先同时发起（两个独立 taskpool 任务并行构建，
// 首次构建墙钟时间约等于单张），再一起等待。
export async function ensureRouxJointsAsync(): Promise<void> {
  const a: Promise<void> = sbJointState.ensureReady();
  const b: Promise<void> = fbJointState.ensureReady();
  await a;
  await b;
}

// 启动/进 worker 预热：有磁盘缓存则同步加载（一次性 8MB×2 读取，毫秒级），
// 否则立即在工作线程后台预构建（fire-and-forget，不阻塞调用方）。
export function warmJointCaches(): void {
  sbJointState.warm();
  fbJointState.warm();
}

// ============================================================================
// solver 核心表磁盘缓存（solver_core.dat，~2.4MB）
// ============================================================================
// 把重建成本最高的数值表一次性序列化落盘：重启后主线程回退路径与各 taskpool
// worker 的首次求解都改为读盘（几十 ms）而不是现建（ArkTS 上数秒）。与左/右桥
// 联合表缓存同目录（setSbJointCacheDir 设置，跨线程传目录本身）。
// 不缓存：单块表/OLL/PLL/CMLL 查找表（重建极快）、rotationsSeqs/rotToGrip
// （未被使用）。固定小端布局，魔数+版本+长度+目标格校验，任何不匹配整体放弃
// 并回落重建（自愈），因此旧版本文件/损坏文件都安全。
const CORE_CACHE_FILE = 'solver_core.dat';
const CORE_CACHE_MAGIC = 0x44504353;
const CORE_CACHE_VERSION = 1;
const CC_LEN_EPD = 11880;
const CC_LEN_EOD = 7920;
const CC_LEN_EPM = 142560;
const CC_LEN_EOM = 95040;
const CC_LEN_PRUN = 2304;
const CC_LEN_PJ = 1990656;
const CC_LEN_LPM = 8640;
const CC_LEN_LOM = 384;
const CC_LEN_LSE = 184320;
const CC_OFF_EPD = 12;
const CC_OFF_EOD = 11892;
const CC_OFF_EPM = 19812;
const CC_OFF_EOM = 162372;
const CC_OFF_PRUN = 257412;
const CC_OFF_PJ = 259716;
const CC_OFF_LPM = 2250372;
const CC_OFF_LOM = 2259012;
const CC_OFF_LSE = 2259396;
const CC_OFF_ROT = 2443716;
const CC_OFF_RTU = 2443860;
const CC_TOTAL = 2444940;

function encodeCoreCache(): Uint8Array | null {
  if (crossEpdT.length !== CC_LEN_EPD || crossEodT.length !== CC_LEN_EOD ||
    crossEpmT.byteLength !== CC_LEN_EPM || crossEomT.byteLength !== CC_LEN_EOM ||
    pairPrunT.length !== CC_LEN_PRUN || pairJointT.length !== CC_LEN_PJ ||
    lsePermMoveT.byteLength !== CC_LEN_LPM || lseOriMoveT.length !== CC_LEN_LOM ||
    lseDist == null || lseDist.length !== CC_LEN_LSE ||
    rotations.length !== 24 || rotToUser.length !== 24) {
    return null;
  }
  const buf = new ArrayBuffer(CC_TOTAL);
  const dv = new DataView(buf);
  dv.setUint32(0, CORE_CACHE_MAGIC, true);
  dv.setUint32(4, CORE_CACHE_VERSION, true);
  dv.setUint32(8, CC_TOTAL, true);
  const u8 = new Uint8Array(buf);
  u8.set(new Uint8Array(crossEpdT.buffer, crossEpdT.byteOffset, CC_LEN_EPD), CC_OFF_EPD);
  u8.set(new Uint8Array(crossEodT.buffer, crossEodT.byteOffset, CC_LEN_EOD), CC_OFF_EOD);
  u8.set(new Uint8Array(crossEpmT.buffer, crossEpmT.byteOffset, CC_LEN_EPM), CC_OFF_EPM);
  u8.set(new Uint8Array(crossEomT.buffer, crossEomT.byteOffset, CC_LEN_EOM), CC_OFF_EOM);
  u8.set(new Uint8Array(pairPrunT.buffer, pairPrunT.byteOffset, CC_LEN_PRUN), CC_OFF_PRUN);
  u8.set(new Uint8Array(pairJointT.buffer, pairJointT.byteOffset, CC_LEN_PJ), CC_OFF_PJ);
  u8.set(new Uint8Array(lsePermMoveT.buffer, lsePermMoveT.byteOffset, CC_LEN_LPM), CC_OFF_LPM);
  u8.set(new Uint8Array(lseOriMoveT.buffer, lseOriMoveT.byteOffset, CC_LEN_LOM), CC_OFF_LOM);
  u8.set(new Uint8Array(lseDist!.buffer, lseDist!.byteOffset, CC_LEN_LSE), CC_OFF_LSE);
  let off = CC_OFF_ROT;
  for (let i = 0; i < 24; i++) {
    for (let j = 0; j < 6; j++) {
      u8[off++] = rotations[i][j];
    }
  }
  off = CC_OFF_RTU;
  for (let i = 0; i < 24; i++) {
    const row = rotToUser[i];
    if (row == null || row.length !== 45) {
      return null;
    }
    for (let j = 0; j < 45; j++) {
      u8[off++] = row[j];
    }
  }
  return u8;
}

// 读取并校验 solver_core.dat；成功则原子提交全部表并返回 true。
// 元素级解码（免对齐依赖），先解到局部、全部校验通过才赋值，避免半恢复状态。
function tryLoadCoreCache(): boolean {
  const path = jointCacheDir.length === 0 ? '' : jointCacheDir + CORE_CACHE_FILE;
  if (path.length === 0) {
    return false;
  }
  const raw = FileIO.readWhole(path);
  if (raw == null || raw.length !== CC_TOTAL) {
    return false;
  }
  const dv = new DataView(raw.buffer, raw.byteOffset, CC_TOTAL);
  if (dv.getUint32(0, true) !== CORE_CACHE_MAGIC ||
    dv.getUint32(4, true) !== CORE_CACHE_VERSION ||
    dv.getUint32(8, true) !== CC_TOTAL) {
    return false;
  }
  const epd = new Int8Array(CC_LEN_EPD);
  for (let i = 0; i < CC_LEN_EPD; i++) {
    epd[i] = raw[CC_OFF_EPD + i];
  }
  const eod = new Int8Array(CC_LEN_EOD);
  for (let i = 0; i < CC_LEN_EOD; i++) {
    eod[i] = raw[CC_OFF_EOD + i];
  }
  const epm = new Uint16Array(CC_LEN_EPM / 2);
  for (let i = 0; i < epm.length; i++) {
    epm[i] = raw[CC_OFF_EPM + i * 2] | (raw[CC_OFF_EPM + i * 2 + 1] << 8);
  }
  const eom = new Uint16Array(CC_LEN_EOM / 2);
  for (let i = 0; i < eom.length; i++) {
    eom[i] = raw[CC_OFF_EOM + i * 2] | (raw[CC_OFF_EOM + i * 2 + 1] << 8);
  }
  const prun = new Int8Array(CC_LEN_PRUN);
  for (let i = 0; i < CC_LEN_PRUN; i++) {
    prun[i] = raw[CC_OFF_PRUN + i];
  }
  const pj = new Int8Array(CC_LEN_PJ);
  for (let i = 0; i < CC_LEN_PJ; i++) {
    pj[i] = raw[CC_OFF_PJ + i];
  }
  const lpm = new Uint16Array(CC_LEN_LPM / 2);
  for (let i = 0; i < lpm.length; i++) {
    lpm[i] = raw[CC_OFF_LPM + i * 2] | (raw[CC_OFF_LPM + i * 2 + 1] << 8);
  }
  const lom = new Uint8Array(CC_LEN_LOM);
  for (let i = 0; i < CC_LEN_LOM; i++) {
    lom[i] = raw[CC_OFF_LOM + i];
  }
  const lse = new Int8Array(CC_LEN_LSE);
  for (let i = 0; i < CC_LEN_LSE; i++) {
    lse[i] = raw[CC_OFF_LSE + i];
  }
  // 目标格校验：核心距离表的原点必须为 0
  if (epd[CROSS_GOAL_EP] !== 0 || eod[CROSS_GOAL_EO] !== 0) {
    return false;
  }
  if (prun[SLOT_CORNER[0] * 3 * 24 + SLOT_EDGE[0] * 2] !== 0) {
    return false;
  }
  const pjGoal = ((SLOT_CORNER[0] * 3) * 24 + SLOT_EDGE[0] * 2) * 576 +
    (SLOT_CORNER[1] * 3) * 24 + SLOT_EDGE[1] * 2;
  if (pj[pjGoal] !== 0) {
    return false;
  }
  if (lse[0] !== 0) {
    return false;
  }
  const rots: number[][] = [];
  let off = CC_OFF_ROT;
  for (let i = 0; i < 24; i++) {
    const row: number[] = [];
    for (let j = 0; j < 6; j++) {
      row.push(raw[off++]);
    }
    rots.push(row);
  }
  if (rots[0][0] !== 0 || rots[0][1] !== 1) {
    return false; // 首行必须是恒等映射
  }
  const rtu: number[][] = [];
  off = CC_OFF_RTU;
  for (let i = 0; i < 24; i++) {
    const row: number[] = [];
    for (let j = 0; j < 45; j++) {
      const v = raw[off++];
      row.push(v > 127 ? v - 256 : v);
    }
    rtu.push(row);
  }
  crossEpdT = epd;
  crossEodT = eod;
  crossEpmT = epm;
  crossEomT = eom;
  pairPrunT = prun;
  pairJointT = pj;
  lsePermMoveT = lpm;
  lseOriMoveT = lom;
  lseDist = lse;
  rotations = rots;
  rotToUser = rtu;
  return true;
}

function saveCoreCache(): void {
  const path = jointCacheDir.length === 0 ? '' : jointCacheDir + CORE_CACHE_FILE;
  if (path.length === 0) {
    return;
  }
  const enc = encodeCoreCache();
  if (enc != null) {
    FileIO.writeWhole(path, enc);
  }
}

// @Concurrent worker task: fully self-contained (no module state, no closures).
// Receives the single-piece move tables as flat arrays plus the block's goal
// piece ids, runs the level-synced scan BFS, returns the distance table's
// ArrayBuffer. Runs on a taskpool worker thread, so the calling thread stays
// fully responsive during the build. Generalized for any 2-corner/3-edge block
// (both Roux FB and SB use this shape).
@Concurrent
function buildJointTableTask(cmFlat: number[], emFlat: number[], cornerPieces: number[],
  edgePieces: number[]): ArrayBuffer {
  const cSize = 576;   // 24^2
  const eSize = 13824; // 24^3
  let cGoal = 0;
  for (let i = 0; i < cornerPieces.length; i++) {
    cGoal = cGoal * 24 + cornerPieces[i] * 3;
  }
  let eGoal = 0;
  for (let i = 0; i < edgePieces.length; i++) {
    eGoal = eGoal * 24 + edgePieces[i] * 2;
  }
  const total = cSize * eSize;
  const tab = new Int8Array(total).fill(-1);
  tab[cGoal * eSize + eGoal] = 0;
  let d = 0;
  let changed = true;
  while (changed) {
    changed = false;
    for (let st = 0; st < total; st++) {
      if (tab[st] === d) {
        const c = Math.floor(st / eSize);
        const e = st % eSize;
        for (let f = 0; f < 6; f++) {
          let cc = c;
          let ce = e;
          for (let t = 0; t < 3; t++) {
            // 2-corner base-24 fast path
            const chi = Math.floor(cc / 24);
            const clo = cc % 24;
            cc = cmFlat[chi * 6 + f] * 24 + cmFlat[clo * 6 + f];
            // 3-edge base-24 fast path
            const ea = Math.floor(ce / 576);
            const erem1 = ce % 576;
            const eb = Math.floor(erem1 / 24);
            const ec = erem1 % 24;
            ce = emFlat[ea * 6 + f] * 576 + emFlat[eb * 6 + f] * 24 + emFlat[ec * 6 + f];
            const ns = cc * eSize + ce;
            if (tab[ns] < 0) {
              tab[ns] = d + 1;
              changed = true;
            }
          }
        }
      }
    }
    d++;
  }
  return tab.buffer;
}

const sbSeq: number[] = new Array<number>(18).fill(0);
function idaSB(fbC: number, fbE: number, sbC: number, sbE: number, d: number, lm: number): boolean {
  if (d === 0) {
    return FB.isSolved(fbC, fbE) && SB.isSolved(sbC, sbE);
  }
  const jd = sbJointState.dist![sbC * SB.eSize + sbE];
  let prun = FB.cP[fbC];
  if (FB.eP[fbE] > prun) {
    prun = FB.eP[fbE];
  }
  if (jd > prun) {
    prun = jd;
  }
  if (prun > d) {
    return false;
  }
  for (let i = 0; i < 6; i++) {
    if (i !== lm) {
      let a = fbC;
      let b = fbE;
      let c = sbC;
      let e = sbE;
      for (let j = 0; j < 3; j++) {
        a = FB.moveC(a, i);
        b = FB.moveE(b, i);
        // direct method refs: SB.moveC detached into a variable loses `this`
        // and crashes on first call (reading 'nC' of undefined)
        c = SB.moveC(c, i);
        e = SB.moveE(e, i);
        if (idaSB(a, b, c, e, d - 1, i)) {
          sbSeq[d] = i * 3 + j;
          return true;
        }
      }
    }
  }
  return false;
}

export async function solveSB(cc: CubieCube): Promise<number[] | null> {
  const f = FB.extract(cc);
  const s = SB.extract(cc);
  if (f != null && s != null && FB.isSolved(f.c, f.e) && SB.isSolved(s.c, s.e)) {
    return [];
  }
  if (f == null || s == null) {
    return null;
  }
  // joint table is built once (taskpool worker) and cached in sbJointState
  await ensureSbJointReady();
  for (let d = 0; d <= 15; d++) {
    await yieldToUi();
    if (idaSB(f.c, f.e, s.c, s.e, d, -1)) {
      const out: number[] = [];
      for (let i = d; i > 0; i--) {
        out.push(sbSeq[i]);
      }
      return out;
    }
  }
  return null;
}

// ============================================================================
// LSE solver (<M,U>)
// ============================================================================
const LSE_LOCAL: number[] = [0, 1, 2, 3, 5, 7]; // min2phase ids UR UF UL UB DF DB
const M_CYCLE: number[] = [4, 1, 3, 5];
const M_FLIP: number[] = [1, 3, 4, 5];
const U_CYCLE: number[] = [1, 0, 3, 2];

let lsePermMoveT: Uint16Array = new Uint16Array(0);
let lseOriMoveT: Uint8Array = new Uint8Array(0);
let lseDist: Int8Array | null = null;

function buildLseTables(): void {
  const pm: Uint16Array = new Uint16Array(720 * 6);
  const om: Uint8Array = new Uint8Array(64 * 6);
  for (let p = 0; p < 720; p++) {
    const perm: number[] = new Array<number>(6).fill(0);
    SolverUtils.idxToPerm(perm, p, 6, false);
    for (let mv = 0; mv < 6; mv++) {
      const m = Math.floor(mv / 3);
      const j = mv % 3;
      const arr: number[] = perm.slice();
      const cyc: number[] = m === 0 ? M_CYCLE : U_CYCLE;
      for (let t = 0; t <= j; t++) {
        const tmp = arr[cyc[0]];
        arr[cyc[0]] = arr[cyc[1]];
        arr[cyc[1]] = arr[cyc[2]];
        arr[cyc[2]] = arr[cyc[3]];
        arr[cyc[3]] = tmp;
      }
      pm[p * 6 + mv] = SolverUtils.permToIdx(arr, 6, false);
    }
  }
  for (let o = 0; o < 64; o++) {
    const ori: number[] = new Array<number>(6).fill(0);
    for (let i = 0; i < 6; i++) {
      ori[i] = (o >> i) & 1;
    }
    for (let mv = 0; mv < 6; mv++) {
      const m = Math.floor(mv / 3);
      const j = mv % 3;
      const arr: number[] = ori.slice();
      const cyc: number[] = m === 0 ? M_CYCLE : U_CYCLE;
      for (let t = 0; t <= j; t++) {
        const tmp = arr[cyc[0]];
        arr[cyc[0]] = arr[cyc[1]];
        arr[cyc[1]] = arr[cyc[2]];
        arr[cyc[2]] = arr[cyc[3]];
        arr[cyc[3]] = tmp;
        if (m === 0) {
          for (let fi = 0; fi < M_FLIP.length; fi++) {
            arr[M_FLIP[fi]] ^= 1;
          }
        }
      }
      let no = 0;
      for (let i = 5; i >= 0; i--) {
        no = (no << 1) | (arr[i] & 1);
      }
      om[o * 6 + mv] = no;
    }
  }
  lsePermMoveT = pm;
  lseOriMoveT = om;
  const dist = new Int8Array(720 * 64 * 4).fill(-1);
  const queue: number[] = [0];
  dist[0] = 0;
  let head = 0;
  while (head < queue.length) {
    const st = queue[head++];
    const d = dist[st];
    const p = Math.floor(st / 256);
    const o = Math.floor(st / 4) % 64;
    const u = st % 4;
    for (let mv = 0; mv < 6; mv++) {
      const np = pm[p * 6 + mv];
      const no = om[o * 6 + mv];
      const nu = mv < 3 ? u : (u + mv - 2) % 4;
      const nst = np * 256 + no * 4 + nu;
      if (dist[nst] < 0) {
        dist[nst] = d + 1;
        queue.push(nst);
      }
    }
  }
  lseDist = dist;
}

export function solveLSE(cc: CubieCube): number[] | null {
  const perm: number[] = new Array<number>(6).fill(0);
  const ori: number[] = new Array<number>(6).fill(0);
  for (let li = 0; li < 6; li++) {
    const pos = LSE_LOCAL[li];
    const piece = cc.ep[pos];
    const lp = LSE_LOCAL.indexOf(piece);
    if (lp < 0) {
      return null;
    }
    perm[li] = lp;
    ori[li] = cc.eo[pos];
  }
  const p = SolverUtils.permToIdx(perm, 6, false);
  let o = 0;
  for (let i = 5; i >= 0; i--) {
    o = (o << 1) | (ori[i] & 1);
  }
  let st = p * 256 + o * 4 + 0;
  if (st === 0) {
    return [];
  }
  const dist = lseDist!;
  if (dist[st] < 0) {
    return null;
  }
  const out: number[] = [];
  while (st !== 0) {
    const d = dist[st];
    const p2 = Math.floor(st / 256);
    const o2 = Math.floor(st / 4) % 64;
    const u2 = st % 4;
    for (let mv = 0; mv < 6; mv++) {
      const np = lsePermMoveT[p2 * 6 + mv];
      const no = lseOriMoveT[o2 * 6 + mv];
      const nu = mv < 3 ? u2 : (u2 + mv - 2) % 4;
      const nst = np * 256 + no * 4 + nu;
      if (dist[nst] === d - 1) {
        // global encoding: M = face 6 (idx 18..20), U = face 0 (idx 0..2)
        out.push(mv < 3 ? 18 + mv : mv - 3);
        st = nst;
        break;
      }
    }
  }
  return out;
}

// ============================================================================
// rotations & scramble remapping
// ============================================================================
function composeRot(a: number[], b: number[]): number[] {
  const r: number[] = new Array<number>(6).fill(0);
  for (let i = 0; i < 6; i++) {
    r[i] = b[a[i]];
  }
  return r;
}

function posOfFaces(faces: number[], table: number[][]): number {
  for (let i = 0; i < table.length; i++) {
    const tf = table[i];
    let hit = true;
    for (let j = 0; j < faces.length; j++) {
      if (tf.indexOf(faces[j]) < 0) {
        hit = false;
        break;
      }
    }
    if (hit && tf.length === faces.length) {
      return i;
    }
  }
  return -1;
}

function cubeMul(a: CubieCube, b: CubieCube): CubieCube {
  const c = new CubieCube();
  CubieCube.CornMult(a, b, c);
  CubieCube.EdgeMult(a, b, c);
  return c;
}

interface RotNode {
  map: number[];
  seq: string[];
}

let rotations: number[][] = [];
let rotationsSeqs: string[][] = [];
let rotToUser: number[][] = [];
let rotToGrip: number[][] = [];

function buildRotations(): void {
  // 45 candidate move states
  const candToks: string[] = [];
  for (let f = 0; f < 15; f++) {
    for (let d = 0; d < 3; d++) {
      candToks.push(FACE_NAMES[f] + TOK_SUFFIX[d]);
    }
  }
  const cand: CubieCube[] = [];
  for (let i = 0; i < 45; i++) {
    const c = new CubieCube();
    applyToken(c, candToks[i]);
    cand.push(c);
  }
  const sameState = (a: CubieCube, b: CubieCube): boolean => {
    for (let i = 0; i < 8; i++) {
      if (a.cp[i] !== b.cp[i] || a.co[i] !== b.co[i]) {
        return false;
      }
    }
    for (let i = 0; i < 12; i++) {
      if (a.ep[i] !== b.ep[i] || a.eo[i] !== b.eo[i]) {
        return false;
      }
    }
    return true;
  };
  const matchMove = (st: CubieCube): number => {
    for (let i = 0; i < 45; i++) {
      if (sameState(cand[i], st)) {
        return i;
      }
    }
    return -1;
  };
  const seen: Record<string, number> = {};
  const idMap: number[] = [0, 1, 2, 3, 4, 5];
  seen[idMap.join(',')] = 0;
  const rots: number[][] = [idMap];
  const seqs: string[][] = [];
  seqs.push([]);
  const queue: RotNode[] = [{ map: idMap, seq: [] }];
  let head = 0;
  const gens: string[] = ['x', 'y', 'z'];
  const genMaps: Record<string, number[]> = { 'x': ROT_X, 'y': ROT_Y, 'z': ROT_Z };
  while (head < queue.length && rots.length < 24) {
    const item = queue[head++];
    for (let g = 0; g < gens.length; g++) {
      const nmap = composeRot(item.map, genMaps[gens[g]]);
      const key = nmap.join(',');
      if (seen[key] !== undefined) {
        continue;
      }
      seen[key] = rots.length;
      const nseq: string[] = [];
      for (let i = 0; i < item.seq.length; i++) {
        nseq.push(item.seq[i]);
      }
      nseq.push(gens[g]);
      rots.push(nmap);
      seqs.push(nseq);
      queue.push({ map: nmap, seq: nseq });
    }
  }
  // verify + build token maps
  const tu: number[][] = [];
  const tg: number[][] = [];
  for (let ri = 0; ri < rots.length; ri++) {
    const seq = seqs[ri];
    const Rf = new CubieCube();
    for (let i = 0; i < seq.length; i++) {
      applyToken(Rf, seq[i]);
    }
    const Rb = new CubieCube();
    for (let i = seq.length - 1; i >= 0; i--) {
      applyToken(Rb, seq[i] + "'");
    }
    const rot = rots[ri];
    let ok = true;
    for (let p = 0; p < 8 && ok; p++) {
      const faceMapped: number[] = [];
      const cf = CORNER_FACES[p];
      for (let j = 0; j < cf.length; j++) {
        faceMapped.push(rot[cf[j]]);
      }
      const np = posOfFaces(faceMapped, CORNER_FACES);
      if (np < 0 || Rf.cp[np] !== p) {
        ok = false;
      }
    }
    for (let p = 0; p < 12 && ok; p++) {
      const faceMapped: number[] = [];
      const ef = EDGE_FACES[p];
      for (let j = 0; j < ef.length; j++) {
        faceMapped.push(rot[ef[j]]);
      }
      const np = posOfFaces(faceMapped, EDGE_FACES);
      if (np < 0 || Rf.ep[np] !== p) {
        ok = false;
      }
    }
    const trow: number[] = new Array<number>(45).fill(-1);
    const grow: number[] = new Array<number>(45).fill(-1);
    for (let mi = 0; mi < 45; mi++) {
      const g = cand[mi];
      trow[mi] = matchMove(cubeMul(cubeMul(Rf, g), Rb));
      grow[mi] = matchMove(cubeMul(cubeMul(Rb, g), Rf));
    }
    tu.push(trow);
    tg.push(grow);
  }
  rotations = rots;
  rotationsSeqs = seqs;
  rotToUser = tu;
  rotToGrip = tg;
}

export function parseToken(tok: string): ParsedToken | null {
  const m = /^([URFDLBMESrlufdb])([2']?)$/.exec(tok);
  if (m == null) {
    return null;
  }
  let dir = 0;
  if (m[2] === '2') {
    dir = 1;
  } else if (m[2] === "'") {
    dir = 2;
  }
  return { face: TOKEN_FACE[m[1]], dir: dir };
}

// remap a scramble (face tokens) by a rotation face map: rot[f] = new face of f
export function rotateScramble(scramble: string, rot: number[]): string[] {
  const toks = scramble.trim().split(/\s+/);
  const out: string[] = [];
  for (let i = 0; i < toks.length; i++) {
    const t = toks[i];
    if (t.length === 0) {
      continue;
    }
    const p = parseToken(t);
    if (p == null) {
      continue;
    }
    out.push(FACE_NAMES[rot[p.face]] + TOK_SUFFIX[p.dir]);
  }
  return out;
}

// remap a scramble by a rotation index (convenience wrapper)
export function rotateScrambleByIdx(scramble: string, rotIdx: number): string[] {
  return rotateScramble(scramble, rotations[rotIdx]);
}

export function applyMoveIdx(cc: CubieCube, idx: number): void {
  const face = Math.floor(idx / 3);
  const dir = idx % 3;
  if (face < 6) {
    copyCube(cc, cc.move(MOVE_MAP[face] + dir));
  } else {
    applyToken(cc, FACE_NAMES[face] + TOK_SUFFIX[dir]);
  }
}

export function movesToStr(moves: number[]): string {
  let s = '';
  for (let i = 0; i < moves.length; i++) {
    const m = moves[i];
    const face = Math.floor(m / 3);
    const dir = m % 3;
    if (i > 0) {
      s += ' ';
    }
    s += FACE_NAMES[face] + TOK_SUFFIX[dir];
  }
  return s;
}

export function simplifyMoves(moves: number[]): number[] {
  const out: number[] = [];
  for (let i = 0; i < moves.length; i++) {
    const m = moves[i];
    const face = Math.floor(m / 3);
    const turns = (m % 3) + 1;
    const last = out.length ? out[out.length - 1] : -1;
    if (last >= 0 && Math.floor(last / 3) === face) {
      const total = (last % 3) + 1 + turns;
      out.pop();
      const t = total % 4;
      if (t === 1) {
        out.push(face * 3 + 0);
      } else if (t === 2) {
        out.push(face * 3 + 1);
      } else if (t === 3) {
        out.push(face * 3 + 2);
      }
    } else {
      out.push(m);
    }
  }
  return out;
}

export function findRotation(bottom: number, front: number): number {
  for (let i = 0; i < rotations.length; i++) {
    const r = rotations[i];
    if (r[bottom] === 1 && r[front] === 4) {
      return i;
    }
  }
  return -1;
}

export function findRotationRoux(bottom: number, left: number): number {
  for (let i = 0; i < rotations.length; i++) {
    const r = rotations[i];
    if (r[bottom] === 1 && r[left] === 2) {
      return i;
    }
  }
  return -1;
}

export function movesToUserFrame(moves: number[], rotIdx: number): number[] {
  const map = rotToUser[rotIdx];
  const out: number[] = new Array<number>(moves.length).fill(0);
  for (let i = 0; i < moves.length; i++) {
    out[i] = map[moves[i]];
  }
  return out;
}

// ============================================================================
// algorithm tables (OLL / PLL / CMLL)
// ============================================================================
export const OLL_ALGS: string[] = [
  "R U2 R2 F R F' U2 R' F R F'",
  "F R U R' U' S R U R' U' f'",
  "R' F2 R2 U2 R' F R U2 R2 F2 R",
  "R' F2 R2 U2 R' F' R U2 R2 F2 R",
  "l' U2 L U L' U l",
  "r U2 R' U' R U' r'",
  "r U R' U R U2 r'",
  "R U2 R' U2 R' F R F'",
  "R U R' U' R' F R2 U R' U' F'",
  "F U F' R' F R U' R' F' R",
  "r' R2 U R' U R U2 R' U M'",
  "l L2 U' L U' L' U2 L U' M'",
  "F U R U2 R' U' R U R' F'",
  "R' F R U R' F' R F U' F'",
  "l' U' l L' U' L U l' U l",
  "r U r' R U R' U' r U' r'",
  "F R' F' R U S' R U' R' S",
  "R U R2 F' U' F U R U2 R' F R F'",
  "S' R U R' S U' R' F R F'",
  "M U R U R' U' M2 U R U' r'",
  "R U R' U R U' R' U R U2 R'",
  "R U2 R2 U' R2 U' R2 U2 R",
  "R2 D R' U2 R D' R' U2 R'",
  "r U R' U' r' F R F'",
  "F' r U R' U' r' F R",
  "R U2 R' U' R U' R'",
  "R U R' U R U2 R'",
  "U2 M' U M U2 M' U M",
  "R U R' U' R U' R' F' U' F R U R'",
  "F U R U2 R' U' R U2 R' U' F'",
  "R' U' F U R U' R' F' R",
  "L U F' U' L' U L F L'",
  "R U R' U' R' F R F'",
  "R U R2 U' R' F R U R U' F'",
  "R U2 R2 F R F' R U2 R'",
  "R' F' U' F2 U R U' R' F' R",
  "F R' F' R U R U' R'",
  "R U R' U R U' R' U' R' F R F'",
  "L F' L' U' L U F U' L'",
  "R' F R U R' U' F' U R",
  "R U R' U R U2 R' F R U R' U' F'",
  "F R' F' R U2 R' U' R2 U' R2 U2 R",
  "R' U' F' U F R",
  "F U R U' R' F'",
  "F R U R' U' F'",
  "R' U' R' F R F' U R",
  "F' L' U' L U L' U' L U F",
  "F R U R' U' R U R' U' F'",
  "R B' R2 F R2 B R2 F' R",
  "R' F R2 B' R2 F' R2 B R'",
  "F U R U' R' U R U' R' F'",
  "R U R' U R U' B U' B' R'",
  "l' U' L U' L' U L U' L' U2 l",
  "r U R' U R U' R' U R U2 r'",
  "R' F U R U' R2 F' R2 U R' U' R",
  "r U r' U R U' R' M' U R U2 r'",
  "R U R' U' M' U R U' r'"
];

export const PLL_ALGS: string[] = [
  "R U' R U R U R U' R' U' R2",
  "R2 U R U R' U' R' U' R' U R'",
  "M2 U M2 U2 M2 U M2",
  "R' U' R U' R U R U' R' U R U R2 U' R'",
  "R' F R' B2 R F' R' B2 R2",
  "R B' R F2 R' B R F2 R2",
  "F R B R' F' R L F L' B' L F' R' L'",
  "R U R' U' R' F R2 U' R' U' R U R' F'",
  "L' U' L F L' U' L U L F' L2 U L",
  "R U R' F' R U R' U' R' F R2 U' R'",
  "R' U' F' R U R' U' R' F R2 U' R' U' R U R' U R",
  "R U R' F' R U2 R' U2 R' F R U R U2 R'",
  "R' U2 R U2 R' F R U R' U' R' F' R2",
  "R' U R' U' B' R' B2 U' B' U B' R B R",
  "F R U' R' U' R U R' F' R U R' U' R' F R F'",
  "R2 U R' U R' U' R U' R2 D U' R' U R D'",
  "R' U' R U D' R2 U R' U R U' R U' R2 D",
  "R2 U' R U' R U R' U R2 D' U R U' R' D",
  "R U R' U' D R2 U' R U' R' U R' U R2 D'",
  "R U R' U R U R' F' R U R' U' R' F R2 U' R' U2 R U' R'",
  "R' U R U' R' F' U' F R U R' F R' F' R U' R"
];

// CMLL permutation extras: conjugated Jb covers the (2 3) adjacent swap orbit
const CMLL_PER_EXTRAS: string[] = ["U2 R U R' F' R U R' U' R' F R2 U' R' U2"];

function algToMoves(alg: string): string[] {
  return alg.trim().split(/\s+/);
}

function invAlg(alg: string): string {
  const toks = algToMoves(alg);
  const out: string[] = [];
  for (let i = toks.length - 1; i >= 0; i--) {
    const t = toks[i];
    if (t.indexOf("'") >= 0) {
      out.push(t.slice(0, -1));
    } else if (t.indexOf('2') >= 0) {
      out.push(t);
    } else {
      out.push(t + "'");
    }
  }
  return out.join(' ');
}

function ollKeyOf(cc: CubieCube): string {
  let k = '';
  for (let i = 0; i < 4; i++) {
    k += cc.co[i];
  }
  k += '|';
  for (let i = 0; i < 4; i++) {
    k += cc.eo[i];
  }
  return k;
}

function pllKeyOf(cc: CubieCube): string {
  let k = '';
  for (let i = 0; i < 4; i++) {
    k += cc.cp[i] + ',';
  }
  k += '|';
  for (let i = 0; i < 4; i++) {
    k += cc.ep[i] + ',';
  }
  return k;
}

function cmllKeyOf(cc: CubieCube): string {
  let k = '';
  for (let i = 0; i < 4; i++) {
    k += cc.cp[i] + ',';
  }
  k += '|';
  for (let i = 0; i < 4; i++) {
    k += cc.co[i];
  }
  return k;
}

function oriKeyOf(cc: CubieCube): string {
  let k = '';
  for (let i = 0; i < 4; i++) {
    k += cc.co[i];
  }
  return k;
}

function cpKeyOf(cc: CubieCube): string {
  let k = '';
  for (let i = 0; i < 4; i++) {
    k += cc.cp[i] + ',';
  }
  return k;
}

function coOrbitKey(coArr: number[]): string {
  const full: number[] = coArr.concat([0, 0, 0, 0]);
  const cc = new CubieCube([0, 1, 2, 3, 4, 5, 6, 7], full,
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], new Array<number>(12).fill(0));
  const variants: string[] = [];
  for (let k = 0; k < 4; k++) {
    if (k > 0) {
      applyToken(cc, 'U');
    }
    variants.push(oriKeyOf(cc));
  }
  variants.sort();
  return variants[0];
}

function cpOrbitKey(cpArr: number[]): string {
  const full: number[] = cpArr.concat([4, 5, 6, 7]);
  const cc = new CubieCube(full, [0, 0, 0, 0, 0, 0, 0, 0],
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], new Array<number>(12).fill(0));
  const variants: string[] = [];
  for (let k = 0; k < 4; k++) {
    if (k > 0) {
      applyToken(cc, 'U');
    }
    variants.push(cpKeyOf(cc));
  }
  variants.sort();
  return variants[0];
}

function scrambleToCube(alg: string): CubieCube {
  const cc = new CubieCube();
  const toks = alg.trim().split(/\s+/);
  for (let i = 0; i < toks.length; i++) {
    if (toks[i].length > 0) {
      applyToken(cc, toks[i]);
    }
  }
  return cc;
}

function buildTable(algs: string[], type: number): Record<string, AlgHit> {
  const table: Record<string, AlgHit> = {};
  for (let a = 0; a < algs.length; a++) {
    const alg = algs[a];
    const state = scrambleToCube(invAlg(alg));
    const seen: string[] = [];
    for (let k = 0; k < 4; k++) {
      if (k > 0) {
        applyToken(state, 'U');
      }
      let key = '';
      if (type === 0) {
        key = ollKeyOf(state);
      } else {
        key = pllKeyOf(state);
      }
      if (seen.indexOf(key) >= 0) {
        continue;
      }
      seen.push(key);
      table[key] = { alg: alg, auf: k };
    }
  }
  const solved = new CubieCube();
  const skey = type === 0 ? ollKeyOf(solved) : pllKeyOf(solved);
  table[skey] = { alg: '', auf: 0 };
  return table;
}

function buildPllTable(algs: string[]): Record<string, PllHit> {
  const table: Record<string, PllHit> = {};
  for (let a = 0; a < algs.length; a++) {
    const alg = algs[a];
    const inv = invAlg(alg);
    for (let post = 0; post < 4; post++) {
      const base = new CubieCube();
      for (let t = 0; t < post; t++) {
        applyToken(base, "U'");
      }
      const itoks = algToMoves(inv);
      for (let i = 0; i < itoks.length; i++) {
        applyToken(base, itoks[i]);
      }
      for (let pre = 0; pre < 4; pre++) {
        const st = new CubieCube();
        copyCube(st, base);
        for (let t = 0; t < pre; t++) {
          applyToken(st, "U'");
        }
        table[pllKeyOf(st)] = { alg: alg, pre: pre, post: post };
      }
    }
  }
  for (let j = 0; j < 4; j++) {
    const st = new CubieCube();
    for (let t = 0; t < j; t++) {
      applyToken(st, 'U');
    }
    table[pllKeyOf(st)] = { alg: '', pre: (4 - j) % 4, post: 0 };
  }
  return table;
}

// returns moves (solver-frame indices) to solve, or null
export function lookupOll(cc: CubieCube): number[] | null {
  const t = getTables().oll;
  const state = new CubieCube();
  copyCube(state, cc);
  for (let ks = 0; ks < 4; ks++) {
    if (ks > 0) {
      applyToken(state, 'U');
    }
    const key = ollKeyOf(state);
    const hit: AlgHit | undefined = t[key];
    if (hit !== undefined) {
      const kSolve = (ks - hit.auf + 4) % 4;
      const moves: number[] = [];
      if (kSolve > 0) {
        moves.push(kSolve - 1);
      }
      const toks = algToMoves(hit.alg);
      for (let i = 0; i < toks.length; i++) {
        const p = parseToken(toks[i]);
        if (p != null) {
          moves.push(p.face * 3 + p.dir);
        }
      }
      return moves;
    }
  }
  return null;
}

export function lookupPll(cc: CubieCube): number[] | null {
  const t = getTables().pll;
  const hit: PllHit | undefined = t[pllKeyOf(cc)];
  if (hit === undefined) {
    return null;
  }
  const moves: number[] = [];
  if (hit.pre > 0) {
    moves.push(hit.pre - 1);
  }
  const toks = algToMoves(hit.alg);
  for (let i = 0; i < toks.length; i++) {
    const p = parseToken(toks[i]);
    if (p != null) {
      moves.push(p.face * 3 + p.dir);
    }
  }
  if (hit.post > 0) {
    moves.push(hit.post - 1);
  }
  return moves;
}

// CMLL orientation lookup (key = co pattern)
export function lookupCmllOri(cc: CubieCube): number[] | null {
  const t = getTables().cmllOri;
  const state = new CubieCube();
  copyCube(state, cc);
  for (let ks = 0; ks < 4; ks++) {
    if (ks > 0) {
      applyToken(state, 'U');
    }
    const key = oriKeyOf(state);
    const hit: AlgHit | undefined = t[key];
    if (hit !== undefined) {
      const kSolve = (ks - hit.auf + 4) % 4;
      const moves: number[] = [];
      if (kSolve > 0) {
        moves.push(kSolve - 1);
      }
      const toks = algToMoves(hit.alg);
      for (let i = 0; i < toks.length; i++) {
        const p = parseToken(toks[i]);
        if (p != null) {
          moves.push(p.face * 3 + p.dir);
        }
      }
      return moves;
    }
  }
  return null;
}

export function lookupCmllPer(cc: CubieCube): number[] | null {
  const t = getTables().cmllPer;
  const state = new CubieCube();
  copyCube(state, cc);
  for (let ks = 0; ks < 4; ks++) {
    if (ks > 0) {
      applyToken(state, 'U');
    }
    const key = cpKeyOf(state);
    const hit: AlgHit | undefined = t[key];
    if (hit !== undefined) {
      const kSolve = (ks - hit.auf + 4) % 4;
      const moves: number[] = [];
      if (kSolve > 0) {
        moves.push(kSolve - 1);
      }
      const toks = algToMoves(hit.alg);
      for (let i = 0; i < toks.length; i++) {
        const p = parseToken(toks[i]);
        if (p != null) {
          moves.push(p.face * 3 + p.dir);
        }
      }
      return moves;
    }
  }
  return null;
}

// ============================================================================
// tables + lazy init
// ============================================================================
interface OriEntry {
  alg: string;
  len: number;
}

let coreReady = false;
let tables: Tables | null = null;

export function getTables(): Tables {
  ensureCore();
  return tables!;
}

function ensureCore(): void {
  if (coreReady) {
    return;
  }
  // 磁盘缓存命中：数值表全部恢复，只剩 OLL/PLL/CMLL 查找表需要现建
  if (tryLoadCoreCache()) {
    if (tables == null) {
      initTables();
    }
    coreReady = true;
    return;
  }
  coreReady = true;
  if (cornerMoveT.length === 0) {
    buildPieceTables();
  }
  if (crossEpdT.length === 0) {
    buildCrossTables();
  }
  if (pairPrunT.length === 0) {
    buildPairPrun();
  }
  if (pairJointT.length === 0) {
    buildPairJointSync();
  }
  if (lseDist == null) {
    buildLseTables();
  }
  if (rotations.length === 0) {
    buildRotations();
  }
  if (tables == null) {
    initTables();
  }
  saveCoreCache();
}

// 异步分段构建：每个重型表之间主动让出主线程，避免"首次 CFOP 求解在某一个
// handler 里同步把全部剪枝/OLL/PLL 表构建完"，在慢速设备上触发 THREAD_BLOCK
// 看门狗闪退。各阶段以"表是否已构建"幂等，重复调用安全。
let corePromise: Promise<void> | null = null;

export async function ensureReadyAsync(): Promise<void> {
  if (coreReady) {
    return;
  }
  if (corePromise != null) {
    return corePromise;
  }
  const p: Promise<void> = buildCoreAsync();
  corePromise = p;
  p.then((): void => {
    corePromise = null;
  }, (): void => {
    corePromise = null;
  });
  return p;
}

async function buildCoreAsync(): Promise<void> {
  if (coreReady) {
    return;
  }
  // 磁盘缓存命中：数值表全部恢复，只剩 OLL/PLL/CMLL 查找表需要现建
  if (tryLoadCoreCache()) {
    if (tables == null) {
      initTables();
    }
    coreReady = true;
    return;
  }
  if (cornerMoveT.length === 0) {
    buildPieceTables();
  }
  await yieldToUi();
  if (crossEpdT.length === 0) {
    buildCrossTables();
  }
  await yieldToUi();
  if (pairPrunT.length === 0) {
    buildPairPrun();
  }
  if (pairJointT.length === 0) {
    await buildPairJointAsync();
  }
  if (lseDist == null) {
    buildLseTables();
  }
  await yieldToUi();
  if (rotations.length === 0) {
    buildRotations();
  }
  await yieldToUi();
  if (tables == null) {
    initTables();
  }
  coreReady = true;
  saveCoreCache();
}

// public kick-off: builds all pruning/lookup tables on first call
export function ensureReady(): void {
  ensureCore();
}

function initTables(): void {
  const oll = buildTable(OLL_ALGS, 0);
  const pll = buildPllTable(PLL_ALGS);
  // CMLL orientation: shortest OLL per orientation orbit
  const oriByOrbit: Record<string, OriEntry> = {};
  for (let a = 0; a < OLL_ALGS.length; a++) {
    const alg = OLL_ALGS[a];
    const cc = scrambleToCube(invAlg(alg));
    const coArr: number[] = [];
    for (let i = 0; i < 4; i++) {
      coArr.push(cc.co[i]);
    }
    const orbit = coOrbitKey(coArr);
    const len = algToMoves(alg).length;
    const cur: OriEntry | undefined = oriByOrbit[orbit];
    if (cur === undefined || len < cur.len) {
      oriByOrbit[orbit] = { alg: alg, len: len };
    }
  }
  const cmllOri: Record<string, AlgHit> = {};
  const oriKeys: string[] = Object.keys(oriByOrbit);
  for (let i = 0; i < oriKeys.length; i++) {
    const orbit = oriKeys[i];
    const alg = oriByOrbit[orbit].alg;
    const state = scrambleToCube(invAlg(alg));
    const seen: string[] = [];
    for (let k = 0; k < 4; k++) {
      if (k > 0) {
        applyToken(state, 'U');
      }
      const key = oriKeyOf(state);
      if (seen.indexOf(key) >= 0) {
        continue;
      }
      seen.push(key);
      cmllOri[key] = { alg: alg, auf: k };
    }
  }
  cmllOri['0000'] = { alg: '', auf: 0 };
  // CMLL permutation: shortest PLL (+extras) per cp orbit
  const perByOrbit: Record<string, OriEntry> = {};
  for (let a = 0; a < PLL_ALGS.length; a++) {
    const alg = PLL_ALGS[a];
    const cc = scrambleToCube(invAlg(alg));
    const cpArr: number[] = [];
    for (let i = 0; i < 4; i++) {
      cpArr.push(cc.cp[i]);
    }
    const orbit = cpOrbitKey(cpArr);
    const len = algToMoves(alg).length;
    const cur: OriEntry | undefined = perByOrbit[orbit];
    if (cur === undefined || len < cur.len) {
      perByOrbit[orbit] = { alg: alg, len: len };
    }
  }
  for (let a = 0; a < CMLL_PER_EXTRAS.length; a++) {
    const alg = CMLL_PER_EXTRAS[a];
    const cc = scrambleToCube(invAlg(alg));
    const cpArr: number[] = [];
    for (let i = 0; i < 4; i++) {
      cpArr.push(cc.cp[i]);
    }
    const orbit = cpOrbitKey(cpArr);
    const len = algToMoves(alg).length;
    const cur: OriEntry | undefined = perByOrbit[orbit];
    if (cur === undefined || len < cur.len) {
      perByOrbit[orbit] = { alg: alg, len: len };
    }
  }
  const cmllPer: Record<string, AlgHit> = {};
  const perKeys: string[] = Object.keys(perByOrbit);
  for (let i = 0; i < perKeys.length; i++) {
    const orbit = perKeys[i];
    const alg = perByOrbit[orbit].alg;
    const state = scrambleToCube(invAlg(alg));
    const seen: string[] = [];
    for (let k = 0; k < 4; k++) {
      if (k > 0) {
        applyToken(state, 'U');
      }
      const key = cpKeyOf(state);
      if (seen.indexOf(key) >= 0) {
        continue;
      }
      seen.push(key);
      cmllPer[key] = { alg: alg, auf: k };
    }
  }
  // identity orbit: pure U^k corners solved by AUF alone
  {
    const st = new CubieCube();
    const seen: string[] = [];
    for (let k = 0; k < 4; k++) {
      if (k > 0) {
        applyToken(st, 'U');
      }
      const key = cpKeyOf(st);
      if (seen.indexOf(key) < 0) {
        seen.push(key);
        cmllPer[key] = { alg: '', auf: k };
      }
    }
  }
  tables = new Tables();
  tables.oll = oll;
  tables.pll = pll;
  tables.cmllOri = cmllOri;
  tables.cmllPer = cmllPer;
}

// helper: build a solver-frame cube from a remapped scramble token list
export function cubeFromTokens(tokens: string[]): CubieCube {
  const cc = new CubieCube();
  for (let i = 0; i < tokens.length; i++) {
    applyToken(cc, tokens[i]);
  }
  return cc;
}