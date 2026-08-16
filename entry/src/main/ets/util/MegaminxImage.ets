/**
 * MegaminxImage - 五魔方打乱状态图
 * 12 个五边形面，每面 11 贴纸（1 中心 + 5 棱 + 5 角），共 132 贴纸。
 *
 * 面标号：0=U 1=F 2=R 3=BR 4=BL 5=L 6=DBR 7=DR 8=DFR 9=DFL 10=DBL 11=D
 *
 * 打乱公式格式："R++ D-- U R-- D++ U ..."（7 段，每段 5 对 R/D + U）
 *   U  = 上层转 1/5（面 1-5 循环 1 步）
 *   U' = 上层反转 1/5
 *   D++ = 绕 D 轴深层转 2/5（面 1-5 循环 2 步）
 *   D-- = 绕 D 轴反转 2/5（面 1-5 循环 3 步）
 *   R++ = 绕 DBR 轴深层转 2/5（面 {0,2,5,8,9} 循环 2 步）
 *   R-- = 绕 DBR 轴反转 2/5
 *
 * 输出 132 个颜色索引（0-11，对应 12 面色）。
 *   0-11: 12 面中心贴纸（固定，始终为面色）
 *   12-71: 30 棱 × 2 贴纸
 *   72-131: 20 角 × 3 贴纸
 */
export class MegaminxImage {
  static readonly COLORS: string[] = [
    '#FFFFFF', // 0 U 白
    '#00CC00', // 1 F 绿
    '#FF8800', // 2 R 橙
    '#0000FF', // 3 BR 蓝
    '#FFDD00', // 4 BL 黄
    '#FF0000', // 5 L 红
    '#996633', // 6 DBR 棕
    '#6633CC', // 7 DR 紫
    '#0099AA', // 8 DFR 青
    '#CC0099', // 9 DFL 粉
    '#336600', // 10 DBL 暗绿
    '#999999'  // 11 D 灰
  ];

  // 30 棱位置（面对面邻接对，已排序 faceA < faceB）
  private static readonly EDGES: number[][] = [
    [0, 1], [0, 2], [0, 3], [0, 4], [0, 5],      // 0-4 上环
    [1, 2], [2, 3], [3, 4], [4, 5], [1, 5],       // 5-9 上侧
    [1, 8], [1, 9], [2, 7], [2, 8], [3, 6],       // 10-14 中
    [3, 7], [4, 6], [4, 10], [5, 9], [5, 10],     // 15-19 中
    [6, 7], [7, 8], [8, 9], [9, 10], [6, 10],     // 20-24 下侧
    [11, 6], [11, 7], [11, 8], [11, 9], [11, 10]  // 25-29 下环
  ];

  // 20 角位置（三面交汇，已排序）
  private static readonly CORNERS: number[][] = [
    [0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 5], [0, 1, 5],     // 0-4 上
    [1, 2, 8], [2, 3, 7], [3, 4, 6], [4, 5, 10], [1, 5, 9],    // 5-9 中上
    [1, 8, 9], [2, 7, 8], [3, 6, 7], [4, 6, 10], [5, 9, 10],   // 10-14 中下
    [11, 6, 7], [11, 7, 8], [11, 8, 9], [11, 9, 10], [11, 6, 10] // 15-19 下
  ];

  // 每面的 5 棱索引和 5 角索引（顺时针排列）
  private static readonly FACE_EDGES: number[][] = MegaminxImage.buildFaceEdges();
  private static readonly FACE_CORNERS: number[][] = MegaminxImage.buildFaceCorners();

  // 4 种移动的面映射（cycleMap[oldFace] = newFace）
  private static permU: number[] | null = null;
  private static permDpp: number[] | null = null;
  private static permRpp: number[] | null = null;

  private static buildFaceEdges(): number[][] {
    // 每面的 5 条棱（按顺时针）
    const result: number[][] = [];
    const faceAdj: number[][] = [
      [1, 2, 3, 4, 5],       // 0 U
      [0, 2, 8, 9, 5],       // 1 F
      [0, 3, 7, 8, 1],       // 2 R
      [0, 4, 6, 7, 2],       // 3 BR
      [0, 5, 10, 6, 3],      // 4 BL
      [0, 1, 9, 10, 4],      // 5 L
      [11, 7, 3, 4, 10],     // 6 DBR
      [11, 8, 2, 3, 6],      // 7 DR
      [11, 9, 1, 2, 7],      // 8 DFR
      [11, 10, 5, 1, 8],     // 9 DFL
      [11, 6, 4, 5, 9],      // 10 DBL
      [6, 7, 8, 9, 10]       // 11 D
    ];
    for (let face: number = 0; face < 12; face++) {
      const edges: number[] = [];
      for (let i: number = 0; i < 5; i++) {
        const a: number = face;
        const b: number = faceAdj[face][i];
        edges.push(MegaminxImage.findEdge(a, b));
      }
      result.push(edges);
    }
    return result;
  }

