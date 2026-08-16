// Ported from solver/Tower.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';

export class Tower {
  static cpm: number[][] = Tower.z2d(40320, 4);
  static epm: number[][] = Tower.z2d(6, 4);
  static cpd: number[] = new Array<number>(40320).fill(0);
  static epd: number[] = [0, 1, 1, 2, 2, 3];
  private static faces: number[] = [3, 1, 1, 3];
  private static turn: string[] = ['U', 'R', 'F', 'D'];
  private static seq: number[] = new Array<number>(20).fill(0);

  private static ini = false;

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  public static init(): void {
    if (Tower.ini) {
      return;
    }
    const arr: number[] = new Array<number>(8).fill(0);
    for (let i = 0; i < 40320; i++) {
      for (let j = 0; j < 4; j++) {
        Utils.set8Perm(arr, 8, i);
        switch (j) {
          case 0: Utils.circle(arr, 0, 3, 2, 1); break;	//U
          case 1: Utils.swap(arr, 1, 5, 2, 6); break;	//R2
          case 2: Utils.swap(arr, 2, 4, 3, 5); break;	//F2
          case 3: Utils.circle(arr, 4, 7, 6, 5); break;	//D
        }
        Tower.cpm[i][j] = Utils.get8Perm(arr, 8);
      }
    }
    for (let i = 1; i < 40320; i++) {
      Tower.cpd[i] = -1;
    }
    Tower.cpd[0] = 0;
    Utils.createPrun(Tower.cpd, 13, Tower.cpm, 3);
    for (let i = 0; i < 6; i++) {
      for (let j = 0; j < 4; j++) {
        Utils.idxToPerm(arr, i, 3, false);
        switch (j) {
          case 1: Utils.swap2(arr, 0, 1); break;	//R2
          case 2: Utils.swap2(arr, 1, 2); break;	//F2
        }
        Tower.epm[i][j] = Utils.permToIdx(arr, 3, false);
      }
    }
    Tower.ini = true;
  }

  private static search(cp: number, ep: number, d: number, lf: number): boolean {
    if (d == 0) {
      return cp == 0 && ep == 0;
    }
    if (Tower.cpd[cp] > d || Tower.epd[ep] > d) {
      return false;
    }
    let y: number;
    let s: number;
    for (let i = 0; i < 4; i++) {
      if (i != lf) {
        y = cp;
        s = ep;
        for (let k = 0; k < Tower.faces[i]; k++) {
          y = Tower.cpm[y][i];
          s = Tower.epm[s][i];
          if (Tower.search(y, s, d - 1, i)) {
            Tower.seq[d] = i * 3 + (Tower.faces[i] == 1 ? 1 : k);
            return true;
          }
        }
      }
    }
    return false;
  }

  public static scramble(): string {
    Tower.init();
    const rnd: () => number = Math.random;
    const cp = Math.floor(rnd() * 40320);
    const ep = Math.floor(rnd() * 6);
    for (let d = 0; d < 20; d++) {
      if (Tower.search(cp, ep, d, -1)) {
        if (d < 2) {
          return Tower.scramble();
        }
        if (d < 4) {
          continue;
        }
        let sb = '';
        for (let i = 1; i <= d; i++) {
          sb += Tower.turn[Math.floor(Tower.seq[i] / 3)] + Utils.suffInv[Tower.seq[i] % 3] + ' ';
        }
        return sb;
      }
    }
    return 'error';
  }

  private static img: number[] = new Array<number>(32).fill(0);

  private static initColor(): void {
    Tower.img = [
      3, 3,
      3, 3,
      5, 5, 4, 4, 2, 2, 1, 1,
      5, 5, 4, 4, 2, 2, 1, 1,
      5, 5, 4, 4, 2, 2, 1, 1,
      0, 0,
      0, 0
    ];
  }

  private static move(turn: number): void {
    switch (turn) {
      case 0:	//U
        Utils.circle(Tower.img, 0, 2, 3, 1);
        Utils.circle(Tower.img, 5, 7, 9, 11);
        Utils.circle(Tower.img, 4, 6, 8, 10);
        break;
      case 1:	//R
        Utils.swap(Tower.img, 1, 29, 3, 31);
        Utils.swap(Tower.img, 8, 25, 9, 24);
        Utils.swap(Tower.img, 16, 17, 15, 18);
        Utils.swap(Tower.img, 7, 26, 23, 10);
        break;
      case 2:	//F
        Utils.swap(Tower.img, 2, 29, 3, 28);
        Utils.swap(Tower.img, 6, 23, 7, 22);
        Utils.swap(Tower.img, 14, 15, 13, 16);
        Utils.swap(Tower.img, 5, 24, 21, 8);
        break;
      case 3:	//D
        Utils.circle(Tower.img, 28, 30, 31, 29);
        Utils.circle(Tower.img, 27, 25, 23, 21);
        Utils.circle(Tower.img, 26, 24, 22, 20);
        break;
    }
  }

  public static image(scramble: string): number[] {
    Tower.initColor();
    for (const s of scramble.split(' ')) {
      if (s.length > 0) {
        const mov = 'URFD'.indexOf(s.charAt(0));
        Tower.move(mov);
        if (s.length > 1 && Tower.faces[mov] != 1) {
          Tower.move(mov);
          if (s.charAt(1) == "'") {
            Tower.move(mov);
          }
        }
      }
    }
    return Tower.img;
  }
}
