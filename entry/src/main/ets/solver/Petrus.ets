// Ported from solver/Petrus.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';
import { Cross } from './Cross';

export class Petrus {
  static epm: number[][] = Petrus.z2d(1320, 6);
  static eom: number[][] = Petrus.z2d(1760, 6);
  private static com: number[][] = Petrus.z2d(24, 6);
  private static epm2: number[][] = Petrus.z2d(132, 6);
  private static eom2: number[][] = Petrus.z2d(264, 6);

  private static epd: number[] = new Array<number>(1320).fill(0);
  private static eod: number[] = new Array<number>(1760).fill(0);
  private static ed2: number[] = new Array<number>(528).fill(0);

  private static moves2: number[] = [0, 3, 4];

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  private static edgemv(c: number, po: number, k: number, f: number): number {
    const n: number[] = new Array<number>(12).fill(0);
    const s: number[] = new Array<number>(3).fill(0);
    Utils.idxToPerm(s, po, k, false);
    let t: number;
    let q = k;
    for (t = 0; t < 12; t++) {
      if (c >= Utils.Cnk[11 - t][q]) {
        c -= Utils.Cnk[11 - t][q--];
        n[t] = (s[q] << 1) | (po & 1);
        po >>= 1;
      } else {
        n[t] = -1;
      }
    }
    Cross.edgemv(n, f);
    c = 0;
    po = 0;
    q = k;
    for (t = 0; t < 12; t++) {
      if (n[t] >= 0) {
        c += Utils.Cnk[11 - t][q--];
        s[q] = n[t] >> 1;
        po |= (n[t] & 1) << (k - 1 - q);
      }
    }
    const p = Utils.permToIdx(s, k, false);
    return ((Utils.fact[k] * c + p) << 3) | po;
  }

  private static ini = false;

  public static init(): void {
    if (Petrus.ini) {
      return;
    }
    for (let i = 0; i < 220; i++) {
      for (let j = 0; j < 8; j++) {
        for (let k = 0; k < 6; k++) {
          const d = Petrus.edgemv(i, j, 3, k);
          if (j < 6) {
            Petrus.epm[i * 6 + j][k] = d >> 3;
          }
          Petrus.eom[i * 8 + j][k] = ((Math.floor(d / 48)) << 3) | (d & 7);
        }
      }
    }
    Petrus.ini = true;
  }

  private static inip1 = false;

  private static initp1(): void {
    if (Petrus.inip1) {
      return;
    }
    Petrus.init();
    const p: number[][] = [
      [1, 0, 3, 0, 0, 4], [2, 1, 1, 5, 1, 0], [3, 2, 2, 1, 6, 2], [0, 3, 7, 3, 2, 3],
      [4, 7, 0, 4, 4, 5], [5, 4, 5, 6, 5, 1], [6, 5, 6, 2, 7, 6], [7, 6, 4, 7, 3, 7]
    ];
    const o: number[][] = [
      [0, 0, 1, 0, 0, 2], [0, 0, 0, 2, 0, 1], [0, 0, 0, 1, 2, 0], [0, 0, 2, 0, 1, 0],
      [0, 0, 2, 0, 0, 1], [0, 0, 0, 1, 0, 2], [0, 0, 0, 2, 1, 0], [0, 0, 1, 0, 2, 0]
    ];
    for (let i = 0; i < 8; i++) {
      for (let j = 0; j < 3; j++) {
        for (let k = 0; k < 6; k++) {
          Petrus.com[i * 3 + j][k] = p[i][k] * 3 + (o[i][k] + j) % 3;
        }
      }
    }
    for (let i = 0; i < 1320; i++) {
      Petrus.epd[i] = -1;
    }
    Petrus.epd[17 * 6] = 0;
    Utils.createPrun(Petrus.epd, 5, Petrus.epm, 3);
    for (let i = 0; i < 1760; i++) {
      Petrus.eod[i] = -1;
    }
    Petrus.eod[17 * 8] = 0;
    Utils.createPrun(Petrus.eod, 5, Petrus.eom, 3);
    Petrus.inip1 = true;
  }

  private static inip2 = false;

