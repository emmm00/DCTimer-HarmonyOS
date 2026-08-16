// Ported from cs/min2phase/Search.java (DCTimer-BLE -> HarmonyOS ArkTS)
// NOTE: import Util BEFORE CubieCube/CoordCube to guarantee module evaluation order.
import { Util } from './Util';
import { CubieCube } from './CubieCube';
import { CoordCube } from './CoordCube';
import { Tools } from './Tools';

const USE_TWIST_FLIP_PRUN = false;
const USE_FULL_PRUN = false;
const TRY_PRE_MOVE = true;
const TRY_INVERSE = true;
const TRY_THREE_AXES = true;
const PRE_IDX_MAX = TRY_PRE_MOVE ? 9 : 1;

export class Search {
  static inited = false;

  static USE_SEPARATOR = 0x1;
  static INVERSE_SOLUTION = 0x2;
  static APPEND_LENGTH = 0x4;
  static OPTIMAL_SOLUTION = 0x8;

  static rotateStr: string[] = ['', 'Fw', "Fw'", 'Fw Uw', 'Fw Uw2', 'Fw Uw\'', "Fw' Uw", "Fw' Uw2", "Fw' Uw'", 'Rw', 'Rw2', "Rw'",
    'Rw Uw', 'Rw Uw2', 'Rw Uw\'', 'Rw2 Uw', 'Rw2 Uw2', 'Rw2 Uw\'', "Rw' Uw", "Rw' Uw2", "Rw' Uw'", 'Uw', 'Uw2', "Uw'"];
  static rotateIdx: string[] = ['', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'L', 'D', 'D', 'D'];

  private move: number[] = new Array<number>(31).fill(0);
  private twist: number[][] = Search.z2d(6, PRE_IDX_MAX);
  private flip: number[][] = Search.z2d(6, PRE_IDX_MAX);
  private slice: number[][] = Search.z2d(6, PRE_IDX_MAX);
  private corn0: number[][] = Search.z2d(6, PRE_IDX_MAX);
  private ud8e0: number[][] = Search.z2d(6, PRE_IDX_MAX);
  private prun: number[][] = Search.z2d(6, PRE_IDX_MAX);

  private conjMask = 0;
  private urfIdx = 0;
  private preIdx = 0;
  private length1 = 0;
  private depth1 = 0;
  private maxDep2 = 0;
  private sol = 0;
  private solutionStr: string | null = null;
  private probe = 0;
  private probeMax = 0;
  private probeMin = 0;
  private verbose = 0;
  private cc: CubieCube = new CubieCube();
  private isRecovery = false;

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  solution(facelets: string, rotate: boolean, rnd: () => number): string {
    const sol = this.solution5(facelets, 21, 10000, 0, 2);
    if (!rotate) {
      return sol;
    }
    const moves = sol.split(' ');
    const lastMove = moves[moves.length - 1].charAt(0);
    let rot: number;
    do {
      rot = Math.floor(rnd() * 24);
    } while (Search.rotateIdx[rot] == lastMove);
    return sol + Search.rotateStr[rot];
  }

  solution5(facelets: string, maxDepth: number, probeMax: number, probeMin: number, verbose: number): string {
    const check = Util.toCubieCube(facelets, this.cc);
    if (check != 0) {
      return 'Error ' + Math.abs(check);
    }
    this.sol = maxDepth + 1;
    this.probe = 0;
    this.probeMax = probeMax;
    this.probeMin = Math.min(probeMin, probeMax);
    this.verbose = verbose;
    this.solutionStr = null;
    this.isRecovery = false;

    Tools.init();

    this.initSearch();

    return (verbose & Search.OPTIMAL_SOLUTION) == 0 ? this.search() : this.searchOpt();
  }

  solution1(facelets: string): string {
    return this.solution5(facelets, 21, 10000, 100, 2);
  }

