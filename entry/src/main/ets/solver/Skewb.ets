// Ported from solver/Skewb.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';

export class Skewb {
  static ctm: number[][] = Skewb.z2d(360, 4);
  static cpm: number[][] = Skewb.z2d(12, 4);
  static com: number[][] = Skewb.z2d(2187, 4);
  static ctd: number[] = new Array<number>(360).fill(0);
  static cd: number[] = new Array<number>(12 * 2187).fill(0);
  static seq: number[] = new Array<number>(12).fill(0);
  private static suff: string[] = ["'", ''];
  static rnd: () => number = Math.random;
  static inited = false;

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  static init(): void {
    if (Skewb.inited) {
      return;
    }
    /* center
     * 		  0
     *	4	1	2	3
     * 		  5
     */
    const arr: number[] = new Array<number>(8).fill(0);
    for (let i = 0; i < 360; i++) {
      for (let j = 0; j < 4; j++) {
        Utils.idxToPerm(arr, i, 6, true);
        switch (j) {
          case 0: Utils.circle3(arr, 2, 5, 3); break;	//R
          case 1: Utils.circle3(arr, 0, 3, 4); break;	//U
          case 2: Utils.circle3(arr, 1, 4, 5); break;	//L
          case 3: Utils.circle3(arr, 0, 1, 2); break;	//F
        }
        Skewb.ctm[i][j] = Utils.permToIdx(arr, 6, true);
      }
    }
    /* corner
     *      4
     *  0	    1
     *  	3
     *  5	    6
     *      2
     */
    for (let i = 0; i < 12; i++) {
      for (let j = 0; j < 4; j++) {
        Utils.idxToPerm(arr, i, 4, true);
        switch (j) {
          case 0: Utils.circle3(arr, 1, 2, 3); break;  //R
          case 1: Utils.circle3(arr, 0, 1, 3); break;  //U
          case 2: Utils.circle3(arr, 2, 0, 3); break;  //L
          case 3: Utils.circle3(arr, 0, 2, 1); break;  //F
        }
        Skewb.cpm[i][j] = Utils.permToIdx(arr, 4, true);
      }
    }
    for (let i = 0; i < 2187; i++) {
      for (let j = 0; j < 4; j++) {
        Utils.idxToOri(arr, i, 8, true);
        switch (j) {
          case 0: //R
            Utils.circle3(arr, 1, 2, 3);
            arr[6]++;
            arr[1] += 2;
            arr[2] += 2;
            arr[3] += 2;
            break;
          case 1: //U
            Utils.circle3(arr, 0, 1, 3);
            arr[4]++;
            arr[0] += 2;
            arr[1] += 2;
            arr[3] += 2;
            break;
          case 2: //L
            Utils.circle3(arr, 2, 0, 3);
            arr[5]++;
            arr[0] += 2;
            arr[2] += 2;
            arr[3] += 2;
            break;
          case 3: //F
            Utils.circle3(arr, 0, 2, 1);
            arr[7]++;
            arr[0] += 2;
            arr[1] += 2;
            arr[2] += 2;
            break;
        }
        Skewb.com[i][j] = Utils.oriToIdx(arr, 8, true);
      }
    }

    for (let i = 0; i < 360; i++) {
      Skewb.ctd[i] = -1;
    }
    Skewb.ctd[0] = 0;
    Utils.createPrun(Skewb.ctd, 5, Skewb.ctm, 2);

    for (let i = 0; i < 12 * 2187; i++) {
      Skewb.cd[i] = -1;
    }
    Skewb.cd[0] = 0;
    Utils.createPrun2(Skewb.cd, 7, Skewb.com, Skewb.cpm, 2);
    Skewb.inited = true;
  }

  static search(ct: number, cp: number, co: number, d: number, l: number): boolean {
    if (d == 0) {
      return ct == 0 && co == 0 && cp == 0;
    }
    if (Skewb.ctd[ct] > d || Skewb.cd[co * 12 + cp] > d) {
      return false;
    }
    for (let k = 0; k < 4; k++) {
      if (k != l) {
        let p = ct;
        let q = cp;
        let r = co;
        for (let m = 0; m < 2; m++) {
          p = Skewb.ctm[p][k];
          q = Skewb.cpm[q][k];
          r = Skewb.com[r][k];
          if (Skewb.search(p, q, r, d - 1, k)) {
            Skewb.seq[d] = (k << 1) | m;
            return true;
          }
        }
      }
    }
    return false;
  }

  public static scramble(): string {
    Skewb.init();
    const ct = Math.floor(Skewb.rnd() * 360);
    let cp: number;
    let co: number;
    do {
      cp = Math.floor(Skewb.rnd() * 12);
      co = Math.floor(Skewb.rnd() * 2187);
    } while (Skewb.cd[co * 12 + cp] < 0);
    for (let d = 0; d < 12; d++) {
      if (Skewb.search(ct, cp, co, d, -1)) {
        if (d < 2) {
          return Skewb.scramble();
        }
        if (d < 5) {
          continue;
        }
        return Skewb.move2fcn(d);
      }
    }
    return 'error';
  }

  private static scramble1(minLen: number): string {
    Skewb.init();
    const ct = Math.floor(Skewb.rnd() * 360);
    let cp: number;
    let co: number;
    do {
      cp = Math.floor(Skewb.rnd() * 12);
      co = Math.floor(Skewb.rnd() * 2187);
    } while (Skewb.cd[co * 12 + cp] < 0);
    for (let d = 0; d < 12; d++) {
      if (Skewb.search(ct, cp, co, d, -1)) {
        if (d < minLen) {
          return 'error';
        }
        if (d < 11) {
          Skewb.search(ct, cp, co, 11, -1);
        }
        return Skewb.move2fcn(11);
      }
    }
    return 'error';
  }

  public static scrambleWCA(): string {
    let scr: string;
    do {
      scr = Skewb.scramble1(7);
    } while (scr == 'error');
    return scr;
  }

  public static scrambleL2L(): string {
    Skewb.init();
    let arr: number[] = new Array<number>(6).fill(0);
    const arr2: number[] = new Array<number>(4).fill(0);
    Utils.idxToPerm(arr, Math.floor(Skewb.rnd() * 60), 5, true);
    arr[5] = 5;
    const ct = Utils.permToIdx(arr, 6, true);
    const cp = 0;
    let co: number;
    do {
      Utils.idxToOri(arr2, Math.floor(Skewb.rnd() * 27), 4, true);
      arr = [arr2[0], arr2[1], 0, 0, arr2[2], 0, 0, arr2[3]];
      co = Utils.oriToIdx(arr, 8, true);
    } while (Skewb.cd[co * 12 + cp] < 0);
    for (let d = 0; d < 12; d++) {
      if (Skewb.search(ct, cp, co, d, -1)) {
        if (d < 2) {
          return Skewb.scramble();
        }
        if (d < 5) {
          continue;
        }
        return Skewb.move2fcn(d);
      }
    }
    return 'error';
  }

  static move2fcn(d: number): string {
    const move2str: string[] = ['R', 'U', 'L', 'B'];
    let sb = '';
    for (let i = 1; i <= d; i++) {
      const mov = Skewb.seq[i] >> 1;
      const pow = Skewb.seq[i] & 1;
      if (mov == 3) {
        for (let j = 0; j <= pow; j++) {
          const temp = move2str[2];
          move2str[2] = move2str[1];
          move2str[1] = move2str[0];
          move2str[0] = temp;
        }
      }
      sb += move2str[mov] + Skewb.suff[pow] + ' ';
    }
    return sb;
  }
}
