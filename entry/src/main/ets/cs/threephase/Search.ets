// Ported from cs/threephase/Search.java (DCTimer-BLE -> HarmonyOS ArkTS)
// Note: this Search never had Android Handler/APP references; the async init lives in
// Util.init() which is called lazily by randomState()/randomCenter() (and can also be
// called explicitly). cs.min2phase.Search is called via its ported solution5().
import { Util } from './Util';
import { Moves } from './Moves';
import { Center1 } from './Center1';
import { Center2 } from './Center2';
import { Center3 } from './Center3';
import { Edge3 } from './Edge3';
import { FullCube } from './FullCube';
import { Search as Search333 } from '../min2phase/Search';

// Java java.util.PriorityQueue<FullCube> with FullCube.ValueComparator (max value polled
// first). Ported as an insertion-sorted list which has identical add/poll/clear/size/
// toArray semantics for this usage (toArray order is discarded by the caller's sort).
class PQueue {
  private data: FullCube[] = [];

  size(): number {
    return this.data.length;
  }

  clear(): void {
    this.data = [];
  }

  add(e: FullCube): void {
    let i = this.data.length;
    this.data.push(e);
    while (i > 0 && FullCube.valueComparator(this.data[i - 1], e) > 0) {
      this.data[i] = this.data[i - 1];
      i--;
    }
    this.data[i] = e;
  }

  poll(): FullCube {
    return this.data.pop() as FullCube;
  }

  toArray(): FullCube[] {
    return this.data.slice();
  }
}

export class Search {
  static readonly PHASE1_SOLUTIONS = 5000;
  static readonly PHASE2_ATTEMPTS = 500;
  static readonly PHASE2_SOLUTIONS = 100;
  static readonly PHASE3_ATTEMPTS = 100;

  private p1sols: PQueue = new PQueue();

  private move1: number[] = new Array<number>(100).fill(0);
  private move2: number[] = new Array<number>(10).fill(0);
  private move3: number[] = new Array<number>(15).fill(0);
  private length1 = 0;
  private length2 = 0;
  private maxlength2 = 0;
  private add1 = false;
  public c: FullCube = new FullCube();
  private c1: FullCube = new FullCube();
  private c2: FullCube = new FullCube();
  private ct2: Center2 = new Center2();
  private ct3: Center3 = new Center3();
  private e12: Edge3 = new Edge3();
  private tempe: Edge3[] = [];
  private search333: Search333 = new Search333();

  private valid1 = 0;
  public solution = '';

  private p1SolsCnt = 0;
  private arr2: FullCube[] = [];
  private arr2idx = 0;

  constructor() {
    for (let i = 0; i < 20; i++) {
      this.tempe.push(new Edge3());
    }
    for (let i = 0; i < Search.PHASE2_SOLUTIONS; i++) {
      this.arr2.push(new FullCube());
    }
  }

  static r: () => number = () => Math.random();

  public randomState(rot: boolean): string {
    Util.init();
    this.c = new FullCube(Search.r);
    this.search(rot);
    return this.solution;
  }

  public randomCenter(): string {
    Util.init();
    this.c = new FullCube(Search.r, 1);
    this.search(false);
    return this.solution;
  }

