// Ported from scrambler/Redi.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from '../solver/Utils';

export class Redi {
  private static img: number[] = new Array<number>(48).fill(0);
  private static moveIdx = 'LRx';

  private static initColor(): void {
    Redi.img = [
      3, 3, 3,
      3, 3,
      3, 3, 3,
      5, 5, 5, 4, 4, 4, 2, 2, 2, 1, 1, 1,
      5, 5, 4, 4, 2, 2, 1, 1,
      5, 5, 5, 4, 4, 4, 2, 2, 2, 1, 1, 1,
      0, 0, 0,
      0, 0,
      0, 0, 0
    ];
  }

  private static move(turn: number): void {
    switch (turn) {
      case 0: // L
        Utils.circle3(Redi.img, 5, 10, 11);
        Utils.circle3(Redi.img, 3, 21, 12);
        Utils.circle3(Redi.img, 9, 22, 6);
        break;
      case 1: // R
        Utils.circle3(Redi.img, 7, 13, 14);
        Utils.circle3(Redi.img, 4, 12, 24);
        Utils.circle3(Redi.img, 6, 23, 15);
        break;
      case 2: // x
        Utils.circle(Redi.img, 0, 11, 40, 39);
        Utils.circle(Redi.img, 1, 12, 41, 38);
        Utils.circle(Redi.img, 2, 13, 42, 37);
        Utils.circle(Redi.img, 3, 22, 43, 27);
        Utils.circle(Redi.img, 4, 23, 44, 26);
        Utils.circle(Redi.img, 5, 31, 45, 19);
        Utils.circle(Redi.img, 6, 32, 46, 18);
        Utils.circle(Redi.img, 7, 33, 47, 17);
        Utils.circle(Redi.img, 8, 10, 30, 28);
        Utils.circle(Redi.img, 9, 21, 29, 20);
        Utils.circle(Redi.img, 14, 34, 36, 16);
        Utils.circle(Redi.img, 15, 24, 35, 25);
        break;
    }
  }

  static image(scr: string): number[] {
    Redi.initColor();
    const s = scr.split(' ');
    for (let i = 0; i < s.length; i++) {
      if (s[i].length > 0) {
        const mov = Redi.moveIdx.indexOf(s[i].charAt(0));
        Redi.move(mov);
        if (s[i].length > 1 && mov < 2) {
          Redi.move(mov);
        }
      }
    }
    return Redi.img;
  }
}
