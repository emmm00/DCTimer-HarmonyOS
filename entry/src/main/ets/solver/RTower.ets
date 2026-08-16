// Ported from solver/RTower.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';
import { Tower } from './Tower';

export class RTower {
  private static epm: number[][] = RTower.z2d(5040, 3);
  private static eom: number[][] = RTower.z2d(729, 3);
  private static epd: number[] = new Array<number>(5040).fill(0);
  private static eod: number[] = new Array<number>(729).fill(0);
  private static faces: number[] = [3, 1, 1, 3];
  private static turn1: string[] = ['Uw', 'R', 'F'];
  private static turn2: string[] = ['U', 'R', 'F', 'D'];
  private static suff: string[] = ["'", '2', ''];
  private static sol: number[] = new Array<number>(25).fill(0);
  private static len1 = 0;
  private static len2 = 0;
  private static ep = 0;
  private static eo = 0;
  private static cp = 0;

  private static ini = false;

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  public static init(): void {
    if (RTower.ini) {
      return;
    }
    Tower.init();
    const arr: number[] = new Array<number>(8).fill(0);
    for (let i = 0; i < 5040; i++) {
      for (let j = 0; j < 3; j++) {
        Utils.set8Perm(arr, 7, i);
        switch (j) {
          case 0: Utils.circle(arr, 0, 3, 2, 1); break;	//Uw
          case 1: Utils.circle(arr, 1, 2, 5, 6); break;	//R
          case 2: Utils.circle(arr, 2, 3, 4, 5); break;	//F
        }
        RTower.epm[i][j] = Utils.get8Perm(arr, 7);
      }
    }
    for (let i = 0; i < 729; i++) {
      for (let j = 0; j < 3; j++) {
        Utils.idxToOri(arr, i, 7, true);
        switch (j) {
          case 0: Utils.circle(arr, 0, 3, 2, 1); break;	//Uw
          case 1:
            Utils.circleOri(arr, 1, 2, 5, 6, [2, 1, 2, 1]);
            break;	//R
          case 2:
            Utils.circleOri(arr, 2, 3, 4, 5, [2, 1, 2, 1]);
            break;	//F
        }
        RTower.eom[i][j] = Utils.oriToIdx(arr, 7, true);
      }
    }

    let n = 1;
    RTower.epd[0] = 0;
    for (let i = 1; i < 5040; i++) {
      Utils.set8Perm(arr, 7, i);
      if (RTower.checkEp1(arr)) {
        RTower.epd[i] = 0;
        n++;
      } else {
        RTower.epd[i] = -1;
      }
    }
    Utils.createPrun(RTower.epd, 4, RTower.epm, 3);

    for (let i = 1; i < 729; i++) {
      RTower.eod[i] = -1;
    }
    RTower.eod[0] = 0;
    Utils.createPrun(RTower.eod, 6, RTower.eom, 3);
    RTower.ini = true;
  }

  private static checkEp1(arr: number[]): boolean {
    if (arr[0] != 0) {
      return false;
    }
    for (let i = 1; i < 4; i++) {
      if (arr[i] + arr[7 - i] != 7) {
        return false;
      }
    }
    return true;
  }

  private static getMi(ep: number): number {
    const arr: number[] = new Array<number>(7).fill(0);
    Utils.set8Perm(arr, 7, ep);
    for (let i = 0; i < 3; i++) {
      if (arr[i + 1] < 4) {
        arr[i] = arr[i + 1];
      } else {
        arr[i] = 6 - arr[i + 1];
      }
    }
    return Utils.permToIdx(arr, 3, false);
  }

