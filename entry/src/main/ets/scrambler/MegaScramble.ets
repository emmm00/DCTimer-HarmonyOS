// Ported from scrambler/MegaScramble.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Scrambler } from './Scrambler';

export class MegaScramble {
  private static rndEl(x: string[]): string {
    return x[Math.floor(Math.random() * x.length)];
  }

  static edgescramble(start: string, end: string[], moves: string[], scrambleLen: number): string {
    let u = 0;
    let d = 0;
    const movemis: number[] = new Array<number>(moves.length).fill(0);
    const triggers: string[][] = [["R", "R'"], ["R'", 'R'], ['L', "L'"], ["L'", 'L'], ["F'", 'F'], ['F', "F'"], ['B', "B'"], ["B'", 'B']];
    const ud: string[] = ['U', 'D'];
    let sb = start;
    for (let i = 0; i < moves.length; i++) {
      movemis[i] = 0;
    }
    for (let i = 0; i < scrambleLen; i++) {
      let done = false;
      let s = '';
      while (!done) {
        s = '';
        for (let j = 0; j < moves.length; j++) {
          const x = Math.floor(Math.random() * 4);
          movemis[j] += x;
          if (x != 0) {
            done = true;
            s += ' ' + moves[j] + Scrambler.cubesuff[x - 1];
          }
        }
      }
      sb += s;
      const trigger = Math.floor(Math.random() * 8);
      const layer = Math.floor(Math.random() * 2);
      const turn = Math.floor(Math.random() * 3);
      sb += ' ' + triggers[trigger][0] + ' ' + ud[layer] + Scrambler.cubesuff[turn] + ' ' + triggers[trigger][1];
      if (layer == 0) {
        u += turn + 1;
      }
      if (layer == 1) {
        d += turn + 1;
      }
    }
    for (let i = 0; i < moves.length; i++) {
      const x = 4 - (movemis[i] % 4);
      if (x < 4) {
        sb += ' ' + moves[i] + Scrambler.cubesuff[x - 1];
      }
    }
    u = 4 - (u % 4);
    d = 4 - (d % 4);
    if (u < 4) {
      sb += ' U' + Scrambler.cubesuff[u - 1];
    }
    if (d < 4) {
      sb += ' D' + Scrambler.cubesuff[d - 1];
    }
    sb += ' ' + MegaScramble.rndEl(end);
    return sb;
  }

  static megascramble(turns: string[][], suffixes: string[] | null, len: number, separator: string): string {
    const donemoves: number[] = new Array<number>(turns[0].length).fill(0);
    let lastaxis = -1;
    let scr = '';
    for (let j = 0; j < len; j++) {
      let done = 0;
      do {
        const first = Math.floor(Math.random() * turns.length);
        const second = Math.floor(Math.random() * turns[first].length);
        if (first != lastaxis || donemoves[second] == 0) {
          if (j != 0) {
            scr += separator;
          }
          if (first == lastaxis) {
            donemoves[second] = 1;
            if (suffixes == null) {
              scr += turns[first][second];
            } else {
              scr += turns[first][second] + MegaScramble.rndEl(suffixes);
            }
          } else {
            for (let k = 0; k < turns[first].length; k++) {
              donemoves[k] = 0;
            }
            lastaxis = first;
            donemoves[second] = 1;
            if (suffixes == null) {
              scr += turns[first][second];
            } else {
              scr += turns[first][second] + MegaScramble.rndEl(suffixes);
            }
          }
          done = 1;
        }
      } while (done == 0);
    }
    return scr;
  }

  static megascramble2(turns: string[][], suffixes: string[] | null, len: number): string {
    return MegaScramble.megascramble(turns, suffixes, len, ' ');
  }

  static megascramble3(turns: string[][][], suffixes: string[] | null, scrambleLen: number): string {
    const donemoves: number[] = new Array<number>(turns[0].length).fill(0);
    let lastaxis = -1;
    let scr = '';
    for (let j = 0; j < scrambleLen; j++) {
      let done = 0;
      do {
        const first = Math.floor(Math.random() * turns.length);
        const second = Math.floor(Math.random() * turns[first].length);
        if (first != lastaxis) {
          for (let k = 0; k < turns[first].length; k++) {
            donemoves[k] = 0;
          }
          lastaxis = first;
        }
        if (donemoves[second] == 0) {
          donemoves[second] = 1;
          if (suffixes == null) {
            scr += MegaScramble.rndEl(turns[first][second]) + ' ';
          } else {
            scr += MegaScramble.rndEl(turns[first][second]) + MegaScramble.rndEl(suffixes) + ' ';
          }
          done = 1;
        }
      } while (done == 0);
    }
    return scr;
  }