  private search(rot: boolean): void {
    this.solution = '';
    const ud = new Center1(this.c.getCenter(), 0).getsym();
    const fb = new Center1(this.c.getCenter(), 1).getsym();
    const rl = new Center1(this.c.getCenter(), 2).getsym();
    const udprun = Center1.csprun[ud >> 6];
    const fbprun = Center1.csprun[fb >> 6];
    const rlprun = Center1.csprun[rl >> 6];

    this.p1SolsCnt = 0;
    this.arr2idx = 0;
    this.p1sols.clear();

    for (this.length1 = Math.min(Math.min(udprun, fbprun), rlprun); this.length1 < 100; this.length1++) {
      if ((rlprun <= this.length1 && this.search1(rl >>> 6, rl & 0x3f, this.length1, -1, 0)) ||
        (udprun <= this.length1 && this.search1(ud >>> 6, ud & 0x3f, this.length1, -1, 0)) ||
        (fbprun <= this.length1 && this.search1(fb >>> 6, fb & 0x3f, this.length1, -1, 0))) {
        break;
      }
    }

    const p1SolsArr: FullCube[] = this.p1sols.toArray();
    p1SolsArr.sort((a: FullCube, b: FullCube) => a.value - b.value);

    let MAX_LENGTH2 = 9;
    let length12 = 0;
    do {
      for (length12 = p1SolsArr[0].value; length12 < 100; length12++) {
        let found = false;
        for (let i = 0; i < p1SolsArr.length; i++) {
          if (p1SolsArr[i].value > length12) {
            break;
          }
          if (length12 - p1SolsArr[i].length1 > MAX_LENGTH2) {
            continue;
          }
          this.c1.copy(p1SolsArr[i]);
          this.ct2.set(this.c1.getCenter(), this.c1.getEdge().getParity());
          const s2ct = this.ct2.getct();
          const s2rl = this.ct2.getrl();
          this.length1 = p1SolsArr[i].length1;
          this.length2 = length12 - p1SolsArr[i].length1;

          if (this.search2(s2ct, s2rl, this.length2, 28, 0)) {
            found = true;
            break;
          }
        }
        if (found) {
          break;
        }
      }
      MAX_LENGTH2++;
    } while (length12 == 100);

    const part: FullCube[] = [];
    for (let i = 0; i < this.arr2idx; i++) {
      part.push(this.arr2[i]);
    }
    part.sort((a: FullCube, b: FullCube) => a.value - b.value);
    for (let i = 0; i < this.arr2idx; i++) {
      this.arr2[i] = part[i];
    }

    let length123 = 0;
    let index = 0;

    let MAX_LENGTH3 = 13;
    do {
      for (length123 = this.arr2[0].value; length123 < 100; length123++) {
        let found = false;
        for (let i = 0; i < Math.min(this.arr2idx, Search.PHASE3_ATTEMPTS); i++) {
          if (this.arr2[i].value > length123) {
            break;
          }
          if (length123 - this.arr2[i].length1 - this.arr2[i].length2 > MAX_LENGTH3) {
            continue;
          }
          const eparity = this.e12.set(this.arr2[i].getEdge());
          this.ct3.set(this.arr2[i].getCenter(), eparity ^ this.arr2[i].getCorner().getParity());
          const ct = this.ct3.getct();
          const edge = this.e12.get(10);
          const prun = Edge3.getprun1(this.e12.getsym());
          const lm = 20;

          if (prun <= length123 - this.arr2[i].length1 - this.arr2[i].length2 &&
            this.search3(edge, ct, prun, length123 - this.arr2[i].length1 - this.arr2[i].length2, lm, 0)) {
            index = i;
            found = true;
            break;
          }
        }
        if (found) {
          break;
        }
      }
      MAX_LENGTH3++;
    } while (length123 == 100);

    const solcube = new FullCube(this.arr2[index]);
    this.length1 = solcube.length1;
    this.length2 = solcube.length2;
    const length = length123 - this.length1 - this.length2;

    for (let i = 0; i < length; i++) {
      solcube.move(Moves.move3std[this.move3[i]]);
    }

    const sol = this.search333.solution5(solcube.to333Facelet(), 21, 10000, 50, 0);
    if (sol.startsWith('Error')) {
      this.solution = sol;
      return;
    }
    const sol333 = Search.tomove(sol);
    for (let i = 0; i < sol333.length; i++) {
      solcube.move(sol333[i]);
    }

    let str = '';
    str += solcube.getMoveString(true, rot);

    this.solution = str;
  }

  public static tostr(moves: number[]): string {
    let s = '';
    for (let i = 0; i < moves.length; i++) {
      s += Moves.move2str[moves[i]] + ' ';
    }
    return s;
  }

  public static tomove(s: string): number[] {
    let t = s.replace(/\s/g, '');
    const arr: number[] = new Array<number>(t.length).fill(0);
    let j = 0;
    for (let i = 0, length = t.length; i < length; i++) {
      let axis = -1;
      switch (t.charAt(i)) {
        case 'U': axis = 0; break;
        case 'R': axis = 1; break;
        case 'F': axis = 2; break;
        case 'D': axis = 3; break;
        case 'L': axis = 4; break;
        case 'B': axis = 5; break;
        case 'u': axis = 6; break;
        case 'r': axis = 7; break;
        case 'f': axis = 8; break;
        case 'd': axis = 9; break;
        case 'l': axis = 10; break;
        case 'b': axis = 11; break;
        default: continue;
      }
      axis *= 3;
      if (++i < length) {
        switch (t.charAt(i)) {
          case '2': axis++; break;
          case "'": axis += 2; break;
          default: --i;
        }
      }
      arr[j++] = axis;
    }

    const ret: number[] = new Array<number>(j).fill(0);
    while (--j >= 0) {
      ret[j] = arr[j];
    }
    return ret;
  }

  private search1(ct: number, sym: number, maxl: number, lm: number, depth: number): boolean {
    if (ct == 0) {
      return maxl == 0 && this.init2(sym, lm);
    }
    for (let axis = 0; axis < 27; axis += 3) {
      if (axis == lm || axis == lm - 9 || axis == lm - 18) {
        continue;
      }
      for (let power = 0; power < 3; power++) {
        const m = axis + power;
        let ctx = Center1.ctsmv[ct][Center1.symmove[sym][m]];
        const prun = Center1.csprun[ctx >>> 6];
        if (prun >= maxl) {
          if (prun > maxl) {
            break;
          }
          continue;
        }
        const symx = Center1.symmult[sym][ctx & 0x3f];
        ctx >>>= 6;
        this.move1[depth] = m;
        if (this.search1(ctx, symx, maxl - 1, axis, depth + 1)) {
          return true;
        }
      }
    }
    return false;
  }