  private initSearch(): void {
    this.conjMask = (TRY_INVERSE ? 0 : 0x38) | (TRY_THREE_AXES ? 0 : 0x36);
    const pc = new CubieCube();

    for (let i = 0; i < 6; i++) {
      for (let j = 0; j < PRE_IDX_MAX; j++) {
        CubieCube.CornMult((CubieCube.preList as CubieCube[])[j], this.cc, pc);
        CubieCube.EdgeMult((CubieCube.preList as CubieCube[])[j], this.cc, pc);
        this.twist[i][j] = pc.getTwistSym();
        this.flip[i][j] = pc.getFlipSym();
        this.slice[i][j] = pc.getUDSlice();
        this.corn0[i][j] = pc.getCPermSym();
        this.ud8e0[i][j] = (pc.getU4Comb() << 16) | pc.getD4Comb();
        this.prun[i][j] = -1;
      }
      this.cc.URFConjugate();
      if (i % 3 == 2) {
        this.cc.invCubieCube();
      }
    }

    for (let i = 0; i < 6; i++) {
      for (let j = 0; j < i; j++) { // If S_i^-1 * C * S_i == C, it's unnecessary to compute it again.
        if (this.twist[i][0] == this.twist[j][0] && this.flip[i][0] == this.flip[j][0] && this.slice[i][0] == this.slice[j][0] &&
          this.corn0[i][0] == this.corn0[j][0] && this.ud8e0[i][0] == this.ud8e0[j][0]) {
          this.conjMask |= 1 << i;
          break;
        }
      }
      if ((this.conjMask & (1 << i)) != 0) {
        continue;
      }
      for (let j = 0; j < PRE_IDX_MAX; j++) {
        this.fillprun(i, j);
      }
    }
  }

  next(probeMax: number, probeMin: number, verbose: number): string {
    this.probe = 0;
    this.probeMax = probeMax;
    this.probeMin = Math.min(probeMin, probeMax);
    this.solutionStr = null;
    this.isRecovery = (this.verbose & Search.OPTIMAL_SOLUTION) == (verbose & Search.OPTIMAL_SOLUTION);
    this.verbose = verbose;
    return (verbose & Search.OPTIMAL_SOLUTION) == 0 ? this.search() : this.searchOpt();
  }

  static isInited(): boolean {
    return Search.inited;
  }

  numberOfProbes(): number {
    return this.probe;
  }

  static init(): void {
    if (Search.inited) {
      return;
    }
    CubieCube.initSym();
    CubieCube.initFlipSym2Raw();
    CubieCube.initTwistSym2Raw();
    CubieCube.initPermSym2Raw();

    CoordCube.initFlipMove();
    CoordCube.initTwistMove();
    CoordCube.initUDSliceMoveConj();

    CoordCube.initCPermMove();
    CoordCube.initEPermMove();
    CoordCube.initMPermMoveConj();
    CoordCube.initCombMoveConj();

    CoordCube.initMEPermPrun();
    CoordCube.initMCPermPrun();
    CoordCube.initPermCombPrun();

    if (USE_FULL_PRUN) {
      CubieCube.initUDSliceFlipSym2Raw();
      CoordCube.initUDSliceFlipMove();
      CoordCube.initTwistMoveConj();
      CoordCube.initUDSliceFlipTwistPrun();
    } else {
      if (USE_TWIST_FLIP_PRUN) {
        CoordCube.initTwistFlipPrun();
      }
      CoordCube.initSliceTwistPrun();
      CoordCube.initSliceFlipPrun();
    }

    Search.inited = true;
  }