  static helicubescramble(scrambleLen: number): string {
    const faces: string[] = ['UF', 'UR', 'UB', 'UL', 'FR', 'BR', 'BL', 'FL', 'DF', 'DR', 'DB', 'DL'];
    const used: number[] = new Array<number>(12).fill(0);
    const adj: string[] = ['010110010000', '101011000000', '010101100000', '101000110000', '110000001100', '011000000110', '001100000011', '100100001001', '000010010101', '000011001010', '000001100101', '000000111010'];
    let sb = '';
    for (let j = 0; j < 12; j++) {
      used[j] = 0;
    }
    for (let j = 0; j < scrambleLen; j++) {
      let done = false;
      do {
        const face = Math.floor(Math.random() * 12);
        if (used[face] == 0) {
          sb += faces[face] + ' ';
          for (let k = 0; k < 12; k++) {
            if (adj[face].charAt(k) == '1') {
              used[k] = 0;
            }
          }
          used[face] = 1;
          done = true;
        }
      } while (!done);
    }
    return sb;
  }

  static rediScramble(suff: string[], scrambleLen: number): string {
    let sb = '';
    for (let i = 0; i < scrambleLen; i++) {
      if (i != 0) {
        sb += 'x ';
      }
      sb += MegaScramble.megascramble2([['R'], ['L']], suff, 3 + Math.floor(Math.random() * 3));
    }
    return sb;
  }

  static gigascramble(scrambleLen: number): string {
    const El: string[] = ['+', '++', '-', '--'];
    const minxsuff: string[] = ['', '2', "'", "2'"];
    let sb = '';
    for (let i = 0; i < Math.ceil(scrambleLen / 10.0); i++) {
      for (let j = 0; j < 10; j++) {
        sb += (j % 2 == 0 ? (Math.random() > 0.5 ? 'R' : 'r') : (Math.random() > 0.5 ? 'D' : 'd')) + MegaScramble.rndEl(El) + ' ';
      }
      sb += 'y' + MegaScramble.rndEl(minxsuff) + ' ';
    }
    return sb;
  }

  static ssq1tScramble(scrambleLen: number): string {
    const seq: number[][][] = [];
    seq.push(MegaScramble.z2d3(scrambleLen * 2));
    seq.push(MegaScramble.z2d3(scrambleLen * 2));
    MegaScramble.sq1Getseq(seq, 0, scrambleLen);
    const s = seq[0];
    const t = seq[1];
    let u = '';
    if (s[0][0] == 7) {
      for (let i = 0; i < scrambleLen; i++) {
        s[i * 2][0] = s[i * 2 + 1][0];
        s[i * 2][1] = s[i * 2 + 1][1];
      }
    }
    if (t[0][0] == 7) {
      for (let i = 0; i < scrambleLen; i++) {
        t[i * 2][0] = t[i * 2 + 1][0];
        t[i * 2][1] = t[i * 2 + 1][1];
      }
    }
    for (let i = 0; i < scrambleLen; i++) {
      u += '(' + s[2 * i][0] + ',' + t[2 * i][0] + ',' + t[2 * i][1] + ',' + s[2 * i][1] + ') / ';
    }
    return u;
  }

