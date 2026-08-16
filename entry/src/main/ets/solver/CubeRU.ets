// Ported from solver/CubeRU.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';

export class CubeRU {
  private static cpm: number[][] = CubeRU.z2d(720, 2);
  private static epm: number[][] = CubeRU.z2d(5040, 2);
  private static com: number[][] = CubeRU.z2d(243, 2);
  private static cd: number[] = new Array<number>(720 * 243).fill(0);
  private static epd: number[] = new Array<number>(5040).fill(0);
  private static seq: number[] = new Array<number>(21).fill(0);
  private static turn: string[] = ['U', 'R'];
  private static turnlu: string[] = ['U', 'L'];
  static inited = false;

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  static init(): void {
    if (CubeRU.inited) {
      return;
    }
    const arr: number[] = new Array<number>(7).fill(0);
    for (let i = 0; i < 720; i++) {
      for (let j = 0; j < 2; j++) {
        Utils.idxToPerm(arr, i, 6, false);
        if (j == 0) {
          Utils.circle(arr, 0, 3, 2, 1);
        } else {
          Utils.circle(arr, 1, 2, 4, 5);
        }
        CubeRU.cpm[i][j] = Utils.permToIdx(arr, 6, false);
      }
    }
    for (let i = 0; i < 243; i++) {
      for (let j = 0; j < 2; j++) {
        Utils.idxToOri(arr, i, 6, true);
        if (j == 0) {
          Utils.circle(arr, 0, 3, 2, 1);
        } else {
          Utils.circleOri(arr, 1, 2, 4, 5, [1, 2, 1, 2]);
        }
        CubeRU.com[i][j] = Utils.oriToIdx(arr, 6, true);
      }
    }
    for (let i = 0; i < 5040; i++) {
      for (let j = 0; j < 2; j++) {
        Utils.idxToPerm(arr, i, 7, false);
        if (j == 0) {
          Utils.circle(arr, 0, 3, 2, 1);
        } else {
          Utils.circle(arr, 1, 6, 5, 4);
        }
        CubeRU.epm[i][j] = Utils.permToIdx(arr, 7, false);
      }
    }
    for (let i = 1; i < 174960; i++) {
      CubeRU.cd[i] = -1;
    }
    CubeRU.cd[0] = 0;
    Utils.createPrun2(CubeRU.cd, 14, CubeRU.cpm, CubeRU.com, 3);
    for (let i = 1; i < 5040; i++) {
      CubeRU.epd[i] = -1;
    }
    CubeRU.epd[0] = 0;
    Utils.createPrun(CubeRU.epd, 11, CubeRU.epm, 3);
    CubeRU.inited = true;
  }

  private static search(cp: number, co: number, ep: number, depth: number, lm: number): boolean {
    if (depth == 0) {
      return cp == 0 && co == 0 && ep == 0;
    }
    if (CubeRU.cd[cp * 243 + co] > depth || CubeRU.epd[ep] > depth) {
      return false;
    }
    for (let i = 0; i < 2; i++) {
      if (i != lm) {
        let d = cp;
        let w = co;
        let y = ep;
        for (let j = 0; j < 3; j++) {
          d = CubeRU.cpm[d][i];
          w = CubeRU.com[w][i];
          y = CubeRU.epm[y][i];
          if (CubeRU.search(d, w, y, depth - 1, i)) {
            CubeRU.seq[depth] = i * 3 + j;
            return true;
          }
        }
      }
    }
    return false;
  }

  public static scramble(lu: boolean): string {
    CubeRU.init();
    let cp: number;
    let co: number;
    let ep: number;
    const c: number[] = new Array<number>(6).fill(0);
    const e: number[] = new Array<number>(7).fill(0);
    const rnd: () => number = Math.random;
    do {
      do {
        cp = Math.floor(rnd() * 720);
        co = Math.floor(rnd() * 243);
      } while (CubeRU.cd[cp * 243 + co] < 0);
      ep = Math.floor(rnd() * 5040);
      Utils.idxToPerm(c, cp, 6, false);
      Utils.idxToPerm(e, ep, 7, false);
    } while (Utils.permutationSign(c) != Utils.permutationSign(e));
    for (let d = 0; d < 21; d++) {
      if (CubeRU.search(cp, co, ep, d, -1)) {
        if (d < 2) {
          return CubeRU.scramble(lu);
        }
        if (d < 4) {
          continue;
        }
        let sb = '';
        for (let i = 1; i <= d; i++) {
          if (lu) {
            sb += CubeRU.turnlu[Math.floor(CubeRU.seq[i] / 3)] + Utils.suff[CubeRU.seq[i] % 3] + ' ';
          } else {
            sb += CubeRU.turn[Math.floor(CubeRU.seq[i] / 3)] + Utils.suffInv[CubeRU.seq[i] % 3] + ' ';
          }
        }
        return sb;
      }
    }
    return 'error';
  }
}
