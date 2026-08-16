// Ported from scrambler/Clock.java (DCTimer-BLE -> HarmonyOS ArkTS)

export class Clock {
  private static turns: string[] = ['UR', 'DR', 'DL', 'UL', 'U', 'R', 'D', 'L', 'ALL'];
  private static moves: number[][] = [
    [0, 1, 1, 0, 1, 1, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0], // UR
    [0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, -1, 0, 0], // DR
    [0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1], // DL
    [1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0], // UL
    [1, 1, 1, 1, 1, 1, 0, 0, 0, -1, 0, -1, 0, 0, 0, 0, 0, 0], // U
    [0, 1, 1, 0, 1, 1, 0, 1, 1, -1, 0, 0, 0, 0, 0, -1, 0, 0], // R
    [0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, -1, 0, -1], // D
    [1, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, -1, 0, 0, 0, 0, 0, -1], // L
    [1, 1, 1, 1, 1, 1, 1, 1, 1, -1, 0, -1, 0, 0, 0, -1, 0, -1] // A
  ];
  private static movesJaap: number[][] = [
    [1, 1, 1, 1, 1, 1, 0, 0, 0, -1, 0, -1, 0, 0, 0, 0, 0, 0], // UUdd
    [0, 1, 1, 0, 1, 1, 0, 1, 1, -1, 0, 0, 0, 0, 0, -1, 0, 0], // dUdU
    [0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, -1, 0, -1], // ddUU
    [1, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, -1, 0, 0, 0, 0, 0, -1], // UdUd
    [0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, -1, -1, -1, -1, -1, -1],
    [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, -1, -1, 0, -1, -1, 0, -1, -1],
    [1, 0, 1, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, 0, 0, 0],
    [0, 0, 1, 0, 0, 0, 0, 0, 1, -1, -1, 0, -1, -1, 0, -1, -1, 0],
    [0, 1, 1, 1, 1, 1, 1, 1, 1, -1, 0, 0, 0, 0, 0, -1, 0, -1], // dUUU
    [1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 0, -1, 0, 0, 0, -1, 0, -1], // UdUU
    [1, 1, 1, 1, 1, 1, 1, 1, 0, -1, 0, -1, 0, 0, 0, 0, 0, -1], // UUUd
    [1, 1, 1, 1, 1, 1, 0, 1, 1, -1, 0, -1, 0, 0, 0, -1, 0, 0], // UUdU
    [1, 1, 1, 1, 1, 1, 1, 1, 1, -1, 0, -1, 0, 0, 0, -1, 0, -1], // UUUU
    [1, 0, 1, 0, 0, 0, 1, 0, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1] // dddd
  ];
  private static epoIdx: number[] = [12, 8, 1, 5, 11, 0, 4, 10, 3, 7, 9, 2, 6, 13];
  posit: number[] = new Array<number>(18).fill(0);
  pegs: number[] = new Array<number>(4).fill(0);

  scramble(): string {
    for (let i = 0; i < 18; i++) {
      this.posit[i] = 0;
    }
    let scramble = '';
    const positCopy: number[] = new Array<number>(18).fill(0);
    for (let x = 0; x < 9; x++) {
      let turn = Math.floor(Math.random() * 12) - 5;
      for (let j = 0; j < 18; j++) {
        positCopy[j] += turn * Clock.moves[x][j];
      }
      const clockwise = turn >= 0;
      turn = Math.abs(turn);
      scramble += Clock.turns[x] + turn + (clockwise ? '+' : '-') + ' ';
    }
    scramble += 'y2 ';
    for (let i = 0; i < 9; i++) {
      this.posit[i] = positCopy[i + 9];
      this.posit[i + 9] = positCopy[i];
    }
    for (let x = 4; x < 9; x++) {
      let turn = Math.floor(Math.random() * 12) - 5;
      for (let j = 0; j < 18; j++) {
        this.posit[j] += turn * Clock.moves[x][j];
      }
      const clockwise = (turn >= 0);
      turn = Math.abs(turn);
      scramble += Clock.turns[x] + turn + (clockwise ? '+' : '-') + ' ';
    }
    for (let j = 0; j < 18; j++) {
      this.posit[j] %= 12;
      while (this.posit[j] <= 0) {
        this.posit[j] += 12;
      }
    }
    for (let x = 0; x < 4; x++) {
      this.pegs[x] = 1;
    }
    return scramble;
  }

