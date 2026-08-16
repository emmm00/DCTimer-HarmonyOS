// Ported from cs/threephase/CenterCube.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Util } from './Util';
import { Moves } from './Moves';

export class CenterCube {
  ct: number[] = new Array<number>(24).fill(0);

  constructor();
  constructor(c: CenterCube);
  constructor(rnd: () => number);
  constructor(moveseq: number[]);
  constructor(a1?: CenterCube | (() => number) | number[]) {
    if (a1 === undefined) {
      for (let i = 0; i < 24; i++) {
        this.ct[i] = i >> 2;
      }
      return;
    }
    if (a1 instanceof CenterCube) {
      this.copy(a1);
      return;
    }
    if (typeof a1 === 'function') {
      for (let i = 0; i < 24; i++) {
        this.ct[i] = i >> 2;
      }
      for (let i = 0; i < 23; i++) {
        const t = i + Math.floor(a1() * (24 - i));
        if (this.ct[t] != this.ct[i]) {
          const m = this.ct[i];
          this.ct[i] = this.ct[t];
          this.ct[t] = m;
        }
      }
      return;
    }
    for (let i = 0; i < 24; i++) {
      this.ct[i] = i >> 2;
    }
    for (let m = 0; m < a1.length; m++) {
      this.move(a1[m]);
    }
  }

  static center333Map: number[] = [0, 4, 2, 1, 5, 3];

  copy(c: CenterCube): void {
    for (let i = 0; i < 24; i++) {
      this.ct[i] = c.ct[i];
    }
  }

  fill333Facelet(facelet: number[]): void {
    const firstIdx = 4;
    const inc = 9;
    for (let i = 0; i < 6; i++) {
      const idx = CenterCube.center333Map[i] << 2;
      if (this.ct[idx] != this.ct[idx + 1] || this.ct[idx + 1] != this.ct[idx + 2] ||
        this.ct[idx + 2] != this.ct[idx + 3]) {
        throw new Error('Unsolved Center');
      }
      facelet[firstIdx + i * inc] = Util.colorMap4to3[this.ct[idx]].charCodeAt(0);
    }
  }

  move(m: number): void {
    let key = m % 3;
    let axis = Math.floor(m / 3);
    switch (axis) {
      case 0: // U
        Util.swap(this.ct, 0, 1, 2, 3, key);
        break;
      case 1: // R
        Util.swap(this.ct, 16, 17, 18, 19, key);
        break;
      case 2: // F
        Util.swap(this.ct, 8, 9, 10, 11, key);
        break;
      case 3: // D
        Util.swap(this.ct, 4, 5, 6, 7, key);
        break;
      case 4: // L
        Util.swap(this.ct, 20, 21, 22, 23, key);
        break;
      case 5: // B
        Util.swap(this.ct, 12, 13, 14, 15, key);
        break;
      case 6: // u
        Util.swap(this.ct, 0, 1, 2, 3, key);
        Util.swap(this.ct, 8, 20, 12, 16, key);
        Util.swap(this.ct, 9, 21, 13, 17, key);
        break;
      case 7: // r
        Util.swap(this.ct, 16, 17, 18, 19, key);
        Util.swap(this.ct, 1, 15, 5, 9, key);
        Util.swap(this.ct, 2, 12, 6, 10, key);
        break;
      case 8: // f
        Util.swap(this.ct, 8, 9, 10, 11, key);
        Util.swap(this.ct, 2, 19, 4, 21, key);
        Util.swap(this.ct, 3, 16, 5, 22, key);
        break;
      case 9: // d
        Util.swap(this.ct, 4, 5, 6, 7, key);
        Util.swap(this.ct, 10, 18, 14, 22, key);
        Util.swap(this.ct, 11, 19, 15, 23, key);
        break;
      case 10: // l
        Util.swap(this.ct, 20, 21, 22, 23, key);
        Util.swap(this.ct, 0, 8, 4, 14, key);
        Util.swap(this.ct, 3, 11, 7, 13, key);
        break;
      case 11: // b
        Util.swap(this.ct, 12, 13, 14, 15, key);
        Util.swap(this.ct, 1, 20, 7, 18, key);
        Util.swap(this.ct, 0, 23, 6, 17, key);
        break;
    }
  }
}
