// Ported from solver/UFO.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';

export class UFO {
  static pd: number[] = [];
  static movei: number[] = [5, 1, 1, 1];
  static ini = false;

  static init(): void {
    if (UFO.ini) {
      return;
    }
    const arr: number[] = new Array<number>(11).fill(0);
    const temp: number[] = new Array<number>(11).fill(0);
    UFO.pd = new Array<number>(Math.floor(39916800 / 8)).fill(0);
    for (let i = 0; i < UFO.pd.length; i++) {
      UFO.pd[i] = -1;
    }
    Utils.setPruning(UFO.pd, 0, 0);
    for (let d = 0; d < 14; d++) {
      let n = 0;
      for (let i = 0; i < 39916800; i++) {
        if (Utils.getPruning(UFO.pd, i) == d) {
          Utils.set11Perm(temp, i, 11);
          for (let k = 0; k < 4; k++) {
            for (let m = 0; m < 11; m++) {
              arr[m] = temp[m];
            }
            for (let m = 0; m < UFO.movei[k]; m++) {
              UFO.move(arr, k);
              const next = Utils.get11Perm(arr, 11);
              if (Utils.getPruning(UFO.pd, next) == 0xf) {
                Utils.setPruning(UFO.pd, next, d + 1);
                n++;
              }
            }
          }
        }
      }
    }
    UFO.ini = true;
  }

  static move(perm: number[], m: number): void {
    switch (m) {
      case 0:	//U
        const a = perm[0];
        perm[0] = perm[5];
        perm[5] = perm[4];
        perm[4] = perm[3];
        perm[3] = perm[2];
        perm[2] = perm[1];
        perm[1] = a;
        break;
      case 1:	//A
        Utils.swap(perm, 4, 10, 0, 7);
        Utils.swap2(perm, 5, 6);
        break;
      case 2:	//B
        Utils.swap(perm, 5, 6, 3, 8);
        Utils.swap2(perm, 4, 7);
        break;
      case 3:	//C
        Utils.swap(perm, 2, 7, 4, 9);
        Utils.swap2(perm, 3, 8);
        break;
    }
  }
}