  private static buildFaceCorners(): number[][] {
    const result: number[][] = [];
    const faceAdj: number[][] = [
      [1, 2, 3, 4, 5],
      [0, 2, 8, 9, 5],
      [0, 3, 7, 8, 1],
      [0, 4, 6, 7, 2],
      [0, 5, 10, 6, 3],
      [0, 1, 9, 10, 4],
      [11, 7, 3, 4, 10],
      [11, 8, 2, 3, 6],
      [11, 9, 1, 2, 7],
      [11, 10, 5, 1, 8],
      [11, 6, 4, 5, 9],
      [6, 7, 8, 9, 10]
    ];
    for (let face: number = 0; face < 12; face++) {
      const corners: number[] = [];
      for (let i: number = 0; i < 5; i++) {
        const a: number = face;
        const b: number = faceAdj[face][i];
        const c: number = faceAdj[face][(i + 1) % 5];
        corners.push(MegaminxImage.findCorner(a, b, c));
      }
      result.push(corners);
    }
    return result;
  }

  private static findEdge(a: number, b: number): number {
    const lo: number = Math.min(a, b);
    const hi: number = Math.max(a, b);
    for (let i: number = 0; i < 30; i++) {
      if (MegaminxImage.EDGES[i][0] === lo && MegaminxImage.EDGES[i][1] === hi) {
        return i;
      }
    }
    return 0;
  }

  private static findCorner(a: number, b: number, c: number): number {
    const sorted: number[] = [a, b, c].sort((x: number, y: number): number => x - y);
    for (let i: number = 0; i < 20; i++) {
      if (MegaminxImage.CORNERS[i][0] === sorted[0] &&
        MegaminxImage.CORNERS[i][1] === sorted[1] &&
        MegaminxImage.CORNERS[i][2] === sorted[2]) {
        return i;
      }
    }
    return 0;
  }

  /** 构建面映射 → 132 贴纸排列 */
  private static computePerm(cycleMap: number[]): number[] {
    const perm: number[] = new Array(132).fill(0);
    // 中心贴纸：固定
    for (let f: number = 0; f < 12; f++) {
      perm[f] = f;
    }
    // 棱贴纸：30 棱 × 2
    for (let eIdx: number = 0; eIdx < 30; eIdx++) {
      const a: number = MegaminxImage.EDGES[eIdx][0];
      const b: number = MegaminxImage.EDGES[eIdx][1];
      const newA: number = cycleMap[a];
      const newB: number = cycleMap[b];
      const newEdge: number = MegaminxImage.findEdge(newA, newB);
      // 面 a 的贴纸 → 面 newA
      perm[12 + newEdge * 2 + MegaminxImage.edgeStickerOffset(newEdge, newA)] =
        12 + eIdx * 2 + MegaminxImage.edgeStickerOffset(eIdx, a);
      // 面 b 的贴纸 → 面 newB
      perm[12 + newEdge * 2 + MegaminxImage.edgeStickerOffset(newEdge, newB)] =
        12 + eIdx * 2 + MegaminxImage.edgeStickerOffset(eIdx, b);
    }
    // 角贴纸：20 角 × 3
    for (let cIdx: number = 0; cIdx < 20; cIdx++) {
      const faces: number[] = MegaminxImage.CORNERS[cIdx];
      const newFaces: number[] = [cycleMap[faces[0]], cycleMap[faces[1]], cycleMap[faces[2]]];
      const newCorner: number = MegaminxImage.findCorner(newFaces[0], newFaces[1], newFaces[2]);
      for (let s: number = 0; s < 3; s++) {
        const oldFace: number = faces[s];
        const newFace: number = cycleMap[oldFace];
        perm[72 + newCorner * 3 + MegaminxImage.cornerStickerOffset(newCorner, newFace)] =
          72 + cIdx * 3 + MegaminxImage.cornerStickerOffset(cIdx, oldFace);
      }
    }
    return perm;
  }

  /** 棱 eIdx 在面 face 上的贴纸偏移（0 或 1） */
  private static edgeStickerOffset(eIdx: number, face: number): number {
    return MegaminxImage.EDGES[eIdx][1] === face ? 1 : 0;
  }

  /** 角 cIdx 在面 face 上的贴纸偏移（0, 1 或 2） */
  private static cornerStickerOffset(cIdx: number, face: number): number {
    const c: number[] = MegaminxImage.CORNERS[cIdx];
    if (c[0] === face) return 0;
    if (c[1] === face) return 1;
    return 2;
  }

  private static ensurePerms(): void {
    if (MegaminxImage.permU === null) {
      // U move: 面 1→2→3→4→5→1，1 步
      const m: number[] = [0, 2, 3, 4, 5, 1, 6, 7, 8, 9, 10, 11];
      MegaminxImage.permU = MegaminxImage.computePerm(m);
    }
    if (MegaminxImage.permDpp === null) {
      // D++ move: 面 1→3→5→2→4→1，2 步（即 1→3, 2→4, 3→5, 4→1, 5→2）
      const m: number[] = [0, 3, 4, 5, 1, 2, 6, 7, 8, 9, 10, 11];
      MegaminxImage.permDpp = MegaminxImage.computePerm(m);
    }
    if (MegaminxImage.permRpp === null) {
      // R++ move: 面 {0,2,5,8,9} 循环 2 步
      // 环序 0→2→8→9→5→0，2 步：0→8, 2→9, 8→5, 9→0, 5→2
      const m: number[] = [8, 1, 9, 3, 4, 2, 6, 7, 5, 0, 10, 11];
      MegaminxImage.permRpp = MegaminxImage.computePerm(m);
    }
  }