  private static z2d3(n: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < n; i++) {
      a.push([0, 0]);
    }
    return a;
  }

  private static sq1Getseq(seq: number[][][], type: number, scrambleLen: number): void {
    for (let n = 0; n < seq.length; n++) {
      const p: number[] = [1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0];
      let cnt = 0;
      let seql = 0;
      while (cnt < scrambleLen) {
        const x = Math.floor(Math.random() * 12) - 5;
        const y = (type == 2) ? 0 : Math.floor(Math.random() * 12) - 5;
        const size = (x == 0 ? 0 : 1) + (y == 0 ? 0 : 1);
        if ((cnt + size <= scrambleLen || type != 1) && (size > 0 || cnt == 0)) {
          if (MegaScramble.sq1Domove(p, x, y)) {
            if (type == 1) {
              cnt += size;
            }
            if (size > 0) {
              seq[n][seql++] = [x, y];
            }
            if (cnt < scrambleLen) {
              cnt++;
              seq[n][seql++] = [7, 0];
              MegaScramble.sq1Domove(p, 7, 0);
            }
          }
        }
      }
    }
  }

  private static sq1Domove(p: number[], x: number, y: number): boolean {
    let temp: number;
    if (x == 7) {
      for (let i = 0; i < 6; i++) {
        temp = p[i + 6];
        p[i + 6] = p[i + 12];
        p[i + 12] = temp;
      }
      return true;
    } else {
      if (p[(17 - x) % 12] != 0 || p[(11 - x) % 12] != 0 || p[12 + ((17 - y) % 12)] != 0 || p[12 + ((11 - y) % 12)] != 0) {
        return false;
      } else {
        const px: number[] = new Array<number>(12).fill(0);
        const py: number[] = new Array<number>(12).fill(0);
        for (let j = 0; j < 12; j++) {
          px[j] = p[j];
        }
        for (let j = 12; j < 24; j++) {
          py[j - 12] = p[j];
        }
        for (let i = 0; i < 12; i++) {
          p[i] = px[(12 + i - x) % 12];
          p[i + 12] = py[(12 + i - y) % 12];
        }
        return true;
      }
    }
  }

  static yj4x4(scrambleLen: number): string {
    const turns: string[][] = [['U', 'D'], ['R', 'L', 'r'], ['F', 'B', 'f']];
    const donemoves: number[] = new Array<number>(3).fill(0);
    let lastaxis = -1;
    let fpos = 0;
    let s = '';
    for (let j = 0; j < scrambleLen; j++) {
      let done = 0;
      do {
        const first = Math.floor(Math.random() * turns.length);
        const second = Math.floor(Math.random() * turns[first].length);
        if (first != lastaxis || donemoves[second] == 0) {
          if (first == lastaxis) {
            donemoves[second] = 1;
            const rs = Math.floor(Math.random() * 3);
            if (first == 0 && second == 0) {
              fpos = (fpos + 4 + rs) % 4;
            }
            if (first == 1 && second == 2) { // r or l
              if (fpos == 0 || fpos == 3) {
                s += 'l' + Scrambler.cubesuff[rs] + ' ';
              } else {
                s += 'r' + Scrambler.cubesuff[rs] + ' ';
              }
            } else if (first == 2 && second == 2) { // f or b
              if (fpos == 0 || fpos == 1) {
                s += 'b' + Scrambler.cubesuff[rs] + ' ';
              } else {
                s += 'f' + Scrambler.cubesuff[rs] + ' ';
              }
            } else {
              s += turns[first][second] + Scrambler.cubesuff[rs] + ' ';
            }
          } else {
            for (let k = 0; k < turns[first].length; k++) {
              donemoves[k] = 0;
            }
            lastaxis = first;
            donemoves[second] = 1;
            const rs = Math.floor(Math.random() * Scrambler.cubesuff.length);
            if (first == 0 && second == 0) {
              fpos = (fpos + 4 + rs) % 4;
            }
            if (first == 1 && second == 2) { // r or l
              if (fpos == 0 || fpos == 3) {
                s += 'l' + Scrambler.cubesuff[rs] + ' ';
              } else {
                s += 'r' + Scrambler.cubesuff[rs] + ' ';
              }
            } else if (first == 2 && second == 2) { // f or b
              if (fpos == 0 || fpos == 1) {
                s += 'b' + Scrambler.cubesuff[rs] + ' ';
              } else {
                s += 'f' + Scrambler.cubesuff[rs] + ' ';
              }
            } else {
              s += turns[first][second] + Scrambler.cubesuff[rs] + ' ';
            }
          }
          done = 1;
        }
      } while (done == 0);
    }
    return s;
  }

  static oldminxscramble(scrambleLen: number): string {
    const minxsuff: string[] = ['', '2', "2'", "'"];
    const faces: string[] = ['F', 'B', 'U', 'D', 'L', 'DBR', 'DL', 'BR', 'DR', 'BL', 'R', 'DBL'];
    const used: number[] = new Array<number>(12).fill(0);
    const adj: string[] = ['001010101010', '000101010101', '100010010110', '010001101001', '101000100101', '010100011010', '100110001001', '011001000110', '100101100010', '011010010001', '101001011000', '010110100100'];
    let s = '';
    for (let j = 0; j < 12; j++) {
      used[j] = 0;
    }
    for (let j = 0; j < scrambleLen; j++) {
      let done = false;
      do {
        const face = Math.floor(Math.random() * 12);
        if (used[face] == 0) {
          s += faces[face] + MegaScramble.rndEl(minxsuff) + ' ';
          for (let k = 0; k < 12; k++) {
            if (adj[face].charAt(k) == '1') {
              used[k] = 0;
            }
          }
          used[face] = 1;
          done = true;
        }
      } while (!done);
    }
    return s;
  }

  static sq1Scramble(type: number, scrambleLen: number): string {
    const seq: number[][][] = [MegaScramble.z2d3(scrambleLen * 2)];
    MegaScramble.sq1Getseq(seq, type, scrambleLen);
    let s = '';
    for (let i = 0; i < seq[0].length; i++) {
      const k = seq[0][i];
      if (k[0] == 7) {
        s += '/ ';
      } else {
        s += '(' + k[0] + ',' + k[1] + ') ';
      }
    }
    return s;
  }

  static do15puzzle(mirrored: boolean, scrambleLen: number): string {
    let moves: string[];
    if (mirrored) {
      moves = ['U', 'L', 'R', 'D'];
    } else {
      moves = ['D', 'R', 'L', 'U'];
    }
    const effect: number[][] = [[0, -1], [1, 0], [-1, 0], [0, 1]];
    let x = 0;
    let y = 3;
    let lastm = 5;
    let s = '';
    for (let k = 0; k < scrambleLen; k++) {
      let done = false;
      while (!done) {
        const m = Math.floor(Math.random() * 4);
        if (x + effect[m][0] >= 0 && x + effect[m][0] <= 3 && y + effect[m][1] >= 0 && y + effect[m][1] <= 3 &&
          m + lastm != 3) {
          done = true;
          x += effect[m][0];
          y += effect[m][1];
          s += moves[m] + ' ';
          lastm = m;
        }
      }
    }
    return s;
  }

  private static d: number[][] = [[0, 1, 2, 5, 8, 7, 6, 3, 4], [6, 7, 8, 13, 20, 19, 18, 11, 12], [0, 3, 6, 11, 18, 17, 16, 9, 10], [8, 5, 2, 15, 22, 21, 20, 13, 14]];
  private static start: number[] = [1, 1, 2, 3, 3, 2, 4, 4, 0, 5, 6, 7, 8, 9, 10, 10, 5, 6, 7, 8, 9, 11, 11];
  private static move: string[] = ['U', 'F', 'L', 'R'];

  private static biCanMove(face: number): boolean {
    const u: number[] = new Array<number>(8).fill(0);
    let ulen = 0;
    let z = 0;
    for (let i = 0; i < 9; i++) {
      let done = 0;
      for (let j = 0; j < ulen; j++) {
        if (u[j] == MegaScramble.start[MegaScramble.d[face][i]]) {
          done = 1;
        }
      }
      if (done == 0) {
        u[ulen++] = MegaScramble.start[MegaScramble.d[face][i]];
        if (MegaScramble.start[MegaScramble.d[face][i]] == 0) {
          z = 1;
        }
      }
    }
    return (ulen == 5 && z == 1);
  }

  private static biDoMove(face: number, amount: number): void {
    for (let i = 0; i < amount; i++) {
      let t = MegaScramble.start[MegaScramble.d[face][0]];
      MegaScramble.start[MegaScramble.d[face][0]] = MegaScramble.start[MegaScramble.d[face][6]];
      MegaScramble.start[MegaScramble.d[face][6]] = MegaScramble.start[MegaScramble.d[face][4]];
      MegaScramble.start[MegaScramble.d[face][4]] = MegaScramble.start[MegaScramble.d[face][2]];
      MegaScramble.start[MegaScramble.d[face][2]] = t;
      t = MegaScramble.start[MegaScramble.d[face][7]];
      MegaScramble.start[MegaScramble.d[face][7]] = MegaScramble.start[MegaScramble.d[face][5]];
      MegaScramble.start[MegaScramble.d[face][5]] = MegaScramble.start[MegaScramble.d[face][3]];
      MegaScramble.start[MegaScramble.d[face][3]] = MegaScramble.start[MegaScramble.d[face][1]];
      MegaScramble.start[MegaScramble.d[face][1]] = t;
    }
  }

  static bicube(scrambleLen: number): string {
    let sb = '';
    const arr: number[][] = [];
    let arrlen = 0;
    let x = 0;
    let y = 0;
    while (arrlen < scrambleLen) {
      const poss: number[] = [1, 1, 1, 1];
      for (let j = 0; j < 4; j++) {
        if (poss[j] == 1 && !MegaScramble.biCanMove(j)) {
          poss[j] = 0;
        }
      }
      let done = 0;
      while (done == 0) {
        x = Math.floor(Math.random() * 4);
        if (poss[x] == 1) {
          y = Math.floor(Math.random() * 3) + 1;
          MegaScramble.biDoMove(x, y);
          done = 1;
        }
      }
      arr.push([x, y]);
      arrlen++;
      if (arrlen >= 2) {
        if (arr[arrlen - 1][0] == arr[arrlen - 2][0]) {
          arr[arrlen - 2][1] = (arr[arrlen - 2][1] + arr[arrlen - 1][1]) % 4;
          arr.pop();
          arrlen--;
        }
      }
      if (arrlen >= 1) {
        if (arr[arrlen - 1][1] == 0) {
          arr.pop();
          arrlen--;
        }
      }
    }
    for (let i = 0; i < scrambleLen; i++) {
      sb += MegaScramble.move[arr[i][0]] + Scrambler.cubesuff[arr[i][1] - 1] + ' ';
    }
    return sb;
  }
}
