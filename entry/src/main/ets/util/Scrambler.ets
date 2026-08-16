export class Scrambler {
  private static readonly MOVES_333 = ['U', 'D', 'R', 'L', 'F', 'B'];
  private static readonly SUFFIXES = ['', "'", '2'];

  static generate(puzzle: number): string {
    switch (puzzle) {
      case 33: return Scrambler.scramble333(25);
      case 31: return Scrambler.scramble333(25); // 3x3 OH
      case 32: return Scrambler.scramble333(25); // 3x3 BLD
      case 34: return Scrambler.scramble333(25); // 3x3 MTS
      case 35: return Scrambler.scrambleFMC();     // 3x3 FMC
      case 22: return Scrambler.scrambleNxN(2, 9);
      case 23: return Scrambler.scrambleNxN(2, 9); // 2x2 BLD
      case 44: return Scrambler.scrambleNxN(4, 40);
      case 42: return Scrambler.scrambleNxN(4, 40); // 4x4 BLD
      case 55: return Scrambler.scrambleNxN(5, 60);
      case 52: return Scrambler.scrambleNxN(5, 60); // 5x5 BLD code placeholder
      case 66: return Scrambler.scrambleNxN(6, 70);
      case 77: return Scrambler.scrambleNxN(7, 100);
      case 70: return Scrambler.scramblePyraminx();
      case 60: return Scrambler.scrambleSkewb();
      case 50: return Scrambler.scrambleMegaminx();
      case 40: return Scrambler.scrambleSQ1();
      case 80: return Scrambler.scrambleClock();
      default: return Scrambler.scramble333(25);
    }
  }

  /** 训练模式打乱：OLL / PLL / F2L 等 */
  static generateTraining(type: number): string {
    switch (type) {
      case 1: return Scrambler.scrambleOLL();
      case 2: return Scrambler.scramblePLL();
      default: return Scrambler.scramble333(25);
    }
  }

  // ================== 基础随机打乱 ==================

  private static scramble333(length: number): string {
    const moves = Scrambler.MOVES_333;
    const suffixes = Scrambler.SUFFIXES;
    const result: string[] = [];
    let lastAxis = -1;
    let lastLastAxis = -1;
    for (let i = 0; i < length; i++) {
      let moveIdx: number;
      do {
        moveIdx = Math.floor(Math.random() * moves.length);
      } while (Math.floor(moveIdx / 2) === lastAxis ||
        (Math.floor(moveIdx / 2) === lastLastAxis && Math.floor(moveIdx / 2) === lastAxis));
      const suffix = suffixes[Math.floor(Math.random() * suffixes.length)];
      result.push(moves[moveIdx] + suffix);
      lastLastAxis = lastAxis;
      lastAxis = Math.floor(moveIdx / 2);
    }
    return result.join(' ');
  }

  private static scrambleNxN(size: number, length: number): string {
    const innerMoves: number[] = [];
    if (size > 2) {
      for (let i = 2; i < size; i++) {
        innerMoves.push(i);
      }
    }
    const faces = ['U', 'D', 'R', 'L', 'F', 'B'];
    const suffixes = ['', "'", '2'];
    const result: string[] = [];
    let lastFace = -1;
    for (let i = 0; i < length; i++) {
      let faceIdx: number;
      do {
        faceIdx = Math.floor(Math.random() * faces.length);
      } while (faceIdx === lastFace);
      const useInner = innerMoves.length > 0 && Math.random() > 0.7;
      const prefix: string = useInner ? innerMoves[Math.floor(Math.random() * innerMoves.length)].toString() : '';
      const suffix = suffixes[Math.floor(Math.random() * suffixes.length)];
      result.push(prefix + faces[faceIdx] + suffix);
      lastFace = faceIdx;
    }
    return result.join(' ');
  }

  // ================== WCA 项目打乱 ==================

  /** FMC: R' U' F + scramble + R' U' F */
  private static scrambleFMC(): string {
    const core: string = Scrambler.scramble333(21);
    return "R' U' F " + core + " R' U' F";
  }

  private static scramblePyraminx(): string {
    const moves = ['U', 'L', 'R', 'B'];
    const tips = ['u', 'l', 'r', 'b'];
    const suffixes = ['', "'"];
    const result: string[] = [];
    // 主体11步（含三轴约束）
    let lastAxis = -1;
    for (let i = 0; i < 11; i++) {
      let idx: number;
      do {
        idx = Math.floor(Math.random() * moves.length);
      } while (idx === lastAxis);
      result.push(moves[idx] + suffixes[Math.floor(Math.random() * suffixes.length)]);
      lastAxis = idx;
    }
    // 角块旋转
    for (let i = 0; i < tips.length; i++) {
      if (Math.random() > 0.5) {
        result.push(tips[i] + suffixes[Math.floor(Math.random() * suffixes.length)]);
      }
    }
    return result.join(' ');
  }

  private static scrambleSkewb(): string {
    const moves = ['U', 'L', 'R', 'B'];
    const suffixes = ['', "'"];
    const result: string[] = [];
    let last = -1;
    for (let i = 0; i < 10; i++) {
      let idx: number;
      do {
        idx = Math.floor(Math.random() * moves.length);
      } while (idx === last);
      result.push(moves[idx] + suffixes[Math.floor(Math.random() * suffixes.length)]);
      last = idx;
    }
    return result.join(' ');
  }

  /** Megaminx: WCA 标准 R++/R-- 与 D++/D-- 严格交替，每行 10 步 + 行尾 U/U' */
  private static scrambleMegaminx(): string {
    const scrLen: number = 70;
    const lineLen: number = 10;
    const lines: number = Math.ceil(scrLen / lineLen);
    const result: string[] = [];

    for (let j: number = 0; j < lines; j++) {
      const line: string[] = [];
      let lastIsPlus: boolean = false;
      for (let i: number = 0; i < lineLen; i++) {
        const isPlus: boolean = Math.random() > 0.5;
        lastIsPlus = isPlus;
        if (i % 2 === 0) {
          line.push('R' + (isPlus ? '++' : '--'));
        } else {
          line.push('D' + (isPlus ? '++' : '--'));
        }
      }
      line.push(lastIsPlus ? 'U' : "U'");
      result.push(line.join(' '));
    }
    return result.join('\n');
  }

  /** Square-1: (top,bottom) / 格式 */
  private static scrambleSQ1(): string {
    const result: string[] = [];
    for (let i = 0; i < 20; i++) {
      const top: number = Math.floor(Math.random() * 12) - 5;
      const bottom: number = Math.floor(Math.random() * 12) - 5;
      result.push('(' + top + ',' + bottom + ')');
      if (i < 19) {
        result.push('/');
      }
    }
    return result.join(' ');
  }

  /** Clock: WCA 标准 */
  private static scrambleClock(): string {
    const pins: number[] = [0, 1, 2, 3]; // UR=0, DR=1, DL=2, UL=3
    const faces1: string[] = ['UR', 'DR', 'DL', 'UL', 'U', 'R', 'D', 'L', 'ALL'];
    const faces2: string[] = ['U', 'R', 'D', 'L', 'ALL'];
    const result: string[] = [];

    // 第一面：9步
    for (let i = 0; i < faces1.length; i++) {
      const amt: number = Math.floor(Math.random() * 12) - 5;
      const sign: string = amt >= 0 ? '+' : '';
      result.push(faces1[i] + sign + amt.toString());
    }

    // y2
    result.push('y2');

    // 第二面：5步
    for (let i = 0; i < faces2.length; i++) {
      const amt: number = Math.floor(Math.random() * 12) - 5;
      const sign: string = amt >= 0 ? '+' : '';
      result.push(faces2[i] + sign + amt.toString());
    }

    // 最后 pin 状态
    const firstPin: number = Math.floor(Math.random() * pins.length);
    const secondPin: number = Math.floor(Math.random() * pins.length);
    const pinNames: string[] = ['UR', 'DR', 'DL', 'UL'];
    result.push(pinNames[firstPin] + ' ' + pinNames[secondPin]);

    return result.join(' ');
  }

  // ================== 训练打乱 (OLL/PLL) ==================

  /** OLL 打乱: F R U R' U' F' (条形) 等常见 OLL 触发 */
  private static scrambleOLL(): string {
    const setUps: string[] = [
      "R U R' U' R' F R F'",
      "F R U R' U' F'",
      "R U R' U R U2 R'",
      "R U2 R' U' R U' R'",
      "R' U' R U' R' U2 R",
      "R U2 R2 U' R2 U' R2 U2 R",
      "r U R' U' r' F R F'",
      "F' r U R' U' r' F R",
      "R U R' U' R' F R2 U' R' U' R U R' F'",
      "R U R' F' R U R' U' R' F R2 U' R'",
      "L' U' L U' L' U2 L",
      "L U L' U L U2 L'",
    ];
    const setUp: string = setUps[Math.floor(Math.random() * setUps.length)];
    const suffix: string[] = ['U', "U'", 'U2', ''];
    const auf: string = suffix[Math.floor(Math.random() * suffix.length)];
    const pre: string[] = ["R U R' U'", "F R U R' U' F'", "R' U' R U", "B' R' U' R U B", ''];
    const prefix: string = pre[Math.floor(Math.random() * pre.length)];
    let s: string = '';
    if (prefix.length > 0) {
      s += prefix + ' ';
    }
    s += setUp;
    if (auf.length > 0) {
      s += ' ' + auf;
    }
    return s;
  }

  /** PLL 打乱: 随机 PLL 算法 */
  private static scramblePLL(): string {
    const plls: string[] = [
      "R U' R U R U R U' R' U' R2",           // Ua
      "R2 U R U R' U' R' U' R' U R'",          // Ub
      "R2 U' R' U' R U R U R U' R",            // Ua 变体
      "M2 U M2 U2 M2 U M2",                     // H
      "M2 U M2 U' M' U2 M2 U2 M' U'",           // Z (简化)
      "x R' U R' D2 R U' R' D2 R2",            // Aa
      "x R2 D2 R U R' D2 R U' R",              // Ab
      "R U' R' U' R U R D R' U' R D' R' U2 R'", // Ra
      "R' U2 R U2 R' F R U R' U' R' F' R2",    // T
      "R U R' U' R' F R2 U' R' U' R U R' F'",  // T 变体
      "R' U L' U2 R U' R' U2 R L",             // Ja
      "R U R' F' R U R' U' R' F R2 U' R'",     // Jb
      "R' U' F' R U R' U' R' F R2 U' R' U' R U R' U R", // F
      "R' U' R U D' R2 U R' U R U' R U' R2 D", // G 系列
      "R U R' y' R2 u' R U' R' U R' u R2",     // Gd
    ];
    const pll: string = plls[Math.floor(Math.random() * plls.length)];
    const aufs: string[] = ['', 'U', "U'", 'U2'];
    const auf: string = aufs[Math.floor(Math.random() * aufs.length)];
    if (auf.length > 0) {
      return pll + ' ' + auf;
    }
    return pll;
  }

  /** CLL / EG-1 二阶训练用 */
  static generateCLL(): string {
    const clls: string[] = [
      "R U R' U' R' F R F'",
      "R U2 R' U' R U R' U' R U' R'",
      "F R U R' U' F'",
      "R U R' U R U2 R'",
    ];
    const aufs: string[] = ['', 'U', "U'", 'U2'];
    const cll: string = clls[Math.floor(Math.random() * clls.length)];
    const auf: string = aufs[Math.floor(Math.random() * aufs.length)];
    if (auf.length > 0) {
      return cll + ' ' + auf;
    }
    return cll;
  }
}