  public static scramble(): string {
    RTower.init();
    const rnd: () => number = Math.random;
    RTower.eo = Math.floor(rnd() * 729);
    RTower.ep = Math.floor(rnd() * 5040);
    RTower.cp = Math.floor(rnd() * 40320);
    for (RTower.len1 = 0; RTower.len1 < 20; RTower.len1++) {
      if (RTower.search1(RTower.ep, RTower.eo, RTower.len1, -1)) {
        if (RTower.len1 + RTower.len2 < 3) {
          return RTower.scramble();
        }
        let sb = '';
        for (let i = RTower.len1 + 1; i <= RTower.len2 + RTower.len1; i++) {
          sb += RTower.turn2[Math.floor(RTower.sol[i] / 3)] + RTower.suff[RTower.sol[i] % 3] + ' ';
        }
        for (let i = 1; i <= RTower.len1; i++) {
          sb += RTower.turn1[Math.floor(RTower.sol[i] / 3)] + RTower.suff[RTower.sol[i] % 3] + ' ';
        }
        return sb;
      }
    }
    return 'error';
  }

  private static search1(ep: number, eo: number, d: number, lf: number): boolean {
    if (d == 0) {
      return eo == 0 && RTower.epd[ep] == 0 && RTower.init2();
    }
    if (RTower.epd[ep] > d || RTower.eod[eo] > d) {
      return false;
    }
    for (let i = 0; i < 3; i++) {
      if (i != lf) {
        let y = eo;
        let s = ep;
        for (let j = 0; j < 3; j++) {
          y = RTower.eom[y][i];
          s = RTower.epm[s][i];
          RTower.sol[d] = i * 3 + j;
          if (RTower.search1(s, y, d - 1, i)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  private static init2(): boolean {
    let epx = RTower.ep;
    let cpx = RTower.cp;
    for (let i = RTower.len1; i > 0; i--) {
      const m = Math.floor(RTower.sol[i] / 3);
      const t = RTower.sol[i] % 3;
      epx = RTower.epm[epx][m];
      cpx = Tower.cpm[cpx][m];
      if (t > 0) {
        epx = RTower.epm[epx][m];
        cpx = Tower.cpm[cpx][m];
        if (t > 1) {
          epx = RTower.epm[epx][m];
          cpx = Tower.cpm[cpx][m];
        }
      }
    }
    epx = RTower.getMi(epx);
    let lf = Math.floor(RTower.sol[1] / 3);
    if (lf == 0) {
      lf = -1;
    }
    for (RTower.len2 = 0; RTower.len2 < 19 - RTower.len1; RTower.len2++) {
      if (RTower.search2(cpx, epx, RTower.len2, lf)) {
        if (RTower.len1 + RTower.len2 < 4) {
          continue;
        }
        return true;
      }
    }
    return false;
  }

  private static search2(cp: number, ep: number, d: number, lf: number): boolean {
    if (d == 0) {
      return cp == 0 && ep == 0;
    }
    if (Tower.epd[ep] > d || Tower.cpd[cp] > d) {
      return false;
    }
    for (let i = 0; i < 4; i++) {
      if (i != lf) {
        let y = cp;
        let s = ep;
        for (let k = 0; k < RTower.faces[i]; k++) {
          y = Tower.cpm[y][i];
          s = Tower.epm[s][i];
          RTower.sol[d + RTower.len1] = i * 3 + (RTower.faces[i] == 1 ? 1 : k);
          if (RTower.search2(y, s, d - 1, i)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  private static img: number[] = new Array<number>(96).fill(0);

  private static initColor(): void {
    RTower.img = [
      -1, -1, -1, -1,
      -1, 0, 0, -1,
      -1, 0, 0, -1,
      -1, -1, -1, -1,
      -1, 2, 2, -1, -1, 4, 4, -1, -1, 3, 3, -1, -1, 5, 5, -1,
      -1, 2, 2, -1, -1, 4, 4, -1, -1, 3, 3, -1, -1, 5, 5, -1,
      -1, 2, 2, -1, -1, 4, 4, -1, -1, 3, 3, -1, -1, 5, 5, -1,
      -1, 2, 2, -1, -1, 4, 4, -1, -1, 3, 3, -1, -1, 5, 5, -1,
      -1, -1, -1, -1,
      -1, 1, 1, -1,
      -1, 1, 1, -1,
      -1, -1, -1, -1
    ];
  }
}
