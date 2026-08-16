// Ported from solver/SkewbFCN.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';

export class SkewbFCN {
  private static ctm: number[][] = SkewbFCN.z2d(360, 4);
  private static cpm: number[][] = SkewbFCN.z2d(36, 4);
  private static com: number[][] = SkewbFCN.z2d(2187, 4);
  private static ctd: number[] = new Array<number>(360).fill(0);
  private static cd: number[] = new Array<number>(2187 * 36).fill(0);
  private static rnd: () => number = Math.random;
  private static turn: string[] = ['R', 'U', 'L', 'B'];
  private static suff: string[] = ["'", ''];
  static inited = false;

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  static init(): void {
    if (SkewbFCN.inited) {
      return;
    }
    // move tables
    /* center
     * 		  0
     *	4	1	2	3
     * 		  5
     */
    const arr: number[] = new Array<number>(7).fill(0);
    for (let i = 0; i < 360; i++) {
      for (let j = 0; j < 4; j++) {
        Utils.idxToPerm(arr, i, 6, true);
        switch (j) {
          case 0: Utils.circle3(arr, 2, 5, 3); break;	//R
          case 1: Utils.circle3(arr, 0, 3, 4); break;	//U
          case 2: Utils.circle3(arr, 1, 4, 5); break;	//L
          case 3: Utils.circle3(arr, 3, 5, 4); break;	//B
        }
        SkewbFCN.ctm[i][j] = Utils.permToIdx(arr, 6, true);
      }
    }
    /* corner permutation
     *     2-0
     *  0	    1
     *  	3
     * 2-1	   2-2
     *      2
     */
    //corner permutation
    const arr2: number[] = new Array<number>(3).fill(0);
    for (let i = 0; i < 12; i++) {
      for (let j = 0; j < 3; j++) {
        for (let k = 0; k < 4; k++) {
          Utils.idxToPerm(arr, i, 4, true);
          Utils.idxToPerm(arr2, j, 3, true);
          switch (k) {
            case 0: Utils.circle3(arr, 1, 2, 3); break;	//R
            case 1: Utils.circle3(arr, 0, 1, 3); break;	//U
            case 2: Utils.circle3(arr, 2, 0, 3); break;	//L
            case 3: Utils.circle3(arr2, 0, 2, 1); break;	//B
          }
          SkewbFCN.cpm[i * 3 + j][k] =
            Utils.permToIdx(arr, 4, true) * 3 + Utils.permToIdx(arr2, 3, true);
        }
      }
    }
    //corner orientation
    /*
     *		0
     *	1		2
     *		3
     *	4		5
     *		6
     */
    for (let i = 0; i < 2187; i++) {
      for (let j = 0; j < 4; j++) {
        Utils.idxToOri(arr, i, 7, false);
        switch (j) {
          case 0:
            Utils.circle3(arr, 2, 6, 3); arr[2] += 2; arr[3] += 2; arr[5]++; arr[6] += 2; break;
          case 1:
            Utils.circle3(arr, 1, 2, 3); arr[0]++; arr[1] += 2; arr[2] += 2; arr[3] += 2; break;
          case 2:
            Utils.circle3(arr, 1, 3, 6); arr[1] += 2; arr[3] += 2; arr[4]++; arr[6] += 2; break;
          case 3:
            Utils.circle3(arr, 0, 5, 4); arr[0] += 2; arr[3]++; arr[4] += 2; arr[5] += 2; break;
        }
        SkewbFCN.com[i][j] = Utils.oriToIdx(arr, 7, false);
      }
    }

    // distance table
    for (let i = 0; i < 360; i++) {
      SkewbFCN.ctd[i] = -1;
    }
    SkewbFCN.ctd[0] = 0;
    Utils.createPrun(SkewbFCN.ctd, 5, SkewbFCN.ctm, 2);

    for (let i = 0; i < 78732; i++) {
      SkewbFCN.cd[i] = -1;
    }
    SkewbFCN.cd[0] = 0;
    Utils.createPrun2(SkewbFCN.cd, 7, SkewbFCN.com, SkewbFCN.cpm, 2);
    SkewbFCN.inited = true;
  }

