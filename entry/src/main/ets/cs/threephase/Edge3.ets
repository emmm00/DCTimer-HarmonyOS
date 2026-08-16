// Ported from cs/threephase/Edge3.java (DCTimer-BLE -> HarmonyOS ArkTS)
// Android Handler/Message imports removed: Edge3.createPrun(Handler) is now synchronous
// createPrun() without progress messages.
import { EdgeCube } from './EdgeCube';
import { Utils as SolverUtils } from '../../solver/Utils';

export class Edge3 {
  static readonly N_SYM = 1538;
  static readonly N_RAW = 20160;
  static readonly N_EPRUN = Edge3.N_SYM * Edge3.N_RAW;
  static readonly MAX_DEPTH = 10;
  static eprun: number[] | null = null;

  static sym2raw: number[] = new Array<number>(Edge3.N_SYM).fill(0);
  static symstate: number[] = new Array<number>(Edge3.N_SYM).fill(0);
  static raw2sym: number[] = new Array<number>(11880).fill(0);

  static syminv: number[] = [0, 1, 6, 3, 4, 5, 2, 7];

  edge: number[] = new Array<number>(12).fill(0);
  edgeo: number[] = new Array<number>(12).fill(0);
  temp: number[] | null = null;
  isStd = true;

  static mvrot: number[][] = Edge3.z2d(20 * 8, 12);
  static mvroto: number[][] = Edge3.z2d(20 * 8, 12);

  static factX: number[] = [1, 1, 1, 3, 12, 60, 360, 2520, 20160, 181440, 1814400, 19958400, 239500800];

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  static initMvrot(): void {
    const e = new Edge3();
    for (let m = 0; m < 20; m++) {
      for (let r = 0; r < 8; r++) {
        e.set2(0);
        e.move(m);
        e.rotate(r);
        for (let i = 0; i < 12; i++) {
          Edge3.mvrot[(m << 3) | r][i] = e.edge[i];
        }
        e.std();
        for (let i = 0; i < 12; i++) {
          Edge3.mvroto[(m << 3) | r][i] = (e.temp as number[])[i];
        }
      }
    }
  }

  static initRaw2Sym(): void {
    const e = new Edge3();
    const occ: number[] = new Array<number>(Math.floor(11880 / 8)).fill(0);
    let count = 0;
    for (let i = 0; i < 11880; i++) {
      if ((occ[i >>> 3] & (1 << (i & 7))) == 0) {
        e.set2(i * Edge3.factX[8]);
        for (let j = 0; j < 8; j++) {
          const idx = e.get(4);
          if (idx == i) {
            Edge3.symstate[count] |= 1 << j;
          }
          occ[idx >> 3] |= (1 << (idx & 7));
          Edge3.raw2sym[idx] = (count << 3) | Edge3.syminv[j];
          e.rot(0);
          if ((j & 1) == 1) {
            e.rot(1);
            e.rot(2);
          }
        }
        Edge3.sym2raw[count++] = i;
      }
    }
  }

  public static createPrun(): void {
    const e = new Edge3();
    const f = new Edge3();
    const g = new Edge3();
    const eprun = Edge3.eprun as number[];
    for (let i = 0; i < eprun.length; i++) {
      eprun[i] = -1;
    }
    let depth = 0;
    let done = 1;
    Edge3.setPruning(eprun, 0, 0);

    while (done != Edge3.N_EPRUN) {
      const inv = depth > 9;
      const depm3 = depth % 3;
      const dep1m3 = (depth + 1) % 3;
      const find = inv ? 0x3 : depm3;
      const chk = inv ? depm3 : 0x3;

      if (depth >= Edge3.MAX_DEPTH - 1) {
        break;
      }

      for (let i_ = 0; i_ < Edge3.N_EPRUN; i_ += 16) {
        let val = eprun[i_ >> 4];
        if (!inv && val == -1) {
          continue;
        }
        for (let i = i_, end = i_ + 16; i < end; i++, val >>= 2) {
          if ((val & 3) != find) {
            continue;
          }
          const symcord1 = Math.floor(i / Edge3.N_RAW);
          const cord1 = Edge3.sym2raw[symcord1];
          const cord2 = i % Edge3.N_RAW;
          e.set2(cord1 * Edge3.N_RAW + cord2);

          for (let m = 0; m < 17; m++) {
            const cord1x = Edge3.getmvrot(e.edge, m << 3, 4);
            let symcord1x = Edge3.raw2sym[cord1x];
            const symx = symcord1x & 0x7;
            symcord1x >>= 3;
            const cord2x = Edge3.getmvrot(e.edge, (m << 3) | symx, 10) % Edge3.N_RAW;
            const idx = symcord1x * Edge3.N_RAW + cord2x;
            if (Edge3.getPruning(eprun, idx) != chk) {
              continue;
            }
            Edge3.setPruning(eprun, inv ? i : idx, dep1m3);
            done++;
            if (inv) {
              break;
            }
            const symState0 = Edge3.symstate[symcord1x];
            let symState = symState0;
            if (symState == 1) {
              continue;
            }
            f.set1(e);
            f.move(m);
            f.rotate(symx);
            for (let j = 1; (symState >>= 1) != 0; j++) {
              if ((symState & 1) == 1) {
                g.set1(f);
                g.rotate(j);
                const idxx = symcord1x * Edge3.N_RAW + g.get(10) % Edge3.N_RAW;
                if (Edge3.getPruning(eprun, idxx) == chk) {
                  Edge3.setPruning(eprun, idxx, dep1m3);
                  done++;
                }
              }
            }
          }
        }
      }
      depth++;
    }
  }