  private fillprun(i: number, j: number): void {
    if (USE_FULL_PRUN) {
      this.prun[i][j] = CoordCube.getUDSliceFlipTwistPrun(
        this.twist[i][j] >> 3, this.twist[i][j] & 7, this.flip[i][j] >> 3, this.flip[i][j] & 7, this.slice[i][j] & 0x1ff);
    } else {
      this.prun[i][j] = Math.max(
        Math.max(
          CoordCube.getPruning(CoordCube.UDSliceTwistPrun,
            (this.twist[i][j] >> 3) * 495 + CoordCube.UDSliceConj[this.slice[i][j] & 0x1ff][this.twist[i][j] & 7]),
          CoordCube.getPruning(CoordCube.UDSliceFlipPrun,
            (this.flip[i][j] >> 3) * 495 + CoordCube.UDSliceConj[this.slice[i][j] & 0x1ff][this.flip[i][j] & 7])),
        USE_TWIST_FLIP_PRUN ? CoordCube.getPruning(CoordCube.TwistFlipPrun as number[],
          ((this.twist[i][j] >> 3) << 11) | (CubieCube.FlipS2RF as number[])[
            (this.flip[i][j] & 0xfff8) | CubieCube.Sym8MultInv[this.flip[i][j] & 7][this.twist[i][j] & 7]
          ]) : 0);
    }
  }

  private search(): string {
    for (this.length1 = this.isRecovery ? this.length1 : 0; this.length1 < this.sol; this.length1++) {
      this.maxDep2 = Math.min(12, this.sol - this.length1);
      for (this.urfIdx = this.isRecovery ? this.urfIdx : 0; this.urfIdx < 6; this.urfIdx++) {
        if ((this.conjMask & (1 << this.urfIdx)) != 0) {
          continue;
        }
        for (this.preIdx = this.isRecovery ? this.preIdx : 0; this.preIdx < PRE_IDX_MAX; this.preIdx++) {
          if (this.preIdx != 0 && this.preIdx % 2 == 0) {
            continue;
          }
          this.depth1 = this.length1 - (this.preIdx == 0 ? 0 : 1);
          if ((this.prun[this.urfIdx][this.preIdx] <= this.depth1) &&
            this.phase1(this.twist[this.urfIdx][this.preIdx] >> 3, this.twist[this.urfIdx][this.preIdx] & 7,
              this.flip[this.urfIdx][this.preIdx] >> 3, this.flip[this.urfIdx][this.preIdx] & 7,
              this.slice[this.urfIdx][this.preIdx] & 0x1ff, this.prun[this.urfIdx][this.preIdx], this.depth1, -1) == 0) {
            return this.solutionStr == null ? 'Error 8' : this.solutionStr;
          }
        }
      }
    }
    return this.solutionStr == null ? 'Error 7' : this.solutionStr;
  }

  private phase1(twist: number, tsym: number, flip: number, fsym: number, slice: number, prun: number,
    maxl: number, lm: number): number {
    if (twist == 0 && flip == 0 && slice == 0 && maxl < 5) {
      if (maxl == 0) {
        let ret = this.initPhase2();
        if (ret == 0 || this.preIdx == 0) {
          return ret;
        }
        this.preIdx++;
        ret = Math.min(this.initPhase2(), ret);
        this.preIdx--;
        return ret;
      } else {
        return 1;
      }
    }

    for (let axis = 0; axis < 18; axis += 3) {
      if (axis == lm || axis == lm - 9 || (this.isRecovery && axis < this.move[this.depth1 - maxl] - 2)) {
        continue;
      }
      for (let power = 0; power < 3; power++) {
        const m = axis + power;

        if (this.isRecovery && m != this.move[this.depth1 - maxl]) {
          continue;
        }

        const slicex = CoordCube.UDSliceMove[slice][m] & 0x1ff;

        let twistx = CoordCube.TwistMove[twist][CubieCube.Sym8Move[tsym][m]];
        const tsymx = CubieCube.Sym8Mult[twistx & 7][tsym];
        twistx >>= 3;

        let flipx = CoordCube.FlipMove[flip][CubieCube.Sym8Move[fsym][m]];
        const fsymx = CubieCube.Sym8Mult[flipx & 7][fsym];
        flipx >>= 3;

        let prunx: number;

        if (USE_FULL_PRUN) {
          prunx = CoordCube.getUDSliceFlipTwistPrun6(twistx, tsymx, flipx, fsymx, slicex, prun);
          if (prunx > maxl) {
            break;
          } else if (prunx == maxl) {
            continue;
          }
        } else {
          if (USE_TWIST_FLIP_PRUN) {
            prunx = CoordCube.getPruning(CoordCube.TwistFlipPrun as number[],
              (twistx << 11) | (CubieCube.FlipS2RF as number[])[(flipx << 3) | CubieCube.Sym8MultInv[fsymx][tsymx]]);
            if (prunx > maxl) {
              break;
            } else if (prunx == maxl) {
              continue;
            }
          }

          prunx = CoordCube.getPruning(CoordCube.UDSliceTwistPrun,
            twistx * 495 + CoordCube.UDSliceConj[slicex][tsymx]);
          if (prunx > maxl) {
            break;
          } else if (prunx == maxl) {
            continue;
          }

          prunx = CoordCube.getPruning(CoordCube.UDSliceFlipPrun,
            flipx * 495 + CoordCube.UDSliceConj[slicex][fsymx]);
          if (prunx > maxl) {
            break;
          } else if (prunx == maxl) {
            continue;
          }
        }

        this.move[this.depth1 - maxl] = m;
        const ret = this.phase1(twistx, tsymx, flipx, fsymx, slicex, prunx, maxl - 1, axis);
        if (ret == 0) {
          return 0;
        } else if (ret == 2) {
          break;
        }
      }
    }
    return 1;
  }

