// Ported from cs/min2phase/CoordCube.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Util } from './Util';
import { CubieCube } from './CubieCube';

const USE_FULL_PRUN = false;
const USE_TWIST_FLIP_PRUN = false;

export class CoordCube {
  static N_SLICE = 495;
  static N_TWIST_SYM = 324;
  static N_FLIP = 2048;
  static N_FLIP_SYM = 336;
  static N_PERM = 40320;
  static N_PERM_SYM = 2768;
  static N_MPERM = 24;
  static N_COMB = 70;
  static N_UDSLICEFLIP_SYM = 64430;
  static N_TWIST = 2187;

  static UDSliceFlipMove: number[][] | null = USE_FULL_PRUN ? CoordCube.z2d(CoordCube.N_UDSLICEFLIP_SYM, 18) : null;
  static TwistMoveF: number[][] | null = USE_FULL_PRUN ? CoordCube.z2d(CoordCube.N_TWIST, 18) : null;
  static TwistConj: number[][] | null = USE_FULL_PRUN ? CoordCube.z2d(CoordCube.N_TWIST, 16) : null;
  static UDSliceFlipTwistPrun: number[] | null = USE_FULL_PRUN ?
    new Array<number>(Math.floor(CoordCube.N_UDSLICEFLIP_SYM * CoordCube.N_TWIST / 16) + 1).fill(0) : null;

  static UDSliceMove: number[][] = CoordCube.z2d(CoordCube.N_SLICE, 18);
  static TwistMove: number[][] = CoordCube.z2d(CoordCube.N_TWIST_SYM, 18);
  static FlipMove: number[][] = CoordCube.z2d(CoordCube.N_FLIP_SYM, 18);
  static UDSliceConj: number[][] = CoordCube.z2d(CoordCube.N_SLICE, 8);
  static UDSliceTwistPrun: number[] = new Array<number>(Math.floor(CoordCube.N_SLICE * CoordCube.N_TWIST_SYM / 8) + 1).fill(0);
  static UDSliceFlipPrun: number[] = new Array<number>(Math.floor(CoordCube.N_SLICE * CoordCube.N_FLIP_SYM / 8)).fill(0);
  static TwistFlipPrun: number[] | null = USE_TWIST_FLIP_PRUN ?
    new Array<number>(Math.floor(CoordCube.N_FLIP * CoordCube.N_TWIST_SYM / 8)).fill(0) : null;

  static CPermMove: number[][] = CoordCube.z2d(CoordCube.N_PERM_SYM, 18);
  static EPermMove: number[][] = CoordCube.z2d(CoordCube.N_PERM_SYM, 10);
  static MPermMove: number[][] = CoordCube.z2d(CoordCube.N_MPERM, 10);
  static MPermConj: number[][] = CoordCube.z2d(CoordCube.N_MPERM, 16);
  static CCombMove: number[][] = CoordCube.z2d(CoordCube.N_COMB, 10);
  static CCombConj: number[][] = CoordCube.z2d(CoordCube.N_COMB, 16);
  static MCPermPrun: number[] = new Array<number>(Math.floor(CoordCube.N_MPERM * CoordCube.N_PERM_SYM / 8)).fill(0);
  static MEPermPrun: number[] = new Array<number>(Math.floor(CoordCube.N_MPERM * CoordCube.N_PERM_SYM / 8)).fill(0);
  static EPermCCombPrun: number[] = new Array<number>(Math.floor(CoordCube.N_COMB * CoordCube.N_PERM_SYM / 8)).fill(0);

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  static setPruning(table: number[], index: number, value: number): void {
    table[index >> 3] ^= (0xf ^ value) << ((index & 7) << 2);
  }

  static getPruning(table: number[], index: number): number {
    return (table[index >> 3] >> ((index & 7) << 2)) & 0xf;
  }

  static setPruning2(table: number[], index: number, value: number): void {
    table[index >> 4] ^= (0x3 ^ value) << ((index & 0xf) << 1);
  }

  static getPruning2(table: number[], index: number): number {
    return (table[index >> 4] >> ((index & 0xf) << 1)) & 0x3;
  }

