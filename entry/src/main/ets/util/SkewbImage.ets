/**
 * SkewbImage - 斜转打乱状态图
 * 使用 6 面展开网图（十字形），每面 5 个贴纸（4 角三角 + 1 中心方块）。
 *
 * 4 个标准转动（U, L, R, B）为绕对角棱的 120° 旋转：
 *   U: 轴 UFR-DBL，(x,y,z)→(y,z,x)
 *   L: 轴 UFL-DBR，(x,y,z)→(-z,-x,y)
 *   R: 轴 UBR-DFL，(x,y,z)→(-z,x,-y)
 *   B: 轴 UBL-DFR，(x,y,z)→(-y,-z,x)
 *
 * 30 个贴纸索引 = 6 面 × 5 贴纸：
 *   面 U(0): 0=TL(UBL) 1=TR(UBR) 2=CTR 3=BL(UFL) 4=BR(UFR)
 *   面 D(1): 5=TL(DFL) 6=TR(DFR) 7=CTR 8=BL(DBL) 9=BR(DBR)
 *   面 F(2): 10=TL(UFL) 11=TR(UFR) 12=CTR 13=BL(DFL) 14=BR(DFR)
 *   面 B(3): 15=TL(UBR) 16=TR(UBL) 17=CTR 18=BL(DBR) 19=BR(DBL)
 *   面 L(4): 20=TL(UBL) 21=TR(UFL) 22=CTR 23=BL(DBL) 24=BR(DFL)
 *   面 R(5): 25=TL(UFR) 26=TR(UBR) 27=CTR 28=BL(DFR) 29=BR(DBR)
 *
 * 输出 30 个颜色索引（0=U 1=D 2=F 3=B 4=L 5=R）。
 */
export class SkewbImage {
  static readonly COLORS: string[] = [
    '#FFFF00', // 0 U 黄
    '#FFFFFF', // 1 D 白
    '#00CC00', // 2 F 绿
    '#0000FF', // 3 B 蓝
    '#FF0000', // 4 L 红
    '#FF8800'  // 5 R 橙
  ];

  // 8 角块坐标 (x=右, y=上, z=前)
  private static readonly CORNER_COORD: number[][] = [
    [1, 1, 1],   // 0 UFR
    [-1, 1, 1],  // 1 UFL
    [-1, 1, -1], // 2 UBL
    [1, 1, -1],  // 3 UBR
    [1, -1, 1],  // 4 DFR
    [-1, -1, 1], // 5 DFL
    [-1, -1, -1],// 6 DBL
    [1, -1, -1]  // 7 DBR
  ];

  // 6 面法向量
  private static readonly FACE_NORMAL: number[][] = [
    [0, 1, 0],  // 0 U
    [0, -1, 0], // 1 D
    [0, 0, 1],  // 2 F
    [0, 0, -1], // 3 B
    [-1, 0, 0], // 4 L
    [1, 0, 0]   // 5 R
  ];

  // 每个贴纸的 (角块索引, 面索引)；中心为 (-1, 面索引)
  private static readonly STICKER_INFO: number[][] = SkewbImage.buildStickerInfo();

  // 4 个转动的排列（new[i] = old[perm[i]]），惰性计算
  private static permU: number[] | null = null;
  private static permL: number[] | null = null;
  private static permR: number[] | null = null;
  private static permB: number[] | null = null;

  private static buildStickerInfo(): number[][] {
    // 面 U(0): TL=UBL(2) TR=UBR(3) CTR BL=UFL(1) BR=UFR(0)
    // 面 D(1): TL=DFL(5) TR=DFR(4) CTR BL=DBL(6) BR=DBR(7)
    // 面 F(2): TL=UFL(1) TR=UFR(0) CTR BL=DFL(5) BR=DFR(4)
    // 面 B(3): TL=UBR(3) TR=UBL(2) CTR BL=DBR(7) BR=DBL(6)
    // 面 L(4): TL=UBL(2) TR=UFL(1) CTR BL=DBL(6) BR=DFL(5)
    // 面 R(5): TL=UFR(0) TR=UBR(3) CTR BL=DFR(4) BR=DBR(7)
    const cornerOrder: number[][] = [
      [2, 3, -1, 1, 0], // U
      [5, 4, -1, 6, 7], // D
      [1, 0, -1, 5, 4], // F
      [3, 2, -1, 7, 6], // B
      [2, 1, -1, 6, 5], // L
      [0, 3, -1, 4, 7]  // R
    ];
    const result: number[][] = [];
    for (let face: number = 0; face < 6; face++) {
      for (let pos: number = 0; pos < 5; pos++) {
        result.push([cornerOrder[face][pos], face]);
      }
    }
    return result;
  }

  // 4 个旋转函数
  private static rotU(p: number[]): number[] { return [p[1], p[2], p[0]]; }
  private static rotL(p: number[]): number[] { return [-p[2], -p[0], p[1]]; }
  private static rotR(p: number[]): number[] { return [-p[2], p[0], -p[1]]; }
  private static rotB(p: number[]): number[] { return [-p[1], -p[2], p[0]]; }

