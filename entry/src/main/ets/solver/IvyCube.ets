// Ported from solver/IvyCube.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';

export class IvyCube {
  private static pm: number[][] = IvyCube.z2d(360, 4);
  private static om: number[][] = IvyCube.z2d(81, 4);
  private static pd: number[] = new Array<number>(360).fill(0);
  private static od: number[] = new Array<number>(81).fill(0);
  private static seq: number[] = new Array<number>(12).fill(0);
  private static suff: string[] = ["'", ''];
  private static rnd: () => number = Math.random;
  static inited = false;

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  static init(): void {
    if (IvyCube.inited) {
      return;
    }
    let arr: number[] = new Array<number>(6).fill(0);
    for (let i = 0; i < 360; i++) {
      for (let j = 0; j < 4; j++) {
        Utils.idxToPerm(arr, i, 6, true);
        switch (j) {
          case 0:
            Utils.circle3(arr, 0, 3, 1);
            break;
          case 1:
            Utils.circle3(arr, 0, 2, 4);
            break;
          case 2:
            Utils.circle3(arr, 1, 5, 2);
            break;
          case 3:
            Utils.circle3(arr, 3, 4, 5);
            break;
        }
        IvyCube.pm[i][j] = Utils.permToIdx(arr, 6, true);
      }
    }

    arr = new Array<number>(4).fill(0);
    for (let i = 0; i < 81; i++) {
      for (let j = 0; j < 4; j++) {
        IvyCube.idxToOri(arr, i, false);
        arr[j]++;
        IvyCube.om[i][j] = IvyCube.oriToIdx(arr, false);
      }
    }

    for (let i = 0; i < 360; i++) {
      IvyCube.pd[i] = -1;
    }
    IvyCube.pd[0] = 0;
    Utils.createPrun(IvyCube.pd, 6, IvyCube.pm, 2);
    for (let i = 0; i < 81; i++) {
      IvyCube.od[i] = -1;
    }
    IvyCube.od[0] = 0;
    Utils.createPrun(IvyCube.od, 6, IvyCube.om, 2);
    IvyCube.inited = true;
  }

  private static search(p: number, o: number, d: number, l: number): boolean {
    if (d == 0) {
      return p == 0 && o == 0;
    }
    if (IvyCube.pd[p] > d || IvyCube.od[o] > d) {
      return false;
    }
    for (let k = 0; k < 4; k++) {
      if (k != l) {
        let cp = p;
        let co = o;
        for (let m = 0; m < 2; m++) {
          cp = IvyCube.pm[cp][k];
          co = IvyCube.om[co][k];
          if (IvyCube.search(cp, co, d - 1, k)) {
            IvyCube.seq[d] = (k << 1) | m;
            return true;
          }
        }
      }
    }
    return false;
  }

  public static scramble(): string {
    IvyCube.init();
    let p: number;
    let o: number;
    do {
      p = Math.floor(IvyCube.rnd() * 360);
      o = Math.floor(IvyCube.rnd() * 81);
    } while ((p == 0 && o == 0) || IvyCube.search(p, o, 0, -1) || IvyCube.search(p, o, 1, -1));
    for (let d = 6; d < 12; d++) {
      if (IvyCube.search(p, o, d, -1)) {
        return IvyCube.moveToString(d);
      }
    }
    return 'error';
  }

  private static moveToString(d: number): string {
    let sb = '';
    for (let i = 1; i <= d; i++) {
      const move = IvyCube.seq[i] >> 1;
      const pow = IvyCube.seq[i] & 1;
      if (sb.length > 0) {
        sb += ' ';
      }
      sb += 'RLUB'.charAt(move) + IvyCube.suff[pow];
    }
    return sb;
  }

  private static oriToIdx(orientation: number[], zeroSum: boolean): number {
    let idx = zeroSum ? 0 : orientation[0] % 3;
    for (let i = orientation.length - 1; i > 0; i--) {
      idx = idx * 3 + orientation[i] % 3;
    }
    return idx;
  }

  private static idxToOri(orientation: number[], idx: number, zeroSum: boolean): void {
    let parity = orientation.length * 3;
    for (let i = 1; i < orientation.length; i++) {
      orientation[i] = idx % 3;
      parity -= orientation[i];
      idx = Math.floor(idx / 3);
    }
    orientation[0] = zeroSum ? parity % 3 : idx % 3;
  }
}
