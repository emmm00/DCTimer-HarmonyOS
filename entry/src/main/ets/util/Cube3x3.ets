/**
 * 3x3 魔方状态模拟器
 * 用于训练模块根据 setup 公式生成 OLL/PLL/F2L 配图
 */

export const FACE_COLORS: string[] = [
  '#FFFFFF', // U 白
  '#FFFF00', // D 黄
  '#FF8C00', // L 橙
  '#FF0000', // R 红
  '#00BB00', // F 绿
  '#0000FF'  // B 蓝
];

const FACE_NAMES: string = 'UDLRFB';

/** 求一段公式的逆（用于从标准解法生成 setup） */
export function invertAlgorithm(alg: string): string {
  const tokens: string[] = alg.trim().split(/\s+/).filter((t: string): boolean => t.length > 0);
  const reversed: string[] = [];
  for (let i: number = tokens.length - 1; i >= 0; i--) {
    const t: string = tokens[i];
    if (t.length === 1) {
      reversed.push(t + "'");
    } else if (t.charAt(1) === "'") {
      reversed.push(t.charAt(0));
    } else if (t.charAt(1) === '2') {
      reversed.push(t);
    } else {
      reversed.push(t);
    }
  }
  return reversed.join(' ');
}

/** 单面 3x3 贴纸数组 */
export class FaceState {
  stickers: number[][] = [[0, 0, 0], [0, 0, 0], [0, 0, 0]];

  constructor(color: number = 0) {
    for (let r: number = 0; r < 3; r++) {
      for (let c: number = 0; c < 3; c++) {
        this.stickers[r][c] = color;
      }
    }
  }

  clone(): FaceState {
    const fs: FaceState = new FaceState();
    for (let r: number = 0; r < 3; r++) {
      for (let c: number = 0; c < 3; c++) {
        fs.stickers[r][c] = this.stickers[r][c];
      }
    }
    return fs;
  }
}

export class Cube3x3 {
  faces: FaceState[] = [];

  constructor() {
    this.reset();
  }

  reset(): void {
    this.faces = [];
    for (let i: number = 0; i < 6; i++) {
      this.faces.push(new FaceState(i));
    }
  }

  /** 复制当前魔方 */
  clone(): Cube3x3 {
    const cube: Cube3x3 = new Cube3x3();
    cube.faces = [];
    for (const f of this.faces) {
      cube.faces.push(f.clone());
    }
    return cube;
  }

  /** 旋转一个面自身（顺时针/逆时针/180） */
  private rotateFace(faceIdx: number, turns: number): void {
    const f: FaceState = this.faces[faceIdx];
    const old: number[][] = f.stickers;
    const n: number[][] = [[0, 0, 0], [0, 0, 0], [0, 0, 0]];
    if (turns === 1 || turns === -1) {
      // 顺时针
      for (let r: number = 0; r < 3; r++) {
        for (let c: number = 0; c < 3; c++) {
          n[c][2 - r] = old[r][c];
        }
      }
    } else if (turns === 2 || turns === -2) {
      // 180
      for (let r: number = 0; r < 3; r++) {
        for (let c: number = 0; c < 3; c++) {
          n[2 - r][2 - c] = old[r][c];
        }
      }
    }
    f.stickers = n;
  }