  static setPruning(table: number[], index: number, value: number): void {
    table[index >> 4] ^= (0x3 ^ value) << ((index & 0xf) << 1);
  }

  static getPruning(table: number[], index: number): number {
    return (table[index >> 4] >> ((index & 0xf) << 1)) & 0x3;
  }

  static getprun(edge: number, prun: number): number {
    const eprun = Edge3.eprun as number[];
    const depm3 = Edge3.getPruning(eprun, edge);
    if (depm3 == 0x3) {
      return Edge3.MAX_DEPTH;
    }
    return (depm3 - prun + 16) % 3 + prun - 1;
  }

  static getprun1(edge: number): number {
    const e = new Edge3();
    let depth = 0;
    const eprun = Edge3.eprun as number[];
    let depm3 = Edge3.getPruning(eprun, edge);
    if (depm3 == 0x3) {
      return Edge3.MAX_DEPTH;
    }
    while (edge != 0) {
      if (depm3 == 0) {
        depm3 = 2;
      } else {
        depm3--;
      }
      const symcord1 = Math.floor(edge / Edge3.N_RAW);
      const cord1 = Edge3.sym2raw[symcord1];
      const cord2 = edge % Edge3.N_RAW;
      e.set2(cord1 * Edge3.N_RAW + cord2);
      for (let m = 0; m < 17; m++) {
        const cord1x = Edge3.getmvrot(e.edge, m << 3, 4);
        let symcord1x = Edge3.raw2sym[cord1x];
        const symx = symcord1x & 0x7;
        symcord1x >>= 3;
        const cord2x = Edge3.getmvrot(e.edge, (m << 3) | symx, 10) % Edge3.N_RAW;
        const idx = symcord1x * Edge3.N_RAW + cord2x;
        if (Edge3.getPruning(eprun, idx) == depm3) {
          depth++;
          edge = idx;
          break;
        }
      }
    }
    return depth;
  }

  toString(): string {
    let sb = '';
    for (let i = 0; i < 12; i++) {
      sb += ' ' + '0123456789AB'.charAt(this.edge[i]);
    }
    sb += '\n';
    for (let i = 0; i < 12; i++) {
      sb += ' ' + '0123456789AB'.charAt(this.edgeo[i]);
    }
    return sb;
  }

  static FullEdgeMap: number[] = [0, 2, 4, 6, 1, 3, 7, 5, 8, 9, 10, 11];

  getsym(): number {
    const cord1x = this.get(4);
    let symcord1x = Edge3.raw2sym[cord1x];
    const symx = symcord1x & 0x7;
    symcord1x >>= 3;
    this.rotate(symx);
    const cord2x = this.get(10) % Edge3.N_RAW;
    return symcord1x * Edge3.N_RAW + cord2x;
  }

  set(c: EdgeCube): number {
    if (this.temp == null) {
      this.temp = new Array<number>(12).fill(0);
    }
    for (let i = 0; i < 12; i++) {
      (this.temp as number[])[i] = i;
      this.edge[i] = c.ep[Edge3.FullEdgeMap[i] + 12] % 12;
    }
    let parity = 1; // because of FullEdgeMap
    for (let i = 0; i < 12; i++) {
      while (this.edge[i] != i) {
        const t = this.edge[i];
        this.edge[i] = this.edge[t];
        this.edge[t] = t;
        const s = (this.temp as number[])[i];
        (this.temp as number[])[i] = (this.temp as number[])[t];
        (this.temp as number[])[t] = s;
        parity ^= 1;
      }
    }
    for (let i = 0; i < 12; i++) {
      this.edge[i] = (this.temp as number[])[c.ep[Edge3.FullEdgeMap[i]] % 12];
    }
    return parity;
  }

