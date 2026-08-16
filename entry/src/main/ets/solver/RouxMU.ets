// Ported from solver/RouxMU.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';

export class RouxMU {
  private static epm: number[][] = RouxMU.z2d(720, 2);
  private static eom: number[][] = RouxMU.z2d(32, 2);
  private static ctm: number[][] = [[1, 0], [2, 1], [3, 2], [0, 3]];
  private static cpm: number[][] = [[0, 1], [1, 2], [2, 3], [3, 0]];
  private static ed: number[] = new Array<number>(720 * 32).fill(0);
  private static eod: number[] = new Array<number>(32 * 16).fill(0);
  private static turn: string[] = ['M', 'U'];
  private static seq: number[] = new Array<number>(21).fill(0);
  static inited = false;

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  static init(): void {
    if (RouxMU.inited) {
      return;
    }
    const temp: number[] = new Array<number>(6).fill(0);
    for (let i = 0; i < 720; i++) {
      for (let j = 0; j < 2; j++) {
        Utils.idxToPerm(temp, i, 6, false);
        switch (j) {
          case 0: Utils.circle(temp, 0, 4, 5, 2); break;
          case 1: Utils.circle(temp, 0, 3, 2, 1); break;
        }
        RouxMU.epm[i][j] = Utils.permToIdx(temp, 6, false);
      }
    }
    for (let i = 0; i < 32; i++) {
      for (let j = 0; j < 2; j++) {
        Utils.idxToFlip(temp, i, 6, true);
        switch (j) {
          case 0:
            Utils.circle(temp, 0, 4, 5, 2);
            temp[0] = 1 - temp[0];
            temp[2] = 1 - temp[2];
            temp[4] = 1 - temp[4];
            temp[5] = 1 - temp[5];
            break;
          case 1: Utils.circle(temp, 0, 3, 2, 1); break;
        }
        RouxMU.eom[i][j] = Utils.flipToIdx(temp, 6, true);
      }
    }

    for (let i = 0; i < 23040; i++) {
      RouxMU.ed[i] = -1;
    }
    RouxMU.ed[0] = 0;
    Utils.createPrun2(RouxMU.ed, 14, RouxMU.epm, RouxMU.eom, 3);
    for (let i = 0; i < 512; i++) {
      RouxMU.eod[i] = -1;
    }
    RouxMU.eod[0] = 0;
    let c = 1;
    for (let d = 0; d < 12; d++) {
      for (let i = 0; i < 32; i++) {
        for (let j = 0; j < 16; j++) {
          if (RouxMU.eod[i * 16 + j] == d) {
            for (let k = 0; k < 2; k++) {
              let y = i;
              let t = j;
              for (let m = 0; m < 3; m++) {
                y = RouxMU.eom[y][k];
                t = RouxMU.ctm[Math.floor(t / 4)][k] * 4 + RouxMU.cpm[t % 4][k];
                if (RouxMU.eod[y * 16 + t] < 0) {
                  RouxMU.eod[y * 16 + t] = d + 1;
                  c++;
                }
              }
            }
          }
        }
      }
    }
    RouxMU.inited = true;
  }

  private static search(ep: number, eo: number, ct: number, cp: number, d: number, lf: number): boolean {
    if (d == 0) {
      return cp == 0 && ep == 0 && ct == 0 && eo == 0;
    }
    if (RouxMU.ed[ep * 32 + eo] > d || RouxMU.eod[eo * 16 + (ct * 4 + cp)] > d) {
      return false;
    }
    for (let i = 0; i < 2; i++) {
      if (i != lf) {
        let y = cp;
        let s = ep;
        let u = ct;
        let t = eo;
        for (let k = 0; k < 3; k++) {
          y = RouxMU.cpm[y][i];
          s = RouxMU.epm[s][i];
          u = RouxMU.ctm[u][i];
          t = RouxMU.eom[t][i];
          if (RouxMU.search(s, t, u, y, d - 1, i)) {
            RouxMU.seq[d] = i * 3 + k;
            return true;
          }
        }
      }
    }
    return false;
  }

  private static ctcpSign(ct: number, cp: number): boolean {
    const a = ct % 2 == 0;
    const b = cp % 2 == 0;
    return a == b;
  }

  public static scramble(rnd: () => number): string {
    RouxMU.init();
    let ep: number;
    let ct: number;
    let cp: number;
    const p: number[] = new Array<number>(6).fill(0);
    do {
      ep = Math.floor(rnd() * 720);
      ct = Math.floor(rnd() * 4);
      cp = Math.floor(rnd() * 4);
      Utils.idxToPerm(p, ep, 6, false);
    } while (Utils.permutationSign(p) != RouxMU.ctcpSign(ct, cp));
    const eo = Math.floor(rnd() * 32);
    for (let d = 0; d < 21; d++) {
      if (RouxMU.search(ep, eo, ct, cp, d, -1)) {
        if (d < 2) {
          return RouxMU.scramble(rnd);
        }
        if (d < 4) {
          continue;
        }
        let sb = '';
        for (let i = 1; i <= d; i++) {
          sb += RouxMU.turn[Math.floor(RouxMU.seq[i] / 3)] + Utils.suffInv[RouxMU.seq[i] % 3] + ' ';
        }
        return sb;
      }
    }
    return 'error';
  }
}
