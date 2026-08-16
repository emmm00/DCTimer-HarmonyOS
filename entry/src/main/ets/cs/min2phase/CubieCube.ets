// Ported from cs/min2phase/CubieCube.java (DCTimer-BLE -> HarmonyOS ArkTS)
// IMPORTANT: modules importing CubieCube must import Util BEFORE CubieCube to ensure
// Util is evaluated first (Util.setNPerm is used in CubieCube constructor at class-load time).
import { Util } from './Util';
import { Utils as SolverUtils } from '../../solver/Utils';

const USE_FULL_PRUN = false;
const USE_TWIST_FLIP_PRUN = false;

export class CubieCube {
  static CubeSym: CubieCube[] = new Array<CubieCube>(16);
  static moveCube: CubieCube[] = new Array<CubieCube>(18);
  static preList: CubieCube[] | null = null;

  static SymInv: number[] = new Array<number>(16).fill(0);
  static SymMult: number[][] = CubieCube.z2d(16, 16);
  static SymMove: number[][] = CubieCube.z2d(16, 18);
  static SymMultInv: number[][] = CubieCube.z2d(16, 16);
  static Sym8Mult: number[][] = CubieCube.z2d(8, 8);
  static Sym8Move: number[][] = CubieCube.z2d(8, 18);
  static Sym8MultInv: number[][] = CubieCube.z2d(8, 8);
  static SymMoveUD: number[][] = CubieCube.z2d(16, 10);

  static FlipS2R: number[] = new Array<number>(336).fill(0);
  static TwistS2R: number[] = new Array<number>(324).fill(0);
  static EPermS2R: number[] = new Array<number>(2768).fill(0);
  static UDSliceFlipS2R: number[] | null = USE_FULL_PRUN ? new Array<number>(64430).fill(0) : null;

  static e2c: number[] = [0, 0, 0, 0, 1, 3, 1, 3, 1, 3, 1, 3, 0, 0, 0, 0];

  static MtoEPerm: number[] = new Array<number>(40320).fill(0);

  static FlipSlice2UDSliceFlip: number[] | null = USE_FULL_PRUN ? new Array<number>(336 * 495).fill(0) : null;

  static FlipR2S: number[] | null = null;
  static TwistR2S: number[] | null = null;
  static EPermR2S: number[] | null = null;
  static FlipS2RF: number[] | null = USE_TWIST_FLIP_PRUN ? new Array<number>(336 * 8).fill(0) : null;
  static TwistS2RF: number[] | null = USE_FULL_PRUN ? new Array<number>(324 * 8).fill(0) : null;

  static SymStateTwist: number[] = new Array<number>(324).fill(0);
  static SymStateFlip: number[] = new Array<number>(336).fill(0);
  static SymStatePerm: number[] = new Array<number>(2768).fill(0);
  static SymStateUDSliceFlip: number[] | null = USE_FULL_PRUN ? new Array<number>(64430).fill(0) : null;

