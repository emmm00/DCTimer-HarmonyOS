// Ported from solver/HalfTurn.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';

export class HalfTurn {
  private static cpm: number[][] = HalfTurn.z2d(24, 6);
  private static epm: number[][][] = HalfTurn.z3d(3, 24, 6);
  private static cpd: number[] = new Array<number>(24 * 24).fill(0);
  private static epd: number[][][] = HalfTurn.z3d(24, 24, 24);
  private static seq: number[] = new Array<number>(21).fill(0);
  private static turn: string[] = ['U', 'D', 'F', 'B', 'L', 'R'];
  static inited = false;

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  private static z3d(r: number, c: number, d: number): number[][][] {
    const a: number[][][] = [];
    for (let i = 0; i < r; i++) {
      const row: number[][] = [];
      for (let j = 0; j < c; j++) {
        row.push(new Array<number>(d).fill(0));
      }
      a.push(row);
    }
    return a;
  }

  static init(): void {
    if (HalfTurn.inited) {
      return;
    }
    const temp: number[] = new Array<number>(4).fill(0);
    for (let i = 0; i < 24; i++) {
      for (let j = 0; j < 6; j++) {
        Utils.idxToPerm(temp, i, 4, false);
        switch (j) {
          case 0: Utils.swap2(temp, 0, 1); break;
          case 1: Utils.swap2(temp, 2, 3); break;
          case 2: Utils.swap2(temp, 0, 2); break;
          case 3: Utils.swap2(temp, 1, 3); break;
          case 4: Utils.swap2(temp, 1, 2); break;
          case 5: Utils.swap2(temp, 0, 3); break;
        }
        HalfTurn.cpm[i][j] = Utils.permToIdx(temp, 4, false);
        Utils.idxToPerm(temp, i, 4, false);
        switch (j) {
          case 0: Utils.swap2(temp, 0, 1); break;
          case 1: Utils.swap2(temp, 2, 3); break;
          case 2: Utils.swap2(temp, 0, 3); break;
          case 3: Utils.swap2(temp, 1, 2); break;
        }
        HalfTurn.epm[0][i][j] = Utils.permToIdx(temp, 4, false);
        Utils.idxToPerm(temp, i, 4, false);
        switch (j) {
          case 0: Utils.swap2(temp, 0, 1); break;
          case 1: Utils.swap2(temp, 2, 3); break;
          case 4: Utils.swap2(temp, 0, 3); break;
          case 5: Utils.swap2(temp, 1, 2); break;
        }
        HalfTurn.epm[1][i][j] = Utils.permToIdx(temp, 4, false);
        Utils.idxToPerm(temp, i, 4, false);
        switch (j) {
          case 2: Utils.swap2(temp, 0, 3); break;
          case 3: Utils.swap2(temp, 1, 2); break;
          case 4: Utils.swap2(temp, 0, 1); break;
          case 5: Utils.swap2(temp, 2, 3); break;
        }
        HalfTurn.epm[2][i][j] = Utils.permToIdx(temp, 4, false);
      }
    }
    for (let i = 1; i < 576; i++) {
      HalfTurn.cpd[i] = -1;
    }
    HalfTurn.cpd[0] = 0;
    Utils.createPrun2(HalfTurn.cpd, 3, HalfTurn.cpm, HalfTurn.cpm, 1);
    for (let i = 0; i < 24; i++) {
      for (let j = 0; j < 24; j++) {
        for (let k = 0; k < 24; k++) {
          HalfTurn.epd[i][j][k] = -1;
        }
      }
    }
    HalfTurn.epd[0][0][0] = 0;
    let c = 1;
    for (let d = 0; d < 8; d++) {
      for (let i = 0; i < 24; i++) {
        for (let j = 0; j < 24; j++) {
          for (let k = 0; k < 24; k++) {
            if (HalfTurn.epd[i][j][k] == d) {
              for (let l = 0; l < 6; l++) {
                const p = HalfTurn.epm[0][i][l];
                const q = HalfTurn.epm[1][j][l];
                const r = HalfTurn.epm[2][k][l];
                if (HalfTurn.epd[p][q][r] == -1) {
                  HalfTurn.epd[p][q][r] = d + 1;
                  c++;
                }
              }
            }
          }
        }
      }
    }
    HalfTurn.inited = true;
  }

  private static search(cp1: number, cp2: number, ep1: number, ep2: number, ep3: number, d: number,
    l: number): boolean {
    if (d == 0) {
      return cp1 == 0 && cp2 == 0 && ep1 == 0 && ep2 == 0 && ep3 == 0;
    }
    if (HalfTurn.cpd[cp1 * 24 + cp2] > d || HalfTurn.epd[ep1][ep2][ep3] > d) {
      return false;
    }
    for (let n = 0; n < 6; n++) {
      if (n != l) {
        const c1n = HalfTurn.cpm[cp1][n];
        const c2n = HalfTurn.cpm[cp2][n];
        const e1n = HalfTurn.epm[0][ep1][n];
        const e2n = HalfTurn.epm[1][ep2][n];
        const e3n = HalfTurn.epm[2][ep3][n];
        if (HalfTurn.search(c1n, c2n, e1n, e2n, e3n, d - 1, n)) {
          HalfTurn.seq[d] = n;
          return true;
        }
      }
    }
    return false;
  }

  public static scramble(rnd: () => number): string {
    HalfTurn.init();
    let cp1: number;
    let cp2: number;
    do {
      cp1 = Math.floor(rnd() * 24);
      cp2 = Math.floor(rnd() * 24);
    } while (HalfTurn.cpd[cp1 * 24 + cp2] < 0);
    let ep1: number;
    let ep2: number;
    let ep3: number;
    do {
      ep1 = Math.floor(rnd() * 24);
      ep2 = Math.floor(rnd() * 24);
      ep3 = Math.floor(rnd() * 24);
    } while (HalfTurn.epd[ep1][ep2][ep3] < 0);
    for (let d = 0; d < 20; d++) {
      if (HalfTurn.search(cp1, cp2, ep1, ep2, ep3, d, -1)) {
        if (d < 2) {
          return HalfTurn.scramble(rnd);
        }
        if (d < 4) {
          continue;
        }
        let sb = '';
        for (let i = 1; i <= d; i++) {
          sb += HalfTurn.turn[HalfTurn.seq[i]] + '2 ';
        }
        return sb;
      }
    }
    return 'error';
  }
}
