// Ported from cs/threephase/Center1.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Util } from './Util';
import { Moves } from './Moves';
import { CenterCube } from './CenterCube';
import { Utils as SolverUtils } from '../../solver/Utils';

export class Center1 {
  static ctsmv: number[][] = Center1.z2d(15582, 36);
  static sym2raw: number[] = new Array<number>(15582).fill(0);
  static csprun: number[] = new Array<number>(15582).fill(0);

  static symmult: number[][] = Center1.z2d(48, 48);
  static symmove: number[][] = Center1.z2d(48, 36);
  static syminv: number[] = new Array<number>(48).fill(0);
  static finish: number[] = new Array<number>(48).fill(0);

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  public static init(): void {
    const c = new Center1();
    const raw2sym: number[] = new Array<number>(735471).fill(0);
    let count = 0;
    for (let i = 0; i < 735471; i++) {
      if ((raw2sym[i] & 1) == 0) {
        c.set(i);
        for (let j = 0; j < 48; j++) {
          const idx = c.get();
          raw2sym[idx] = ((count << 6) | Center1.syminv[j]) << 1 | 1;
          c.rot(0);
          if ((j & 1) == 1) c.rot(1);
          if ((j & 7) == 7) c.rot(2);
          if ((j & 15) == 15) c.rot(3);
        }
        Center1.sym2raw[count++] = i;
      }
    }
    const d = new Center1();
    for (let i = 0; i < 15582; i++) {
      d.set(Center1.sym2raw[i]);
      for (let m = 0; m < 36; m++) {
        c.set1(d);
        c.move(m);
        Center1.ctsmv[i][m] = raw2sym[c.get()] >> 1;
      }
    }
  }

  ct: number[] = new Array<number>(24).fill(0);

