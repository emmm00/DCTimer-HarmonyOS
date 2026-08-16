// Ported from solver/Roux.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';
import { Petrus } from './Petrus';
import { Cross } from './Cross';

export class Roux {
  private static cpm: number[][] = Roux.z2d(56, 6);
  private static com: number[][] = Roux.z2d(252, 6);

  private static epm2: number[][] = Roux.z2d(504, 3);
  private static eom2: number[][] = Roux.z2d(672, 3);
  private static cpm2: number[][] = Roux.z2d(30, 3);
  private static com2: number[][] = Roux.z2d(135, 3);

  private static ed: number[] = new Array<number>(220 * 48).fill(0);
  private static cd: number[] = new Array<number>(28 * 18).fill(0);
  private static ed2: number[] = new Array<number>(84 * 48).fill(0);
  private static cd2: number[] = new Array<number>(15 * 18).fill(0);

  private static seq: number[] = new Array<number>(15).fill(0);

  private static ini1 = false;
  private static ini2 = false;

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  private static initr(): void {
    if (Roux.ini1) {
      return;
    }
    Petrus.init();
    for (let i = 0; i < 28; i++) {
      for (let j = 0; j < 9; j++) {
        for (let k = 0; k < 6; k++) {
          const d = Roux.cornmv(i, j, k);
          if (j < 2) {
            Roux.cpm[(i << 1) | j][k] = Math.floor(d / 9);
          }
          Roux.com[i * 9 + j][k] = Math.floor(d / 18) * 9 + d % 9;
        }
      }
    }

    for (let i = 0; i < 10560; i++) {
      Roux.ed[i] = -1;
    }

    Roux.ed[12 * 48] = 0;
    let c = 1;
    for (let d = 0; d < 7; d++) {
      for (let i = 0; i < 1320; i++) {
        for (let j = 0; j < 8; j++) {
          if (Roux.ed[(i << 3) | j] == d) {
            for (let l = 0; l < 6; l++) {
              let x = i;
              let y = j;
              for (let m = 0; m < 3; m++) {
                y = Petrus.eom[((Math.floor(x / 6)) << 3) | (y & 7)][l] & 7;
                x = Petrus.epm[x][l];
                if (Roux.ed[(x << 3) | y] < 0) {
                  Roux.ed[(x << 3) | y] = d + 1;
                  c++;
                }
              }
            }
          }
        }
      }
    }
    for (let i = 0; i < 504; i++) {
      Roux.cd[i] = -1;
    }
    Roux.cd[25 * 18] = 0;
    c = 1;
    for (let d = 0; d < 4; d++) {
      for (let i = 0; i < 56; i++) {
        for (let j = 0; j < 9; j++) {
          if (Roux.cd[i * 9 + j] == d) {
            for (let l = 0; l < 6; l++) {
              let x = i;
              let y = j;
              for (let m = 0; m < 3; m++) {
                y = Roux.com[Math.floor(x / 2) * 9 + y % 9][l] % 9;
                x = Roux.cpm[x][l];
                if (Roux.cd[x * 9 + y] < 0) {
                  Roux.cd[x * 9 + y] = d + 1;
                  c++;
                }
              }
            }
          }
        }
      }
    }
    Roux.ini1 = true;
  }

