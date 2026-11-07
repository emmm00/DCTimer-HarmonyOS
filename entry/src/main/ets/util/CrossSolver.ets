/**
 * 魔方十字求解器 (Cross Solver)
 *
 * 移植自 DCTimer-BLE app/src/main/java/solver/Cross.java
 * 使用 IDA* + 预计算剪枝表，追踪 4 个底面棱块的排列与朝向。
 */

const FACE_NAMES: string[] = ['U', 'D', 'L', 'R', 'F', 'B'];
const SUFFIXES: string[] = ['', '2', "'"];

// 面颜色名（与项目配色一致：U白 D黄 L橙 R红 F绿 B蓝）
const FACE_COLORS: string[] = ['白', '黄', '橙', '红', '绿', '蓝'];

// 每个底面对应的默认前面（朝自己的面），用于显示
// 索引 0=U 1=D 2=L 3=R 4=F 5=B
// U/D/L/R 底 -> 绿朝前； F/B 底 -> 黄朝前
const FRONT_FACE_FOR_BOTTOM: number[] = [4, 4, 4, 4, 1, 1];

// 棱块编号（与 DCTimer-BLE Cross.java 一致）
// 0=UF 1=UR 2=UB 3=UL 4=DF 5=DL 6=DB 7=DR 8=FR 9=FL 10=BL 11=BR

// 6 个面的转动循环（棱块位置）
// U, D, L, R, F, B
const EDGE_CYCLES: number[][] = [
  [0, 1, 2, 3],   // U
  [4, 7, 6, 5],   // D
  [2, 9, 6, 10],  // L
  [0, 11, 4, 8],  // R
  [1, 8, 5, 9],   // F
  [3, 10, 7, 11]  // B
];

// 哪些面转动会翻转棱块朝向：F/B
const FLIP_FACES: boolean[] = [false, false, false, false, true, true];

interface CrossSolution {
  title: string;
  solution: string;
}

interface StatePair {
  ep: number;
  eo: number;
}

// 组合数表 C(n,k)
class CrossTables {
  static readonly Cnk: number[][] = CrossTables.buildCnk();
  static readonly epm: number[][] = new Array(11880).fill(0).map((): number[] => new Array(6).fill(0));
  static readonly eom: number[][] = new Array(7920).fill(0).map((): number[] => new Array(6).fill(0));
  static readonly epd: number[] = new Array(11880).fill(-1);
  static readonly eod: number[] = new Array(7920).fill(-1);
  static initialized: boolean = false;

  private static buildCnk(): number[][] {
    const c: number[][] = new Array(25).fill(0).map((): number[] => new Array(25).fill(0));
    for (let i: number = 0; i < 25; i++) {
      c[i][0] = 1;
      c[i][i] = 1;
      for (let j: number = 1; j < i; j++) {
        c[i][j] = c[i - 1][j - 1] + c[i - 1][j];
      }
    }
    return c;
  }
}

function circle(arr: number[], a: number, b: number, c: number, d: number, ori: number): void {
  const t: number = arr[a];
  arr[a] = arr[d] ^ ori;
  arr[d] = arr[c] ^ ori;
  arr[c] = arr[b] ^ ori;
  arr[b] = t ^ ori;
}

function edgemv(arr: number[], m: number): void {
  const c: number[] = EDGE_CYCLES[m];
  circle(arr, c[0], c[1], c[2], c[3], FLIP_FACES[m] ? 1 : 0);
}

function idxToPerm(permutation: number[], index: number, length: number, even: boolean): void {
  let sum: number = 0;
  if (even) {
    permutation[length - 1] = 1;
    permutation[length - 2] = 0;
  } else {
    permutation[length - 1] = 0;
  }
  const start: number = even ? length - 3 : length - 2;
  for (let i: number = start; i >= 0; i--) {
    permutation[i] = index % (length - i);
    sum += permutation[i];
    index = Math.floor(index / (length - i));
    for (let j: number = i + 1; j < length; j++) {
      if (permutation[j] >= permutation[i]) {
        permutation[j]++;
      }
    }
  }
  if (even && sum % 2 !== 0) {
    const t: number = permutation[length - 1];
    permutation[length - 1] = permutation[length - 2];
    permutation[length - 2] = t;
  }
}

function permToIdx(permutation: number[], length: number, even: boolean): number {
  let index: number = 0;
  const end: number = even ? length - 2 : length - 1;
  for (let i: number = 0; i < end; i++) {
    index *= length - i;
    for (let j: number = i + 1; j < length; j++) {
      if (permutation[i] > permutation[j]) {
        index++;
      }
    }
  }
  return index;
}