  constructor();
  constructor(ct: number[]);
  constructor(c: CenterCube, urf: number);
  constructor(a1?: CenterCube | number[], a2?: number) {
    if (a1 === undefined) {
      for (let i = 0; i < 8; i++) {
        this.ct[i] = 1;
      }
      for (let i = 8; i < 24; i++) {
        this.ct[i] = 0;
      }
      return;
    }
    if (a1 instanceof CenterCube) {
      for (let i = 0; i < 24; i++) {
        this.ct[i] = (Math.floor(a1.ct[i] / 2) == (a2 as number)) ? 1 : 0;
      }
      return;
    }
    for (let i = 0; i < 24; i++) {
      this.ct[i] = a1[i];
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

  set(idx: number): void {
    SolverUtils.idxToComb(this.ct, idx, 8, 24);
  }

  private get(): number {
    return SolverUtils.combToIdx(this.ct, 8, 24);
  }

  getsym(): number {
    for (let j = 0; j < 48; j++) {
      const cord = Center1.raw2sym(this.get());
      if (cord != -1) {
        return cord * 64 + j;
      }
      this.rot(0);
      if ((j & 1) == 1) this.rot(1);
      if ((j & 7) == 7) this.rot(2);
      if ((j & 15) == 15) this.rot(3);
    }
    return -1;
  }

  static raw2sym(n: number): number {
    const m = Util.binarySearch(Center1.sym2raw, n);
    return (m >= 0 ? m : -1);
  }

  set1(c: Center1): void {
    for (let i = 0; i < 24; i++) {
      this.ct[i] = c.ct[i];
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
        Util.swap(this.ct, 16, 19, 21, 22, 1);
        Util.swap(this.ct, 17, 18, 20, 23, 1);
        break;
      case 3:
        this.move(Moves.ux1);
        this.move(Moves.dx3);
        this.move(Moves.fx1);
        this.move(Moves.bx3);
        break;
    }
  }

  static rot2str: string[] = ['', 'y2', 'x', 'x y2', 'x2', 'z2', "x'", "x' y2", '', '', '', '', '', '', '', '',
    'y z', "y' z'", 'y2 z', "z'", "y' z", "y z'", 'z', 'z y2', '', '', '', '', '', '', '', '',
    "y' x'", 'y x', "y'", 'y', "y' x", "y x'", 'y z2', "y' z2", '', '', '', '', '', '', '', ''];

  private rotate(r: number): void {
    for (let j = 0; j < r; j++) {
      this.rot(0);
      if ((j & 1) == 1) this.rot(1);
      if ((j & 7) == 7) this.rot(2);
      if ((j & 15) == 15) this.rot(3);
    }
  }

  static getSolvedSym(cube: CenterCube): number {
    const c = new Center1(cube.ct);
    for (let j = 0; j < 48; j++) {
      let check = true;
      for (let i = 0; i < 24; i++) {
        if (c.ct[i] != Math.floor(i / 4)) {
          check = false;
          break;
        }
      }
      if (check) {
        return j;
      }
      c.rot(0);
      if ((j & 1) == 1) c.rot(1);
      if ((j & 7) == 7) c.rot(2);
      if ((j & 15) == 15) c.rot(3);
    }
    return -1;
  }

  equals(c: Center1): boolean {
    for (let i = 0; i < 24; i++) {
      if (this.ct[i] != c.ct[i]) {
        return false;
      }
    }
    return true;
  }

  static initSym(): void {
    const c = new Center1();
    for (let i = 0; i < 24; i++) {
      c.ct[i] = i;
    }
    const d = new Center1(c.ct);
    const e = new Center1(c.ct);
    const f = new Center1(c.ct);

    for (let i = 0; i < 48; i++) {
      for (let j = 0; j < 48; j++) {
        for (let k = 0; k < 48; k++) {
          if (c.equals(d)) {
            Center1.symmult[i][j] = k;
            if (k == 0) {
              Center1.syminv[i] = j;
            }
          }
          d.rot(0);
          if ((k & 1) == 1) d.rot(1);
          if ((k & 7) == 7) d.rot(2);
          if ((k & 15) == 15) d.rot(3);
        }
        c.rot(0);
        if ((j & 1) == 1) c.rot(1);
        if ((j & 7) == 7) c.rot(2);
        if ((j & 15) == 15) c.rot(3);
      }
      c.rot(0);
      if ((i & 1) == 1) c.rot(1);
      if ((i & 7) == 7) c.rot(2);
      if ((i & 15) == 15) c.rot(3);
    }

    for (let i = 0; i < 48; i++) {
      c.set1(e);
      c.rotate(Center1.syminv[i]);
      for (let j = 0; j < 36; j++) {
        d.set1(c);
        d.move(j);
        d.rotate(i);
        for (let k = 0; k < 36; k++) {
          f.set1(e);
          f.move(k);
          if (f.equals(d)) {
            Center1.symmove[i][j] = k;
            break;
          }
        }
      }
    }

    c.set(0);
    for (let i = 0; i < 48; i++) {
      Center1.finish[Center1.syminv[i]] = c.get();
      c.rot(0);
      if ((i & 1) == 1) c.rot(1);
      if ((i & 7) == 7) c.rot(2);
      if ((i & 15) == 15) c.rot(3);
    }
  }

  static createPrun(): void {
    for (let i = 1; i < 15582; i++) {
      Center1.csprun[i] = -1;
    }
    Center1.csprun[0] = 0;
    let depth = 0;

    while (depth < 8) {
      const inv = depth > 4;
      const select = inv ? -1 : depth;
      const check = inv ? depth : -1;
      depth++;
      for (let i = 0; i < 15582; i++) {
        if (Center1.csprun[i] == select) {
          for (let m = 0; m < 27; m++) {
            const idx = Center1.ctsmv[i][m] >>> 6;
            if (Center1.csprun[idx] == check) {
              if (inv) {
                Center1.csprun[i] = depth;
                break;
              } else {
                Center1.csprun[idx] = depth;
              }
            }
          }
        }
      }
    }
  }
}