  /** 计算某旋转的 30 贴纸排列 */
  private static computePerm(rot: (p: number[]) => number[]): number[] {
    const perm: number[] = new Array(30).fill(0);
    for (let dest: number = 0; dest < 30; dest++) {
      const info: number[] = SkewbImage.STICKER_INFO[dest];
      const cornerIdx: number = info[0];
      const faceIdx: number = info[1];
      if (cornerIdx === -1) {
        // 中心贴纸：面法向量旋转后到新面
        const newNormal: number[] = rot(SkewbImage.FACE_NORMAL[faceIdx]);
        const newFace: number = SkewbImage.findFace(newNormal);
        perm[dest] = newFace * 5 + 2; // 新面的中心
      } else {
        // 角块贴纸：角块坐标旋转 + 面法向量旋转
        const newCoord: number[] = rot(SkewbImage.CORNER_COORD[cornerIdx]);
        const newCorner: number = SkewbImage.findCorner(newCoord);
        const newNormal: number[] = rot(SkewbImage.FACE_NORMAL[faceIdx]);
        const newFace: number = SkewbImage.findFace(newNormal);
        perm[dest] = SkewbImage.findSticker(newCorner, newFace);
      }
    }
    return perm;
  }

  private static findFace(normal: number[]): number {
    for (let i: number = 0; i < 6; i++) {
      if (SkewbImage.FACE_NORMAL[i][0] === normal[0] &&
        SkewbImage.FACE_NORMAL[i][1] === normal[1] &&
        SkewbImage.FACE_NORMAL[i][2] === normal[2]) {
        return i;
      }
    }
    return 0;
  }

  private static findCorner(coord: number[]): number {
    for (let i: number = 0; i < 8; i++) {
      if (SkewbImage.CORNER_COORD[i][0] === coord[0] &&
        SkewbImage.CORNER_COORD[i][1] === coord[1] &&
        SkewbImage.CORNER_COORD[i][2] === coord[2]) {
        return i;
      }
    }
    return 0;
  }

  private static findSticker(corner: number, face: number): number {
    for (let i: number = 0; i < 30; i++) {
      if (SkewbImage.STICKER_INFO[i][0] === corner && SkewbImage.STICKER_INFO[i][1] === face) {
        return i;
      }
    }
    return 0;
  }

  private static ensurePerms(): void {
    if (SkewbImage.permU === null) {
      SkewbImage.permU = SkewbImage.computePerm(SkewbImage.rotU);
    }
    if (SkewbImage.permL === null) {
      SkewbImage.permL = SkewbImage.computePerm(SkewbImage.rotL);
    }
    if (SkewbImage.permR === null) {
      SkewbImage.permR = SkewbImage.computePerm(SkewbImage.rotR);
    }
    if (SkewbImage.permB === null) {
      SkewbImage.permB = SkewbImage.computePerm(SkewbImage.rotB);
    }
  }

  /** 应用排列（正向） */
  private static applyPerm(state: number[], perm: number[]): number[] {
    const newState: number[] = new Array(30).fill(0);
    for (let i: number = 0; i < 30; i++) {
      newState[i] = state[perm[i]];
    }
    return newState;
  }

  /** 应用排列（逆向，用于 ' 后缀） */
  private static applyPermInverse(state: number[], perm: number[]): number[] {
    const newState: number[] = new Array(30).fill(0);
    for (let i: number = 0; i < 30; i++) {
      newState[perm[i]] = state[i];
    }
    return newState;
  }

  /**
   * 计算斜转打乱状态。
   * @returns number[30]：每贴纸的颜色索引。
   */
  static image(scramble: string): number[] {
    SkewbImage.ensurePerms();
    // 初始状态：每贴纸颜色 = 所在面
    let state: number[] = [];
    for (let face: number = 0; face < 6; face++) {
      for (let i: number = 0; i < 5; i++) {
        state.push(face);
      }
    }

    const tokens: string[] = scramble.split(/\s+/);
    for (let i: number = 0; i < tokens.length; i++) {
      const t: string = tokens[i];
      if (t.length === 0) continue;
      const c0: string = t.charAt(0);
      const inverse: boolean = t.length > 1 && t.charAt(1) === '\'';
      let perm: number[] | null = null;
      if (c0 === 'U') { perm = SkewbImage.permU; }
      else if (c0 === 'L') { perm = SkewbImage.permL; }
      else if (c0 === 'R') { perm = SkewbImage.permR; }
      else if (c0 === 'B') { perm = SkewbImage.permB; }
      if (perm === null) continue;
      if (inverse) {
        state = SkewbImage.applyPermInverse(state, perm);
      } else {
        state = SkewbImage.applyPerm(state, perm);
      }
    }
    return state;
  }

  static getColors(): string[] {
    return SkewbImage.COLORS;
  }

  /** 展开网图各面的网格位置 [face] = [col, row]（十字形：U上 F中 D下 L左 R右 B右） */
  static readonly NET_LAYOUT: number[][] = [
    [1, 0], // U
    [1, 2], // D
    [1, 1], // F
    [3, 1], // B
    [0, 1], // L
    [2, 1]  // R
  ];
}