  private init2(sym: number, lm: number): boolean {
    this.c1.copy(this.c);
    for (let i = 0; i < this.length1; i++) {
      this.c1.move(this.move1[i]);
    }

    switch (Center1.finish[sym]) {
      case 0:
        this.c1.move(Moves.fx1);
        this.c1.move(Moves.bx3);
        this.move1[this.length1] = Moves.fx1;
        this.move1[this.length1 + 1] = Moves.bx3;
        this.add1 = true;
        sym = 19;
        break;
      case 12869:
        this.c1.move(Moves.ux1);
        this.c1.move(Moves.dx3);
        this.move1[this.length1] = Moves.ux1;
        this.move1[this.length1 + 1] = Moves.dx3;
        this.add1 = true;
        sym = 34;
        break;
      case 735470:
        this.add1 = false;
        sym = 0;
    }
    this.ct2.set(this.c1.getCenter(), this.c1.getEdge().getParity());
    const s2ct = this.ct2.getct();
    const s2rl = this.ct2.getrl();
    const ctp = Center2.ctprun[s2ct * 70 + s2rl];

    this.c1.value = ctp + this.length1;
    this.c1.length1 = this.length1;
    this.c1.add1 = this.add1;
    this.c1.sym = sym;
    this.p1SolsCnt++;

    let next: FullCube;
    if (this.p1sols.size() < Search.PHASE2_ATTEMPTS) {
      next = new FullCube(this.c1);
    } else {
      next = this.p1sols.poll();
      if (next.value > this.c1.value) {
        next.copy(this.c1);
      }
    }
    this.p1sols.add(next);

    return this.p1SolsCnt == Search.PHASE1_SOLUTIONS;
  }

  private search2(ct: number, rl: number, maxl: number, lm: number, depth: number): boolean {
    if (ct == 0 && Center2.ctprun[rl] == 0) {
      return maxl == 0 && this.init3();
    }
    for (let m = 0; m < 23; m++) {
      if (Moves.ckmv2[lm][m]) {
        m = Moves.skipAxis2[m];
        continue;
      }
      const ctx = Center2.ctmv[ct][m];
      const rlx = Center2.rlmv[rl][m];

      const prun = Center2.ctprun[ctx * 70 + rlx];
      if (prun >= maxl) {
        if (prun > maxl) {
          m = Moves.skipAxis2[m];
        }
        continue;
      }

      this.move2[depth] = Moves.move2std[m];
      if (this.search2(ctx, rlx, maxl - 1, m, depth + 1)) {
        return true;
      }
    }
    return false;
  }

  private init3(): boolean {
    this.c2.copy(this.c1);
    for (let i = 0; i < this.length2; i++) {
      this.c2.move(this.move2[i]);
    }
    if (!this.c2.checkEdge()) {
      return false;
    }
    const eparity = this.e12.set(this.c2.getEdge());
    this.ct3.set(this.c2.getCenter(), eparity ^ this.c2.getCorner().getParity());
    const ct = this.ct3.getct();
    const prun = Edge3.getprun1(this.e12.getsym());

    this.arr2[this.arr2idx].copy(this.c2);
    this.arr2[this.arr2idx].value = this.length1 + this.length2 + Math.max(prun, Center3.prun[ct]);
    this.arr2[this.arr2idx].length2 = this.length2;
    this.arr2idx++;

    return this.arr2idx == this.arr2.length;
  }

  public search3(edge: number, ct: number, prun: number, maxl: number, lm: number, depth: number): boolean {
    if (maxl == 0) {
      return edge == 0 && ct == 0;
    }
    this.tempe[depth].set2(edge);
    for (let m = 0; m < 17; m++) {
      if (Moves.ckmv3[lm][m]) {
        m = Moves.skipAxis3[m];
        continue;
      }
      const ctx = Center3.ctmove[ct][m];
      const prun1 = Center3.prun[ctx];
      if (prun1 >= maxl) {
        if (prun1 > maxl && m < 14) {
          m = Moves.skipAxis3[m];
        }
        continue;
      }
      const edgex = Edge3.getmvrot(this.tempe[depth].edge, m << 3, 10);

      const cord1x = Math.floor(edgex / Edge3.N_RAW);
      let symcord1x = Edge3.raw2sym[cord1x];
      const symx = symcord1x & 0x7;
      symcord1x >>= 3;
      const cord2x = Edge3.getmvrot(this.tempe[depth].edge, (m << 3) | symx, 10) % Edge3.N_RAW;

      const prunx = Edge3.getprun(symcord1x * Edge3.N_RAW + cord2x, prun);
      if (prunx >= maxl) {
        if (prunx > maxl && m < 14) {
          m = Moves.skipAxis3[m];
        }
        continue;
      }

      if (this.search3(edgex, ctx, prunx, maxl - 1, m, depth + 1)) {
        this.move3[depth] = m;
        return true;
      }
    }
    return false;
  }
}