  scrambleJaap(concise: boolean): string {
    const seq: number[] = new Array<number>(14).fill(0);
    for (let i = 0; i < 18; i++) {
      this.posit[i] = 0;
    }
    for (let i = 0; i < 14; i++) {
      seq[i] = Math.floor(Math.random() * 12) - 5;
    }
    for (let i = 0; i < 14; i++) {
      for (let j = 0; j < 18; j++) {
        this.posit[j] += seq[i] * Clock.movesJaap[i][j];
      }
    }
    for (let j = 0; j < 18; j++) {
      this.posit[j] %= 12;
      while (this.posit[j] <= 0) {
        this.posit[j] += 12;
      }
    }
    let sb = '';
    if (concise) {
      for (let i = 0; i < 4; i++) {
        sb += '(' + seq[i] + ', ' + seq[i + 4] + ') / ';
      }
      for (let i = 8; i < 14; i++) {
        sb += '(' + seq[i] + ') / ';
      }
    } else {
      sb += 'UUdd u=' + seq[0] + ',d=' + seq[4] + ' / ';
      sb += 'dUdU u=' + seq[1] + ',d=' + seq[5] + ' / ';
      sb += 'ddUU u=' + seq[2] + ',d=' + seq[6] + ' / ';
      sb += 'UdUd u=' + seq[3] + ',d=' + seq[7] + ' / ';
      sb += 'dUUU u=' + seq[8] + ' / ';
      sb += 'UdUU u=' + seq[9] + ' / ';
      sb += 'UUUd u=' + seq[10] + ' / ';
      sb += 'UUdU u=' + seq[11] + ' / ';
      sb += 'UUUU u=' + seq[12] + ' / ';
      sb += 'dddd d=' + seq[13] + ' / ';
    }
    for (let i = 0; i < 4; i++) {
      this.pegs[i] = Math.floor(Math.random() * 2);
      if (this.pegs[i] == 0) {
        sb += 'U';
      } else {
        sb += 'd';
      }
    }
    return sb;
  }

  scrambleEpo(): string {
    const seq: number[] = new Array<number>(14).fill(0);
    for (let i = 0; i < 18; i++) {
      this.posit[i] = 0;
    }
    for (let i = 0; i < 14; i++) {
      seq[i] = Math.floor(Math.random() * 12) - 5;
    }
    for (let i = 0; i < 14; i++) {
      for (let j = 0; j < 18; j++) {
        this.posit[j] += seq[i] * Clock.movesJaap[Clock.epoIdx[i]][j];
      }
    }
    for (let j = 0; j < 18; j++) {
      this.posit[j] %= 12;
      while (this.posit[j] <= 0) {
        this.posit[j] += 12;
      }
    }
    let sb = '';
    sb += 'UUUU u=' + seq[0] + ' / ';
    sb += 'dUUU u=' + seq[1] + ' / ';
    sb += 'dUdU u=' + seq[2] + ',d=' + seq[3] + ' / ';
    sb += 'UUdU u=' + seq[4] + ' / ';
    sb += 'UUdd u=' + seq[5] + ',d=' + seq[6] + ' / ';
    sb += 'UUUd u=' + seq[7] + ' / ';
    sb += 'UdUd u=' + seq[8] + ',d=' + seq[9] + ' / ';
    sb += 'UdUU u=' + seq[10] + ' / ';
    sb += 'ddUU u=' + seq[11] + ',d=' + seq[12] + ' / ';
    sb += 'dddd d=' + seq[13] + ' / ';
    for (let i = 0; i < 4; i++) {
      this.pegs[i] = Math.floor(Math.random() * 2);
      if (this.pegs[i] == 0) {
        sb += 'U';
      } else {
        sb += 'd';
      }
    }
    return sb;
  }

  getPosit(): number[] {
    return this.posit;
  }

  getPegs(): number[] {
    return this.pegs;
  }

  image(scramble: string): number[] {
    const s = scramble.split(' ');
    this.pegs = [1, 1, 1, 1];
    const positCopy: number[] = new Array<number>(18).fill(0);
    for (let i = 0; i < s.length; i++) {
      if (s[i].length > 0) {
        if (s[i] == 'UR') {
          this.pegs[1] = 0;
        } else if (s[i] == 'DR') {
          this.pegs[3] = 0;
        } else if (s[i] == 'DL') {
          this.pegs[2] = 0;
        } else if (s[i] == 'UL') {
          this.pegs[0] = 0;
        } else if (s[i] == 'y2') {
          for (let j = 0; j < 9; j++) {
            this.posit[j] = positCopy[j + 9];
            this.posit[j + 9] = positCopy[j];
          }
          for (let j = 0; j < 18; j++) {
            positCopy[j] = this.posit[j];
          }
        } else {
          const x = this.indexOf(s[i]);
          if (x >= 0) {
            const turn = this.getTurn(s[i]);
            for (let j = 0; j < 18; j++) {
              positCopy[j] += turn * Clock.moves[x][j];
            }
          }
        }
      }
    }
    for (let j = 0; j < 18; j++) {
      this.posit[j] = positCopy[j];
    }
    return this.posit;
  }

  private indexOf(s: string): number {
    for (let i = 0; i < Clock.turns.length; i++) {
      if (s.startsWith(Clock.turns[i])) {
        return i;
      }
    }
    return -1;
  }

  private getTurn(s: string): number {
    let sb = '';
    for (let i = 0; i < s.length; i++) {
      const c = s.charCodeAt(i);
      if (c >= 0x30 && c <= 0x39) {
        sb += s.charAt(i);
      }
    }
    const turn = parseInt(sb);
    if (s.endsWith('-')) {
      return -turn;
    }
    if (s.endsWith('+')) {
      return turn;
    }
    return 0;
  }
}
