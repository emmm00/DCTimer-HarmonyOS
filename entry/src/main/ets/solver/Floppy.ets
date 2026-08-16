// Ported from solver/Floppy.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';

export class Floppy {
  private static distance: number[][] = Floppy.z2d(24, 16);
  private static turn: string[] = ['U', 'R', 'D', 'L'];
  private static seq: number[] = new Array<number>(10).fill(0);
  static arr: number[] = new Array<number>(4).fill(0);
  static inited = false;

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  static init(): void {
    if (Floppy.inited) {
      return;
    }
    for (let i = 0; i < 24; i++) {
      for (let j = 0; j < 16; j++) {
        Floppy.distance[i][j] = -1;
      }
    }
    Floppy.distance[0][0] = 0;
    let n = 1;
    for (let depth = 0; depth < 8; depth++) {
      for (let i = 0; i < 24; i++) {
        for (let j = 0; j < 16; j++) {
          if (Floppy.distance[i][j] == depth) {
            for (let k = 0; k < 4; k++) {
              const cp = Floppy.permMove(i, k);
              const eo = Floppy.flipMove(j, k);
              if (Floppy.distance[cp][eo] == -1) {
                Floppy.distance[cp][eo] = depth + 1;
                n++;
              }
            }
          }
        }
      }
    }
    Floppy.inited = true;
  }

  private static permMove(cp: number, m: number): number {
    Utils.idxToPerm(Floppy.arr, cp, 4, false);
    switch (m) {
      case 0: Utils.swap2(Floppy.arr, 0, 1); break;	//U2
      case 1: Utils.swap2(Floppy.arr, 1, 2); break;	//R2
      case 2: Utils.swap2(Floppy.arr, 2, 3); break;	//D2
      case 3: Utils.swap2(Floppy.arr, 0, 3); break;	//L2
    }
    return Utils.permToIdx(Floppy.arr, 4, false);
  }

  private static flipMove(eo: number, m: number): number {
    Utils.idxToFlip(Floppy.arr, eo, 4, false);
    Floppy.arr[m] = 1 - Floppy.arr[m];
    return Utils.flipToIdx(Floppy.arr, 4, false);
  }

  private static search(cp: number, eo: number, d: number, lm: number): boolean {
    if (d == 0) {
      return cp == 0 && eo == 0;
    }
    if (Floppy.distance[cp][eo] > d) {
      return false;
    }
    for (let i = 0; i < 4; i++) {
      if (i != lm) {
        const cpi = Floppy.permMove(cp, i);
        const eoi = Floppy.flipMove(eo, i);
        if (Floppy.search(cpi, eoi, d - 1, i)) {
          Floppy.seq[d] = i;
          return true;
        }
      }
    }
    return false;
  }

  public static scramble(): string {
    Floppy.init();
    const rnd: () => number = Math.random;
    let cp: number;
    let eo: number;
    do {
      cp = Math.floor(rnd() * 24);
      eo = Math.floor(rnd() * 16);
    } while (Floppy.distance[cp][eo] < 2);
    for (let d = 3; d < 9; d++) {
      if (Floppy.search(cp, eo, d, -1)) {
        let sb = '';
        for (let i = 1; i <= d; i++) {
          sb += Floppy.turn[Floppy.seq[i]] + '2 ';
        }
        return sb;
      }
    }
    return 'error';
  }

  private static img: number[] = new Array<number>(30).fill(0);

  private static initColor(): void {
    Floppy.img = [
      3, 3, 3,
      5, 4, 4, 4, 2, 1, 1, 1,
      5, 4, 4, 4, 2, 1, 1, 1,
      5, 4, 4, 4, 2, 1, 1, 1,
      0, 0, 0
    ];
  }

  private static move(turn: number): void {
    switch (turn) {
      case 0: //U
        Utils.swap(Floppy.img, 0, 2, 3, 7);
        Utils.swap(Floppy.img, 4, 8, 6, 10);
        Utils.swap2(Floppy.img, 5, 9);
        break;
      case 1:	//R
        Utils.swap(Floppy.img, 7, 23, 2, 29);
        Utils.swap(Floppy.img, 6, 24, 22, 8);
        Utils.swap2(Floppy.img, 14, 16);
        break;
      case 2:	//D
        Utils.swap(Floppy.img, 27, 29, 19, 23);
        Utils.swap(Floppy.img, 20, 24, 22, 26);
        Utils.swap2(Floppy.img, 21, 25);
        break;
      case 3:	//L
        Utils.swap(Floppy.img, 3, 19, 0, 27);
        Utils.swap(Floppy.img, 4, 26, 20, 10);
        Utils.swap2(Floppy.img, 12, 18);
        break;
    }
  }

  public static image(scr: string): number[] {
    Floppy.initColor();
    const s = scr.split(' ');
    for (let i = 0; i < s.length; i++) {
      if (s[i].length > 0) {
        Floppy.move('URDL'.indexOf(s[i].charAt(0)));
      }
    }
    return Floppy.img;
  }
}