  static initUDSliceMoveConj(): void {
    const c = new CubieCube();
    const d = new CubieCube();
    for (let i = 0; i < CoordCube.N_SLICE; i++) {
      c.setUDSlice(i);
      for (let j = 0; j < 18; j += 3) {
        CubieCube.EdgeMult(c, CubieCube.moveCube[j], d);
        CoordCube.UDSliceMove[i][j] = d.getUDSlice();
      }
      for (let j = 0; j < 16; j += 2) {
        CubieCube.EdgeConjugate(c, CubieCube.SymInv[j], d);
        CoordCube.UDSliceConj[i][j >> 1] = d.getUDSlice() & 0x1ff;
      }
    }
    for (let i = 0; i < CoordCube.N_SLICE; i++) {
      for (let j = 0; j < 18; j += 3) {
        let udslice = CoordCube.UDSliceMove[i][j];
        for (let k = 1; k < 3; k++) {
          const cx = CoordCube.UDSliceMove[udslice & 0x1ff][j];
          udslice = (Util.permMult[udslice >> 9][cx >> 9] << 9) | (cx & 0x1ff);
          CoordCube.UDSliceMove[i][j + k] = udslice;
        }
      }
    }
  }

  static initFlipMove(): void {
    const c = new CubieCube();
    const d = new CubieCube();
    for (let i = 0; i < CoordCube.N_FLIP_SYM; i++) {
      c.setFlip(CubieCube.FlipS2R[i]);
      for (let j = 0; j < 18; j++) {
        CubieCube.EdgeMult(c, CubieCube.moveCube[j], d);
        CoordCube.FlipMove[i][j] = d.getFlipSym();
      }
    }
  }

  static initTwistMove(): void {
    const c = new CubieCube();
    const d = new CubieCube();
    for (let i = 0; i < CoordCube.N_TWIST_SYM; i++) {
      c.setTwist(CubieCube.TwistS2R[i]);
      for (let j = 0; j < 18; j++) {
        CubieCube.CornMult(c, CubieCube.moveCube[j], d);
        CoordCube.TwistMove[i][j] = d.getTwistSym();
      }
    }
  }

  static initCPermMove(): void {
    const c = new CubieCube();
    const d = new CubieCube();
    for (let i = 0; i < CoordCube.N_PERM_SYM; i++) {
      c.setCPerm(CubieCube.EPermS2R[i]);
      for (let j = 0; j < 18; j++) {
        CubieCube.CornMult(c, CubieCube.moveCube[j], d);
        CoordCube.CPermMove[i][j] = d.getCPermSym();
      }
    }
  }

  static initEPermMove(): void {
    const c = new CubieCube();
    const d = new CubieCube();
    for (let i = 0; i < CoordCube.N_PERM_SYM; i++) {
      c.setEPerm(CubieCube.EPermS2R[i]);
      for (let j = 0; j < 10; j++) {
        CubieCube.EdgeMult(c, CubieCube.moveCube[Util.ud2std[j]], d);
        CoordCube.EPermMove[i][j] = d.getEPermSym();
      }
    }
  }

  static initMPermMoveConj(): void {
    const c = new CubieCube();
    const d = new CubieCube();
    for (let i = 0; i < CoordCube.N_MPERM; i++) {
      c.setMPerm(i);
      for (let j = 0; j < 10; j++) {
        CubieCube.EdgeMult(c, CubieCube.moveCube[Util.ud2std[j]], d);
        CoordCube.MPermMove[i][j] = d.getMPerm();
      }
      for (let j = 0; j < 16; j++) {
        CubieCube.EdgeConjugate(c, CubieCube.SymInv[j], d);
        CoordCube.MPermConj[i][j] = d.getMPerm();
      }
    }
  }

  static initCombMoveConj(): void {
    const c = new CubieCube();
    const d = new CubieCube();
    for (let i = 0; i < CoordCube.N_COMB; i++) {
      Util.setComb(c.cp, 69 - i, 0);
      for (let j = 0; j < 10; j++) {
        CubieCube.CornMult(c, CubieCube.moveCube[Util.ud2std[j]], d);
        CoordCube.CCombMove[i][j] = 69 - (Util.getComb(d.cp, 0) & 0x1ff);
      }
      for (let j = 0; j < 16; j++) {
        CubieCube.CornConjugate(c, CubieCube.SymInv[j], d);
        CoordCube.CCombConj[i][j] = 69 - (Util.getComb(d.cp, 0) & 0x1ff);
      }
    }
  }

  static initUDSliceFlipMove(): void {
    const c = new CubieCube();
    const d = new CubieCube();
    for (let i = 0; i < CoordCube.N_UDSLICEFLIP_SYM; i++) {
      c.setUDSliceFlip((CubieCube.UDSliceFlipS2R as number[])[i]);
      const udslice = (CubieCube.UDSliceFlipS2R as number[])[i] >> 11;
      for (let j = 0; j < 18; j++) {
        CubieCube.EdgeMult(c, CubieCube.moveCube[j], d);
        const flip = d.getFlipSym();
        const fsym = flip & 0x7;
        const flipIdx = flip >> 3;
        const udsliceflip = (CubieCube.FlipSlice2UDSliceFlip as number[])[
          flipIdx * CoordCube.N_SLICE + CoordCube.UDSliceConj[CoordCube.UDSliceMove[udslice][j] & 0x1ff][fsym]
        ];
        (CoordCube.UDSliceFlipMove as number[][])[i][j] =
          (udsliceflip & 0xfffffff0) | CubieCube.SymMult[udsliceflip & 0xf][fsym << 1];
      }
    }
  }