  private static initp2(): void {
    if (Petrus.inip2) {
      return;
    }
    for (let i = 0; i < 66; i++) {
      for (let j = 0; j < 4; j++) {
        for (let k = 0; k < 6; k++) {
          const d = Petrus.edgemv(i, j, 2, k);
          if (j < 2) {
            Petrus.epm2[i * 2 + j][k] = d >> 3;
          }
          Petrus.eom2[i * 4 + j][k] = ((Math.floor(d / 16)) << 2) | (d & 3);
        }
      }
    }
    for (let i = 0; i < 528; i++) {
      Petrus.ed2[i] = -1;
    }
    Petrus.ed2[44 * 8] = 0;
    Petrus.ed2[21 * 8] = 0;
    Petrus.ed2[17 * 8] = 0;
    let c = 3;
    for (let d = 0; d < 6; d++) {
      for (let i = 0; i < 132; i++) {
        for (let j = 0; j < 4; j++) {
          if (Petrus.ed2[i * 4 + j] == d) {
            for (let l = 0; l < 3; l++) {
              let x = i;
              let y = j;
              for (let m = 0; m < 3; m++) {
                y = Petrus.eom2[((Math.floor(x / 2)) << 2) | (y & 3)][Petrus.moves2[l]] & 3;
                x = Petrus.epm2[x][Petrus.moves2[l]];
                if (Petrus.ed2[x * 4 + y] < 0) {
                  Petrus.ed2[x * 4 + y] = d + 1;
                  c++;
                }
              }
            }
          }
        }
      }
    }
    Petrus.inip2 = true;
  }

  private static seq: number[] = new Array<number>(10).fill(0);

  private static idaPetrus1(co: number, ep: number, eo: number, depth: number, lm: number,
    block: number): boolean {
    if (depth == 0) {
      return co == 12 && ep == 102 && eo == 136;
    }
    if (Petrus.epd[ep] > depth || Petrus.eod[eo] > depth) {
      return false;
    }
    for (let i = 0; i < 6; i++) {
      if (i != lm) {
        let w = co;
        let y = ep;
        let s = eo;
        for (let j = 0; j < 3; j++) {
          w = Petrus.com[w][i];
          y = Petrus.epm[y][i];
          s = Petrus.eom[s][i];
          if (Petrus.idaPetrus1(w, y, s, depth - 1, i, block)) {
            Petrus.seq[depth] = i * 3 + j;
            return true;
          }
        }
      }
    }
    return false;
  }

  private static solvedEp: number[] = [88, 42, 34];
  private static solvedEo: number[] = [176, 84, 68];
  private static solvedCo: number[] = [0, 15, 21];

  private static idaPetrus2(co: number, ep: number, eo: number, depth: number, lm: number,
    idx: number): boolean {
    if (depth == 0) {
      return ep == Petrus.solvedEp[idx] && eo == Petrus.solvedEo[idx] && co == Petrus.solvedCo[idx];
    }
    if (Petrus.ed2[(ep << 2) | (eo & 3)] > depth) {
      return false;
    }
    for (let i = 0; i < 3; i++) {
      if (i != lm) {
        let x = co;
        let y = ep;
        let s = eo;
        for (let j = 0; j < 3; j++) {
          x = Petrus.com[x][Petrus.moves2[i]];
          y = Petrus.epm2[y][Petrus.moves2[i]];
          s = Petrus.eom2[s][Petrus.moves2[i]];
          if (Petrus.idaPetrus2(x, y, s, depth - 1, i, idx)) {
            Petrus.seq[depth] = Petrus.moves2[i] * 3 + j;
            return true;
          }
        }
      }
    }
    return false;
  }

  private static moveIdx: string[] = ['DULRBF', 'FBLRDU', 'DUFBLR', 'DURLFB',
    'UDFBRL', 'UDLRFB', 'UDRLBF', 'UDBFLR'];
  private static blks: string[] = ['ULF:', 'ULB:', 'URF:', 'URB:', 'DLF:', 'DLB:', 'DRF:', 'DRB:'];

