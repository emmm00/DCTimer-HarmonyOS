// Ported from solver/Gear.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';

export class Gear {
  private static cpm: number[][] = Gear.z2d(24, 3);
  private static epm: number[][] = Gear.z2d(24, 3);
  private static eom: number[][] = Gear.z2d(27, 3);
  private static pd: number[][] = Gear.z2d(3, 576);
  private static turn: string[] = ['U', 'R', 'F'];
  private static suff: string[] = ["'", "2'", "3'", "4'", "5'", '6', '5', '4', '3', '2', ''];
  private static seq: number[] = new Array<number>(8).fill(0);
  static inited = false;

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  static init(): void {
    if (Gear.inited) {
      return;
    }
    let arr: number[] = new Array<number>(4).fill(0);
    for (let i = 0; i < 24; i++) {
      for (let j = 0; j < 3; j++) {
        Utils.idxToPerm(arr, i, 4, false);
        Utils.swap2(arr, 3, j);
        Gear.cpm[i][j] = Utils.permToIdx(arr, 4, false);
      }
    }
    for (let i = 0; i < 24; i++) {
      for (let j = 0; j < 3; j++) {
        Utils.idxToPerm(arr, i, 4, false);
        switch (j) {
          case 0: Utils.circle(arr, 0, 3, 2, 1); break;
          case 1: Utils.swap2(arr, 0, 1); break;
          case 2: Utils.swap2(arr, 1, 2); break;
        }
        Gear.epm[i][j] = Utils.permToIdx(arr, 4, false);
      }
    }
    arr = new Array<number>(3).fill(0);
    for (let i = 0; i < 27; i++) {
      for (let j = 0; j < 3; j++) {
        Utils.idxToOri(arr, i, 3, false);
        arr[j] = (arr[j] + 1) % 3;
        Gear.eom[i][j] = Utils.oriToIdx(arr, 3, false);
      }
    }
    for (let i = 0; i < 3; i++) {
      for (let j = 1; j < 576; j++) {
        Gear.pd[i][j] = -1;
      }
      Gear.pd[i][0] = 0;
      for (let d = 0; d < 5; d++) {
        for (let j = 0; j < 576; j++) {
          if (Gear.pd[i][j] == d) {
            for (let k = 0; k < 3; k++) {
              let p = j;
              for (let m = 0; m < 11; m++) {
                let e = p % 24;
                p = Math.floor(p / 24);
                p = Gear.cpm[p][k];
                e = Gear.epm[e][(k + i) % 3];
                p = 24 * p + e;
                if (Gear.pd[i][p] == -1) {
                  Gear.pd[i][p] = d + 1;
                }
              }
            }
          }
        }
      }
    }
    Gear.inited = true;
  }

  private static search(cp: number, ep1: number, ep2: number, ep3: number, eo: number, d: number,
    l: number): boolean {
    if (d == 0) {
      return cp == 0 && ep1 == 0 && ep2 == 0 && ep3 == 0 && eo == 0;
    }
    if (Math.max(Math.max(Gear.pd[0][24 * cp + ep1], Gear.pd[1][24 * cp + ep2]), Gear.pd[2][24 * cp + ep3]) > d) {
      return false;
    }
    for (let n = 0; n < 3; n++) {
      if (n != l) {
        let cn = cp;
        let e1n = ep1;
        let e2n = ep2;
        let e3n = ep3;
        let en = eo;
        for (let m = 0; m < 11; m++) {
          cn = Gear.cpm[cn][n];
          e1n = Gear.epm[e1n][n];
          e2n = Gear.epm[e2n][(n + 1) % 3];
          e3n = Gear.epm[e3n][(n + 2) % 3];
          en = Gear.eom[en][n];
          if (Gear.search(cn, e1n, e2n, e3n, en, d - 1, n)) {
            Gear.seq[d] = n * 11 + m;
            return true;
          }
        }
      }
    }
    return false;
  }

  public static scramble(): string {
    Gear.init();
    const rnd: () => number = Math.random;
    const cp = Math.floor(rnd() * 24);
    const ep: number[] = new Array<number>(3).fill(0);
    for (let i = 0; i < 3; i++) {
      do {
        ep[i] = Math.floor(rnd() * 24);
      } while (Gear.pd[i][24 * cp + ep[i]] < 0);
    }
    const eo = Math.floor(rnd() * 27);
    for (let d = 0; d < 7; d++) {
      if (Gear.search(cp, ep[0], ep[1], ep[2], eo, d, -1)) {
        if (d < 2) {
          return Gear.scramble();
        }
        if (d < 3) {
          continue;
        }
        let sb = '';
        for (let i = 1; i <= d; i++) {
          sb += Gear.turn[Math.floor(Gear.seq[i] / 11)] + Gear.suff[Gear.seq[i] % 11] + ' ';
        }
        return sb;
      }
    }
    return 'error';
  }
}