  private searchOpt(): string {
    let maxprun1 = 0;
    let maxprun2 = 0;
    for (let i = 0; i < 6; i++) {
      if (this.prun[i][0] == -1) {
        this.fillprun(i, 0);
      }
      if (i < 3) {
        maxprun1 = Math.max(maxprun1, this.prun[i][0]);
      } else {
        maxprun2 = Math.max(maxprun2, this.prun[i][0]);
      }
    }
    this.urfIdx = maxprun2 > maxprun1 ? 3 : 0;
    this.preIdx = 0;
    for (this.length1 = this.isRecovery ? this.length1 : 0; this.length1 < this.sol; this.length1++) {
      if (this.prun[0][0] <= this.length1 && this.prun[1][0] <= this.length1 && this.prun[2][0] <= this.length1 &&
        this.phase1opt(
          this.twist[0 + this.urfIdx][0] >> 3, this.twist[0 + this.urfIdx][0] & 7, this.flip[0 + this.urfIdx][0] >> 3,
          this.flip[0 + this.urfIdx][0] & 7, this.slice[0 + this.urfIdx][0] & 0x1ff, this.prun[0 + this.urfIdx][0],
          this.twist[1 + this.urfIdx][0] >> 3, this.twist[1 + this.urfIdx][0] & 7, this.flip[1 + this.urfIdx][0] >> 3,
          this.flip[1 + this.urfIdx][0] & 7, this.slice[1 + this.urfIdx][0] & 0x1ff, this.prun[1 + this.urfIdx][0],
          this.twist[2 + this.urfIdx][0] >> 3, this.twist[2 + this.urfIdx][0] & 7, this.flip[2 + this.urfIdx][0] >> 3,
          this.flip[2 + this.urfIdx][0] & 7, this.slice[2 + this.urfIdx][0] & 0x1ff, this.prun[2 + this.urfIdx][0],
          this.length1, -1) == 0) {
        return this.solutionStr == null ? 'Error 8' : this.solutionStr;
      }
    }
    return this.solutionStr == null ? 'Error 7' : this.solutionStr;
  }