  private static petrus1(scramble: string, block: number, solveS2: boolean): string {
    const s = scramble.split(' ');
    let co = 12;
    let ep = 102;
    let eo = 136;
    for (let d = 0; d < s.length; d++) {
      if (0 != s[d].length) {
        const o = Petrus.moveIdx[block].indexOf(s[d].charAt(0));
        co = Petrus.com[co][o];
        ep = Petrus.epm[ep][o];
        eo = Petrus.eom[eo][o];
        if (s[d].length > 1) {
          co = Petrus.com[co][o];
          eo = Petrus.eom[eo][o];
          ep = Petrus.epm[ep][o];
          if (s[d].charAt(1) == "'") {
            co = Petrus.com[co][o];
            eo = Petrus.eom[eo][o];
            ep = Petrus.epm[ep][o];
          }
        }
      }
    }
    for (let d = 0; d < 9; d++) {
      if (Petrus.idaPetrus1(co, ep, eo, d, -1, block)) {
        let sb = '\n';
        sb += Petrus.blks[block];
        for (let i = d; i > 0; i--) {
          sb += ' ' + Petrus.moveIdx[block].charAt(Math.floor(Petrus.seq[i] / 3)) + Utils.suff[Petrus.seq[i] % 3];
        }
        if (solveS2) {
          sb += Petrus.petrus2(s, block, d);
        }
        return sb;
      }
    }
    return '\nerror';
  }

  static petrus2(s: string[], block: number, d: number): string {
    const co2: number[] = new Array<number>(3).fill(0);
    const ep2: number[] = new Array<number>(3).fill(0);
    const eo2: number[] = new Array<number>(3).fill(0);
    for (let i = 0; i < 3; i++) {
      co2[i] = Petrus.solvedCo[i];
      ep2[i] = Petrus.solvedEp[i];
      eo2[i] = Petrus.solvedEo[i];
    }
    for (let i = 0; i < s.length; i++) {
      if (s[i].length > 0) {
        const o = Petrus.moveIdx[block].indexOf(s[i].charAt(0));
        for (let j = 0; j < 3; j++) {
          co2[j] = Petrus.com[co2[j]][o];
          ep2[j] = Petrus.epm2[ep2[j]][o];
          eo2[j] = Petrus.eom2[eo2[j]][o];
          if (s[i].length > 1) {
            co2[j] = Petrus.com[co2[j]][o];
            ep2[j] = Petrus.epm2[ep2[j]][o];
            eo2[j] = Petrus.eom2[eo2[j]][o];
            if (s[i].charAt(1) == "'") {
              co2[j] = Petrus.com[co2[j]][o];
              ep2[j] = Petrus.epm2[ep2[j]][o];
              eo2[j] = Petrus.eom2[eo2[j]][o];
            }
          }
        }
      }
    }
    for (let i = d; i > 0; i--) {
      const m = Math.floor(Petrus.seq[i] / 3);
      const n = Petrus.seq[i] % 3;
      for (let j = 0; j < 3; j++) {
        for (let k = 0; k <= n; k++) {
          co2[j] = Petrus.com[co2[j]][m];
          ep2[j] = Petrus.epm2[ep2[j]][m];
          eo2[j] = Petrus.eom2[eo2[j]][m];
        }
      }
    }
    for (let l = 0; l < 10; l++) {
      for (let idx = 0; idx < 3; idx++) {
        if (Petrus.idaPetrus2(co2[idx], ep2[idx], eo2[idx], l, -1, idx)) {
          let sb = ' /';
          for (let i = l; i > 0; i--) {
            sb += ' ' + Petrus.moveIdx[block].charAt(Math.floor(Petrus.seq[i] / 3)) + Utils.suff[Petrus.seq[i] % 3];
          }
          return sb;
        }
      }
    }
    return ' / error';
  }

  public static solvePetrus(scramble: string, block: number): string {
    Petrus.initp1();
    const solveS2 = ((block >> 8) & 1) != 0;
    if (solveS2) {
      Petrus.initp2();
    }
    let s = '\n';
    for (let i = 0; i < 8; i++) {
      if (((block >> i) & 1) != 0) {
        s += Petrus.petrus1(scramble, i, solveS2);
      }
    }
    return s;
  }
}