  static initTwistMoveConj(): void {
    const c = new CubieCube();
    const d = new CubieCube();
    for (let i = 0; i < CoordCube.N_TWIST; i++) {
      c.setTwist(i);
      for (let j = 0; j < 18; j += 3) {
        CubieCube.CornMult(c, CubieCube.moveCube[j], d);
        (CoordCube.TwistMoveF as number[][])[i][j] = d.getTwist();
      }
      for (let j = 0; j < 16; j++) {
        CubieCube.CornConjugate(c, CubieCube.SymInv[j], d);
        (CoordCube.TwistConj as number[][])[i][j] = d.getTwist();
      }
    }
    for (let i = 0; i < CoordCube.N_TWIST; i++) {
      for (let j = 0; j < 18; j += 3) {
        let twist = (CoordCube.TwistMoveF as number[][])[i][j];
        for (let k = 1; k < 3; k++) {
          twist = (CoordCube.TwistMoveF as number[][])[twist][j];
          (CoordCube.TwistMoveF as number[][])[i][j + k] = twist;
        }
      }
    }
  }

  static initTwistFlipPrun(): void {
    let depth = 0;
    let done = 1;
    const N_SIZE = CoordCube.N_FLIP * CoordCube.N_TWIST_SYM;
    for (let i = 0; i < Math.floor(N_SIZE / 8); i++) {
      (CoordCube.TwistFlipPrun as number[])[i] = -1;
    }
    CoordCube.setPruning(CoordCube.TwistFlipPrun as number[], 0, 0);

    while (done < N_SIZE) {
      const inv = depth > 6;
      const select = inv ? 0xf : depth;
      const check = inv ? depth : 0xf;
      depth++;
      let val = 0;
      for (let i = 0; i < N_SIZE; i++, val >>= 4) {
        if ((i & 7) == 0) {
          val = (CoordCube.TwistFlipPrun as number[])[i >> 3];
          if (!inv && val == -1) {
            i += 7;
            continue;
          }
        }
        if ((val & 0xf) != select) {
          continue;
        }
        const twist = i >> 11;
        const flip = (CubieCube.FlipR2S as number[])[i & 0x7ff] as number;
        let fsym = flip & 7;
        const flipIdx = flip >> 3;
        for (let m = 0; m < 18; m++) {
          let twistx = CoordCube.TwistMove[twist][m];
          const tsymx = twistx & 7;
          twistx >>= 3;
          let flipx = CoordCube.FlipMove[flipIdx][CubieCube.Sym8Move[fsym][m]];
          const fsymx = CubieCube.Sym8MultInv[CubieCube.Sym8Mult[flipx & 7][fsym]][tsymx];
          flipx >>= 3;
          const idx = (twistx << 11) | (CubieCube.FlipS2RF as number[])[(flipx << 3) | fsymx];
          if (CoordCube.getPruning(CoordCube.TwistFlipPrun as number[], idx) != check) {
            continue;
          }
          done++;
          if (inv) {
            CoordCube.setPruning(CoordCube.TwistFlipPrun as number[], i, depth);
            break;
          }
          CoordCube.setPruning(CoordCube.TwistFlipPrun as number[], idx, depth);
          const sym = CubieCube.SymStateTwist[twistx];
          if (sym == 1) {
            continue;
          }
          for (let k = 0; k < 8; k++) {
            if ((sym & (1 << k)) == 0) {
              continue;
            }
            const idxx = (twistx << 11) | (CubieCube.FlipS2RF as number[])[(flipx << 3) | CubieCube.Sym8MultInv[fsymx][k]];
            if (CoordCube.getPruning(CoordCube.TwistFlipPrun as number[], idxx) == 0xf) {
              CoordCube.setPruning(CoordCube.TwistFlipPrun as number[], idxx, depth);
              done++;
            }
          }
        }
      }
    }
  }