  private phase1opt(
    ud_twist: number, ud_tsym: number, ud_flip: number, ud_fsym: number, ud_slice: number, ud_prun: number,
    rl_twist: number, rl_tsym: number, rl_flip: number, rl_fsym: number, rl_slice: number, rl_prun: number,
    fb_twist: number, fb_tsym: number, fb_flip: number, fb_fsym: number, fb_slice: number, fb_prun: number,
    maxl: number, lm: number): number {

    if (ud_twist == 0 && ud_flip == 0 && ud_slice == 0 && maxl < 5) {
      this.maxDep2 = maxl + 1;
      this.depth1 = this.length1 - maxl;
      return this.initPhase2() == 0 ? 0 : 1;
    }

    for (let axis = 0; axis < 18; axis += 3) {
      if (axis == lm || axis == lm - 9 || (this.isRecovery && axis < this.move[this.length1 - maxl] - 2)) {
        continue;
      }
      for (let power = 0; power < 3; power++) {
        let m = axis + power;

        if (this.isRecovery && m != this.move[this.length1 - maxl]) {
          continue;
        }

        // UD Axis
        const ud_slicex = CoordCube.UDSliceMove[ud_slice][m] & 0x1ff;
        let ud_twistx = CoordCube.TwistMove[ud_twist][CubieCube.Sym8Move[ud_tsym][m]];
        const ud_tsymx = CubieCube.Sym8Mult[ud_twistx & 7][ud_tsym];
        ud_twistx >>= 3;
        let ud_flipx = CoordCube.FlipMove[ud_flip][CubieCube.Sym8Move[ud_fsym][m]];
        const ud_fsymx = CubieCube.Sym8Mult[ud_flipx & 7][ud_fsym];
        ud_flipx >>= 3;

        let ud_prunx = 0;
        if (USE_FULL_PRUN) {
          ud_prunx = CoordCube.getUDSliceFlipTwistPrun6(ud_twistx, ud_tsymx, ud_flipx, ud_fsymx, ud_slicex, ud_prun);
          if (ud_prunx > maxl) {
            break;
          } else if (ud_prunx == maxl) {
            continue;
          }
        } else {
          if (USE_TWIST_FLIP_PRUN) {
            ud_prunx = CoordCube.getPruning(CoordCube.TwistFlipPrun as number[],
              (ud_twistx << 11) | (CubieCube.FlipS2RF as number[])[(ud_flipx << 3) | CubieCube.Sym8MultInv[ud_fsymx][ud_tsymx]]);
            if (ud_prunx > maxl) {
              break;
            } else if (ud_prunx == maxl) {
              continue;
            }
          }
          ud_prunx = Math.max(ud_prunx, CoordCube.getPruning(CoordCube.UDSliceTwistPrun,
            ud_twistx * 495 + CoordCube.UDSliceConj[ud_slicex][ud_tsymx]));
          if (ud_prunx > maxl) {
            break;
          } else if (ud_prunx == maxl) {
            continue;
          }
          ud_prunx = Math.max(ud_prunx, CoordCube.getPruning(CoordCube.UDSliceFlipPrun,
            ud_flipx * 495 + CoordCube.UDSliceConj[ud_slicex][ud_fsymx]));
          if (ud_prunx > maxl) {
            break;
          } else if (ud_prunx == maxl) {
            continue;
          }
        }

        // RL Axis
        m = CubieCube.urfMove[2][m];
        const rl_slicex = CoordCube.UDSliceMove[rl_slice][m] & 0x1ff;
        let rl_twistx = CoordCube.TwistMove[rl_twist][CubieCube.Sym8Move[rl_tsym][m]];
        const rl_tsymx = CubieCube.Sym8Mult[rl_twistx & 7][rl_tsym];
        rl_twistx >>= 3;
        let rl_flipx = CoordCube.FlipMove[rl_flip][CubieCube.Sym8Move[rl_fsym][m]];
        const rl_fsymx = CubieCube.Sym8Mult[rl_flipx & 7][rl_fsym];
        rl_flipx >>= 3;

        let rl_prunx = 0;
        if (USE_FULL_PRUN) {
          rl_prunx = CoordCube.getUDSliceFlipTwistPrun6(rl_twistx, rl_tsymx, rl_flipx, rl_fsymx, rl_slicex, rl_prun);
          if (rl_prunx > maxl) {
            break;
          } else if (rl_prunx == maxl) {
            continue;
          }
        } else {
          if (USE_TWIST_FLIP_PRUN) {
            rl_prunx = CoordCube.getPruning(CoordCube.TwistFlipPrun as number[],
              (rl_twistx << 11) | (CubieCube.FlipS2RF as number[])[(rl_flipx << 3) | CubieCube.Sym8MultInv[rl_fsymx][rl_tsymx]]);
            if (rl_prunx > maxl) {
              break;
            } else if (rl_prunx == maxl) {
              continue;
            }
          }
          rl_prunx = Math.max(rl_prunx, CoordCube.getPruning(CoordCube.UDSliceTwistPrun,
            rl_twistx * 495 + CoordCube.UDSliceConj[rl_slicex][rl_tsymx]));
          if (rl_prunx > maxl) {
            break;
          } else if (rl_prunx == maxl) {
            continue;
          }
          rl_prunx = Math.max(rl_prunx, CoordCube.getPruning(CoordCube.UDSliceFlipPrun,
            rl_flipx * 495 + CoordCube.UDSliceConj[rl_slicex][rl_fsymx]));
          if (rl_prunx > maxl) {
            break;
          } else if (rl_prunx == maxl) {
            continue;
          }
        }

        // FB Axis
        m = CubieCube.urfMove[2][m];
        const fb_slicex = CoordCube.UDSliceMove[fb_slice][m] & 0x1ff;
        let fb_twistx = CoordCube.TwistMove[fb_twist][CubieCube.Sym8Move[fb_tsym][m]];
        const fb_tsymx = CubieCube.Sym8Mult[fb_twistx & 7][fb_tsym];
        fb_twistx >>= 3;
        let fb_flipx = CoordCube.FlipMove[fb_flip][CubieCube.Sym8Move[fb_fsym][m]];
        const fb_fsymx = CubieCube.Sym8Mult[fb_flipx & 7][fb_fsym];
        fb_flipx >>= 3;

        let fb_prunx = 0;
        if (USE_FULL_PRUN) {
          fb_prunx = CoordCube.getUDSliceFlipTwistPrun6(fb_twistx, fb_tsymx, fb_flipx, fb_fsymx, fb_slicex, fb_prun);
        } else {
          if (USE_TWIST_FLIP_PRUN) {
            fb_prunx = CoordCube.getPruning(CoordCube.TwistFlipPrun as number[],
              (fb_twistx << 11) | (CubieCube.FlipS2RF as number[])[(fb_flipx << 3) | CubieCube.Sym8MultInv[fb_fsymx][fb_tsymx]]);
            if (fb_prunx > maxl) {
              break;
            } else if (fb_prunx == maxl) {
              continue;
            }
          }
          fb_prunx = Math.max(fb_prunx, CoordCube.getPruning(CoordCube.UDSliceTwistPrun,
            fb_twistx * 495 + CoordCube.UDSliceConj[fb_slicex][fb_tsymx]));
          if (fb_prunx > maxl) {
            break;
          } else if (fb_prunx == maxl) {
            continue;
          }
          fb_prunx = Math.max(fb_prunx, CoordCube.getPruning(CoordCube.UDSliceFlipPrun,
            fb_flipx * 495 + CoordCube.UDSliceConj[fb_slicex][fb_fsymx]));
        }
        const inc_prun = (ud_prunx == rl_prunx && rl_prunx == fb_prunx && fb_prunx != 0) ? 1 : 0;

        if (fb_prunx + inc_prun > maxl) {
          break;
        } else if (fb_prunx + inc_prun == maxl) {
          continue;
        }

        m = CubieCube.urfMove[2][m];

        this.move[this.length1 - maxl] = m;
        const ret = this.phase1opt(
          ud_twistx, ud_tsymx, ud_flipx, ud_fsymx, ud_slicex, ud_prunx,
          rl_twistx, rl_tsymx, rl_flipx, rl_fsymx, rl_slicex, rl_prunx,
          fb_twistx, fb_tsymx, fb_flipx, fb_fsymx, fb_slicex, fb_prunx,
          maxl - 1, axis);
        if (ret == 0) {
          return 0;
        } else if (ret == 2) {
          break;
        }
      }
    }
    return 1;
  }

