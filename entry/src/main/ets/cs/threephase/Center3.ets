// Ported from cs/threephase/Center3.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Util } from './Util';
import { CenterCube } from './CenterCube';
import { Utils as SolverUtils } from '../../solver/Utils';

export class Center3 {
  ud: number[] = new Array<number>(8).fill(0);
  rl: number[] = new Array<number>(8).fill(0);
  fb: number[] = new Array<number>(8).fill(0);
  parity = 0;

  static ctmove: number[][] = Center3.z2d(35 * 35 * 12 * 2, 20);
  static pmove: number[] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1];

  static prun: number[] = new Array<number>(35 * 35 * 12 * 2).fill(0);

  static rl2std: number[] = [0, 9, 14, 23, 27, 28, 41, 42, 46, 55, 60, 69];
  static std2rl: number[] = new Array<number>(70).fill(0);

  private static inited = false;

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  static init(): void {
    if (Center3.inited) {
      return;
    }
    for (let i = 0; i < 12; i++) {
      Center3.std2rl[Center3.rl2std[i]] = i;
    }
    Center3.inited = true;
  }

  public static createMove(): void {
    Center3.init();
    const c = new Center3();
    for (let i = 0; i < 35 * 35 * 12 * 2; i++) {
      for (let m = 0; m < 20; m++) {
        c.setct(i);
        c.move(m);
        Center3.ctmove[i][m] = c.getct();
      }
    }
  }

  public static createPrun(): void {
    Center3.init();
    for (let i = 0; i < 29400; i++) {
      Center3.prun[i] = -1;
    }
    Center3.prun[0] = 0;
    let depth = 0;
    let done = 1;
    while (done != 29400) {
      for (let i = 0; i < 29400; i++) {
        if (Center3.prun[i] == depth) {
          for (let m = 0; m < 17; m++) {
            if (Center3.prun[Center3.ctmove[i][m]] == -1) {
              Center3.prun[Center3.ctmove[i][m]] = depth + 1;
              done++;
            }
          }
        }
      }
      depth++;
    }
  }

  set(c: CenterCube, eXc_parity: number): void {
    const parity = ((c.ct[0] > c.ct[8]) ? 1 : 0) ^ ((c.ct[8] > c.ct[16]) ? 1 : 0) ^ ((c.ct[0] > c.ct[16]) ? 1 : 0);
    for (let i = 0; i < 8; i++) {
      this.ud[i] = (c.ct[i] & 1) ^ 1;
      this.fb[i] = (c.ct[i + 8] & 1) ^ 1;
      this.rl[i] = (c.ct[i + 16] & 1) ^ 1 ^ parity;
    }
    this.parity = parity ^ eXc_parity;
  }

  getct(): number {
    let idx = 0;
    let r = 4;
    for (let i = 6; i >= 0; i--) {
      if (this.ud[i] != this.ud[7]) {
        idx += SolverUtils.Cnk[i][r--];
      }
    }
    idx *= 35;
    r = 4;
    for (let i = 6; i >= 0; i--) {
      if (this.fb[i] != this.fb[7]) {
        idx += SolverUtils.Cnk[i][r--];
      }
    }
    idx *= 12;
    const check = this.fb[7] ^ this.ud[7];
    let idxrl = 0;
    r = 4;
    for (let i = 7; i >= 0; i--) {
      if (this.rl[i] != check) {
        idxrl += SolverUtils.Cnk[i][r--];
      }
    }
    return this.parity + 2 * (idx + Center3.std2rl[idxrl]);
  }

  setct(idx: number): void {
    this.parity = idx & 1;
    idx >>>= 1;
    let idxrl = Center3.rl2std[idx % 12];
    idx = Math.floor(idx / 12);
    let r = 4;
    for (let i = 7; i >= 0; i--) {
      this.rl[i] = 0;
      if (idxrl >= SolverUtils.Cnk[i][r]) {
        idxrl -= SolverUtils.Cnk[i][r--];
        this.rl[i] = 1;
      }
    }
    let idxfb = idx % 35;
    idx = Math.floor(idx / 35);
    r = 4;
    this.fb[7] = 0;
    for (let i = 6; i >= 0; i--) {
      if (idxfb >= SolverUtils.Cnk[i][r]) {
        idxfb -= SolverUtils.Cnk[i][r--];
        this.fb[i] = 1;
      } else {
        this.fb[i] = 0;
      }
    }
    r = 4;
    this.ud[7] = 0;
    for (let i = 6; i >= 0; i--) {
      if (idx >= SolverUtils.Cnk[i][r]) {
        idx -= SolverUtils.Cnk[i][r--];
        this.ud[i] = 1;
      } else {
        this.ud[i] = 0;
      }
    }
  }

  move(i: number): void {
    this.parity ^= Center3.pmove[i];
    switch (i) {
      case 0: // U
      case 1: // U2
      case 2: // U'
        Util.swap(this.ud, 0, 1, 2, 3, i % 3);
        break;
      case 3: // R2
        Util.swap(this.rl, 0, 1, 2, 3, 1);
        break;
      case 4: // F
      case 5: // F2
      case 6: // F'
        Util.swap(this.fb, 0, 1, 2, 3, (i - 1) % 3);
        break;
      case 7: // D
      case 8: // D2
      case 9: // D'
        Util.swap(this.ud, 4, 5, 6, 7, (i - 1) % 3);
        break;
      case 10: // L2
        Util.swap(this.rl, 4, 5, 6, 7, 1);
        break;
      case 11: // B
      case 12: // B2
      case 13: // B'
        Util.swap(this.fb, 4, 5, 6, 7, (i + 1) % 3);
        break;
      case 14: // u2
        Util.swap(this.ud, 0, 1, 2, 3, 1);
        Util.swap(this.rl, 0, 5, 4, 1, 1);
        Util.swap(this.fb, 0, 5, 4, 1, 1);
        break;
      case 15: // r2
        Util.swap(this.rl, 0, 1, 2, 3, 1);
        Util.swap(this.fb, 1, 4, 7, 2, 1);
        Util.swap(this.ud, 1, 6, 5, 2, 1);
        break;
      case 16: // f2
        Util.swap(this.fb, 0, 1, 2, 3, 1);
        Util.swap(this.ud, 3, 2, 5, 4, 1);
        Util.swap(this.rl, 0, 3, 6, 5, 1);
        break;
      case 17: // d2
        Util.swap(this.ud, 4, 5, 6, 7, 1);
        Util.swap(this.rl, 3, 2, 7, 6, 1);
        Util.swap(this.fb, 3, 2, 7, 6, 1);
        break;
      case 18: // l2
        Util.swap(this.rl, 4, 5, 6, 7, 1);
        Util.swap(this.fb, 0, 3, 6, 5, 1);
        Util.swap(this.ud, 0, 3, 4, 7, 1);
        break;
      case 19: // b2
        Util.swap(this.fb, 4, 5, 6, 7, 1);
        Util.swap(this.ud, 0, 7, 6, 1, 1);
        Util.swap(this.rl, 1, 4, 7, 2, 1);
        break;
    }
  }
}