function idxToComb(arr: number[], s: number[], c: number, o: number): void {
  let q: number = 4;
  for (let i: number = 0; i < 12; i++) {
    if (c >= CrossTables.Cnk[11 - i][q]) {
      c -= CrossTables.Cnk[11 - i][q--];
      arr[i] = (s[q] << 1) | (o & 1);
      o >>= 1;
    } else {
      arr[i] = -1;
    }
  }
}

function getmv(c: number, po: number, f: number): number {
  const arr: number[] = new Array(12).fill(0);
  const ps: number[] = new Array(4).fill(0);
  idxToPerm(ps, po, 4, false);
  idxToComb(arr, ps, c, po);
  edgemv(arr, f);
  c = 0;
  po = 0;
  let q: number = 4;
  for (let t: number = 0; t < 12; t++) {
    if (arr[t] >= 0) {
      c += CrossTables.Cnk[11 - t][q--];
      ps[q] = arr[t] >> 1;
      po |= (arr[t] & 1) << (3 - q);
    }
  }
  const i: number = permToIdx(ps, 4, false);
  return ((24 * c + i) << 4) | po;
}

function createPrun(prun: number[], depth: number, moveTable: number[][], times: number): void {
  const total: number = prun.length;
  let c: number = 1;
  for (let d: number = 0; d < depth; d++) {
    for (let i: number = 0; i < total; i++) {
      if (prun[i] === d) {
        for (let j: number = 0; j < 6; j++) {
          let next: number = i;
          for (let k: number = 0; k < times; k++) {
            next = moveTable[next][j];
            if (prun[next] < 0) {
              prun[next] = d + 1;
              c++;
            }
          }
        }
      }
    }
  }
}

function init(): void {
  if (CrossTables.initialized) {
    return;
  }

  for (let a: number = 0; a < 495; a++) {
    for (let b: number = 0; b < 24; b++) {
      for (let c: number = 0; c < 6; c++) {
        const d: number = getmv(a, b, c);
        CrossTables.epm[24 * a + b][c] = d >> 4;
        if (b < 16) {
          CrossTables.eom[16 * a + b][c] = ((Math.floor(d / 384)) << 4) | (d & 15);
        }
      }
    }
  }

  CrossTables.epd[1670] = 0;
  createPrun(CrossTables.epd, 6, CrossTables.epm, 3);

  CrossTables.eod[69 * 16] = 0;
  createPrun(CrossTables.eod, 7, CrossTables.eom, 3);

  CrossTables.initialized = true;
}

function parseSingleMove(move: string): number {
  if (move.length === 0) {
    return -1;
  }
  const faceChar: string = move.charAt(0);
  let face: number = -1;
  switch (faceChar) {
    case 'U': face = 0; break;
    case 'D': face = 1; break;
    case 'L': face = 2; break;
    case 'R': face = 3; break;
    case 'F': face = 4; break;
    case 'B': face = 5; break;
    default: return -1;
  }
  let dir: number = 0; // 90°
  if (move.length > 1) {
    const suffix: string = move.charAt(1);
    if (suffix === '2') {
      dir = 1;
    } else if (suffix === "'") {
      dir = 2;
    } else if (suffix === '3') {
      dir = 2;
    }
  }
  return face * 3 + dir;
}

/** 整体旋转对应的面名称映射。
 *  选择某颜色为底面时，把 scramble 中的面名按此表映射，
 *  等价于先把魔方整体旋转使该面朝下，再在同一坐标系下求解。
 *  ROTATION_MAP[bottomFace][oldFace] = newFace */
const ROTATION_MAP: number[][] = [
  [1, 0, 3, 2, 4, 5], // U -> z2: U↔D, L↔R, F/B 不变
  [0, 1, 2, 3, 4, 5], // D -> 无旋转
  [2, 3, 1, 0, 4, 5], // L -> z': U->L, L->D, D->R, R->U, F/B 不变
  [3, 2, 0, 1, 4, 5], // R -> z : U->R, R->D, D->L, L->U, F/B 不变
  [4, 5, 2, 3, 1, 0], // F -> x : U->F, F->D, D->B, B->U, L/R 不变
  [5, 4, 2, 3, 0, 1]  // B -> x': U->B, B->D, D->F, F->U, L/R 不变
];

/** 将 scramble 中的每一步按选定底面做整体旋转映射 */
function rotateScramble(moves: string[], bottomFace: number): string[] {
  const map: number[] = ROTATION_MAP[bottomFace];
  const result: string[] = [];
  for (const move of moves) {
    if (move.length === 0) {
      continue;
    }
    const oldFace: number = parseSingleMove(move);
    if (oldFace < 0) {
      continue;
    }
    const newFaceIdx: number = map[Math.floor(oldFace / 3)];
    const dir: number = oldFace % 3;
    result.push(FACE_NAMES[newFaceIdx] + SUFFIXES[dir]);
  }
  return result;
}