  private initPhase2(): number {
    this.isRecovery = false;
    if (this.probe >= (this.solutionStr == null ? this.probeMax : this.probeMin)) {
      return 0;
    }
    ++this.probe;
    let cidx = this.corn0[this.urfIdx][this.preIdx] >> 4;
    let csym = this.corn0[this.urfIdx][this.preIdx] & 0xf;
    let mid = this.slice[this.urfIdx][this.preIdx];
    for (let i = 0; i < this.depth1; i++) {
      const m = this.move[i];
      cidx = CoordCube.CPermMove[cidx][CubieCube.SymMove[csym][m]];
      csym = CubieCube.SymMult[cidx & 0xf][csym];
      cidx >>= 4;

      const cx = CoordCube.UDSliceMove[mid & 0x1ff][m];
      mid = (Util.permMult[mid >> 9][cx >> 9] << 9) | (cx & 0x1ff);
    }
    mid >>= 9;
    let prun = CoordCube.getPruning(CoordCube.MCPermPrun, cidx * 24 + CoordCube.MPermConj[mid][csym]);
    if (prun >= this.maxDep2) {
      return prun > this.maxDep2 ? 2 : 1;
    }

    let u4e = this.ud8e0[this.urfIdx][this.preIdx] >> 16;
    let d4e = this.ud8e0[this.urfIdx][this.preIdx] & 0xffff;
    for (let i = 0; i < this.depth1; i++) {
      const m = this.move[i];

      let cx = CoordCube.UDSliceMove[u4e & 0x1ff][m];
      u4e = (Util.permMult[u4e >> 9][cx >> 9] << 9) | (cx & 0x1ff);

      cx = CoordCube.UDSliceMove[d4e & 0x1ff][m];
      d4e = (Util.permMult[d4e >> 9][cx >> 9] << 9) | (cx & 0x1ff);
    }

    let edge = CubieCube.MtoEPerm[494 - (u4e & 0x1ff) + (u4e >> 9) * 70 + (d4e >> 9) * 1680];
    const esym = edge & 0xf;
    edge >>= 4;

    prun = Math.max(CoordCube.getPruning(CoordCube.MEPermPrun, edge * 24 + CoordCube.MPermConj[mid][esym]), prun);
    if (prun >= this.maxDep2) {
      return prun > this.maxDep2 ? 2 : 1;
    }

    let lm = 10;
    if (this.depth1 >= 2 && Math.floor(this.move[this.depth1 - 1] / 3) % 3 == Math.floor(this.move[this.depth1 - 2] / 3) % 3) {
      lm = Util.std2ud[Math.floor(Math.max(this.move[this.depth1 - 1], this.move[this.depth1 - 2]) / 3) * 3 + 1];
    } else if (this.depth1 >= 1) {
      lm = Util.std2ud[Math.floor(this.move[this.depth1 - 1] / 3) * 3 + 1];
      if (this.move[this.depth1 - 1] > Util.Fx3) {
        lm = -lm;
      }
    }

    let depth2: number;
    for (depth2 = this.maxDep2 - 1; depth2 >= prun; depth2--) {
      const ret = this.phase2(edge, esym, cidx, csym, mid, depth2, this.depth1, lm);
      if (ret < 0) {
        break;
      }
      depth2 = depth2 - ret;
      this.sol = this.depth1 + depth2;
      if (this.preIdx != 0) {
        const axisPre = Math.floor(Util.preMove[this.preIdx] / 3);
        const axisLast = Math.floor(this.move[this.sol - 1] / 3);
        if (axisPre == axisLast) {
          const pow = (Util.preMove[this.preIdx] % 3 + this.move[this.sol - 1] % 3 + 1) % 4;
          this.move[this.sol - 1] = axisPre * 3 + pow;
        } else if (depth2 > 1 &&
          axisPre % 3 == axisLast % 3 &&
          Math.floor(this.move[this.sol - 2] / 3) == axisPre) {
          const pow = (Util.preMove[this.preIdx] % 3 + this.move[this.sol - 2] % 3 + 1) % 4;
          this.move[this.sol - 2] = axisPre * 3 + pow;
        } else {
          this.move[this.sol++] = Util.preMove[this.preIdx];
        }
      }
      this.solutionStr = this.solutionToString();
    }

    if (depth2 != this.maxDep2 - 1) { // At least one solution has been found.
      this.maxDep2 = Math.min(12, this.sol - this.length1);
      return this.probe >= this.probeMin ? 0 : 1;
    } else {
      return 1;
    }
  }