  private static initr2(): void {
    if (Roux.ini2) {
      return;
    }
    for (let i = 0; i < 84; i++) {
      for (let j = 0; j < 8; j++) {
        for (let k = 0; k < 3; k++) {
          const d = Roux.edgemv2(i, j, j, k);
          if (j < 6) {
            Roux.epm2[i * 6 + j][k] = d >> 3;
          }
          Roux.eom2[i * 8 + j][k] = ((Math.floor(d / 48)) << 3) | (d & 7);
        }
      }
    }
    for (let i = 0; i < 15; i++) {
      for (let j = 0; j < 9; j++) {
        for (let k = 0; k < 3; k++) {
          const d = Roux.cornmv2(i, j, k);
          if (j < 2) {
            Roux.cpm2[i * 2 + j][k] = Math.floor(d / 9);
          }
          Roux.com2[i * 9 + j][k] = Math.floor(d / 18) * 9 + d % 9;
        }
      }
    }
    for (let i = 0; i < 4032; i++) {
      Roux.ed2[i] = -1;
    }
    Roux.ed2[0] = 0;
    let c = 1;
    for (let d = 0; d < 11; d++) {
      for (let i = 0; i < 504; i++) {
        for (let j = 0; j < 8; j++) {
          if (Roux.ed2[i * 8 + j] == d) {
            for (let l = 0; l < 3; l++) {
              let x = i;
              let y = j;
              for (let m = 0; m < 3; m++) {
                y = Roux.eom2[((Math.floor(x / 6)) << 3) | (y & 7)][l] & 7;
                x = Roux.epm2[x][l];
                if (Roux.ed2[x * 8 + y] < 0) {
                  Roux.ed2[x * 8 + y] = d + 1;
                  c++;
                }
              }
            }
          }
        }
      }
    }
    for (let i = 0; i < 270; i++) {
      Roux.cd2[i] = -1;
    }
    Roux.cd2[14 * 18] = 0;
    c = 1;
    for (let d = 0; d < 7; d++) {
      for (let i = 0; i < 30; i++) {
        for (let j = 0; j < 9; j++) {
          if (Roux.cd2[i * 9 + j] == d) {
            for (let l = 0; l < 3; l++) {
              let x = i;
              let y = j;
              for (let m = 0; m < 3; m++) {
                y = Roux.com2[Math.floor(x / 2) * 9 + y % 9][l] % 9;
                x = Roux.cpm2[x][l];
                if (Roux.cd2[x * 9 + y] < 0) {
                  Roux.cd2[x * 9 + y] = d + 1;
                  c++;
                }
              }
            }
          }
        }
      }
    }
    Roux.ini2 = true;
  }

  private static cornmv(c: number, po: number, f: number): number {
    const n: number[] = new Array<number>(8).fill(0);
    const s: number[] = new Array<number>(4).fill(0);
    Roux.getCorner(n, c, po, po);
    switch (f) {
      case 0:
        Utils.circle(n, 0, 3, 2, 1); break;
      case 1:
        Utils.circle(n, 4, 5, 6, 7); break;
      case 2:
        Utils.circleOri(n, 0, 4, 7, 3, [2, 1, 2, 1]);
        break;
      case 3:
        Utils.circleOri(n, 1, 2, 6, 5, [1, 2, 1, 2]);
        break;
      case 4:
        Utils.circleOri(n, 2, 3, 7, 6, [1, 2, 1, 2]);
        break;
      case 5:
        Utils.circleOri(n, 0, 1, 5, 4, [1, 2, 1, 2]);
        break;
    }
    c = 0;
    for (let q = 2, t = 7; t >= 0; t--) {
      if (n[t] >= 0) {
        c += Utils.Cnk[t][q--];
        s[q] = n[t] >> 3;
        s[q + 2] = (n[t] & 7) % 3;
      }
    }
    return (c * 2 + s[0]) * 9 + s[2] * 3 + s[3];
  }

  private static edgemv2(c: number, p: number, o: number, f: number): number {
    const n: number[] = new Array<number>(9).fill(0);
    const s: number[] = new Array<number>(3).fill(0);
    Utils.idxToPerm(s, p, 3, false);
    let t: number;
    let q = 3;
    for (t = 0; t < 9; t++) {
      if (c >= Utils.Cnk[8 - t][q]) {
        c -= Utils.Cnk[8 - t][q--];
        n[t] = (s[q] << 1) | (o & 1);
        o >>= 1;
      } else {
        n[t] = -1;
      }
    }
    switch (f) {
      case 0: //U
        Cross.circle(n, 0, 1, 2, 3, 0); break;
      case 1: //r
        Cross.circle(n, 0, 2, 4, 5, 1);
      case 2: //R
        Cross.circle(n, 1, 6, 7, 8, 0); break;
    }
    c = 0;
    o = 0;
    q = 3;
    for (t = 0; t < 9; t++) {
      if (n[t] >= 0) {
        c += Utils.Cnk[8 - t][q--];
        s[q] = n[t] >> 1;
        o |= (n[t] & 1) << (2 - q);
      }
    }
    p = Utils.permToIdx(s, 3, false);
    return ((6 * c + p) << 3) | o;
  }