  private static applyPerm(state: number[], perm: number[]): number[] {
    const newState: number[] = new Array(132).fill(0);
    for (let i: number = 0; i < 132; i++) {
      newState[i] = state[perm[i]];
    }
    return newState;
  }

  private static applyPermInverse(state: number[], perm: number[]): number[] {
    const newState: number[] = new Array(132).fill(0);
    for (let i: number = 0; i < 132; i++) {
      newState[perm[i]] = state[i];
    }
    return newState;
  }

  /**
   * 计算五魔方打乱状态。
   * @returns number[132]：每贴纸的颜色索引。
   */
  static image(scramble: string): number[] {
    MegaminxImage.ensurePerms();
    // 初始状态：每贴纸颜色 = 所在面
    let state: number[] = new Array(132).fill(0);
    for (let f: number = 0; f < 12; f++) {
      state[f] = f; // 中心
    }
    for (let e: number = 0; e < 30; e++) {
      state[12 + e * 2] = MegaminxImage.EDGES[e][0];
      state[12 + e * 2 + 1] = MegaminxImage.EDGES[e][1];
    }
    for (let c: number = 0; c < 20; c++) {
      state[72 + c * 3] = MegaminxImage.CORNERS[c][0];
      state[72 + c * 3 + 1] = MegaminxImage.CORNERS[c][1];
      state[72 + c * 3 + 2] = MegaminxImage.CORNERS[c][2];
    }

    // 解析打乱公式：支持换行和空格分隔
    const tokens: string[] = scramble.split(/[\s\n]+/);
    for (let i: number = 0; i < tokens.length; i++) {
      const t: string = tokens[i];
      if (t.length === 0) continue;
      if (t === 'U') {
        state = MegaminxImage.applyPerm(state, MegaminxImage.permU!);
      } else if (t === "U'") {
        state = MegaminxImage.applyPermInverse(state, MegaminxImage.permU!);
      } else if (t === 'R++') {
        state = MegaminxImage.applyPerm(state, MegaminxImage.permRpp!);
      } else if (t === 'R--') {
        state = MegaminxImage.applyPermInverse(state, MegaminxImage.permRpp!);
      } else if (t === 'D++') {
        state = MegaminxImage.applyPerm(state, MegaminxImage.permDpp!);
      } else if (t === 'D--') {
        state = MegaminxImage.applyPermInverse(state, MegaminxImage.permDpp!);
      }
    }
    return state;
  }

  static getColors(): string[] {
    return MegaminxImage.COLORS;
  }

  /** 获取某面的 5 棱索引 */
  static getFaceEdges(face: number): number[] {
    return MegaminxImage.FACE_EDGES[face];
  }

  /** 获取某面的 5 角索引 */
  static getFaceCorners(face: number): number[] {
    return MegaminxImage.FACE_CORNERS[face];
  }

  /** 获取棱的 2 个面 */
  static getEdgeFaces(eIdx: number): number[] {
    return MegaminxImage.EDGES[eIdx];
  }

  /** 获取角的 3 个面 */
  static getCornerFaces(cIdx: number): number[] {
    return MegaminxImage.CORNERS[cIdx];
  }

  /** 展开网图各面中心位置 [face] = [centerX, centerY]（2 花形布局） */
  static readonly NET_LAYOUT: number[][] = MegaminxImage.buildNetLayout();

  private static buildNetLayout(): number[][] {
    // 花 1：U(0) 中心，5 面环绕（1=F 2=R 3=BR 4=BL 5=L）
    // 花 2：D(11) 中心，5 面环绕（6=DBR 7=DR 8=DFR 9=DFL 10=DBL）
    const r: number = 1.05; // 面间距
    const layout: number[][] = new Array(12).fill(0).map((_: number): number[] => [0, 0]);
    // 花 1 中心
    layout[0] = [0, 0];
    for (let i: number = 0; i < 5; i++) {
      const angle: number = -Math.PI / 2 + i * 2 * Math.PI / 5;
      layout[1 + i] = [r * Math.cos(angle), r * Math.sin(angle)];
    }
    // 花 2 中心（在花 1 右侧）
    const dx: number = r * (1 + Math.cos(Math.PI / 5)) * 1.1;
    layout[11] = [dx, 0];
    for (let i: number = 0; i < 5; i++) {
      const angle: number = -Math.PI / 2 + i * 2 * Math.PI / 5;
      layout[6 + i] = [dx + r * Math.cos(angle), r * Math.sin(angle)];
    }
    return layout;
  }
}