  static initRawSymPrun(PrunTable: number[], INV_DEPTH: number,
    RawMove: number[][], RawConj: number[][],
    SymMove: number[][], SymState: number[],
    SymSwitch: number[] | null, moveMap: number[] | null, SYM_SHIFT: number): void {
    const SYM_MASK = (1 << SYM_SHIFT) - 1;
    const N_RAW = RawMove.length;
    const N_SYM = SymMove.length;
    const N_SIZE = N_RAW * N_SYM;
    const N_MOVES = RawMove[0].length;

    for (let i = 0; i < Math.floor((N_RAW * N_SYM + 7) / 8); i++) {
      PrunTable[i] = -1;
    }
    CoordCube.setPruning(PrunTable, 0, 0);

    let depth = 0;
    let done = 1;

    while (done < N_SIZE) {
      const inv = depth > INV_DEPTH;
      const select = inv ? 0xf : depth;
      const check = inv ? depth : 0xf;
      depth++;
      let val = 0;
      for (let i = 0; i < N_SIZE; i++, val >>= 4) {
        if ((i & 7) == 0) {
          val = PrunTable[i >> 3];
          if (!inv && val == -1) {
            i += 7;
            continue;
          }
        }
        if ((val & 0xf) != select) {
          continue;
        }
        const raw = i % N_RAW;
        const sym = Math.floor(i / N_RAW);
        for (let m = 0; m < N_MOVES; m++) {
          let symx = SymMove[sym][moveMap == null ? m : moveMap[m]];
          const rawx = RawConj[RawMove[raw][m] & 0x1ff][symx & SYM_MASK];
          symx >>= SYM_SHIFT;
          const idx = symx * N_RAW + rawx;
          if (CoordCube.getPruning(PrunTable, idx) != check) {
            continue;
          }
          done++;
          if (inv) {
            CoordCube.setPruning(PrunTable, i, depth);
            break;
          }
          CoordCube.setPruning(PrunTable, idx, depth);
          for (let j = 1, symState = SymState[symx]; (symState >>= 1) != 0; j++) {
            if ((symState & 1) != 1) {
              continue;
            }
            const idxx = symx * N_RAW + RawConj[rawx][j ^ (SymSwitch == null ? 0 : SymSwitch[j])];
            if (CoordCube.getPruning(PrunTable, idxx) == 0xf) {
              CoordCube.setPruning(PrunTable, idxx, depth);
              done++;
            }
          }
        }
      }
    }
  }

  static MAXDEPTH = 15;

  static getUDSliceFlipTwistPrunMod3(twist: number, tsym: number, flip: number, fsym: number, slice: number): number {
    const udsliceflip = (CubieCube.FlipSlice2UDSliceFlip as number[])[
      flip * CoordCube.N_SLICE + CoordCube.UDSliceConj[slice][fsym]
    ];
    const twistr = (CubieCube.TwistS2RF as number[])[(twist << 3) | CubieCube.Sym8MultInv[fsym][tsym]];
    const udsfsym = udsliceflip & 0xf;
    const udsliceflipIdx = udsliceflip >> 4;
    return CoordCube.getPruning2(CoordCube.UDSliceFlipTwistPrun as number[],
      udsliceflipIdx * CoordCube.N_TWIST + (CoordCube.TwistConj as number[][])[twistr][udsfsym]);
  }

  static getUDSliceFlipTwistPrun(twist: number, tsym: number, flip: number, fsym: number, slice: number): number {
    let nextpm3 = CoordCube.getUDSliceFlipTwistPrunMod3(twist, tsym, flip, fsym, slice);
    if (nextpm3 == 0x3) {
      return CoordCube.MAXDEPTH;
    }
    let prun = 0;
    while (twist != 0 || flip != 0 || slice != 0) {
      ++prun;
      nextpm3 = (nextpm3 + 2) % 3;
      for (let m = 0; m < 18; m++) {
        const slicex = CoordCube.UDSliceMove[slice][m] & 0x1ff;
        let twistx = CoordCube.TwistMove[twist][CubieCube.Sym8Move[tsym][m]];
        const tsymx = CubieCube.Sym8Mult[twistx & 7][tsym];
        twistx >>= 3;
        let flipx = CoordCube.FlipMove[flip][CubieCube.Sym8Move[fsym][m]];
        const fsymx = CubieCube.Sym8Mult[flipx & 7][fsym];
        flipx >>= 3;
        if (nextpm3 == CoordCube.getUDSliceFlipTwistPrunMod3(twistx, tsymx, flipx, fsymx, slicex)) {
          twist = twistx;
          tsym = tsymx;
          flip = flipx;
          fsym = fsymx;
          slice = slicex;
          break;
        }
      }
    }
    return prun;
  }