  private static cornmv2(c: number, po: number, f: number): number {
    const n: number[] = new Array<number>(6).fill(0);
    const s: number[] = new Array<number>(4).fill(0);
    s[0] = po % 2;
    s[1] = 1 - s[0];
    s[2] = Math.floor(po / 3);
    s[3] = po % 3;
    let t: number;
    let q = 2;
    for (t = 5; t >= 0; t--) {
      if (c >= Utils.Cnk[t][q]) {
        c -= Utils.Cnk[t][q--];
        n[t] = (s[q] << 3) | s[q + 2];
      } else {
        n[t] = -3;
      }
    }
    switch (f) {
      case 0: //U
        Utils.circle(n, 0, 3, 2, 1);
        break;
      case 1: //r
      case 2: //R
        Utils.circleOri(n, 1, 2, 4, 5, [1, 2, 1, 2]);
        break;
    }
    c = 0;
    q = 2;
    for (t = 5; t >= 0; t--) {
      if (n[t] >= 0) {
        c += Utils.Cnk[t][q--];
        s[q] = n[t] >> 3;
        s[q + 2] = (n[t] & 7) % 3;
      }
    }
    return (c * 2 + s[0]) * 9 + (s[2] * 3 + s[3]);
  }

  private static idaRoux1(cp: number, co: number, ep: number, eo: number, depth: number, lm: number): boolean {
    if (depth == 0) {
      return cp == 50 && co == 225 && ep == 72 && eo == 96;
    }
    if (Roux.ed[(ep << 3) | (eo & 7)] > depth || Roux.cd[cp * 9 + co % 9] > depth) {
      return false;
    }
    for (let i = 0; i < 6; i++) {
      if (i != lm) {
        for (let d = cp, w = co, y = ep, s = eo, j = 0; j < 3; j++) {
          d = Roux.cpm[d][i];
          w = Roux.com[w][i];
          y = Petrus.epm[y][i];
          s = Petrus.eom[s][i];
          if (Roux.idaRoux1(d, w, y, s, depth - 1, i)) {
            Roux.seq[depth] = i * 3 + j;
            return true;
          }
        }
      }
    }
    return false;
  }

  private static idaRoux2(cp: number, co: number, ep: number, eo: number, depth: number, lm: number): boolean {
    if (depth == 0) {
      return cp == 0 && co == 0 && ep == 28 && eo == 126;
    }
    if (Roux.ed2[(ep << 3) | (eo & 7)] > depth || Roux.cd2[cp * 9 + co % 9] > depth) {
      return false;
    }
    for (let i = 0; i < 3; i++) {
      if (i != lm) {
        let p = cp;
        let q = co;
        let r = ep;
        let s = eo;
        for (let j = 0; j < 3; j++) {
          p = Roux.cpm2[p][i];
          q = Roux.com2[q][i];
          r = Roux.epm2[r][i];
          s = Roux.eom2[s][i];
          if (Roux.idaRoux2(p, q, r, s, depth - 1, i)) {
            Roux.seq[depth] = i * 3 + j;
            return true;
          }
        }
      }
    }
    return false;
  }

  private static moveIdx: string[][] = [
    ['UDLRFB', 'DULRBF', 'BFLRUD', 'FBLRDU'],
    ['UDFBRL', 'DUFBLR', 'LRFBUD', 'RLFBDU'],
    ['DURLFB', 'UDRLBF', 'BFRLDU', 'FBRLUD'],
    ['UDBFLR', 'DUBFRL', 'RLBFUD', 'LRBFDU']
  ];

  private static sideStr: string[] = ['LU', 'LD', 'FU', 'FD', 'RU', 'RD', 'BU', 'BD'];
  private static rotateIdx: string[] = ['', 'y', 'z2', "y'"];
  private static rotateIdx2: string[] = ['', ' x2', " x'", ' x'];
  private static scp: number[] = [50, 7, 49, 12];
  private static sco: number[] = [225, 27, 221, 61];
  private static sep: number[] = [72, 518, 580, 575];
  private static seo: number[] = [96, 688, 768, 760];
  private static oriIdx: number[][] = [[1, 0, 2, 3], [0, 1, 3, 2], [2, 3, 0, 1], [3, 2, 1, 0]];

