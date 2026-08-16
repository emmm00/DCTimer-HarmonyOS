/**
 * CubeImage - 移植自 DCTimer-Android scrambler/Cube.java
 * 根据打乱公式计算 NxN 魔方各贴纸颜色，输出展开网图顺序的颜色索引数组。
 *
 * img[] 颜色索引含义（与原 app drawScramble 的 colors 数组对应）：
 *   0 = D面(黄)  1 = B面(蓝)  2 = R面(红)  3 = U面(白)  4 = F面(绿)  5 = L面(橙)
 *
 * img[] 排列顺序（b = size）：
 *   前 b*b 个为 U 面（按行优先），
 *   接下来 b 行，每行 4*b 个依次为 L F R B 四面各一行，
 *   最后 b*b 个为 D 面。
 */
export class CubeImage {
  private static size: number = 3;
  private static seq: number[] = [];
  private static posit: number[] = [];
  // 内部面顺序 D L B U R F -> 输出颜色索引
  private static readonly COLORS: number[] = [0, 5, 1, 3, 2, 4];

  /** Java String.replace 是全部替换，ArkTS 需要手动实现 */
  private static replaceAllStr(s: string, from: string, to: string): string {
    return s.split(from).join(to);
  }

  /**
   * 计算打乱后的贴纸状态
   * @param scramble 打乱公式（支持 U D L R F B、' / 2、w 宽层、2-9 多层前缀、小写宽层、M/x/y/z(3阶)）
   * @param cubeSize 魔方阶数 2-7
   * @returns 展开网图顺序的颜色索引数组（长度 6*size*size）
   */
  static image(scramble: string, cubeSize: number): number[] {
    CubeImage.size = cubeSize;
    let scr: string = scramble;
    if (cubeSize === 3) {
      scr = CubeImage.replaceAllStr(scr, "M'", "r R'");
      scr = CubeImage.replaceAllStr(scr, "M2", "r2 R2");
      scr = CubeImage.replaceAllStr(scr, "M", "r' R");
      scr = CubeImage.replaceAllStr(scr, "x'", "r' L");
      scr = CubeImage.replaceAllStr(scr, "x2", "r2 L2");
      scr = CubeImage.replaceAllStr(scr, "x", "r L'");
      scr = CubeImage.replaceAllStr(scr, "y'", "u' D");
      scr = CubeImage.replaceAllStr(scr, "y2", "u2 D2");
      scr = CubeImage.replaceAllStr(scr, "y", "u D'");
      scr = CubeImage.replaceAllStr(scr, "z'", "f' B");
      scr = CubeImage.replaceAllStr(scr, "z2", "f2 B2");
      scr = CubeImage.replaceAllStr(scr, "z", "f B'");
    } else if (cubeSize === 4) {
      scr = CubeImage.replaceAllStr(scr, "x'", "r' l");
      scr = CubeImage.replaceAllStr(scr, "x2", "r2 l2");
      scr = CubeImage.replaceAllStr(scr, "x", "r l'");
      scr = CubeImage.replaceAllStr(scr, "y'", "u' d");
      scr = CubeImage.replaceAllStr(scr, "y2", "u2 d2");
      scr = CubeImage.replaceAllStr(scr, "y", "u d'");
      scr = CubeImage.replaceAllStr(scr, "z'", "f' b");
      scr = CubeImage.replaceAllStr(scr, "z2", "f2 b2");
      scr = CubeImage.replaceAllStr(scr, "z", "f b'");
    }

    const tokens: string[] = scr.split(' ');
    const parsed: number[] = [];
    for (let i: number = 0; i < tokens.length; i++) {
      const t: string = tokens[i];
      if (t.length === 0) {
        continue;
      }
      let k: number = 0;
      let move: number = -1;
      const c0: string = t.charAt(0);
      if (c0 === '5') { k = 4; }
      else if (c0 === '4') { k = 3; }
      else if (c0 === '3') { k = 2; }
      else if (c0 === '2') { k = 1; }
      else if (c0 === 'R') { move = 16; }
      else if (c0 === 'L') { move = 4; }
      else if (c0 === 'U') { move = 12; }
      else if (c0 === 'D') { move = 0; }
      else if (c0 === 'F') { move = 20; }
      else if (c0 === 'B') { move = 8; }
      else if (c0 === 'r') { move = 16; k = 1; }
      else if (c0 === 'l') { move = 4; k = 1; }
      else if (c0 === 'u') { move = 12; k = 1; }
      else if (c0 === 'd') { move = 0; k = 1; }
      else if (c0 === 'f') { move = 20; k = 1; }
      else if (c0 === 'b') { move = 8; k = 1; }

      if (t.length > 1) {
        const c1: string = t.charAt(1);
        if (c1 === '\'') { move += 2; }
        else if (c1 === '2') { move += 1; }
        else if (c1 === '³') { k = 2; }
        else if (c1 === '²') { k = 1; }
        else if (c1 === 'w') { move += 24; }
        else if (c1 === 'r' || c1 === 'R') { move = 16; }
        else if (c1 === 'l' || c1 === 'L') { move = 4; }
        else if (c1 === 'u' || c1 === 'U') { move = 12; }
        else if (c1 === 'd' || c1 === 'D') { move = 0; }
        else if (c1 === 'f' || c1 === 'F') { move = 20; }
        else if (c1 === 'b' || c1 === 'B') { move = 8; }

        if (t.length > 2) {
          const c2: string = t.charAt(2);
          if (c2 === '\'') { move += 2; }
          else if (c2 === '2') { move += 1; }
          if (t.length > 3) {
            const c3: string = t.charAt(3);
            if (c3 === '\'') { move += 2; }
            else if (c3 === '2') { move += 1; }
          }
        }
      }
      if (move < 0) {
        // 无法解析的记号，跳过
        continue;
      }
      parsed.push(move + k * 24);
    }
    CubeImage.seq = parsed;
    return CubeImage.buildImage();
  }