  /**
   * 单层转动。face: 0=U 1=D 2=L 3=R 4=F 5=B
   * dir: 1=顺时针 2=180 3=逆时针（从该面外侧看）
   */
  move(face: number, dir: number): void {
    if (dir === 0) {
      return;
    }
    const turns: number = dir === 2 ? 2 : (dir === 3 ? -1 : 1);
    this.rotateFace(face, turns);

    // 相邻面边条循环：每条边条用 (面, 坐标模式) 描述
    // 坐标模式：isRow=true 表示行 row[i][c]，isRow=false 表示列 col[i][r]
    interface StripDesc {
      faceIdx: number;
      isRow: boolean;
      line: number;
      reverse: boolean;
    }
    let strips: StripDesc[] = [];
    switch (face) {
      case 0: // U: F[0] -> R[0] -> B[0] -> L[0] -> F[0]
        strips = [
          { faceIdx: 4, isRow: true, line: 0, reverse: false }, // F top
          { faceIdx: 3, isRow: true, line: 0, reverse: false }, // R top
          { faceIdx: 5, isRow: true, line: 0, reverse: true },  // B top
          { faceIdx: 2, isRow: true, line: 0, reverse: false }  // L top
        ];
        break;
      case 1: // D: F[2] -> L[2] -> B[2] -> R[2] -> F[2]
        strips = [
          { faceIdx: 4, isRow: true, line: 2, reverse: false }, // F bottom
          { faceIdx: 2, isRow: true, line: 2, reverse: false }, // L bottom
          { faceIdx: 5, isRow: true, line: 2, reverse: true },  // B bottom
          { faceIdx: 3, isRow: true, line: 2, reverse: false }  // R bottom
        ];
        break;
      case 2: // L: U[0] -> F[0] -> D[0] -> B[2] -> U[0]
        strips = [
          { faceIdx: 0, isRow: false, line: 0, reverse: false }, // U left
          { faceIdx: 4, isRow: false, line: 0, reverse: false }, // F left
          { faceIdx: 1, isRow: false, line: 0, reverse: false }, // D left
          { faceIdx: 5, isRow: false, line: 2, reverse: true }   // B right
        ];
        break;
      case 3: // R: U -> F -> D -> B -> U
        strips = [
          { faceIdx: 0, isRow: false, line: 2, reverse: false }, // U right
          { faceIdx: 4, isRow: false, line: 2, reverse: false }, // F right
          { faceIdx: 1, isRow: false, line: 2, reverse: false }, // D right
          { faceIdx: 5, isRow: false, line: 0, reverse: true }   // B left
        ];
        break;
      case 4: // F: U[2] -> R[0] -> D[0] -> L[2] -> U[2]
        strips = [
          { faceIdx: 0, isRow: true, line: 2, reverse: false }, // U bottom
          { faceIdx: 3, isRow: false, line: 0, reverse: false }, // R left
          { faceIdx: 1, isRow: true, line: 0, reverse: true },  // D top
          { faceIdx: 2, isRow: false, line: 2, reverse: true }  // L right
        ];
        break;
      case 5: // B: U[0] -> L[0] -> D[2] -> R[2] -> U[0]
        strips = [
          { faceIdx: 0, isRow: true, line: 0, reverse: false }, // U top
          { faceIdx: 2, isRow: false, line: 0, reverse: true },  // L left
          { faceIdx: 1, isRow: true, line: 2, reverse: true },  // D bottom
          { faceIdx: 3, isRow: false, line: 2, reverse: true }  // R right
        ];
        break;
    }

    // 提取边条
    const stripValues: number[][] = [];
    for (const s of strips) {
      const strip: number[] = [0, 0, 0];
      for (let j: number = 0; j < 3; j++) {
        const idx: number = s.reverse ? 2 - j : j;
        if (s.isRow) {
          strip[j] = this.faces[s.faceIdx].stickers[s.line][idx];
        } else {
          strip[j] = this.faces[s.faceIdx].stickers[idx][s.line];
        }
      }
      stripValues.push(strip);
    }

    // 转动方向：顺时针时， strips[0] -> strips[1] -> strips[2] -> strips[3] -> strips[0]
    const shift: number = turns === 1 ? 1 : (turns === -1 ? -1 : 2);
    for (let i: number = 0; i < 4; i++) {
      const target: number = i;
      const src: number = ((i - shift) % 4 + 4) % 4;
      const s: StripDesc = strips[target];
      for (let j: number = 0; j < 3; j++) {
        const idx: number = s.reverse ? 2 - j : j;
        if (s.isRow) {
          this.faces[s.faceIdx].stickers[s.line][idx] = stripValues[src][j];
        } else {
          this.faces[s.faceIdx].stickers[idx][s.line] = stripValues[src][j];
        }
      }
    }
  }

  /** 整体旋转 */
  rotate(axis: number, dir: number): void {
    // axis: 0=x 1=y 2=z
    // 整体旋转 = 对应外层 + 中层 + 对侧外层
    // 注意：M/E/S 的约定与 L/D/B 同向，因此整体旋转时中层用反方向
    const invDir: number = dir === 1 ? 3 : (dir === 3 ? 1 : dir);
    if (axis === 0) { // x = R + M' + L'
      this.move(3, dir); // R
      this.sliceMove(0, invDir); // M'
      this.move(2, invDir); // L'
    } else if (axis === 1) { // y = U + E' + D'
      this.move(0, dir); // U
      this.sliceMove(1, invDir); // E'
      this.move(1, invDir); // D'
    } else { // z = F + S + B'
      this.move(4, dir); // F
      this.sliceMove(2, dir); // S
      this.move(5, invDir); // B'
    }
  }

  /** 解析并执行一段公式 */
  applyAlgorithm(alg: string): void {
    const tokens: string[] = alg.trim().split(/\s+/).filter((t: string): boolean => t.length > 0);
    for (const token of tokens) {
      this.applyToken(token);
    }
  }