  static getUDSliceFlipTwistPrun6(twist: number, tsym: number, flip: number, fsym: number, slice: number,
    prun: number): number {
    const prunm3 = CoordCube.getUDSliceFlipTwistPrunMod3(twist, tsym, flip, fsym, slice);
    return prunm3 == 0x3 ? CoordCube.MAXDEPTH : ((0x24924924 >> (prun - prunm3 + 2)) & 3) + prun - 1;
  }

  static initUDSliceFlipTwistPrun(): void {
    const N_SIZE = CoordCube.N_TWIST * CoordCube.N_UDSLICEFLIP_SYM;
    for (let i = 0; i < Math.floor((N_SIZE + 15) / 16); i++) {
      (CoordCube.UDSliceFlipTwistPrun as number[])[i] = -1;
    }
    CoordCube.setPruning2(CoordCube.UDSliceFlipTwistPrun as number[], 0, 0);

    let depth = 0;
    let done = 1;

    while (done < N_SIZE) {
      const inv = depth > 8;
      const select = inv ? 0x3 : depth % 3;
      const check = inv ? depth % 3 : 0x3;
      depth++;
      const depm3 = depth % 3;
      if (depth >= CoordCube.MAXDEPTH) {
        break;
      }
      for (let i = 0; i < N_SIZE;) {
        let val = (CoordCube.UDSliceFlipTwistPrun as number[])[i >> 4];
        if (!inv && val == -1) {
          i += 16;
          continue;
        }
        for (const end = Math.min(i + 16, N_SIZE); i < end; i++, val >>= 2) {
          if ((val & 0x3) != select) {
            continue;
          }
          const raw = i % CoordCube.N_TWIST;
          const sym = Math.floor(i / CoordCube.N_TWIST);
          for (let m = 0; m < 18; m++) {
            let symx = (CoordCube.UDSliceFlipMove as number[][])[sym][m];
            const rawx = (CoordCube.TwistConj as number[][])[(CoordCube.TwistMoveF as number[][])[raw][m]][symx & 0xf];
            symx >>= 4;
            const idx = symx * CoordCube.N_TWIST + rawx;
            if (CoordCube.getPruning2(CoordCube.UDSliceFlipTwistPrun as number[], idx) != check) {
              continue;
            }
            done++;
            if (inv) {
              CoordCube.setPruning2(CoordCube.UDSliceFlipTwistPrun as number[], i, depm3);
              break;
            }
            CoordCube.setPruning2(CoordCube.UDSliceFlipTwistPrun as number[], idx, depm3);
            for (let j = 1, symState = (CubieCube.SymStateUDSliceFlip as number[])[symx]; (symState >>= 1) != 0; j++) {
              if ((symState & 1) != 1) {
                continue;
              }
              const idxx = symx * CoordCube.N_TWIST + (CoordCube.TwistConj as number[][])[rawx][j];
              if (CoordCube.getPruning2(CoordCube.UDSliceFlipTwistPrun as number[], idxx) == 0x3) {
                CoordCube.setPruning2(CoordCube.UDSliceFlipTwistPrun as number[], idxx, depm3);
                done++;
              }
            }
          }
        }
      }
    }
  }

  static initSliceTwistPrun(): void {
    CoordCube.initRawSymPrun(
      CoordCube.UDSliceTwistPrun, 6,
      CoordCube.UDSliceMove, CoordCube.UDSliceConj,
      CoordCube.TwistMove, CubieCube.SymStateTwist,
      null, null, 3
    );
  }

  static initSliceFlipPrun(): void {
    CoordCube.initRawSymPrun(
      CoordCube.UDSliceFlipPrun, 6,
      CoordCube.UDSliceMove, CoordCube.UDSliceConj,
      CoordCube.FlipMove, CubieCube.SymStateFlip,
      null, null, 3
    );
  }

  static initMEPermPrun(): void {
    CoordCube.initRawSymPrun(
      CoordCube.MEPermPrun, 7,
      CoordCube.MPermMove, CoordCube.MPermConj,
      CoordCube.EPermMove, CubieCube.SymStatePerm,
      null, null, 4
    );
  }

  static initMCPermPrun(): void {
    CoordCube.initRawSymPrun(
      CoordCube.MCPermPrun, 10,
      CoordCube.MPermMove, CoordCube.MPermConj,
      CoordCube.CPermMove, CubieCube.SymStatePerm,
      CubieCube.e2c, Util.ud2std, 4
    );
  }

  static initPermCombPrun(): void {
    CoordCube.initRawSymPrun(
      CoordCube.EPermCCombPrun, 7,
      CoordCube.CCombMove, CoordCube.CCombConj,
      CoordCube.EPermMove, CubieCube.SymStatePerm,
      null, null, 4
    );
  }
}