  private static buildImage(): number[] {
    const size: number = CubeImage.size;
    const img: number[] = [];
    CubeImage.posit = [];
    const s2: number = size * size;
    // 初始化贴纸：每个面一个颜色（内部面序 D L B U R F -> 0..5）
    for (let f: number = 0; f < 6; f++) {
      for (let i: number = 0; i < s2; i++) {
        CubeImage.posit.push(f);
      }
    }
    // 执行转动序列
    for (let i: number = 0; i < CubeImage.seq.length; i++) {
      const q: number = CubeImage.seq[i] & 3;
      let f: number = CubeImage.seq[i] >> 2;
      let d: number = 0;
      while (f > 5) {
        f -= 6;
        d++;
      }
      // mult 恒为 true：从第 d 层一直转到第 0 层（宽层效果）
      do {
        CubeImage.doSlice(f, d, q + 1);
        d--;
      } while (d >= 0);
    }
    // 展开网图位置 -> posit 索引映射
    const flat2posit: number[] = [];
    for (let i: number = 0; i < 12 * s2; i++) {
      flat2posit.push(-1);
    }
    for (let i: number = 0; i < size; i++) {
      for (let j: number = 0; j < size; j++) {
        flat2posit[4 * size * (3 * size - i - 1) + size + j] = i * size + j;             // D
        flat2posit[4 * size * (size + i) + size - j - 1] = (size + i) * size + j;        // L
        flat2posit[4 * size * (size + i) + 4 * size - j - 1] = (2 * size + i) * size + j; // B
        flat2posit[4 * size * i + size + j] = (3 * size + i) * size + j;                 // U
        flat2posit[4 * size * (size + i) + 2 * size + j] = (4 * size + i) * size + j;    // R
        flat2posit[4 * size * (size + i) + size + j] = (5 * size + i) * size + j;        // F
      }
    }
    let d: number = 0;
    for (let i: number = 0; i < 3 * size; i++) {
      for (let f: number = 0; f < 4 * size; f++) {
        if (flat2posit[d] >= 0) {
          const c: number = CubeImage.posit[flat2posit[d]];
          img.push(CubeImage.COLORS[c]);
        }
        d++;
      }
    }
    return img;
  }

