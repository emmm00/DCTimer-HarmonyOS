// Ported from cs/threephase/CornerCube.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Util } from './Util';
import { Moves } from './Moves';
import { Utils as SolverUtils } from '../../solver/Utils';

export class CornerCube {
  /**
   * 18 move cubes
   */
  private static moveCube: CornerCube[] = new Array<CornerCube>(18);

  private cp: number[] = [0, 1, 2, 3, 4, 5, 6, 7];
  private co: number[] = [0, 0, 0, 0, 0, 0, 0, 0];

  temps: CornerCube | null = null;

  constructor();
  constructor(rnd: () => number);
  constructor(cperm: number, twist: number);
  constructor(c: CornerCube);
  constructor(a1?: (() => number) | number | CornerCube, a2?: number) {
    if (a1 === undefined) {
      return;
    }
    if (typeof a1 === 'function') {
      this.setCPerm(Math.floor(a1() * 40320));
      this.setTwist(Math.floor(a1() * 2187));
      return;
    }
    if (typeof a1 === 'number') {
      this.setCPerm(a1);
      this.setTwist(a2 as number);
      return;
    }
    this.copy(a1);
  }

  copy(c: CornerCube): void {
    for (let i = 0; i < 8; i++) {
      this.cp[i] = c.cp[i];
    }
    for (let i = 0; i < 8; i++) {
      this.co[i] = c.co[i];
    }
  }

  getParity(): number {
    return Util.parity(this.cp);
  }

  static readonly cornerFacelet: number[][] = [[Moves.U9, Moves.R1, Moves.F3], [Moves.U7, Moves.F1, Moves.L3],
    [Moves.U1, Moves.L1, Moves.B3], [Moves.U3, Moves.B1, Moves.R3],
    [Moves.D3, Moves.F9, Moves.R7], [Moves.D1, Moves.L9, Moves.F7], [Moves.D7, Moves.B9, Moves.L7],
    [Moves.D9, Moves.R9, Moves.B7]];

  fill333Facelet(facelet: number[]): void {
    for (let corn = 0; corn < 8; corn++) {
      const j = this.cp[corn];
      const ori = this.co[corn];
      for (let n = 0; n < 3; n++) {
        facelet[CornerCube.cornerFacelet[corn][(n + ori) % 3]] =
          'URFDLB'.charCodeAt(Math.floor(CornerCube.cornerFacelet[j][n] / 9));
      }
    }
  }

  /**
   * prod = a * b, Corner Only.
   */
  static CornMult(a: CornerCube, b: CornerCube, prod: CornerCube): void {
    for (let corn = 0; corn < 8; corn++) {
      prod.cp[corn] = a.cp[b.cp[corn]];
      const oriA = a.co[b.cp[corn]];
      const oriB = b.co[corn];
      let ori = oriA;
      ori += (oriA < 3) ? oriB : 6 - oriB;
      ori %= 3;
      if (((oriA >= 3) ? 1 : 0) ^ ((oriB >= 3) ? 1 : 0)) {
        ori += 3;
      }
      prod.co[corn] = ori;
    }
  }

  setTwist(idx: number): void {
    let twst = 0;
    for (let i = 6; i >= 0; i--) {
      twst += this.co[i] = idx % 3;
      idx = Math.floor(idx / 3);
    }
    this.co[7] = (15 - twst) % 3;
  }

  private setCPerm(idx: number): void {
    SolverUtils.set8Perm(this.cp, 8, idx);
  }

  move(idx: number): void {
    if (this.temps == null) {
      this.temps = new CornerCube();
    }
    CornerCube.CornMult(this, CornerCube.moveCube[idx], this.temps);
    this.copy(this.temps);
  }

  private static inited = false;

  static init(): void {
    if (CornerCube.inited) {
      return;
    }
    CornerCube.moveCube[0] = new CornerCube(15120, 0);
    CornerCube.moveCube[3] = new CornerCube(21021, 1494);
    CornerCube.moveCube[6] = new CornerCube(8064, 1236);
    CornerCube.moveCube[9] = new CornerCube(9, 0);
    CornerCube.moveCube[12] = new CornerCube(1230, 412);
    CornerCube.moveCube[15] = new CornerCube(224, 137);
    for (let a = 0; a < 18; a += 3) {
      for (let p = 0; p < 2; p++) {
        CornerCube.moveCube[a + p + 1] = new CornerCube();
        CornerCube.CornMult(CornerCube.moveCube[a + p], CornerCube.moveCube[a], CornerCube.moveCube[a + p + 1]);
      }
    }
    CornerCube.inited = true;
  }
}

CornerCube.init();
