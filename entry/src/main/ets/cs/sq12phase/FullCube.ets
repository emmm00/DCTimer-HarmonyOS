// Ported from cs/sq12phase/FullCube.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Shape } from './Shape';
import { Square } from './Square';
import { Utils as SolverUtils } from '../../solver/Utils';

export class FullCube {
  ul = 0x011233;
  ur = 0x455677;
  dl = 0x998bba;
  dr = 0xddcffe;
  public ml = 0;

  constructor(s?: string) {
    // TODO
  }

  private static r: () => number = () => Math.random();

  public static randomCube(): FullCube {
    return FullCube.randomCube1(Math.floor(FullCube.r() * 3678));
  }

  public static randomCube1(shape: number): FullCube {
    return FullCube.randomCube2(shape, Math.floor(FullCube.r() * 40320), Math.floor(FullCube.r() * 40320));
  }

  public static randomCube2(shape: number, corner: number, edge: number): FullCube {
    shape = Shape.ShapeIdx[shape];
    const f = new FullCube();
    const pc: number[] = new Array<number>(8).fill(0);
    const pe: number[] = new Array<number>(8).fill(0);
    SolverUtils.set8Perm(pc, 8, corner);
    SolverUtils.set8Perm(pe, 8, edge);
    let cc = 0;
    let ec = 0;
    for (let i = 0; i < 24; i++) {
      if (((shape >> i) & 1) == 0) { // edge
        f.setPiece(23 - i, pe[ec++] << 1);
      } else { // corner
        f.setPiece(23 - i, (pc[cc] << 1) | 1);
        f.setPiece(22 - i, (pc[cc++] << 1) | 1);
        i++;
      }
    }
    f.ml = Math.floor(FullCube.r() * 2);
    return f;
  }

  copy(c: FullCube): void {
    this.ul = c.ul;
    this.ur = c.ur;
    this.dl = c.dl;
    this.dr = c.dr;
    this.ml = c.ml;
  }

  /**
   * @param move
   * 0 = twist
   * [1, 11] = top move
   * [-1, -11] = bottom move
   * for example, 6 == (6, 0), 9 == (-3, 0), -4 == (0, 4)
   */
  doMove(move: number): void {
    move <<= 2;
    if (move > 24) {
      move = 48 - move;
      const temp = this.ul;
      this.ul = (this.ul >> move | this.ur << (24 - move)) & 0xffffff;
      this.ur = (this.ur >> move | temp << (24 - move)) & 0xffffff;
    } else if (move > 0) {
      const temp = this.ul;
      this.ul = (this.ul << move | this.ur >> (24 - move)) & 0xffffff;
      this.ur = (this.ur << move | temp >> (24 - move)) & 0xffffff;
    } else if (move == 0) {
      const temp = this.ur;
      this.ur = this.dl;
      this.dl = temp;
      this.ml = 1 - this.ml;
    } else if (move >= -24) {
      move = -move;
      const temp = this.dl;
      this.dl = (this.dl << move | this.dr >> (24 - move)) & 0xffffff;
      this.dr = (this.dr << move | temp >> (24 - move)) & 0xffffff;
    } else if (move < -24) {
      move = 48 + move;
      const temp = this.dl;
      this.dl = (this.dl >> move | this.dr << (24 - move)) & 0xffffff;
      this.dr = (this.dr >> move | temp << (24 - move)) & 0xffffff;
    }
  }

  private pieceAt(idx: number): number {
    let ret = 0;
    if (idx < 6) {
      ret = this.ul >> ((5 - idx) << 2);
    } else if (idx < 12) {
      ret = this.ur >> ((11 - idx) << 2);
    } else if (idx < 18) {
      ret = this.dl >> ((17 - idx) << 2);
    } else {
      ret = this.dr >> ((23 - idx) << 2);
    }
    return ret & 0x0f;
  }

  private setPiece(idx: number, value: number): void {
    if (idx < 6) {
      this.ul &= ~(0xf << ((5 - idx) << 2));
      this.ul |= value << ((5 - idx) << 2);
    } else if (idx < 12) {
      this.ur &= ~(0xf << ((11 - idx) << 2));
      this.ur |= value << ((11 - idx) << 2);
    } else if (idx < 18) {
      this.dl &= ~(0xf << ((17 - idx) << 2));
      this.dl |= value << ((17 - idx) << 2);
    } else {
      this.dr &= ~(0xf << ((23 - idx) << 2));
      this.dr |= value << ((23 - idx) << 2);
    }
  }

  arr: number[] = new Array<number>(16).fill(0);

  getParity(): number {
    let cnt = 0;
    this.arr[0] = this.pieceAt(0);
    for (let i = 1; i < 24; i++) {
      if (this.pieceAt(i) != this.arr[cnt]) {
        this.arr[++cnt] = this.pieceAt(i);
      }
    }
    let p = 0;
    for (let a = 0; a < 16; a++) {
      for (let b = a + 1; b < 16; b++) {
        if (this.arr[a] > this.arr[b]) p ^= 1;
      }
    }
    return p;
  }

  getShapeIdx(): number {
    const urx = this.ur & 0x111111;
    let urx2 = urx;
    urx2 |= urx2 >> 3;
    urx2 |= urx2 >> 6;
    urx2 = (urx2 & 0xf) | ((urx2 >> 12) & 0x30);
    const ulx = this.ul & 0x111111;
    let ulx2 = ulx;
    ulx2 |= ulx2 >> 3;
    ulx2 |= ulx2 >> 6;
    ulx2 = (ulx2 & 0xf) | ((ulx2 >> 12) & 0x30);
    const drx = this.dr & 0x111111;
    let drx2 = drx;
    drx2 |= drx2 >> 3;
    drx2 |= drx2 >> 6;
    drx2 = (drx2 & 0xf) | ((drx2 >> 12) & 0x30);
    const dlx = this.dl & 0x111111;
    let dlx2 = dlx;
    dlx2 |= dlx2 >> 3;
    dlx2 |= dlx2 >> 6;
    dlx2 = (dlx2 & 0xf) | ((dlx2 >> 12) & 0x30);
    return Shape.getShape2Idx((this.getParity() << 24) | (ulx2 << 18) | (urx2 << 12) | (dlx2 << 6) | drx2);
  }

  prm: number[] = new Array<number>(8).fill(0);

  getSquare(sq: Square): void {
    for (let a = 0; a < 8; a++) {
      this.prm[a] = this.pieceAt(a * 3 + 1) >> 1;
    }
    // convert to number
    sq.cornperm = SolverUtils.get8Perm(this.prm, 8);

    let a = 0;
    let b = 0;
    // Strip top layer edges
    sq.topEdgeFirst = this.pieceAt(0) == this.pieceAt(1);
    a = sq.topEdgeFirst ? 2 : 0;
    for (b = 0; b < 4; a += 3, b++) {
      this.prm[b] = this.pieceAt(a) >> 1;
    }

    sq.botEdgeFirst = this.pieceAt(12) == this.pieceAt(13);
    a = sq.botEdgeFirst ? 14 : 12;

    for (; b < 8; a += 3, b++) {
      this.prm[b] = this.pieceAt(a) >> 1;
    }
    sq.edgeperm = SolverUtils.get8Perm(this.prm, 8);

    sq.ml = this.ml;
  }

  isSolved(): boolean {
    return this.ul == 0x011233 && this.ur == 0x455677 && this.dl == 0x998bba && this.dr == 0xddcffe && this.ml == 0;
  }
}