  private static roux1(scramble: string, side: number, solveS2: boolean): string {
    const s = scramble.split(' ');
    const cp: number[] = new Array<number>(4).fill(0);
    const co: number[] = new Array<number>(4).fill(0);
    const ep: number[] = new Array<number>(4).fill(0);
    const eo: number[] = new Array<number>(4).fill(0);
    for (let i = 0; i < 4; i++) {
      cp[i] = Roux.scp[Roux.oriIdx[side % 2][i]];
      co[i] = Roux.sco[Roux.oriIdx[side % 2][i]];
      ep[i] = Roux.sep[Roux.oriIdx[side % 2][i]];
      eo[i] = Roux.seo[Roux.oriIdx[side % 2][i]];
    }
    for (let d = 0; d < s.length; d++) {
      if (s[d].length > 0) {
        for (let i = 0; i < 4; i++) {
          const m = Roux.moveIdx[Math.floor(side / 2)][i].indexOf(s[d].charAt(0));
          cp[i] = Roux.cpm[cp[i]][m];
          co[i] = Roux.com[co[i]][m];
          ep[i] = Petrus.epm[ep[i]][m];
          eo[i] = Petrus.eom[eo[i]][m];
          if (s[d].length > 1) {
            cp[i] = Roux.cpm[cp[i]][m];
            co[i] = Roux.com[co[i]][m];
            ep[i] = Petrus.epm[ep[i]][m];
            eo[i] = Petrus.eom[eo[i]][m];
            if (s[d].charAt(1) == "'") {
              cp[i] = Roux.cpm[cp[i]][m];
              co[i] = Roux.com[co[i]][m];
              ep[i] = Petrus.epm[ep[i]][m];
              eo[i] = Petrus.eom[eo[i]][m];
            }
          }
        }
      }
    }
    for (let d = 0; d < 10; d++) {
      for (let idx = 0; idx < 4; idx++) {
        if (Roux.idaRoux1(cp[idx], co[idx], ep[idx], eo[idx], d, -1)) {
          let sb = '\n';
          sb += Roux.sideStr[side] + ': ' + Roux.rotateIdx[Math.floor(side / 2)] + Roux.rotateIdx2[idx];
          for (let i = d; i > 0; i--) {
            sb += ' ' + Utils.turn[Math.floor(Roux.seq[i] / 3)] + Utils.suff[Roux.seq[i] % 3];
          }
          if (solveS2) {
            const s1: number[] = Roux.seq.slice(0, d + 1);
            s1[0] = Math.floor(side / 2) * 4 + idx;
            sb += Roux.roux2(scramble, s1);
          }
          return sb;
        }
      }
    }
    return '\nerror';
  }

  private static getEdge(n: number[], c: number, p: number, o: number): void {
    const s: number[] = new Array<number>(3).fill(0);
    Utils.idxToPerm(s, p, 3, false);
    let t: number;
    let q = 3;
    for (t = 0; t < 12; t++) {
      if (c >= Utils.Cnk[11 - t][q]) {
        c -= Utils.Cnk[11 - t][q--];
        n[t] = (s[q] << 1) | (o & 1);
        o >>= 1;
      } else {
        n[t] = -1;
      }
    }
  }

  private static getCorner(n: number[], c: number, p: number, o: number): void {
    const s: number[] = new Array<number>(4).fill(0);
    s[0] = p % 2;
    s[1] = 1 - s[0];
    s[2] = Math.floor(o / 3);
    s[3] = o % 3;
    let q = 2;
    let t: number;
    for (t = 7; t >= 0; t--) {
      if (c >= Utils.Cnk[t][q]) {
        c -= Utils.Cnk[t][q--];
        n[t] = (s[q] << 3) | s[q + 2];
      } else {
        n[t] = -3;
      }
    }
  }

  private static roux2(scramble: string, s1: number[]): string {
    const s = scramble.split(' ');
    for (let d = 0; d < s.length; d++) {
      if (s[d].length > 0) {
        const m = 'URFDLB'.indexOf(s[d].charAt(0));
      }
    }
    if (s1[0] > 0) {
    }
    for (let i = s1.length - 1; i > 0; i--) {
    }
    return '\nerror';
  }

  public static solveRoux1(scramble: string, face: number): string {
    Roux.initr();
    let s = '\n';
    for (let i = 0; i < 8; i++) {
      if (((face >> i) & 1) != 0) {
        s += Roux.roux1(scramble, i, false);
      }
    }
    return s;
  }
}