  private set1(e: Edge3): void {
    for (let i = 0; i < 12; i++) {
      this.edge[i] = e.edge[i];
    }
    for (let i = 0; i < 12; i++) {
      this.edgeo[i] = e.edgeo[i];
    }
    this.isStd = e.isStd;
  }

  static getmvrot(ep: number[], mrIdx: number, end: number): number {
    const movo = Edge3.mvroto[mrIdx];
    const mov = Edge3.mvrot[mrIdx];
    let idx = 0;
    let val = 0xba9876543210n;
    for (let i = 0; i < end; i++) {
      const v = movo[ep[mov[i]]] << 2;
      idx *= 12 - i;
      idx += Number((val >> BigInt(v)) & 0xfn);
      val -= 0x111111111110n << BigInt(v);
    }
    return idx;
  }

  std(): void {
    if (this.temp == null) {
      this.temp = new Array<number>(12).fill(0);
    }
    for (let i = 0; i < 12; i++) {
      (this.temp as number[])[this.edgeo[i]] = i;
    }
    for (let i = 0; i < 12; i++) {
      this.edge[i] = (this.temp as number[])[this.edge[i]];
      this.edgeo[i] = i;
    }
    this.isStd = true;
  }

  get(end: number): number {
    if (!this.isStd) {
      this.std();
    }
    let idx = 0;
    let val = 0xba9876543210n;
    for (let i = 0; i < end; i++) {
      const v = this.edge[i] << 2;
      idx *= 12 - i;
      idx += Number((val >> BigInt(v)) & 0xfn);
      val -= 0x111111111110n << BigInt(v);
    }
    return idx;
  }

  set2(idx: number): void {
    let val = 0xba9876543210n;
    let parity = 0;
    for (let i = 0; i < 11; i++) {
      const p = Edge3.factX[11 - i];
      let v = Math.floor(idx / p);
      idx = idx % p;
      parity ^= v;
      v <<= 2;
      this.edge[i] = Number((val >> BigInt(v)) & 0xfn);
      const m = (1n << BigInt(v)) - 1n;
      val = (val & m) + ((val >> 4n) & ~m);
    }
    if ((parity & 1) == 0) {
      this.edge[11] = Number(val);
    } else {
      this.edge[11] = this.edge[10];
      this.edge[10] = Number(val);
    }
    for (let i = 0; i < 12; i++) {
      this.edgeo[i] = i;
    }
    this.isStd = true;
  }

