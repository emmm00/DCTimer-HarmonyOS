// Ported from solver/Domino.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';

export class Domino {
  private static cpm: number[][] = Domino.z2d(40320, 5);
  private static epm: number[][] = Domino.z2d(40320, 5);
  private static cpd: number[] = new Array<number>(40320).fill(0);
  private static epd: number[] = new Array<number>(40320).fill(0);
  private static faces: number[] = [3, 1, 1, 1, 1];
  private static turn: string[] = ['U', 'L', 'R', 'F', 'B'];
  private static seq: number[] = new Array<number>(20).fill(0);

  private static ini = false;

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  static init(): void {
    if (Domino.ini) {
      return;
    }
    const arr: number[] = new Array<number>(8).fill(0);
    const temp: number[] = new Array<number>(8).fill(0);
    for (let i = 0; i < 40320; i++) {
      Utils.set8Perm(temp, 8, i);
      for (let j = 0; j < 5; j++) {
        for (let n = 0; n < 8; n++) {
          arr[n] = temp[n];
        }
        switch (j) {
          case 0: Utils.circle(arr, 0, 3, 2, 1); break;	//U
          case 1: Utils.swap(arr, 0, 7, 3, 4); break;	//L
          case 2: Utils.swap(arr, 1, 6, 2, 5); break;	//R
          case 3: Utils.swap(arr, 3, 6, 2, 7); break;	//F
          case 4: Utils.swap(arr, 0, 5, 1, 4); break;	//B
        }
        Domino.cpm[i][j] = Utils.get8Perm(arr, 8);
        for (let n = 0; n < 8; n++) {
          arr[n] = temp[n];
        }
        switch (j) {
          case 0: Utils.circle(arr, 0, 3, 2, 1); break;	//U
          case 1: Utils.swap2(arr, 3, 7); break;	//L
          case 2: Utils.swap2(arr, 1, 5); break;	//R
          case 3: Utils.swap2(arr, 2, 6); break;	//F
          case 4: Utils.swap2(arr, 0, 4); break;	//B
        }
        Domino.epm[i][j] = Utils.get8Perm(arr, 8);
      }
    }

    for (let i = 1; i < 40320; i++) {
      Domino.cpd[i] = -1;
      Domino.epd[i] = -1;
    }
    Domino.cpd[0] = 0;
    Domino.epd[0] = 0;
    Utils.createPrun(Domino.cpd, 13, Domino.cpm, 3);
    Utils.createPrun(Domino.epd, 11, Domino.epm, 3);
    Domino.ini = true;
  }

  private static search(cp: number, ep: number, d: number, lf: number): boolean {
    if (d == 0) {
      return cp == 0 && ep == 0;
    }
    if (Domino.cpd[cp] > d || Domino.epd[ep] > d) {
      return false;
    }
    let y: number;
    let s: number;
    for (let i = 0; i < 5; i++) {
      if (i != lf) {
        y = cp;
        s = ep;
        for (let k = 0; k < Domino.faces[i]; k++) {
          y = Domino.cpm[y][i];
          s = Domino.epm[s][i];
          if (Domino.search(y, s, d - 1, i)) {
            Domino.seq[d] = i * 3 + (i < 1 ? k : 1);
            return true;
          }
        }
      }
    }
    return false;
  }

  public static scramble(): string {
    Domino.init();
    const rnd: () => number = Math.random;
    const cp = Math.floor(rnd() * 40320);
    const ep = Math.floor(rnd() * 40320);

    for (let d = 0; d < 19; d++) {
      if (Domino.search(cp, ep, d, -1)) {
        if (d < 2) {
          return Domino.scramble();
        }
        if (d < 4) {
          continue;
        }
        let s = '';
        for (let i = 1; i <= d; i++) {
          s += Domino.turn[Math.floor(Domino.seq[i] / 3)] + Utils.suffInv[Domino.seq[i] % 3] + ' ';
        }
        return s;
      }
    }
    return 'error';
  }

  private static img: number[] = new Array<number>(42).fill(0);

  private static initColor(): void {
    Domino.img = [
      3, 3, 3,
      3, 3, 3,
      3, 3, 3,
      5, 5, 5, 4, 4, 4, 2, 2, 2, 1, 1, 1,
      5, 5, 5, 4, 4, 4, 2, 2, 2, 1, 1, 1,
      0, 0, 0,
      0, 0, 0,
      0, 0, 0
    ];
  }

  private static move(turn: number): void {
    switch (turn) {
      case 0:	//U
        Utils.circle(Domino.img, 0, 6, 8, 2);
        Utils.circle(Domino.img, 1, 3, 7, 5);
        Utils.circle(Domino.img, 9, 12, 15, 18);
        Utils.circle(Domino.img, 10, 13, 16, 19);
        Utils.circle(Domino.img, 11, 14, 17, 20);
        break;
      case 1:	//D
        Utils.circle(Domino.img, 33, 39, 41, 35);
        Utils.circle(Domino.img, 34, 36, 40, 38);
        Utils.circle(Domino.img, 30, 27, 24, 21);
        Utils.circle(Domino.img, 31, 28, 25, 22);
        Utils.circle(Domino.img, 32, 29, 26, 23);
        break;
      case 2:	//L
        Utils.swap(Domino.img, 9, 23, 11, 21);
        Utils.swap(Domino.img, 10, 22, 3, 36);
        Utils.swap(Domino.img, 0, 33, 6, 39);
        Utils.swap(Domino.img, 20, 24, 32, 12);
        break;
      case 3:	//R
        Utils.swap(Domino.img, 15, 29, 17, 27);
        Utils.swap(Domino.img, 16, 28, 5, 38);
        Utils.swap(Domino.img, 8, 41, 2, 35);
        Utils.swap(Domino.img, 14, 30, 26, 18);
        break;
      case 4:	//F
        Utils.swap(Domino.img, 12, 26, 14, 24);
        Utils.swap(Domino.img, 13, 25, 7, 34);
        Utils.swap(Domino.img, 6, 35, 8, 33);
        Utils.swap(Domino.img, 11, 27, 15, 23);
        break;
      case 5:	//B
        Utils.swap(Domino.img, 18, 32, 20, 30);
        Utils.swap(Domino.img, 19, 31, 1, 40);
        Utils.swap(Domino.img, 2, 39, 0, 41);
        Utils.swap(Domino.img, 17, 21, 29, 9);
        break;
    }
  }

  public static image(scr: string): number[] {
    Domino.initColor();
    const s = scr.split(' ');
    for (let i = 0; i < s.length; i++) {
      if (s[i].length > 0) {
        const mov = 'UDLRFB'.indexOf(s[i].charAt(0));
        Domino.move(mov);
        if (s[i].length > 1 && mov < 2) {
          Domino.move(mov);
          if (s[i].charAt(1) == "'") {
            Domino.move(mov);
          }
        }
      }
    }
    return Domino.img;
  }
}