function parseMove(move: string): number {
  return parseSingleMove(move);
}

function moveToString(moveIdx: number): string {
  const face: number = Math.floor(moveIdx / 3);
  const dir: number = moveIdx % 3;
  return FACE_NAMES[face] + SUFFIXES[dir];
}

let solutionSeq: number[] = new Array(20).fill(0);

function idacross(ep: number, eo: number, d: number, lm: number): boolean {
  if (d === 0) {
    return ep === 1670 && eo === 1104;
  }
  if (CrossTables.epd[ep] > d || CrossTables.eod[eo] > d) {
    return false;
  }
  for (let i: number = 0; i < 6; i++) {
    if (i !== lm) {
      let epx: number = ep;
      let eox: number = eo;
      for (let j: number = 0; j < 3; j++) {
        epx = CrossTables.epm[epx][i];
        eox = CrossTables.eom[eox][i];
        if (idacross(epx, eox, d - 1, i)) {
          solutionSeq[d] = i * 3 + j;
          return true;
        }
      }
    }
  }
  return false;
}

function applyMoveToState(ep: number, eo: number, m: number): StatePair {
  const face: number = Math.floor(m / 3);
  eo = CrossTables.eom[eo][face];
  ep = CrossTables.epm[ep][face];
  if (m % 3 !== 0) {
    eo = CrossTables.eom[eo][face];
    ep = CrossTables.epm[ep][face];
    if (m % 3 === 2) {
      eo = CrossTables.eom[eo][face];
      ep = CrossTables.epm[ep][face];
    }
  }
  const pair: StatePair = { ep, eo };
  return pair;
}

/**
 * 求解指定颜色底面的十字。
 * @param scramble 打乱公式，如 "R U R' U' ..."
 * @param bottomFace 底面索引：0=U(白), 1=D(黄), 2=L(橙), 3=R(红), 4=F(绿), 5=B(蓝)
 * @returns 求解步骤字符串，未找到返回 null
 */
export function solveCross(scramble: string, bottomFace: number = 1): CrossSolution | null {
  init();

  const moves: string[] = scramble.trim().split(/\s+/).filter((m: string): boolean => m.length > 0);
  if (moves.length === 0) {
    const emptyResult: CrossSolution = { title: buildTitle(bottomFace), solution: '（无需求解）' };
    return emptyResult;
  }

  // 将 scramble 按所选底面做整体旋转映射，使该颜色位于 D 面坐标系下
  const rotatedMoves: string[] = rotateScramble(moves, bottomFace);

  // 十字已解状态：4 个底面棱位于 D 层，排列秩为 14（ep = 24*69 + 14 = 1670）
  let ep: number = 1670;
  let eo: number = 1104;

  // 应用映射后的打乱
  for (const move of rotatedMoves) {
    const m: number = parseMove(move);
    if (m < 0) {
      continue;
    }
    const state: StatePair = applyMoveToState(ep, eo, m);
    ep = state.ep;
    eo = state.eo;
  }

  if (ep === 1670 && eo === 1104) {
    const solvedResult: CrossSolution = { title: buildTitle(bottomFace), solution: '（十字已完成，无需求解）' };
    return solvedResult;
  }

  for (let d: number = 0; d < 9; d++) {
    if (idacross(ep, eo, d, -1)) {
      const result: string[] = [];
      for (let i: number = d; i > 0; i--) {
        result.push(moveToString(solutionSeq[i]));
      }
      const solutionResult: CrossSolution = { title: buildTitle(bottomFace), solution: result.join(' ') };
      return solutionResult;
    }
  }

  const notFoundResult: CrossSolution = { title: buildTitle(bottomFace), solution: '未找到解 (超过 9 步)' };
  return notFoundResult;
}

function buildTitle(bottomFace: number): string {
  const bottomColor: string = FACE_COLORS[bottomFace];
  const frontFace: number = FRONT_FACE_FOR_BOTTOM[bottomFace];
  const frontColor: string = FACE_COLORS[frontFace];
  return `${bottomColor}底（${frontColor}朝前）`;
}

export const CROSS_FACE_OPTIONS: string[] = ['白底', '黄底', '橙底', '红底', '绿底', '蓝底'];
export const CROSS_FACE_VALUES: number[] = [0, 1, 2, 3, 4, 5];