  move(i: number): void {
    this.isStd = false;
    switch (i) {
      case 0: // U
        this.circle(this.edge, 0, 4, 1, 5);
        this.circle(this.edgeo, 0, 4, 1, 5);
        break;
      case 1: // U2
        this.swap(this.edge, 0, 4, 1, 5);
        this.swap(this.edgeo, 0, 4, 1, 5);
        break;
      case 2: // U'
        this.circle(this.edge, 0, 5, 1, 4);
        this.circle(this.edgeo, 0, 5, 1, 4);
        break;
      case 3: // R2
        this.swap(this.edge, 5, 10, 6, 11);
        this.swap(this.edgeo, 5, 10, 6, 11);
        break;
      case 4: // F
        this.circle(this.edge, 0, 11, 3, 8);
        this.circle(this.edgeo, 0, 11, 3, 8);
        break;
      case 5: // F2
        this.swap(this.edge, 0, 11, 3, 8);
        this.swap(this.edgeo, 0, 11, 3, 8);
        break;
      case 6: // F'
        this.circle(this.edge, 0, 8, 3, 11);
        this.circle(this.edgeo, 0, 8, 3, 11);
        break;
      case 7: // D
        this.circle(this.edge, 2, 7, 3, 6);
        this.circle(this.edgeo, 2, 7, 3, 6);
        break;
      case 8: // D2
        this.swap(this.edge, 2, 7, 3, 6);
        this.swap(this.edgeo, 2, 7, 3, 6);
        break;
      case 9: // D'
        this.circle(this.edge, 2, 6, 3, 7);
        this.circle(this.edgeo, 2, 6, 3, 7);
        break;
      case 10: // L2
        this.swap(this.edge, 4, 8, 7, 9);
        this.swap(this.edgeo, 4, 8, 7, 9);
        break;
      case 11: // B
        this.circle(this.edge, 1, 9, 2, 10);
        this.circle(this.edgeo, 1, 9, 2, 10);
        break;
      case 12: // B2
        this.swap(this.edge, 1, 9, 2, 10);
        this.swap(this.edgeo, 1, 9, 2, 10);
        break;
      case 13: // B'
        this.circle(this.edge, 1, 10, 2, 9);
        this.circle(this.edgeo, 1, 10, 2, 9);
        break;
      case 14: // u2
        this.swap(this.edge, 0, 4, 1, 5);
        this.swap(this.edgeo, 0, 4, 1, 5);
        SolverUtils.swap2(this.edge, 9, 11);
        SolverUtils.swap2(this.edgeo, 8, 10);
        break;
      case 15: // r2
        this.swap(this.edge, 5, 10, 6, 11);
        this.swap(this.edgeo, 5, 10, 6, 11);
        SolverUtils.swap2(this.edge, 1, 3);
        SolverUtils.swap2(this.edgeo, 0, 2);
        break;
      case 16: // f2
        this.swap(this.edge, 0, 11, 3, 8);
        this.swap(this.edgeo, 0, 11, 3, 8);
        SolverUtils.swap2(this.edge, 5, 7);
        SolverUtils.swap2(this.edgeo, 4, 6);
        break;
      case 17: // d2
        this.swap(this.edge, 2, 7, 3, 6);
        this.swap(this.edgeo, 2, 7, 3, 6);
        SolverUtils.swap2(this.edge, 8, 10);
        SolverUtils.swap2(this.edgeo, 9, 11);
        break;
      case 18: // l2
        this.swap(this.edge, 4, 8, 7, 9);
        this.swap(this.edgeo, 4, 8, 7, 9);
        SolverUtils.swap2(this.edge, 0, 2);
        SolverUtils.swap2(this.edgeo, 1, 3);
        break;
      case 19: // b2
        this.swap(this.edge, 1, 9, 2, 10);
        this.swap(this.edgeo, 1, 9, 2, 10);
        SolverUtils.swap2(this.edge, 4, 6);
        SolverUtils.swap2(this.edgeo, 5, 7);
        break;
    }
  }

  rot(r: number): void {
    this.isStd = false;
    switch (r) {
      case 0:
        this.move(14);
        this.move(17);
        break;
      case 1:
        this.circlex(11, 5, 10, 6); // r
        this.circlex(5, 10, 6, 11);
        this.circlex(1, 2, 3, 0);
        this.circlex(4, 9, 7, 8); // l'
        this.circlex(8, 4, 9, 7);
        this.circlex(0, 1, 2, 3);
        break;
      case 2:
        this.swapx(4, 5); this.swapx(5, 4);
        this.swapx(11, 8); this.swapx(8, 11);
        this.swapx(7, 6); this.swapx(6, 7);
        this.swapx(9, 10); this.swapx(10, 9);
        this.swapx(1, 1); this.swapx(0, 0);
        this.swapx(3, 3); this.swapx(2, 2);
        break;
    }
  }

  rotate(r: number): void {
    while (r >= 2) {
      r -= 2;
      this.rot(1);
      this.rot(2);
    }
    if (r != 0) {
      this.rot(0);
    }
  }

  static tempi = 0;

  circle(arr: number[], a: number, b: number, c: number, d: number): void {
    Edge3.tempi = arr[d];
    arr[d] = arr[c];
    arr[c] = arr[b];
    arr[b] = arr[a];
    arr[a] = Edge3.tempi;
  }

  swap(arr: number[], a: number, b: number, c: number, d: number): void {
    Edge3.tempi = arr[a];
    arr[a] = arr[c];
    arr[c] = Edge3.tempi;
    Edge3.tempi = arr[b];
    arr[b] = arr[d];
    arr[d] = Edge3.tempi;
  }

  swapx(x: number, y: number): void {
    Edge3.tempi = this.edge[x];
    this.edge[x] = this.edgeo[y];
    this.edgeo[y] = Edge3.tempi;
  }

  circlex(a: number, b: number, c: number, d: number): void {
    Edge3.tempi = this.edgeo[d];
    this.edgeo[d] = this.edge[c];
    this.edge[c] = this.edgeo[b];
    this.edgeo[b] = this.edge[a];
    this.edge[a] = Edge3.tempi;
  }
}
