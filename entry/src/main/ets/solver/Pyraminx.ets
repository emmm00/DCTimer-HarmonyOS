// Ported from solver/Pyraminx.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';

export class Pyraminx {
  private static colmap: number[] = new Array<number>(91).fill(0);
  private static perm: number[] = new Array<number>(360).fill(0);	// pruning table for edge permutation
  private static twst: number[] = new Array<number>(2592).fill(0);	// pruning table for edge orientation+twist
  private static permmv: number[][] = Pyraminx.z2d(360, 4);	// transition table for edge permutation
  private static twstmv: number[][] = Pyraminx.z2d(81, 4);	// transition table for corner orientation
  private static flipmv: number[][] = Pyraminx.z2d(32, 4);	// transition table for edge orientation
  private static turn: string[] = ['L', 'R', 'B', 'U'];
  private static suff: string[] = ["'", ''];
  private static tips: string[] = ['l', 'r', 'b', 'u'];
  private static img: number[] = new Array<number>(91).fill(0);
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
    if (Pyraminx.inited) {
      return;
    }
    Pyraminx.calcperm();
    Pyraminx.inited = true;
  }

  public static scramble(): string {
    Pyraminx.init();
    let scramble: string;
    do {
      const t = Math.floor(Pyraminx.rnd() * 2592);
      const q = Math.floor(Pyraminx.rnd() * 360);
      scramble = Pyraminx.scramble1(q, t);
    } while (scramble == 'error');
    return scramble;
  }

  public static scrambleL4E(): string {
    Pyraminx.init();
    let scramble: string;
    do {
      const ps: number[] = [0, 1, 2, 3, 4, 5];
      Utils.idxToPerm(ps, Math.floor(Pyraminx.rnd() * 12), 4, true);
      const ts: number[] = new Array<number>(6).fill(0);
      Utils.idxToFlip(ts, Math.floor(Pyraminx.rnd() * 8), 4, true);
      const p = Utils.permToIdx(ps, 6, true);
      const t = Math.floor(Pyraminx.rnd() * 3) * 864 + Utils.flipToIdx(ts, 6, true);
      scramble = Pyraminx.scramble1(p, t);
    } while (scramble == 'error');
    return scramble;
  }

  private static scramble1(p: number, t: number): string {
    const seq: number[] = new Array<number>(12).fill(0);
    for (let l = 0; l < 12; l++) {
      if (Pyraminx.search(p, t, l, -1, seq)) {
        if (l < 2) {
          return 'error';
        }
        if (l < 5) {
          continue;
        }
        let sol = '';
        for (let i = 1; i <= l; i++) {
          sol += Pyraminx.turn[seq[i] >> 1] + Pyraminx.suff[seq[i] & 1] + ' ';
        }
        for (let i = 0; i < 4; i++) {
          const j = Math.floor(Pyraminx.rnd() * 3);
          if (j < 2) {
            sol += Pyraminx.tips[i] + Pyraminx.suff[j] + ' ';
          }
        }
        return sol;
      }
    }
    return 'error';
  }

  public static scrambleWCA(): string {
    let scr: string;
    do {
      scr = Pyraminx.scramble2(6);
    } while (scr == 'error');
    return scr;
  }

  private static scramble2(minLen: number): string {
    Pyraminx.init();
    let a = 0;
    const tip: number[] = new Array<number>(4).fill(0);
    for (let i = 0; i < 4; i++) {
      tip[i] = Math.floor(Pyraminx.rnd() * 3);
      if (tip[i] < 2) {
        a++;
      }
    }
    const t = Math.floor(Pyraminx.rnd() * 2592);
    const q = Math.floor(Pyraminx.rnd() * 360);
    const seq: number[] = new Array<number>(12).fill(0);
    for (let l = 0; l < 12; l++) {
      if (Pyraminx.search(q, t, l, -1, seq)) {
        if (l + a < minLen) {
          return 'error';
        }
        if (l < 11) {
          Pyraminx.search(q, t, 11, -2, seq);
        }
        let sol = '';
        let last = -1;
        for (let i = 1; i <= 11; i++) {
          if (last == Math.floor(seq[i] / 2)) {
            return 'error';
          }
          sol += Pyraminx.turn[seq[i] >> 1] + Pyraminx.suff[seq[i] & 1] + ' ';
          last = seq[i] >> 1;
        }
        for (let i = 0; i < 4; i++) {
          if (tip[i] < 2) {
            sol += Pyraminx.tips[i] + Pyraminx.suff[tip[i]] + ' ';
          }
        }
        return sol;
      }
    }
    return 'error';
  }

  private static search(p: number, t: number, l: number, lm: number, seq: number[]): boolean {
    //searches for solution, from position p|t, in l moves exactly. last move was lm, current depth=d
    if (l == 0) {
      return p == 0 && t == 0;
    }
    if (Pyraminx.perm[p] > l || Pyraminx.twst[t] > l) {
      return false;
    }
    let q: number;
    let s: number;
    let a: number;
    let m: number;
    if (lm == -2) {
      let n = Math.floor(Pyraminx.rnd() * 8);
      m = Math.floor(n / 2);
      n %= 2;
      q = p;
      s = t;
      for (a = 0; a <= n; a++) {
        q = Pyraminx.permmv[q][m];
        s = (Pyraminx.twstmv[s >> 5][m] << 5) | Pyraminx.flipmv[s & 31][m];
      }
      if (Pyraminx.search(q, s, l - 1, m, seq)) {
        seq[l] = (m << 1) | n;
        return true;
      }
    } else {
      for (m = 0; m < 4; m++) {
        if (m != lm) {
          q = p;
          s = t;
          for (a = 0; a < 2; a++) {
            q = Pyraminx.permmv[q][m];
            s = (Pyraminx.twstmv[s >> 5][m] << 5) | Pyraminx.flipmv[s & 31][m];
            if (Pyraminx.search(q, s, l - 1, m, seq)) {
              seq[l] = (m << 1) | a;
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  private static calcperm(): void {
    //calculate solving arrays
    //first permutation
    //initialise arrays
    for (let p = 0; p < 360; p++) {
      Pyraminx.perm[p] = -1;
      for (let m = 0; m < 4; m++) {
        Pyraminx.permmv[p][m] = Pyraminx.getprmmv(p, m);
      }
    }
    //fill it
    Pyraminx.perm[0] = 0;
    Utils.createPrun(Pyraminx.perm, 5, Pyraminx.permmv, 2);

    //then twist && flip
    //initialise arrays
    for (let p = 0; p < 81; p++) {
      for (let m = 0; m < 4; m++) {
        Pyraminx.twstmv[p][m] = Pyraminx.gettwsmv(p, m);
        if (p < 32) {
          Pyraminx.flipmv[p][m] = Pyraminx.getflpmv(p, m);
        }
      }
    }
    //fill it
    for (let p = 0; p < 2592; p++) {
      Pyraminx.twst[p] = -1;
    }
    Pyraminx.twst[0] = 0;
    Utils.createPrun2(Pyraminx.twst, 7, Pyraminx.twstmv, Pyraminx.flipmv, 2);
  }

  private static getprmmv(p: number, m: number): number {
    //given position p<360 and move m<4, return new position number
    //convert number into array
    const ps: number[] = new Array<number>(6).fill(0);
    //edge permutation
    Utils.idxToPerm(ps, p, 6, true);
    //perform move on array
    if (m == 0) {
      Utils.circle3(ps, 1, 5, 2);  //L
    } else if (m == 1) {
      Utils.circle3(ps, 0, 2, 4);  //R
    } else if (m == 2) {
      Utils.circle3(ps, 3, 4, 5);  //B
    } else if (m == 3) {
      Utils.circle3(ps, 0, 3, 1);  //U
    }
    //convert array back to number
    return Utils.permToIdx(ps, 6, true);
  }

  private static getflpmv(p: number, m: number): number {
    //given orientation p<32 and move m<4, return new position number
    //convert number into array;
    const ps: number[] = new Array<number>(6).fill(0);
    //edge orientation
    Utils.idxToFlip(ps, p, 6, true);
    //perform move on array
    switch (m) {
      case 0:	//L
        Utils.circle3(ps, 1, 5, 2);
        ps[2] ^= 1;
        ps[5] ^= 1;
        break;
      case 1:	//R
        Utils.circle3(ps, 0, 2, 4);
        ps[0] ^= 1;
        ps[2] ^= 1;
        break;
      case 2:	//B
        Utils.circle3(ps, 3, 4, 5);
        ps[3] ^= 1;
        ps[4] ^= 1;
        break;
      case 3:	//U
        Utils.circle3(ps, 0, 3, 1);
        ps[1] ^= 1;
        ps[3] ^= 1;
        break;
    }
    return Utils.flipToIdx(ps, 6, true);
  }

  private static gettwsmv(p: number, m: number): number {
    //given orientation p<81 and move m<4, return new position number
    //convert number into array;
    const ps: number[] = new Array<number>(4).fill(0);
    //corner orientation
    Utils.idxToOri(ps, p, 4, false);
    //perform move on array
    switch (m) {
      case 0:	//L
        ps[1]++;
        if (ps[1] == 3) {
          ps[1] = 0;
        }
        break;
      case 1:	//R
        ps[2]++;
        if (ps[2] == 3) {
          ps[2] = 0;
        }
        break;
      case 2:	//B
        ps[3]++;
        if (ps[3] == 3) {
          ps[3] = 0;
        }
        break;
      case 3:	//U
        ps[0]++;
        if (ps[0] == 3) {
          ps[0] = 0;
        }
        break;
    }
    //convert array back to number
    //corner orientation
    return Utils.oriToIdx(ps, 4, false);
  }

  private static picmove(type: number, direction: number): void {
    switch (type) {
      case 0: // L
        Pyraminx.rotate3(14, 58, 18, direction);
        Pyraminx.rotate3(15, 57, 31, direction);
        Pyraminx.rotate3(16, 70, 32, direction);
      case 4: // l
        Pyraminx.rotate3(30, 28, 56, direction);
        break;
      case 1: // R
        Pyraminx.rotate3(32, 72, 22, direction);
        Pyraminx.rotate3(33, 59, 23, direction);
        Pyraminx.rotate3(20, 58, 24, direction);
      case 5: // r
        Pyraminx.rotate3(34, 60, 36, direction);
        break;
      case 2: // B
        Pyraminx.rotate3(14, 10, 72, direction);
        Pyraminx.rotate3(1, 11, 71, direction);
        Pyraminx.rotate3(2, 24, 70, direction);
      case 6: // b
        Pyraminx.rotate3(0, 12, 84, direction);
        break;
      case 3: // U
        Pyraminx.rotate3(2, 18, 22, direction);
        Pyraminx.rotate3(3, 19, 9, direction);
        Pyraminx.rotate3(16, 20, 10, direction);
      case 7: // u
        Pyraminx.rotate3(4, 6, 8, direction);
        break;
    }
  }

  private static rotate3(v1: number, v2: number, v3: number, clockwise: number): void {
    if (clockwise == 2) {
      Utils.circle3(Pyraminx.colmap, v3, v2, v1);
    } else {
      Utils.circle3(Pyraminx.colmap, v1, v2, v3);
    }
  }

  public static image(scr: string): number[] {
    const s = scr.split(' ');
    Pyraminx.colmap = [
      1, 1, 1, 1, 1, 0, 2, 0, 3, 3, 3, 3, 3,
      0, 1, 1, 1, 0, 2, 2, 2, 0, 3, 3, 3, 0,
      0, 0, 1, 0, 2, 2, 2, 2, 2, 0, 3, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 4, 4, 4, 4, 4, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 4, 4, 4, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0
    ];
    let turn: number;
    let suff: number;
    for (let i = 0; i < s.length; i++) {
      suff = s[i].length;
      if (suff > 0) {
        turn = 'LRBUlrbu'.indexOf(s[i].charAt(0));
        Pyraminx.picmove(turn, suff);
      }
    }
    let d = 0;
    for (let x = 0; x < 91; x++) {
      Pyraminx.img[d++] = Pyraminx.colmap[x] - 1;
    }
    return Pyraminx.img;
  }
}
