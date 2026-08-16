// Ported from cs/threephase/EdgeCube.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Util } from './Util';
import { Moves } from './Moves';

export class EdgeCube {
  static readonly EdgeColor: number[][] = [[Moves.F, Moves.U], [Moves.L, Moves.U], [Moves.B, Moves.U],
    [Moves.R, Moves.U], [Moves.B, Moves.D], [Moves.L, Moves.D], [Moves.F, Moves.D], [Moves.R, Moves.D],
    [Moves.F, Moves.L], [Moves.B, Moves.L], [Moves.B, Moves.R], [Moves.F, Moves.R]];

  static readonly EdgeMap: number[] = [Moves.F2, Moves.L2, Moves.B2, Moves.R2, Moves.B8, Moves.L8, Moves.F8,
    Moves.R8, Moves.F4, Moves.B6, Moves.B4, Moves.F6, Moves.U8, Moves.U4, Moves.U2, Moves.U6, Moves.D8, Moves.D4,
    Moves.D2, Moves.D6, Moves.L6, Moves.L4, Moves.R6, Moves.R4];

  ep: number[] = new Array<number>(24).fill(0);

  constructor();
  constructor(c: EdgeCube);
  constructor(rnd: () => number);
  constructor(moveseq: number[]);
  constructor(a1?: EdgeCube | (() => number) | number[]) {
    if (a1 === undefined) {
      for (let i = 0; i < 24; i++) {
        this.ep[i] = i;
      }
      return;
    }
    if (a1 instanceof EdgeCube) {
      this.copy(a1);
      return;
    }
    if (typeof a1 === 'function') {
      for (let i = 0; i < 24; i++) {
        this.ep[i] = i;
      }
      for (let i = 0; i < 23; i++) {
        const t = i + Math.floor(a1() * (24 - i));
        if (t != i) {
          const m = this.ep[i];
          this.ep[i] = this.ep[t];
          this.ep[t] = m;
        }
      }
      return;
    }
    for (let i = 0; i < 24; i++) {
      this.ep[i] = i;
    }
    for (let m = 0; m < a1.length; m++) {
      this.move(a1[m]);
    }
  }

  getParity(): number {
    return Util.parity(this.ep);
  }

  copy(c: EdgeCube): void {
    for (let i = 0; i < 24; i++) {
      this.ep[i] = c.ep[i];
    }
  }

  fill333Facelet(facelet: number[]): void {
    for (let i = 0; i < 24; i++) {
      facelet[EdgeCube.EdgeMap[i]] =
        Util.colorMap4to3[EdgeCube.EdgeColor[this.ep[i] % 12][Math.floor(this.ep[i] / 12)]].charCodeAt(0);
    }
  }

  checkEdge(): boolean {
    let ck = 0;
    let parity = false;
    for (let i = 0; i < 12; i++) {
      ck |= 1 << this.ep[i];
      parity = parity != this.ep[i] >= 12;
    }
    ck &= ck >> 12;
    return ck == 0 && !parity;
  }

  move(m: number): void {
    let key = m % 3;
    let axis = Math.floor(m / 3);
    switch (axis) {
      case 0: // U
        Util.swap(this.ep, 0, 1, 2, 3, key);
        Util.swap(this.ep, 12, 13, 14, 15, key);
        break;
      case 1: // R
        Util.swap(this.ep, 11, 15, 10, 19, key);
        Util.swap(this.ep, 23, 3, 22, 7, key);
        break;
      case 2: // F
        Util.swap(this.ep, 0, 11, 6, 8, key);
        Util.swap(this.ep, 12, 23, 18, 20, key);
        break;
      case 3: // D
        Util.swap(this.ep, 4, 5, 6, 7, key);
        Util.swap(this.ep, 16, 17, 18, 19, key);
        break;
      case 4: // L
        Util.swap(this.ep, 1, 20, 5, 21, key);
        Util.swap(this.ep, 13, 8, 17, 9, key);
        break;
      case 5: // B
        Util.swap(this.ep, 2, 9, 4, 10, key);
        Util.swap(this.ep, 14, 21, 16, 22, key);
        break;
      case 6: // u
        Util.swap(this.ep, 0, 1, 2, 3, key);
        Util.swap(this.ep, 12, 13, 14, 15, key);
        Util.swap(this.ep, 9, 22, 11, 20, key);
        break;
      case 7: // r
        Util.swap(this.ep, 11, 15, 10, 19, key);
        Util.swap(this.ep, 23, 3, 22, 7, key);
        Util.swap(this.ep, 2, 16, 6, 12, key);
        break;
      case 8: // f
        Util.swap(this.ep, 0, 11, 6, 8, key);
        Util.swap(this.ep, 12, 23, 18, 20, key);
        Util.swap(this.ep, 3, 19, 5, 13, key);
        break;
      case 9: // d
        Util.swap(this.ep, 4, 5, 6, 7, key);
        Util.swap(this.ep, 16, 17, 18, 19, key);
        Util.swap(this.ep, 8, 23, 10, 21, key);
        break;
      case 10: // l
        Util.swap(this.ep, 1, 20, 5, 21, key);
        Util.swap(this.ep, 13, 8, 17, 9, key);
        Util.swap(this.ep, 14, 0, 18, 4, key);
        break;
      case 11: // b
        Util.swap(this.ep, 2, 9, 4, 10, key);
        Util.swap(this.ep, 14, 21, 16, 22, key);
        Util.swap(this.ep, 7, 15, 1, 17, key);
        break;
    }
  }
}
