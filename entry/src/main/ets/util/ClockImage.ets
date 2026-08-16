/**
 * ClockImage - 移植自 cstimer image.js 的 clkImage
 * 解析魔表打乱公式，计算 18 个时钟指针状态与 8 个按钮状态。
 *
 * 内部 14 个时钟值（列优先 3x3 前面 + 5 个独立后面）：
 *   0..8 前面 9 个时钟（列优先：UL,ML,DL,UM,MM,DM,UR,MR,DR）
 *   9..13 后面 5 个独立时钟（back-ML, back-UM, back-MM, back-DM, back-MR）
 *   后面四角由前面四角反向派生：back-UL=12-front-DL, back-UR=12-front-DR,
 *   back-DL=12-front-UL, back-DR=12-front-UR
 *
 * 输出 18 个显示时钟（前面 9 + 后面 9，3 行 x 6 列）+ 8 个按钮（前 4 + 后 4）。
 */
export class ClockImage {
  private static readonly COLORS: string[] = [
    '#FF0000', // 0 红 - 指针/边框
    '#3377BB', // 1 蓝 - 前面表盘
    '#55CCFF', // 2 浅蓝 - 后面表盘
    '#FFFF00', // 3 黄 - 按钮弹起
    '#885500'  // 4 棕 - 按钮按下
  ];

  /**
   * moveArr[18][14]：每个动作对 14 个内部时钟的影响系数。
   * 行 0-8 为前面动作（UR,DR,DL,UL,U,R,D,L,ALL），
   * 行 9-17 为后面动作（back-UR,DR,DL,UL,U,R,D,L,ALL）。
   * 后面动作对链接的前面角落用 -1（反向）。
   */
  private static readonly MOVE_ARR: number[][] = [
    // 前面动作（仅影响 clks[0..8]）
    [0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0], // 0 UR
    [0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0], // 1 DR
    [0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0], // 2 DL
    [1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0], // 3 UL
    [1, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0], // 4 U
    [0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0], // 5 R
    [0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0], // 6 D
    [1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0], // 7 L
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0], // 8 ALL
    // 后面动作（影响 clks[0..8] 的反向角 + clks[9..13]）
    [0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 1, 1, 0, 1],  // 9 back-UR
    [0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 1, 1],  // 10 back-DR
    [-1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0],  // 11 back-DL
    [0, 0, -1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0],  // 12 back-UL
    [0, 0, -1, 0, 0, 0, 0, 0, -1, 1, 1, 1, 0, 1], // 13 back-U
    [0, 0, 0, 0, 0, 0, -1, 0, -1, 0, 1, 1, 1, 1], // 14 back-R
    [-1, 0, 0, 0, 0, 0, -1, 0, 0, 1, 0, 1, 1, 1], // 15 back-D
    [-1, 0, -1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0], // 16 back-L
    [-1, 0, -1, 0, 0, 0, -1, 0, -1, 1, 1, 1, 1, 1] // 17 back-ALL
  ];

  private static readonly MOVE_STR: string[] = ['UR', 'DR', 'DL', 'UL', 'U', 'R', 'D', 'L', 'ALL'];

  /** 将 power 规范到 [0,12) */
  private static mod12(v: number): number {
    let r: number = v % 12;
    if (r < 0) {
      r += 12;
    }
    return r;
  }

  /**
   * 计算魔表状态。
   * @returns number[]：前 18 个为时钟值（0-11，3行x6列），后 8 个为按钮状态（0/1）。
   */
  static image(scramble: string): number[] {
    const moves: string[] = scramble.split(/\s+/);
    let flip: number = 9;
    const buttons: number[] = [0, 0, 0, 0];
    const clks: number[] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

    const movere: RegExp = /([UD][RL]|ALL|[UDRLy]|all)(?:(\d[+-]?)|\((\d[+-]?),(\d[+-]?)\))?/;

    for (let i: number = 0; i < moves.length; i++) {
      const m: RegExpMatchArray | null = moves[i].match(movere);
      if (!m) {
        continue;
      }
      if (m[0] === 'y2') {
        flip = 9 - flip;
        continue;
      }
      const axisBase: number = ClockImage.MOVE_STR.indexOf(m[1]);
      if (axisBase < 0) {
        continue;
      }
      const axis: number = axisBase + flip;

      // 无数值 → 仅设置按钮（结尾的 pin 状态）
      if (m[2] === undefined && m[3] === undefined) {
        buttons[axis % 9] = 1;
        continue;
      }

      let power: number;
      const actions: number[] = [];
      if (m[1] === 'all' || m[1] === 'ALL') {
        // ALL：符号翻转，轴使用 8 + 9 - flip
        const sign: number = m[2].charAt(1) === '+' ? -1 : 1;
        power = parseInt(m[2].charAt(0), 10) * sign + 12;
        actions.push(8 + 9 - flip, power);
      } else if (m[2] !== undefined) {
        const sign: number = m[2].charAt(1) === '+' ? 1 : -1;
        power = parseInt(m[2].charAt(0), 10) * sign + 12;
        actions.push(axis, power);
      } else {
        // (a,b) 双动格式 - 我们的 Scrambler 不生成，但保留兼容
        const sign1: number = m[3].charAt(1) === '+' ? 1 : -1;
        power = parseInt(m[3].charAt(0), 10) * sign1 + 12;
        actions.push(axis, power);
        const sign2: number = m[4].charAt(1) === '+' ? -1 : 1;
        power = parseInt(m[4].charAt(0), 10) * sign2 + 12;
        const axis2: number = (10 - axis % 9) % 4 + 4 + 9 - flip;
        actions.push(axis2, power);
      }

      for (let k: number = 0; k < actions.length; k += 2) {
        const a: number = actions[k];
        const p: number = actions[k + 1];
        const row: number[] = ClockImage.MOVE_ARR[a];
        for (let j: number = 0; j < 14; j++) {
          clks[j] = ClockImage.mod12(clks[j] + row[j] * p);
        }
      }
    }

    // 14 内部值 → 18 显示值
    const display: number[] = [
      clks[0], clks[3], clks[6], clks[1], clks[4], clks[7], clks[2], clks[5], clks[8],
      12 - clks[2], clks[10], 12 - clks[8], clks[9], clks[11], clks[13],
      12 - clks[0], clks[12], 12 - clks[6]
    ];
    // 规范化到 [0,12)
    for (let i: number = 0; i < 18; i++) {
      display[i] = ClockImage.mod12(display[i]);
    }

    // 4 按钮 → 8 显示按钮（前 4 + 后 4）
    const dispButtons: number[] = [
      buttons[3], buttons[2], buttons[0], buttons[1],
      1 - buttons[0], 1 - buttons[1], 1 - buttons[3], 1 - buttons[2]
    ];

    const result: number[] = [];
    for (let i: number = 0; i < 18; i++) {
      result.push(display[i]);
    }
    for (let i: number = 0; i < 8; i++) {
      result.push(dispButtons[i]);
    }
    return result;
  }

  static getColors(): string[] {
    return ClockImage.COLORS;
  }
}