  private static search(ct: number, cp: number, co: number, d: number, l: number, seq: number[]): boolean {
    if (d == 0) {
      return ct == 0 && co == 0 && cp == 0;
    }
    if (SkewbFCN.ctd[ct] > d || SkewbFCN.cd[co * 36 + cp] > d) {
      return false;
    }
    if (l == -2) {
      const n0 = Math.floor(SkewbFCN.rnd() * 8);
      const k = Math.floor(n0 / 2);
      const n = n0 % 2;
      let p = ct;
      let q = cp;
      let r = co;
      for (let m = 0; m <= n; m++) {
        p = SkewbFCN.ctm[p][k];
        q = SkewbFCN.cpm[q][k];
        r = SkewbFCN.com[r][k];
      }
      if (SkewbFCN.search(p, q, r, d - 1, k, seq)) {
        seq[d] = (k << 1) | n;
        return true;
      }
    } else {
      for (let k = 0; k < 4; k++) {
        if (k != l) {
          let p = ct;
          let q = cp;
          let r = co;
          for (let m = 0; m < 2; m++) {
            p = SkewbFCN.ctm[p][k];
            q = SkewbFCN.cpm[q][k];
            r = SkewbFCN.com[r][k];
            if (SkewbFCN.search(p, q, r, d - 1, k, seq)) {
              seq[d] = (k << 1) | m;
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  public static scramble(): string {
    SkewbFCN.init();
    const ct = Math.floor(SkewbFCN.rnd() * 360);
    let cp: number;
    let co: number;
    do {
      cp = Math.floor(SkewbFCN.rnd() * 36);
      co = Math.floor(SkewbFCN.rnd() * 2187);
    } while (SkewbFCN.cd[co * 36 + cp] < 0);
    const seq: number[] = new Array<number>(12).fill(0);
    for (let d = 0; d < 12; d++) {
      if (SkewbFCN.search(ct, cp, co, d, -1, seq)) {
        if (d < 2) {
          return SkewbFCN.scramble();
        }
        if (d < 4) {
          continue;
        }
        let sol = '';
        for (let i = 1; i <= d; i++) {
          sol += SkewbFCN.turn[seq[i] >> 1] + SkewbFCN.suff[seq[i] & 1] + ' ';
        }
        return sol;
      }
    }
    return 'error';
  }

  private static scramble1(minLen: number): string {
    SkewbFCN.init();
    const ct = Math.floor(SkewbFCN.rnd() * 360);
    let cp: number;
    let co: number;
    do {
      cp = Math.floor(SkewbFCN.rnd() * 36);
      co = Math.floor(SkewbFCN.rnd() * 2187);
    } while (SkewbFCN.cd[co * 36 + cp] < 0);
    const seq: number[] = new Array<number>(12).fill(0);
    for (let d = 0; d < 12; d++) {
      if (SkewbFCN.search(ct, cp, co, d, -1, seq)) {
        if (d < minLen) {
          return 'error';
        }
        if (d < 11) {
          SkewbFCN.search(ct, cp, co, 11, -2, seq);
        }
        let sol = '';
        let last = -1;
        for (let i = 1; i <= 11; i++) {
          if (last == Math.floor(seq[i] / 2)) {
            return 'error';
          }
          sol += SkewbFCN.turn[seq[i] >> 1] + SkewbFCN.suff[seq[i] & 1] + ' ';
          last = seq[i] >> 1;
        }
        return sol;
      }
    }
    return 'error';
  }

  public static scrambleWCA(): string {
    let scr: string;
    do {
      scr = SkewbFCN.scramble1(7);
    } while (scr == 'error');
    return scr;
  }

  private static img: number[] = new Array<number>(30).fill(0);

  private static initColor(): void {
    for (let i = 0; i < 5; i++) {
      for (let j = 0; j < 6; j++) {
        SkewbFCN.img[j * 5 + i] = j;
      }
    }
  }

  private static move(turn: number): void {
    switch (turn) {
      case 0:	//R
        Utils.circle3(SkewbFCN.img, 17, 27, 22);
        Utils.circle3(SkewbFCN.img, 19, 29, 23);
        Utils.circle3(SkewbFCN.img, 1, 14, 8);
        Utils.circle3(SkewbFCN.img, 20, 18, 28);
        Utils.circle3(SkewbFCN.img, 16, 26, 24);
        break;
      case 1:	//U
        Utils.circle3(SkewbFCN.img, 2, 22, 7);
        Utils.circle3(SkewbFCN.img, 0, 21, 5);
        Utils.circle3(SkewbFCN.img, 3, 20, 8);
        Utils.circle3(SkewbFCN.img, 10, 16, 28);
        Utils.circle3(SkewbFCN.img, 6, 1, 24);
        break;
      case 2:	//L
        Utils.circle3(SkewbFCN.img, 12, 7, 27);
        Utils.circle3(SkewbFCN.img, 13, 9, 25);
        Utils.circle3(SkewbFCN.img, 3, 24, 18);
        Utils.circle3(SkewbFCN.img, 10, 8, 26);
        Utils.circle3(SkewbFCN.img, 6, 28, 14);
        break;
      case 3:	//B
        Utils.circle3(SkewbFCN.img, 22, 27, 7);
        Utils.circle3(SkewbFCN.img, 24, 28, 8);
        Utils.circle3(SkewbFCN.img, 0, 19, 13);
        Utils.circle3(SkewbFCN.img, 5, 23, 25);
        Utils.circle3(SkewbFCN.img, 21, 29, 9);
        break;
    }
  }

  public static image(scramble: string): number[] | null {
    SkewbFCN.initColor();
    const s = scramble.split(' ');
    for (let i = 0; i < s.length; i++) {
      if (s[i].length > 0) {
        const mov = 'RULB'.indexOf(s[i].charAt(0));
        if (mov < 0) {
          return null;
        }
        SkewbFCN.move(mov);
        if (s[i].length > 1) {
          if (s[i].charAt(1) != "'") {
            return null;
          }
          SkewbFCN.move(mov);
        }
      }
    }
    return SkewbFCN.img;
  }
}
