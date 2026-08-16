// Ported from cs/threephase/Center2.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Util } from './Util';
import { Moves } from './Moves';
import { CenterCube } from './CenterCube';
import { Utils as SolverUtils } from '../../solver/Utils';

export class Center2 {
  rl: number[] = new Array<number>(8).fill(0);
  ct: number[] = new Array<number>(16).fill(0);
  parity = 0;

  static rlmv: number[][] = Center2.z2d(70, 28);
  static ctmv: number[][] = Center2.z2d(6435, 28);
  static rlrot: number[][] = Center2.z2d(70, 16);
  static ctrot: number[][] = Center2.z2d(6435, 16);
  static ctprun: number[] = new Array<number>(6435 * 35 * 2).fill(0);

  private static pmv: number[] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1,
    0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0];

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  public static initRl(): void {
    const c = new Center2();
    for (let i = 0; i < 35 * 2; i++) {
      for (let m = 0; m < 28; m++) {
        c.setrl(i);
        c.move(Moves.move2std[m]);
        Center2.rlmv[i][m] = c.getrl();
      }
    }
    for (let i = 0; i < 70; i++) {
      c.setrl(i);
      for (let j = 0; j < 16; j++) {
        Center2.rlrot[i][j] = c.getrl();
        c.rot(0);
        if ((j & 1) == 1) c.rot(1);
        if ((j & 7) == 7) c.rot(2);
      }
    }
  }

  public static initCt(): void {
    const c = new Center2();
    for (let i = 0; i < 6435; i++) {
      c.setct(i);
      for (let j = 0; j < 16; j++) {
        Center2.ctrot[i][j] = c.getct();
        c.rot(0);
        if ((j & 1) == 1) c.rot(1);
        if ((j & 7) == 7) c.rot(2);
      }
    }
    for (let i = 0; i < 6435; i++) {
      for (let m = 0; m < 28; m++) {
        c.setct(i);
        c.move(Moves.move2std[m]);
        Center2.ctmv[i][m] = c.getct();
      }
    }
    for (let i = 0; i < 6435 * 35 * 2; i++) {
      Center2.ctprun[i] = -1;
    }
    Center2.ctprun[0] = 0;
    Center2.ctprun[18] = 0;
    Center2.ctprun[28] = 0;
    Center2.ctprun[46] = 0;
    Center2.ctprun[54] = 0;
    Center2.ctprun[56] = 0;
    let depth = 0;
    let done = 6;
    while (done != 6435 * 35 * 2) {
      for (let i = 0; i < 6435 * 35 * 2; i++) {
        if (Center2.ctprun[i] == depth) {
          const ct = Math.floor(i / 70);
          const rl = i % 70;
          for (let m = 0; m < 23; m++) {
            const ctx = Center2.ctmv[ct][m];
            const rlx = Center2.rlmv[rl][m];
            const idx = ctx * 70 + rlx;
            if (Center2.ctprun[idx] == -1) {
              Center2.ctprun[idx] = depth + 1;
              done++;
            }
          }
        }
      }
      depth++;
    }
  }

  constructor();
  constructor(c: CenterCube);
  constructor(c?: CenterCube) {
    if (c === undefined) {
      return;
    }
    for (let i = 0; i < 16; i++) {
      this.ct[i] = Math.floor(c.ct[i] / 2);
    }
    for (let i = 0; i < 8; i++) {
      this.rl[i] = c.ct[i + 16];
    }
  }

  set(c: CenterCube, edgeParity: number): void {
    for (let i = 0; i < 16; i++) {
      this.ct[i] = Math.floor(c.ct[i] / 2);
    }
    for (let i = 0; i < 8; i++) {
      this.rl[i] = c.ct[i + 16];
    }
    this.parity = edgeParity;
  }

  getrl(): number {
    let idx = 0;
    let r = 4;
    for (let i = 6; i >= 0; i--) {
      if (this.rl[i] != this.rl[7]) {
        idx += SolverUtils.Cnk[i][r--];
      }
    }
    return idx * 2 + this.parity;
  }

  private setrl(idx: number): void {
    this.parity = idx & 1;
    idx >>>= 1;
    let r = 4;
    this.rl[7] = 0;
    for (let i = 6; i >= 0; i--) {
      if (idx >= SolverUtils.Cnk[i][r]) {
        idx -= SolverUtils.Cnk[i][r--];
        this.rl[i] = 1;
      } else {
        this.rl[i] = 0;
      }
    }
  }

  getct(): number {
    let idx = 0;
    let r = 8;
    for (let i = 14; i >= 0; i--) {
      if (this.ct[i] != this.ct[15]) {
        idx += SolverUtils.Cnk[i][r--];
      }
    }
    return idx;
  }

  private setct(idx: number): void {
    let r = 8;
    this.ct[15] = 0;
    for (let i = 14; i >= 0; i--) {
      if (idx >= SolverUtils.Cnk[i][r]) {
        idx -= SolverUtils.Cnk[i][r--];
        this.ct[i] = 1;
      } else {
        this.ct[i] = 0;
      }
    }
  }

  private rot(r: number): void {
    switch (r) {
      case 0:
        this.move(Moves.ux2);
        this.move(Moves.dx2);
        break;
      case 1:
        this.move(Moves.rx1);
        this.move(Moves.lx3);
        break;
      case 2:
        Util.swap(this.ct, 0, 3, 1, 2, 1);
        Util.swap(this.ct, 8, 11, 9, 10, 1);
        Util.swap(this.ct, 4, 7, 5, 6, 1);
        Util.swap(this.ct, 12, 15, 13, 14, 1);
        Util.swap(this.rl, 0, 3, 5, 6, 1);
        Util.swap(this.rl, 1, 2, 4, 7, 1);
        break;
    }
  }

  private move(m: number): void {
    this.parity ^= Center2.pmv[m];
    let key = m % 3;
    let axis = Math.floor(m / 3);
    switch (axis) {
      case 0: // U
        Util.swap(this.ct, 0, 1, 2, 3, key);
        break;
      case 1: // R
        Util.swap(this.rl, 0, 1, 2, 3, key);
        break;
      case 2: // F
        Util.swap(this.ct, 8, 9, 10, 11, key);
        break;
      case 3: // D
        Util.swap(this.ct, 4, 5, 6, 7, key);
        break;
      case 4: // L
        Util.swap(this.rl, 4, 5, 6, 7, key);
        break;
      case 5: // B
        Util.swap(this.ct, 12, 13, 14, 15, key);
        break;
      case 6: // u
        Util.swap(this.ct, 0, 1, 2, 3, key);
        Util.swap(this.rl, 0, 5, 4, 1, key);
        Util.swap(this.ct, 8, 9, 12, 13, key);
        break;
      case 7: // r
        Util.swap(this.rl, 0, 1, 2, 3, key);
        Util.swap(this.ct, 1, 15, 5, 9, key);
        Util.swap(this.ct, 2, 12, 6, 10, key);
        break;
      case 8: // f
        Util.swap(this.ct, 8, 9, 10, 11, key);
        Util.swap(this.rl, 0, 3, 6, 5, key);
        Util.swap(this.ct, 3, 2, 5, 4, key);
        break;
      case 9: // d
        Util.swap(this.ct, 4, 5, 6, 7, key);
        Util.swap(this.rl, 3, 2, 7, 6, key);
        Util.swap(this.ct, 11, 10, 15, 14, key);
        break;
      case 10: // l
        Util.swap(this.rl, 4, 5, 6, 7, key);
        Util.swap(this.ct, 0, 8, 4, 14, key);
        Util.swap(this.ct, 3, 11, 7, 13, key);
        break;
      case 11: // b
        Util.swap(this.ct, 12, 13, 14, 15, key);
        Util.swap(this.rl, 1, 4, 7, 2, key);
        Util.swap(this.ct, 1, 0, 7, 6, key);
        break;
    }
  }
}
