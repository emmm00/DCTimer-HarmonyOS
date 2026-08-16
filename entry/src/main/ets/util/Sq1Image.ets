/**
 * Sq1Image - 移植自 cstimer image.js 的 sq1Image 与 sq1.js 的 SqCubie
 * 解析 Square-1 打乱公式 "(top,bottom)/"，计算 24 个块的状态。
 *
 * SqCubie 使用 4 个 24 位整数（ul,ur,dl,dr）打包 24 个块，每块 4 位。
 *   ul/ur: 上面 12 个块（每 4 位一个），dl/dr: 下面 12 个块。
 *   ml: 中层翻转状态（0/1）。
 *
 * 输出 25 个值：[piece0..piece23, ml]。
 *   piece 值 0-7 为上层块（U 色），8-15 为下层块（D 色）。
 *   偶数 = 棱块（单格），奇数 = 角块（双格）。
 */
export class Sq1Image {
  /** 颜色索引：0=U黄 1=D白 2=R橙 3=F绿 4=L红 5=B蓝 */
  private static readonly COLORS: string[] = [
    '#FFFF00', '#FFFFFF', '#FF8800', '#00CC00', '#FF0000', '#0000FF'
  ];

  /** 棱块侧面颜色（偶数 val → 颜色索引） */
  private static readonly EDGE_COL: number[] = [2, 0, 5, 0, 4, 0, 3, 0, 3, 0, 4, 0, 5, 0, 2, 0];
  /** 角块两个侧面颜色（奇数 val → [左色, 右色]） */
  private static readonly CORNER_COL: number[][] = [
    [], [2, 5], [], [5, 4], [], [4, 3], [], [3, 2],
    [], [2, 3], [], [3, 4], [], [4, 5], [], [5, 2]
  ];

  static getColors(): string[] {
    return Sq1Image.COLORS;
  }

  static getEdgeColor(val: number): number {
    return Sq1Image.EDGE_COL[val];
  }

  static getCornerColors(val: number): number[] {
    return Sq1Image.CORNER_COL[val];
  }

  /** 上下面颜色：val<8 → U(0), val>=8 → D(1) */
  static getUDColor(val: number): number {
    return val >= 8 ? 1 : 0;
  }

  /**
   * 计算 Square-1 打乱状态。
   * @returns number[25]：前 24 为块值，第 25 为中层状态 ml。
   */
  static image(scramble: string): number[] {
    const sc: SqCubie = new SqCubie();

    // 按 "/" 分割
    const segments: string[] = scramble.split('/');
    const movere: RegExp = /^\s*\(\s*(-?\d+)\s*,\s*(-?\d+)\s*\)\s*$/;

    for (let i: number = 0; i < segments.length; i++) {
      const seg: string = segments[i];
      if (seg.trim().length === 0) {
        // 空段（连续 / 或首尾 /）→ 仅做 /
        sc.doMove(0);
        continue;
      }
      const m: RegExpMatchArray | null = seg.match(movere);
      if (!m) {
        continue;
      }
      const top: number = (parseInt(m[1], 10) + 12) % 12;
      const bottom: number = (parseInt(m[2], 10) + 12) % 12;
      if (top !== 0) {
        sc.doMove(top);
      }
      if (bottom !== 0) {
        sc.doMove(-bottom);
      }
      sc.doMove(0);
    }

    const result: number[] = [];
    for (let i: number = 0; i < 24; i++) {
      result.push(sc.pieceAt(i));
    }
    result.push(sc.ml);
    return result;
  }
}

/** Square-1 块状态（移植自 cstimer sq1.js SqCubie） */
class SqCubie {
  ul: number = 0x011233;
  ur: number = 0x455677;
  dl: number = 0x998bba;
  dr: number = 0xddcffe;
  ml: number = 0;

  pieceAt(idx: number): number {
    if (idx < 6) {
      return (this.ul >> ((5 - idx) << 2)) & 0xf;
    }
    if (idx < 12) {
      return (this.ur >> ((11 - idx) << 2)) & 0xf;
    }
    if (idx < 18) {
      return (this.dl >> ((17 - idx) << 2)) & 0xf;
    }
    return (this.dr >> ((23 - idx) << 2)) & 0xf;
  }

  /**
   * 执行转动。
   * @param move 正数=上层转 move 步，负数=下层转 |move| 步，0=中层 /
   */
  doMove(move: number): void {
    let temp: number;
    let m: number = move << 2;
    if (m > 24) {
      m = 48 - m;
      temp = this.ul;
      this.ul = ((this.ul >> m) | (this.ur << (24 - m))) & 0xffffff;
      this.ur = ((this.ur >> m) | (temp << (24 - m))) & 0xffffff;
    } else if (m > 0) {
      temp = this.ul;
      this.ul = ((this.ul << m) | (this.ur >> (24 - m))) & 0xffffff;
      this.ur = ((this.ur << m) | (temp >> (24 - m))) & 0xffffff;
    } else if (m === 0) {
      temp = this.ur;
      this.ur = this.dl;
      this.dl = temp;
      this.ml = 1 - this.ml;
    } else if (m >= -24) {
      m = -m;
      temp = this.dl;
      this.dl = ((this.dl << m) | (this.dr >> (24 - m))) & 0xffffff;
      this.dr = ((this.dr << m) | (temp >> (24 - m))) & 0xffffff;
    } else {
      m = 48 + m;
      temp = this.dl;
      this.dl = ((this.dl >> m) | (this.dr << (24 - m))) & 0xffffff;
      this.dr = ((this.dr >> m) | (temp << (24 - m))) & 0xffffff;
    }
  }
}