  static urf1: CubieCube = new CubieCube(2531, 1373, 67026819, 1367);
  static urf2: CubieCube = new CubieCube(2089, 1906, 322752913, 2040);
  static urfMove: number[][] = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
    [6, 7, 8, 0, 1, 2, 3, 4, 5, 15, 16, 17, 9, 10, 11, 12, 13, 14],
    [3, 4, 5, 6, 7, 8, 0, 1, 2, 12, 13, 14, 15, 16, 17, 9, 10, 11],
    [2, 1, 0, 5, 4, 3, 8, 7, 6, 11, 10, 9, 14, 13, 12, 17, 16, 15],
    [8, 7, 6, 2, 1, 0, 5, 4, 3, 17, 16, 15, 11, 10, 9, 14, 13, 12],
    [5, 4, 3, 8, 7, 6, 2, 1, 0, 14, 13, 12, 17, 16, 15, 11, 10, 9]
  ];

  static Perm2Comb: number[] = new Array<number>(2768).fill(0);

  cp: number[] = [0, 1, 2, 3, 4, 5, 6, 7];
  co: number[] = [0, 0, 0, 0, 0, 0, 0, 0];
  ep: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
  eo: number[] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
  temps: CubieCube | null = null;

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  private static setNPermLocal(arr: number[], idx: number, n: number): void {
    arr[n - 1] = 0;
    for (let i = n - 2; i >= 0; i--) {
      arr[i] = idx % (n - i);
      idx = Math.floor(idx / (n - i));
      for (let j = i + 1; j < n; j++) {
        if (arr[j] >= arr[i]) {
          arr[j]++;
        }
      }
    }
  }

  constructor();
  constructor(cp: number[], co: number[], ep: number[], eo: number[]);
  constructor(cperm: number, twist: number, eperm: number, flip: number);
  constructor(c: CubieCube);
  constructor(a1?: number[] | number | CubieCube, a2?: number[] | number, a3?: number[] | number,
    a4?: number[] | number) {
    if (typeof a1 === 'undefined') {
      return;
    }
    if (a1 instanceof CubieCube) {
      this.copy(a1);
      return;
    }
    if (typeof a1 === 'number') {
      this.setCPerm(a1);
      this.setTwist(typeof a2 === 'number' ? a2 : 0);
      CubieCube.setNPermLocal(this.ep, typeof a3 === 'number' ? a3 : 0, 12);
      this.setFlip(typeof a4 === 'number' ? a4 : 0);
      return;
    }
    if (Array.isArray(a1)) {
      this.cp = a1;
      if (Array.isArray(a2)) {
        this.co = a2;
      }
      if (Array.isArray(a3)) {
        this.ep = a3;
      }
      if (Array.isArray(a4)) {
        this.eo = a4;
      }
      return;
    }
  }

  private copy(c: CubieCube): void {
    for (let i = 0; i < 8; i++) {
      this.cp[i] = c.cp[i];
      this.co[i] = c.co[i];
    }
    for (let i = 0; i < 12; i++) {
      this.ep[i] = c.ep[i];
      this.eo[i] = c.eo[i];
    }
  }

  invCubieCube(): void {
    if (this.temps == null) {
      this.temps = new CubieCube();
    }
    const temps = this.temps;
    for (let edge = 0; edge < 12; edge++) {
      temps.ep[this.ep[edge]] = edge;
    }
    for (let edge = 0; edge < 12; edge++) {
      temps.eo[edge] = this.eo[temps.ep[edge]];
    }
    for (let corn = 0; corn < 8; corn++) {
      temps.cp[this.cp[corn]] = corn;
    }
    for (let corn = 0; corn < 8; corn++) {
      let ori = this.co[temps.cp[corn]];
      temps.co[corn] = -ori;
      if (temps.co[corn] < 0) {
        temps.co[corn] += 3;
      }
    }
    this.copy(temps);
  }

  static CornMult(a: CubieCube, b: CubieCube, prod: CubieCube): void {
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

  static EdgeMult(a: CubieCube, b: CubieCube, prod: CubieCube): void {
    for (let ed = 0; ed < 12; ed++) {
      prod.ep[ed] = a.ep[b.ep[ed]];
      prod.eo[ed] = b.eo[ed] ^ a.eo[b.ep[ed]];
    }
  }

  static CornConjugate(a: CubieCube, idx: number, b: CubieCube): void {
    const sinv = CubieCube.CubeSym[CubieCube.SymInv[idx]];
    const s = CubieCube.CubeSym[idx];
    for (let corn = 0; corn < 8; corn++) {
      b.cp[corn] = sinv.cp[a.cp[s.cp[corn]]];
      const oriA = sinv.co[a.cp[s.cp[corn]]];
      const oriB = a.co[s.cp[corn]];
      b.co[corn] = (oriA < 3) ? oriB : (3 - oriB) % 3;
    }
  }

  static EdgeConjugate(a: CubieCube, idx: number, b: CubieCube): void {
    const sinv = CubieCube.CubeSym[CubieCube.SymInv[idx]];
    const s = CubieCube.CubeSym[idx];
    for (let ed = 0; ed < 12; ed++) {
      b.ep[ed] = sinv.ep[a.ep[s.ep[ed]]];
      b.eo[ed] = s.eo[ed] ^ a.eo[s.ep[ed]] ^ sinv.eo[a.ep[s.ep[ed]]];
    }
  }

  URFConjugate(): void {
    if (this.temps == null) {
      this.temps = new CubieCube();
    }
    const temps = this.temps;
    CubieCube.CornMult(CubieCube.urf2, this, temps);
    CubieCube.CornMult(temps, CubieCube.urf1, this);
    CubieCube.EdgeMult(CubieCube.urf2, this, temps);
    CubieCube.EdgeMult(temps, CubieCube.urf1, this);
  }

  getFlip(): number {
    let idx = 0;
    for (let i = 0; i < 11; i++) {
      idx <<= 1;
      idx |= this.eo[i];
    }
    return idx;
  }

  setFlip(idx: number): void {
    let parity = 0;
    for (let i = 10; i >= 0; i--) {
      this.eo[i] = idx & 1;
      parity ^= this.eo[i];
      idx >>= 1;
    }
    this.eo[11] = parity;
  }

  getFlipSym(): number {
    if (CubieCube.FlipR2S != null) {
      return (CubieCube.FlipR2S as number[])[this.getFlip()];
    }
    if (this.temps == null) {
      this.temps = new CubieCube();
    }
    const temps = this.temps;
    for (let k = 0; k < 16; k += 2) {
      CubieCube.EdgeConjugate(this, CubieCube.SymInv[k], temps);
      const idx = Util.binarySearchChar(CubieCube.FlipS2R, temps.getFlip());
      if (idx != 0xffff) {
        return (idx << 3) | (k >> 1);
      }
    }
    return 0;
  }

  getTwist(): number {
    let idx = 0;
    for (let i = 0; i < 7; i++) {
      idx *= 3;
      idx += this.co[i];
    }
    return idx;
  }

  setTwist(idx: number): void {
    let twst = 0;
    for (let i = 6; i >= 0; i--) {
      this.co[i] = idx % 3;
      twst += this.co[i];
      idx = Math.floor(idx / 3);
    }
    this.co[7] = (15 - twst) % 3;
  }

  getTwistSym(): number {
    if (CubieCube.TwistR2S != null) {
      return (CubieCube.TwistR2S as number[])[this.getTwist()];
    }
    if (this.temps == null) {
      this.temps = new CubieCube();
    }
    const temps = this.temps;
    for (let k = 0; k < 16; k += 2) {
      CubieCube.CornConjugate(this, CubieCube.SymInv[k], temps);
      const idx = Util.binarySearchChar(CubieCube.TwistS2R, temps.getTwist());
      if (idx != 0xffff) {
        return (idx << 3) | (k >> 1);
      }
    }
    return 0;
  }

  getUDSlice(): number {
    return Util.getComb(this.ep, 8);
  }

  setUDSlice(idx: number): void {
    Util.setComb(this.ep, idx, 8);
  }

  getU4Comb(): number {
    return Util.getComb(this.ep, 0);
  }

  getD4Comb(): number {
    return Util.getComb(this.ep, 4);
  }

  getCPerm(): number {
    return SolverUtils.get8Perm(this.cp, 8);
  }

  setCPerm(idx: number): void {
    SolverUtils.set8Perm(this.cp, 8, idx);
  }

  getCPermSym(): number {
    if (CubieCube.EPermR2S != null) {
      const idx = (CubieCube.EPermR2S as number[])[this.getCPerm()];
      return idx ^ CubieCube.e2c[idx & 0x0f];
    }
    if (this.temps == null) {
      this.temps = new CubieCube();
    }
    const temps = this.temps;
    for (let k = 0; k < 16; k++) {
      CubieCube.CornConjugate(this, CubieCube.SymInv[k], temps);
      const idx = Util.binarySearchChar(CubieCube.EPermS2R, temps.getCPerm());
      if (idx != 0xffff) {
        return (idx << 4) | k;
      }
    }
    return 0;
  }

  getEPerm(): number {
    return SolverUtils.get8Perm(this.ep, 8);
  }

  setEPerm(idx: number): void {
    SolverUtils.set8Perm(this.ep, 8, idx);
  }

  getEPermSym(): number {
    if (CubieCube.EPermR2S != null) {
      return (CubieCube.EPermR2S as number[])[this.getEPerm()];
    }
    if (this.temps == null) {
      this.temps = new CubieCube();
    }
    const temps = this.temps;
    for (let k = 0; k < 16; k++) {
      CubieCube.EdgeConjugate(this, CubieCube.SymInv[k], temps);
      const idx = Util.binarySearchChar(CubieCube.EPermS2R, temps.getEPerm());
      if (idx != 0xffff) {
        return (idx << 4) | k;
      }
    }
    return 0;
  }

  getMPerm(): number {
    return Util.getComb(this.ep, 8) >> 9;
  }

  setMPerm(idx: number): void {
    Util.setComb(this.ep, idx << 9, 8);
  }

  verify(): number {
    let sum = 0;
    let edgeMask = 0;
    for (let e = 0; e < 12; e++) {
      edgeMask |= 1 << this.ep[e];
    }
    if (edgeMask != 0x0fff) {
      return -2; // missing edges
    }
    for (let i = 0; i < 12; i++) {
      sum ^= this.eo[i];
    }
    if (sum % 2 != 0) {
      return -3;
    }
    let cornMask = 0;
    for (let c = 0; c < 8; c++) {
      cornMask |= 1 << this.cp[c];
    }
    if (cornMask != 0x00ff) {
      return -4; // missing corners
    }
    sum = 0;
    for (let i = 0; i < 8; i++) {
      sum += this.co[i];
    }
    if (sum % 3 != 0) {
      return -5; // twisted corner
    }
    if ((Util.getNParity(Util.getNPerm(this.ep, 12), 12) ^ Util.getNParity(this.getCPerm(), 8)) != 0) {
      return -6; // parity error
    }
    return 0; // cube ok
  }

  setUDSliceFlip(idx: number): void {
    this.setFlip(idx & 0x7ff);
    this.setUDSlice(idx >> 11);
  }

  getUDSliceFlip(): number {
    return ((this.getUDSlice() & 0x1ff) << 11) | this.getFlip();
  }

  getUDSliceFlipSym(): number {
    if (this.temps == null) {
      this.temps = new CubieCube();
    }
    const temps = this.temps;
    for (let k = 0; k < 16; k++) {
      CubieCube.EdgeConjugate(this, CubieCube.SymInv[k], temps);
      const idx = Util.binarySearchInt(CubieCube.UDSliceFlipS2R as number[], temps.getUDSliceFlip());
      if (idx != 0xffff) {
        return (idx << 4) | k;
      }
    }
    return 0;
  }

  move(m: number): CubieCube {
    const c = new CubieCube();
    CubieCube.CornMult(this, CubieCube.moveCube[m], c);
    CubieCube.EdgeMult(this, CubieCube.moveCube[m], c);
    return c;
  }

  toFaceCube(cornerFacelet: number[][], edgeFacelet: number[][]): string {
    const f: string[] = new Array<string>(54).fill('');
    const ts: string[] = ['U', 'R', 'F', 'D', 'L', 'B'];
    for (let i = 0; i < 54; i++) {
      f[i] = ts[Math.floor(i / 9)];
    }
    for (let c = 0; c < 8; c++) {
      const j = this.cp[c]; // cornercubie with index j is at cornerposition with index c
      const ori = this.co[c]; // Orientation of this cubie
      for (let n = 0; n < 3; n++) {
        f[cornerFacelet[c][(n + ori) % 3]] = ts[Math.floor(cornerFacelet[j][n] / 9)];
      }
    }
    for (let e = 0; e < 12; e++) {
      const j = this.ep[e]; // edgecubie with index j is at edgeposition with index e
      const ori = this.eo[e]; // Orientation of this cubie
      for (let n = 0; n < 2; n++) {
        f[edgeFacelet[e][(n + ori) % 2]] = ts[Math.floor(edgeFacelet[j][n] / 9)];
      }
    }
    return f.join('');
  }

  static initMove(): void {
    CubieCube.moveCube[0] = new CubieCube(15120, 0, 119750400, 0);
    CubieCube.moveCube[3] = new CubieCube(21021, 1494, 323403417, 0);
    CubieCube.moveCube[6] = new CubieCube(8064, 1236, 29441808, 550);
    CubieCube.moveCube[9] = new CubieCube(9, 0, 5880, 0);
    CubieCube.moveCube[12] = new CubieCube(1230, 412, 2949660, 0);
    CubieCube.moveCube[15] = new CubieCube(224, 137, 328552, 137);
    for (let a = 0; a < 18; a += 3) {
      for (let p = 0; p < 2; p++) {
        CubieCube.moveCube[a + p + 1] = new CubieCube();
        CubieCube.EdgeMult(CubieCube.moveCube[a + p], CubieCube.moveCube[a], CubieCube.moveCube[a + p + 1]);
        CubieCube.CornMult(CubieCube.moveCube[a + p], CubieCube.moveCube[a], CubieCube.moveCube[a + p + 1]);
      }
    }
    CubieCube.preList = [
      new CubieCube(), CubieCube.moveCube[3], CubieCube.moveCube[5],
      CubieCube.moveCube[6], CubieCube.moveCube[8], CubieCube.moveCube[12],
      CubieCube.moveCube[14], CubieCube.moveCube[15], CubieCube.moveCube[17]
    ];
  }

  static initSym(): void {
    let c = new CubieCube();
    let d = new CubieCube();
    let t: CubieCube;

    const f2 = new CubieCube(28783, 0, 259268407, 0);
    const u4 = new CubieCube(15138, 0, 119765538, 7);
    const lr2 = new CubieCube(5167, 0, 83473207, 0);
    lr2.co = [3, 3, 3, 3, 3, 3, 3, 3];

    for (let i = 0; i < 16; i++) {
      CubieCube.CubeSym[i] = new CubieCube(c);
      CubieCube.CornMult(c, u4, d);
      CubieCube.EdgeMult(c, u4, d);
      t = d;
      d = c;
      c = t;
      if (i % 4 == 3) {
        CubieCube.CornMult(c, lr2, d);
        CubieCube.EdgeMult(c, lr2, d);
        t = d;
        d = c;
        c = t;
      }
      if (i % 8 == 7) {
        CubieCube.CornMult(c, f2, d);
        CubieCube.EdgeMult(c, f2, d);
        t = d;
        d = c;
        c = t;
      }
    }
    for (let i = 0; i < 16; i++) {
      for (let j = 0; j < 16; j++) {
        CubieCube.CornMult(CubieCube.CubeSym[i], CubieCube.CubeSym[j], c);
        for (let k = 0; k < 16; k++) {
          if (CubieCube.CubeSym[k].cp[0] == c.cp[0] && CubieCube.CubeSym[k].cp[1] == c.cp[1] &&
            CubieCube.CubeSym[k].cp[2] == c.cp[2]) {
            CubieCube.SymMult[i][j] = k;
            if (k == 0) {
              CubieCube.SymInv[i] = j;
            }
            break;
          }
        }
      }
    }
    for (let j = 0; j < 18; j++) {
      for (let s = 0; s < 16; s++) {
        CubieCube.CornConjugate(CubieCube.moveCube[j], CubieCube.SymInv[s], c);
        let found = false;
        for (let m = 0; m < 18; m++) {
          let match = true;
          for (let i = 0; i < 8; i += 2) {
            if (c.cp[i] != CubieCube.moveCube[m].cp[i]) {
              match = false;
              break;
            }
          }
          if (match) {
            CubieCube.SymMove[s][j] = m;
            found = true;
            break;
          }
        }
        void found;
      }
    }
    for (let j = 0; j < 10; j++) {
      for (let s = 0; s < 16; s++) {
        CubieCube.SymMoveUD[s][j] = Util.std2ud[CubieCube.SymMove[s][Util.ud2std[j]]];
      }
    }
    for (let j = 0; j < 16; j++) {
      for (let s = 0; s < 16; s++) {
        CubieCube.SymMultInv[j][s] = CubieCube.SymMult[j][CubieCube.SymInv[s]];
      }
    }
    for (let j = 0; j < 8; j++) {
      for (let s = 0; s < 8; s++) {
        CubieCube.Sym8Mult[j][s] = CubieCube.SymMult[j << 1][s << 1] >> 1;
        CubieCube.Sym8MultInv[j][s] = CubieCube.SymMult[j << 1][CubieCube.SymInv[s << 1]] >> 1;
      }
    }
    for (let j = 0; j < 18; j++) {
      for (let s = 0; s < 8; s++) {
        CubieCube.Sym8Move[s][j] = CubieCube.SymMove[s << 1][j];
      }
    }
  }

  static initFlipSym2Raw(): void {
    const c = new CubieCube();
    const d = new CubieCube();
    const occ: number[] = new Array<number>(2048 >> 5).fill(0);
    let count = 0;
    CubieCube.FlipR2S = new Array<number>(2048).fill(0);
    for (let i = 0; i < 2048; i++) {
      if (SolverUtils.getBit(occ, i) == 0) {
        c.setFlip(i);
        for (let s = 0; s < 16; s += 2) {
          CubieCube.EdgeConjugate(c, s, d);
          const idx = d.getFlip();
          if (idx == i) {
            CubieCube.SymStateFlip[count] |= 1 << (s >> 1);
          }
          SolverUtils.setBit(occ, idx);
          (CubieCube.FlipR2S as number[])[idx] = (count << 3) | (s >> 1);
          if (USE_TWIST_FLIP_PRUN && CubieCube.FlipS2RF != null) {
            (CubieCube.FlipS2RF as number[])[(count << 3) | (s >> 1)] = idx;
          }
        }
        CubieCube.FlipS2R[count++] = i;
      }
    }
  }

  static initTwistSym2Raw(): void {
    const c = new CubieCube();
    const d = new CubieCube();
    const occ: number[] = new Array<number>(Math.floor(2187 / 32) + 1).fill(0);
    let count = 0;
    CubieCube.TwistR2S = new Array<number>(2187).fill(0);
    for (let i = 0; i < 2187; i++) {
      if (SolverUtils.getBit(occ, i) == 0) {
        c.setTwist(i);
        for (let s = 0; s < 16; s += 2) {
          CubieCube.CornConjugate(c, s, d);
          const idx = d.getTwist();
          if (idx == i) {
            CubieCube.SymStateTwist[count] |= 1 << (s >> 1);
          }
          SolverUtils.setBit(occ, idx);
          (CubieCube.TwistR2S as number[])[idx] = (count << 3) | (s >> 1);
          if (USE_FULL_PRUN && CubieCube.TwistS2RF != null) {
            (CubieCube.TwistS2RF as number[])[(count << 3) | (s >> 1)] = idx;
          }
        }
        CubieCube.TwistS2R[count++] = i;
      }
    }
  }

  static initPermSym2Raw(): void {
    const c = new CubieCube();
    const d = new CubieCube();
    const occ: number[] = new Array<number>(Math.floor(40320 / 32)).fill(0);
    let count = 0;
    CubieCube.EPermR2S = new Array<number>(40320).fill(0);
    for (let i = 0; i < 40320; i++) {
      if (SolverUtils.getBit(occ, i) == 0) {
        c.setEPerm(i);
        for (let s = 0; s < 16; s++) {
          CubieCube.EdgeConjugate(c, s, d);
          const idx = d.getEPerm();
          if (idx == i) {
            CubieCube.SymStatePerm[count] |= 1 << s;
          }
          SolverUtils.setBit(occ, idx);
          const a = d.getU4Comb();
          const b = d.getD4Comb() >> 9;
          const m = 494 - (a & 0x1ff) + (a >> 9) * 70 + b * 1680;
          CubieCube.MtoEPerm[m] = (CubieCube.EPermR2S as number[])[idx] = (count << 4) | s;
          if (s == 0) {
            CubieCube.Perm2Comb[count] = 494 - (a & 0x1ff);
          }
        }
        CubieCube.EPermS2R[count++] = i;
      }
    }
  }

  static initUDSliceFlipSym2Raw(): void {
    const c = new CubieCube();
    const d = new CubieCube();
    const occ: number[] = new Array<number>(Math.floor(2048 * 495 / 32)).fill(0);
    let count = 0;
    for (let i = 0; i < 2048 * 495; i++) {
      if (SolverUtils.getBit(occ, i) == 0) {
        c.setUDSliceFlip(i);
        for (let s = 0; s < 16; s++) {
          CubieCube.EdgeConjugate(c, s, d);
          const idx = d.getUDSliceFlip();
          if (idx == i) {
            (CubieCube.SymStateUDSliceFlip as number[])[count] |= 1 << s;
          }
          SolverUtils.setBit(occ, idx);
          const fidx = Util.binarySearchChar(CubieCube.FlipS2R, idx & 0x7ff);
          if (fidx != 0xffff) {
            (CubieCube.FlipSlice2UDSliceFlip as number[])[fidx * 495 + (idx >> 11)] = (count << 4) | s;
          }
        }
        (CubieCube.UDSliceFlipS2R as number[])[count++] = i;
      }
    }
  }
}

CubieCube.initMove();