  /** 转 face f 的第 d 层，q 个顺时针四分之一转 */
  private static doSlice(face: number, d: number, q: number): void {
    let f: number = face;
    let f1: number = 0, f2: number = 0, f3: number = 0, f4: number = 0;
    const size: number = CubeImage.size;
    const s2: number = size * size;
    const posit: number[] = CubeImage.posit;
    if (f > 5) {
      f -= 6;
    }
    for (let k: number = 0; k < q; k++) {
      // 循环侧面贴纸
      for (let i: number = 0; i < size; i++) {
        if (f === 0) {
          f1 = 6 * s2 - size * d - size + i;
          f2 = 2 * s2 - size * d - 1 - i;
          f3 = 3 * s2 - size * d - 1 - i;
          f4 = 5 * s2 - size * d - size + i;
        } else if (f === 1) {
          f1 = 3 * s2 + d + size * i;
          f2 = 3 * s2 + d - size * (i + 1);
          f3 = s2 + d - size * (i + 1);
          f4 = 5 * s2 + d + size * i;
        } else if (f === 2) {
          f1 = 3 * s2 + d * size + i;
          f2 = 4 * s2 + size - 1 - d + size * i;
          f3 = d * size + size - 1 - i;
          f4 = 2 * s2 - 1 - d - size * i;
        } else if (f === 3) {
          f1 = 4 * s2 + d * size + size - 1 - i;
          f2 = 2 * s2 + d * size + i;
          f3 = s2 + d * size + i;
          f4 = 5 * s2 + d * size + size - 1 - i;
        } else if (f === 4) {
          f1 = 6 * s2 - 1 - d - size * i;
          f2 = size - 1 - d + size * i;
          f3 = 2 * s2 + size - 1 - d + size * i;
          f4 = 4 * s2 - 1 - d - size * i;
        } else if (f === 5) {
          f1 = 4 * s2 - size - d * size + i;
          f2 = 2 * s2 - size + d - size * i;
          f3 = s2 - 1 - d * size - i;
          f4 = 4 * s2 + d + size * i;
        }
        const c: number = posit[f1];
        posit[f1] = posit[f2];
        posit[f2] = posit[f3];
        posit[f3] = posit[f4];
        posit[f4] = c;
      }
      // 转动面自身
      if (d === 0) {
        for (let i: number = 0; i + i < size; i++) {
          for (let j: number = 0; j + j < size - 1; j++) {
            f1 = f * s2 + i + j * size;
            f3 = f * s2 + (size - 1 - i) + (size - 1 - j) * size;
            if (f < 3) {
              f2 = f * s2 + (size - 1 - j) + i * size;
              f4 = f * s2 + j + (size - 1 - i) * size;
            } else {
              f4 = f * s2 + (size - 1 - j) + i * size;
              f2 = f * s2 + j + (size - 1 - i) * size;
            }
            const c: number = posit[f1];
            posit[f1] = posit[f2];
            posit[f2] = posit[f3];
            posit[f3] = posit[f4];
            posit[f4] = c;
          }
        }
      }
    }
  }
}

/** 六色方案（与原 app 默认值一致）：索引 0-5 = D B R U F L */
export const SCRAMBLE_FACE_COLORS: string[] = [
  '#FFFF00', // 0 D 黄
  '#0000FF', // 1 B 蓝
  '#FF0000', // 2 R 红
  '#FFFFFF', // 3 U 白
  '#009900', // 4 F 绿
  '#FF9900'  // 5 L 橙
];