  private applyToken(token: string): void {
    if (token.length === 0) {
      return;
    }
    const first: string = token.charAt(0);
    let faceIdx: number = FACE_NAMES.indexOf(first);

    if (faceIdx >= 0) {
      // 大写单层转动
      const dir: number = this.parseDir(token);
      this.move(faceIdx, dir);
      return;
    }

    // 小写表示 wide（含中层）
    const upper: string = first.toUpperCase();
    faceIdx = FACE_NAMES.indexOf(upper);
    if (faceIdx >= 0) {
      const dir: number = this.parseDir(token);
      this.wideMove(faceIdx, dir);
      return;
    }

    // x/y/z 整体旋转
    const axis: number = 'xyz'.indexOf(first);
    if (axis >= 0) {
      const dir: number = this.parseDir(token);
      this.rotate(axis, dir);
      return;
    }

    // M/E/S 中层转动
    const sliceIdx: number = 'MES'.indexOf(first);
    if (sliceIdx >= 0) {
      const dir: number = this.parseDir(token);
      this.sliceMove(sliceIdx, dir);
    }
  }

  /** wide move：同时转动该面及相邻中层（两层） */
  private wideMove(face: number, dir: number): void {
    // r = R + M', l = L + M, f = F + S, b = B + S', u = U + E', d = D + E
    this.move(face, dir);
    // slice 索引：U/D->E(1), L/R->M(0), F/B->S(2)
    const sliceMap: number[] = [1, 1, 0, 0, 2, 2];
    const slice: number = sliceMap[face];
    let sliceDir: number = dir;
    if (face === 0 || face === 3 || face === 5) {
      // U, R, B 对应的 slice 方向与面外侧方向相反
      sliceDir = dir === 1 ? 3 : (dir === 3 ? 1 : dir);
    }
    this.sliceMove(slice, sliceDir);
  }

  /** M/E/S 中层转动。slice: 0=M(左右中层) 1=E(上下中层) 2=S(前后中层) */
  private sliceMove(slice: number, dir: number): void {
    // 等效于两次整体旋转 minus 两个外层：
    // M = x - R - L' ; E = y - U - D' ; S = z - F - B'
    // 这里用直接循环边条的方式实现，避免改变面朝向
    const turns: number = dir === 2 ? 2 : (dir === 3 ? -1 : 1);
    if (slice === 0) {
      this.cycleM(turns);
    } else if (slice === 1) {
      this.cycleE(turns);
    } else {
      this.cycleS(turns);
    }
  }

  private cycleM(turns: number): void {
    // M 影响 U[1] <- F[1] <- D[1] <- B[1] <- U[1]
    // B 面需要反向
    const cycle: number[] = [0, 4, 1, 5];
    this.cycleSlices(cycle, turns, [1, 1, 1, 1], [false, false, false, true]);
  }

  private cycleE(turns: number): void {
    // E 影响 F[1] <- L[1] <- B[1] <- R[1] <- F[1]
    // B 面需要反向
    const cycle: number[] = [4, 2, 5, 3];
    this.cycleSlices(cycle, turns, [1, 1, 1, 1], [false, false, true, false]);
  }

  private cycleS(turns: number): void {
    // S 影响 U[1] <- R[1] <- D[1] <- L[1] <- U[1]
    // D 和 L 面需要反向
    const cycle: number[] = [0, 3, 1, 2];
    this.cycleSlices(cycle, turns, [1, 1, 1, 1], [false, false, true, true]);
  }

  /** 通用中层边条循环 */
  private cycleSlices(faces: number[], turns: number, rows: number[], reverse: boolean[]): void {
    const strips: number[][] = [];
    for (let i: number = 0; i < 4; i++) {
      const fi: number = faces[i];
      const row: number = rows[i];
      const strip: number[] = [0, 0, 0];
      for (let j: number = 0; j < 3; j++) {
        const col: number = reverse[i] ? 2 - j : j;
        strip[j] = this.faces[fi].stickers[row][col];
      }
      strips.push(strip);
    }

    const shift: number = turns === 1 ? -1 : (turns === -1 ? 1 : 2);
    for (let i: number = 0; i < 4; i++) {
      const target: number = i;
      const src: number = ((i - shift) % 4 + 4) % 4;
      const fi: number = faces[target];
      const row: number = rows[target];
      for (let j: number = 0; j < 3; j++) {
        const col: number = reverse[target] ? 2 - j : j;
        this.faces[fi].stickers[row][col] = strips[src][j];
      }
    }
  }

  private parseDir(token: string): number {
    if (token.length === 1) {
      return 1;
    }
    const suffix: string = token.charAt(1);
    if (suffix === "'") {
      return 3;
    }
    if (suffix === '2') {
      return 2;
    }
    return 1;
  }

  /** 获取某个面的 3x3 颜色数组 */
  getFace(faceIdx: number): number[][] {
    return this.faces[faceIdx].stickers;
  }
}
