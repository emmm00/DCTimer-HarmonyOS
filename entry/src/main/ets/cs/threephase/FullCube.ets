// Ported from cs/threephase/FullCube.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Moves } from './Moves';
import { Center1 } from './Center1';
import { EdgeCube } from './EdgeCube';
import { CenterCube } from './CenterCube';
import { CornerCube } from './CornerCube';

// Java "new Random(seed)" LCG port (java.util.Random with long seed).
class SeededRandom {
  private seed: bigint = 0n;

  constructor(seed: number) {
    this.seed = (BigInt(seed) ^ 0x5deece66dn) & 0xffffffffffffn;
  }

  private next(bits: number): number {
    this.seed = (this.seed * 0x5deece66dn + 0xbn) & 0xffffffffffffn;
    return Number(this.seed >> BigInt(48 - bits));
  }

  nextInt(n: number): number {
    if ((n & -n) == n) {
      return Number((BigInt(this.next(31)) * BigInt(n)) >> 31n);
    }
    let bits = 0;
    let val = 0;
    do {
      bits = this.next(31);
      val = bits % n;
    } while (bits - val + (n - 1) < 0);
    return val;
  }
}

export class FullCube {
  // Java: implements Comparable<FullCube>
  // Java inner class ValueComparator (compare = c2.value - c1.value) -> static method.
  static valueComparator(c1: FullCube, c2: FullCube): number {
    return c2.value - c1.value;
  }

  private edge: EdgeCube = new EdgeCube();
  private center: CenterCube = new CenterCube();
  private corner: CornerCube = new CornerCube();

  value = 0;
  add1 = false;
  length1 = 0;
  length2 = 0;
  length3 = 0;

  public compareTo(c: FullCube): number {
    return this.value - c.value;
  }

  constructor();
  constructor(c: FullCube);
  constructor(rnd: () => number);
  constructor(seed: number);
  constructor(moveseq: number[]);
  constructor(rnd: () => number, part: number);
  constructor(a1?: FullCube | (() => number) | number | number[], a2?: number) {
    if (a1 === undefined) {
      return;
    }
    if (a1 instanceof FullCube) {
      this.copy(a1);
      return;
    }
    if (typeof a1 === 'function') {
      if (a2 === undefined) {
        this.edge = new EdgeCube(a1);
        this.center = new CenterCube(a1);
        this.corner = new CornerCube(a1);
      } else {
        this.edge = a2 == 0 ? new EdgeCube(a1) : new EdgeCube();
        this.center = a2 == 1 ? new CenterCube(a1) : new CenterCube();
        this.corner = a2 == 2 ? new CornerCube(a1) : new CornerCube();
      }
      return;
    }
    if (typeof a1 === 'number') {
      const r = new SeededRandom(a1);
      this.edge = new EdgeCube(() => { return Math.floor(r.nextInt(0x1000000) / 0x1000000); });
      this.center = new CenterCube(() => { return Math.floor(r.nextInt(0x1000000) / 0x1000000); });
      this.corner = new CornerCube(() => { return Math.floor(r.nextInt(0x1000000) / 0x1000000); });
      return;
    }
    for (let m = 0; m < a1.length; m++) {
      this.doMove(a1[m]);
    }
  }

  public copy(c: FullCube): void {
    this.edge.copy(c.edge);
    this.center.copy(c.center);
    this.corner.copy(c.corner);

    this.value = c.value;
    this.add1 = c.add1;
    this.length1 = c.length1;
    this.length2 = c.length2;
    this.length3 = c.length3;

    this.sym = c.sym;

    for (let i = 0; i < 60; i++) {
      this.moveBuffer[i] = c.moveBuffer[i];
    }

    this.moveLength = c.moveLength;
    this.edgeAvail = c.edgeAvail;
    this.centerAvail = c.centerAvail;
    this.cornerAvail = c.cornerAvail;
  }

  public checkEdge(): boolean {
    return this.getEdge().checkEdge();
  }

  public getMoveString(inverse: boolean, rotation: boolean): string {
    const fixedMoves: number[] = new Array<number>(this.moveLength - (this.add1 ? 2 : 0)).fill(0);
    let idx = 0;
    for (let i = 0; i < this.length1; i++) {
      fixedMoves[idx++] = this.moveBuffer[i];
    }
    let sym = this.sym;
    for (let i = this.length1 + (this.add1 ? 2 : 0); i < this.moveLength; i++) {
      if (Center1.symmove[sym][this.moveBuffer[i]] >= Moves.dx1) {
        fixedMoves[idx++] = Center1.symmove[sym][this.moveBuffer[i]] - 9;
        const rot = FullCube.move2rot[Center1.symmove[sym][this.moveBuffer[i]] - Moves.dx1];
        sym = Center1.symmult[sym][rot];
      } else {
        fixedMoves[idx++] = Center1.symmove[sym][this.moveBuffer[i]];
      }
    }
    const finishSym = Center1.symmult[Center1.syminv[sym]][Center1.getSolvedSym(this.getCenter())];

    let sb = '';
    sym = finishSym;
    if (inverse) {
      for (let i = idx - 1; i >= 0; i--) {
        let move = fixedMoves[i];
        move = Math.floor(move / 3) * 3 + (2 - move % 3);
        if (Center1.symmove[sym][move] >= Moves.dx1) {
          sb += Moves.move2str[Center1.symmove[sym][move] - 9] + ' ';
          const rot = FullCube.move2rot[Center1.symmove[sym][move] - Moves.dx1];
          sym = Center1.symmult[sym][rot];
        } else {
          sb += Moves.move2str[Center1.symmove[sym][move]] + ' ';
        }
      }
      if (rotation) {
        sb += Center1.rot2str[Center1.syminv[sym]] + ' '; // cube rotation after solution. for wca scramble, it should be omitted.
      }
    } else {
      for (let i = 0; i < idx; i++) {
        sb += Moves.move2str[fixedMoves[i]] + ' ';
      }
      if (rotation) {
        sb += Center1.rot2str[finishSym]; // cube rotation after solution.
      }
    }
    return sb;
  }

  private static move2rot: number[] = [35, 1, 34, 2, 4, 6, 22, 5, 19];

  to333Facelet(): string {
    const ret: number[] = new Array<number>(54).fill(0);
    this.getEdge().fill333Facelet(ret);
    this.getCenter().fill333Facelet(ret);
    this.getCorner().fill333Facelet(ret);
    let r = '';
    for (let i = 0; i < ret.length; i++) {
      r += String.fromCharCode(ret[i]);
    }
    return r;
  }

  moveBuffer: number[] = new Array<number>(60).fill(0);
  private moveLength = 0;
  private edgeAvail = 0;
  private centerAvail = 0;
  private cornerAvail = 0;

  sym = 0;

  move(m: number): void {
    this.moveBuffer[this.moveLength++] = m;
  }

  doMove(m: number): void {
    this.getEdge().move(m);
    this.getCenter().move(m);
    this.getCorner().move(m % 18);
  }

  getEdge(): EdgeCube {
    while (this.edgeAvail < this.moveLength) {
      this.edge.move(this.moveBuffer[this.edgeAvail++]);
    }
    return this.edge;
  }

  getCenter(): CenterCube {
    while (this.centerAvail < this.moveLength) {
      this.center.move(this.moveBuffer[this.centerAvail++]);
    }
    return this.center;
  }

  getCorner(): CornerCube {
    while (this.cornerAvail < this.moveLength) {
      this.corner.move(this.moveBuffer[this.cornerAvail++] % 18);
    }
    return this.corner;
  }
}