  private phase2(eidx: number, esym: number, cidx: number, csym: number, mid: number, maxl: number,
    depth: number, lm: number): number {
    if (eidx == 0 && cidx == 0 && mid == 0) {
      return maxl;
    }
    for (let m = 0; m < 10; m++) {
      if (lm < 0 ? (m == -lm) : Util.ckmv2[lm][m]) {
        continue;
      }
      const midx = CoordCube.MPermMove[mid][m];
      let cidxx = CoordCube.CPermMove[cidx][CubieCube.SymMove[csym][Util.ud2std[m]]];
      const csymx = CubieCube.SymMult[cidxx & 0xf][csym];
      cidxx >>= 4;
      if (CoordCube.getPruning(CoordCube.MCPermPrun,
        cidxx * 24 + CoordCube.MPermConj[midx][csymx]) >= maxl) {
        continue;
      }
      let eidxx = CoordCube.EPermMove[eidx][CubieCube.SymMoveUD[esym][m]];
      const esymx = CubieCube.SymMult[eidxx & 0xf][esym];
      eidxx >>= 4;

      if (CoordCube.getPruning(CoordCube.EPermCCombPrun,
        eidxx * 70 + CoordCube.CCombConj[CubieCube.Perm2Comb[cidxx]][CubieCube.SymMultInv[esymx][csymx]]) >= maxl) {
        continue;
      }
      if (CoordCube.getPruning(CoordCube.MEPermPrun,
        eidxx * 24 + CoordCube.MPermConj[midx][esymx]) >= maxl) {
        continue;
      }
      const ret = this.phase2(eidxx, esymx, cidxx, csymx, midx, maxl - 1, depth + 1, (lm < 0 && m + lm == -5) ? -lm : m);
      if (ret >= 0) {
        this.move[depth] = Util.ud2std[m];
        return ret;
      }
    }
    return -1;
  }

  private solutionToString(): string {
    let sb = '';
    const urf = (this.verbose & Search.INVERSE_SOLUTION) != 0 ? (this.urfIdx + 3) % 6 : this.urfIdx;
    if (urf < 3) {
      for (let s = 0; s < this.sol; s++) {
        if ((this.verbose & Search.USE_SEPARATOR) != 0 && s == this.depth1) {
          sb += '.  ';
        }
        sb += Util.move2str[CubieCube.urfMove[urf][this.move[s]]] + ' ';
      }
    } else {
      for (let s = this.sol - 1; s >= 0; s--) {
        sb += Util.move2str[CubieCube.urfMove[urf][this.move[s]]] + ' ';
        if ((this.verbose & Search.USE_SEPARATOR) != 0 && s == this.depth1) {
          sb += '.  ';
        }
      }
    }
    if ((this.verbose & Search.APPEND_LENGTH) != 0) {
      sb += '(' + this.sol + 'f)';
    }
    return sb;
  }
}
