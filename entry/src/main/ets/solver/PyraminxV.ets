// Ported from solver/PyraminxV.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';

export class PyraminxV {
  private static epm: number[][] = PyraminxV.z2d(30, 4);
  private static eom: number[][] = PyraminxV.z2d(60, 4);
  private static com: number[][] = PyraminxV.z2d(27, 4);
  private static prun: number[] = new Array<number>(3240).fill(0);
  private static moveStr: string[] = ['LRBU', 'ULBR', 'RUBL', 'LURB'];
  private static suff: string[] = ['', "'"];
  private static seq: number[] = new Array<number>(7).fill(0);
  private static ini = false;

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  static init(): void {
    if (PyraminxV.ini) {
      return;
    }
    for (let a = 0; a < 15; a++) {
      for (let b = 0; b < 4; b++) {
        for (let f = 0; f < 4; f++) {
          const c = PyraminxV.getmv(a, b, b, f);
          PyraminxV.eom[4 * a + b][f] = ((Math.floor(c / 8)) << 2) | (c & 3);
          if (b < 2) {
            PyraminxV.epm[2 * a + b][f] = c >> 2;
          }
        }
      }
    }
    const tws: number[] = new Array<number>(3).fill(0);
    for (let p = 0; p < 27; p++) {
      for (let m = 0; m < 4; m++) {
        Utils.idxToOri(tws, p, 3, false);
        switch (m) {
          case 0:	//L
            tws[1]++;
            if (tws[1] == 3) {
              tws[1] = 0;
            }
            break;
          case 1:	//R
            tws[2]++;
            if (tws[2] == 3) {
              tws[2] = 0;
            }
            break;
          case 2:	//B
            tws[0]++;
            if (tws[0] == 3) {
              tws[0] = 0;
            }
            break;
        }
        PyraminxV.com[p][m] = Utils.oriToIdx(tws, 3, false);
      }
    }
    for (let i = 0; i < 3240; i++) {
      PyraminxV.prun[i] = -1;
    }
    PyraminxV.prun[3 * 8] = 0;
    PyraminxV.prun[4 * 8] = 0;
    PyraminxV.prun[0] = 0;
    let c = 3;
    for (let d = 0; d < 6; d++) {
      for (let i = 0; i < 27; i++) {
        for (let j = 0; j < 30; j++) {
          for (let k = 0; k < 4; k++) {
            if (PyraminxV.prun[i * 120 + j * 4 + k] == d) {
              for (let m = 0; m < 4; m++) {
                let x = i;
                let y = j;
                let z = k;
                for (let n = 0; n < 2; n++) {
                  x = PyraminxV.com[x][m];
                  z = PyraminxV.eom[Math.floor(y / 2) * 4 + z % 4][m] % 4;
                  y = PyraminxV.epm[y][m];
                  const next = x * 120 + y * 4 + z;
                  if (PyraminxV.prun[next] < 0) {
                    PyraminxV.prun[next] = d + 1;
                    c++;
                  }
                }
              }
            }
          }
        }
      }
    }
    PyraminxV.ini = true;
  }

  private static getmv(c: number, p: number, o: number, f: number): number {
    const n: number[] = new Array<number>(6).fill(0);
    const s: number[] = new Array<number>(2).fill(0);
    let q: number;
    let t: number;
    Utils.idxToPerm(s, p, 2, false);
    PyraminxV.idxToComb(n, s, c, o);
    switch (f) {
      case 0:	//L
        Utils.circle3(n, 1, 5, 2);
        n[2] ^= 1;
        n[5] ^= 1;
        break;
      case 1:	//R
        Utils.circle3(n, 0, 2, 4);
        n[0] ^= 1;
        n[2] ^= 1;
        break;
      case 2:	//B
        Utils.circle3(n, 3, 4, 5);
        n[3] ^= 1;
        n[4] ^= 1;
        break;
      case 3:	//U
        Utils.circle3(n, 0, 3, 1);
        n[1] ^= 1;
        n[3] ^= 1;
        break;
    }
    c = 0;
    o = 0;
    q = 2;
    for (t = 0; t < 6; t++) {
      if (n[t] >= 0) {
        c += Utils.Cnk[5 - t][q--];
        s[q] = n[t] >> 1;
        o |= (n[t] & 1) << (1 - q);
      }
    }
    const i = Utils.permToIdx(s, 2, false);
    return ((2 * c + i) << 2) | o;
  }

  private static idxToComb(n: number[], s: number[], c: number, o: number): void {
    let q = 2;
    for (let t = 0; t < 6; t++) {
      if (c >= Utils.Cnk[5 - t][q]) {
        c -= Utils.Cnk[5 - t][q--];
        n[t] = (s[q] << 1) | (o & 1);
        o >>= 1;
      } else {
        n[t] = -1;
      }
    }
  }

  private static search(p: number, f: number, t: number, solvedp: number, d: number, lm: number): boolean {
    if (d == 0) {
      return p == solvedp && f == solvedp * 2 && t == 0;
    }
    if (PyraminxV.prun[t * 120 + p * 4 + f % 4] > d) {
      return false;
    }
    for (let i = 0; i < 4; i++) {
      if (i != lm) {
        let x = p;
        let y = f;
        let z = t;
        for (let j = 0; j < 2; j++) {
          x = PyraminxV.epm[x][i];
          y = PyraminxV.eom[y][i];
          z = PyraminxV.com[z][i];
          if (PyraminxV.search(x, y, z, solvedp, d - 1, i)) {
            PyraminxV.seq[d] = i * 2 + j;
            return true;
          }
        }
      }
    }
    return false;
  }

  private static solvedEp: number[] = [0, 6, 8];

  private static solve(scramble: string, face: number): string {
    const s = scramble.split(' ');
    let t = 0;
    const p: number[] = [0, 6, 8];
    const f: number[] = [0, 12, 16];
    for (let i = 0; i < s.length; i++) {
      if (s[i].length > 0) {
        const o = PyraminxV.moveStr[face].indexOf(s[i].charAt(0));
        if (o < 0) {
          continue;
        }
        t = PyraminxV.com[t][o];
        for (let j = 0; j < 3; j++) {
          p[j] = PyraminxV.epm[p[j]][o];
          f[j] = PyraminxV.eom[f[j]][o];
        }
        if (s[i].length > 1) {
          t = PyraminxV.com[t][o];
          for (let j = 0; j < 3; j++) {
            p[j] = PyraminxV.epm[p[j]][o];
            f[j] = PyraminxV.eom[f[j]][o];
          }
        }
      }
    }
    for (let d = 0; d < 7; d++) {
      for (let idx = 0; idx < 3; idx++) {
        if (PyraminxV.search(p[idx], f[idx], t, PyraminxV.solvedEp[idx], d, -1)) {
          let sb = '';
          for (let i = d; i > 0; i--) {
            sb += ' ' + PyraminxV.moveStr[face].charAt(Math.floor(PyraminxV.seq[i] / 2)) + PyraminxV.suff[PyraminxV.seq[i] % 2];
          }
          return sb;
        }
      }
    }
    return ' error';
  }

  public static solveV(scramble: string, face: number): string {
    PyraminxV.init();
    let sb = '\n';
    for (let i = 0; i < 4; i++) {
      if (((face >> i) & 1) != 0) {
        sb += '\n' + 'DLRF'.charAt(i) + ': ' + PyraminxV.solve(scramble, i);
      }
    }
    return sb;
  }
}
