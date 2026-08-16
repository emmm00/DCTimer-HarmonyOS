// Ported from cs/sq12phase/Search.java (DCTimer-BLE -> HarmonyOS ArkTS)
// android.util.Log calls removed. The (commented-out in Java) static{} block that called
// Shape.init()/Square.init() is restored as Search.init() (guarded), invoked lazily from
// the scramble entry points.
import { FullCube } from './FullCube';
import { Shape } from './Shape';
import { Square } from './Square';
import { Utils as SolverUtils } from '../../solver/Utils';

export class Search {
  public static readonly INVERSE_SOLUTION = 0x2;
  static readonly FACE_TURN_METRIC = 0;
  static readonly WCA_TURN_METRIC = 1;
  private static readonly PRUN_INC = 2;

  private static inited = false;

  static init(): void {
    if (Search.inited) {
      return;
    }
    Shape.init();
    Square.init();
    Search.inited = true;
  }

  private move: number[] = new Array<number>(100).fill(0);
  private c: FullCube | null = null;
  private d: FullCube = new FullCube('');
  private sq: Square = new Square();
  private length1 = 0;
  movelen1 = 0;
  private maxlen2 = 0;
  verbose = 0;
  private sol_string: string | null = null;

  private solution(c: FullCube, verbose: number): string {
    this.c = c;
    this.verbose = verbose;
    this.sol_string = null;
    const shape = c.getShapeIdx();
    for (this.length1 = Shape.ShapePrun[shape]; this.length1 < 50; this.length1++) {
      this.maxlen2 = Math.min(33 - this.length1, 17);
      if (this.phase1(shape, Shape.ShapePrun[shape], this.length1, 0, -1)) {
        break;
      }
    }
    return this.sol_string ?? '';
  }

  public scramble(): string {
    Search.init();
    let scr: string | null;
    do {
      scr = this.solution(FullCube.randomCube(), Search.INVERSE_SOLUTION);
    } while (scr == null || scr.length < 4);
    return scr;
  }

  public scramble1(shape: number): string {
    Search.init();
    let scr: string | null;
    do {
      scr = this.solution(FullCube.randomCube1(shape), Search.INVERSE_SOLUTION);
    } while (scr == null || scr.length < 4);
    return scr;
  }

  public scramblePBL(rnd: () => number): string {
    Search.init();
    let scr: string | null;
    do {
      const corner: number[] = [7, 6, 5, 4, 3, 2, 1, 0];
      for (let i = 0; i < 4; i++) {
        let x = i + Math.floor(rnd() * (4 - i));
        if (x != i) SolverUtils.swap2(corner, i, x);
        x = i + 4 + Math.floor(rnd() * (4 - i));
        if (x != i + 4) SolverUtils.swap2(corner, i + 4, x);
      }
      const edge: number[] = [7, 6, 5, 4, 3, 2, 1, 0];
      for (let i = 0; i < 4; i++) {
        let x = i + Math.floor(rnd() * (4 - i));
        if (x != i) SolverUtils.swap2(edge, i, x);
        x = i + 4 + Math.floor(rnd() * (4 - i));
        if (x != i + 4) SolverUtils.swap2(edge, i + 4, x);
      }
      scr = this.solution(FullCube.randomCube2(1037, SolverUtils.get8Perm(corner, 8),
        SolverUtils.get8Perm(edge, 8)), Search.INVERSE_SOLUTION);
    } while (scr == null || scr.length < 4);
    return scr;
  }

  public scrambleWCA(): string {
    Search.init();
    let c = new FullCube();
    let sol: string | null;
    do {
      c = FullCube.randomCube();
      sol = this.solutionOpt(c, 11, Search.INVERSE_SOLUTION);
    } while (sol != null);
    return this.solution(c, Search.INVERSE_SOLUTION);
  }

  private solutionOpt(c: FullCube, maxl: number, verbose: number): string | null {
    this.c = c;
    this.verbose = verbose;
    const shape = c.getShapeIdx();
    for (this.length1 = Shape.ShapePrunOpt[shape] * Search.PRUN_INC;
      this.length1 <= maxl * Search.PRUN_INC; this.length1 += Search.PRUN_INC) {
      if (this.phase1Opt(shape, Shape.ShapePrunOpt[shape], this.length1, 0, -1, 0)) {
        return this.sol_string;
      }
    }
    return null;
  }

  private static count0xf(val: number): number {
    val &= val >> 1;
    val &= val >> 2;
    return Search.bitCount(val & 0x11111111);
  }

  private static bitCount(x: number): number {
    x = x - ((x >> 1) & 0x55555555);
    x = (x & 0x33333333) + ((x >> 2) & 0x33333333);
    x = (x + (x >> 4)) & 0x0f0f0f0f;
    return (x * 0x01010101) >> 24;
  }

  private phase1Opt(shape: number, prunvalue: number, maxl: number, depth: number, lm: number,
    lastTurns: number): boolean {
    const i = Search.count0xf((lastTurns ^ ~0x000000) & 0xff00ff) -
      Search.count0xf((lastTurns ^ ~0x666666) & 0xff00ff);
    if (i < 0 || i == 0 && (lastTurns >> 20 & 0xf) >= 6) {
      return false;
    }

    if (Math.floor(maxl / Search.PRUN_INC) == 0) {
      this.movelen1 = depth;
      if (this.isSolvedInPhase1()) {
        return true;
      }
      if (maxl == 0) {
        return false;
      }
    }
    // try each possible move. First twist;
    if (lm != 0) {
      const shapex = Shape.spTwistMove[shape];
      const prun = Shape.ShapePrunOpt[shapex];
      if (prun < Math.floor(maxl / Search.PRUN_INC)) {
        this.move[depth] = 0;
        const next_maxl = (Math.floor(maxl / Search.PRUN_INC) - 1) * Search.PRUN_INC;
        if (this.phase1Opt(shapex, prun, next_maxl, depth + 1, 0, lastTurns << 8)) {
          return true;
        }
      }
    }

    // Try top layer
    let shapex = shape;
    if (lm <= 0) {
      let m = 0;
      while (true) {
        m += Shape.spTopMove[shapex];
        shapex = m >> 4;
        m &= 0x0f;
        if (m >= 12) {
          break;
        }
        const prun = Shape.ShapePrunOpt[shapex];
        if (prun * Search.PRUN_INC > (maxl + Search.PRUN_INC - 1)) {
          break;
        } else if (prun * Search.PRUN_INC < (maxl + Search.PRUN_INC - 1)) {
          this.move[depth] = m;
          if (this.phase1Opt(shapex, prun, maxl - 1, depth + 1, 1, lastTurns | (m << 4))) {
            return true;
          }
        }
      }
    }

    shapex = shape;
    // Try bottom layer
    if (lm <= 1) {
      let m = 0;
      while (true) {
        m += Shape.spBottomMove[shapex];
        shapex = m >> 4;
        m &= 0x0f;
        if (m >= 12) {
          break;
        }
        const prun = Shape.ShapePrunOpt[shapex];
        if (prun * Search.PRUN_INC > (maxl + Search.PRUN_INC - 1)) {
          break;
        } else if (prun * Search.PRUN_INC < (maxl + Search.PRUN_INC - 1)) {
          this.move[depth] = -m;
          if (this.phase1Opt(shapex, prun, maxl - 1, depth + 1, 2, lastTurns | m)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  private isSolvedInPhase1(): boolean {
    this.d.copy(this.c as FullCube);
    for (let i = 0; i < this.movelen1; i++) {
      this.d.doMove(this.move[i]);
    }
    const isSolved = this.d.isSolved();
    if (isSolved) {
      this.sol_string = this.move2string(this.movelen1);
    }
    return isSolved;
  }

  private phase1(shape: number, prunvalue: number, maxl: number, depth: number, lm: number): boolean {
    if (prunvalue == 0 && maxl < 4) {
      this.movelen1 = depth;
      return maxl == 0 && this.init2();
    }

    // try each possible move. First twist;
    if (lm != 0) {
      const shapex = Shape.spTwistMove[shape];
      const prunx = Shape.ShapePrun[shapex];
      if (prunx < maxl) {
        this.move[depth] = 0;
        if (this.phase1(shapex, prunx, maxl - 1, depth + 1, 0)) {
          return true;
        }
      }
    }

    // Try top layer
    if (lm <= 0) {
      let m = 0;
      let shapex = shape;
      while (true) {
        m += Shape.spTopMove[shapex];
        shapex = m >> 4;
        m &= 0x0f;
        if (m >= 12) {
          break;
        }
        const prun = Shape.ShapePrun[shapex];
        if (prun > maxl) {
          break;
        } else if (prun < maxl) {
          this.move[depth] = m;
          if (this.phase1(shapex, prun, maxl - 1, depth + 1, 1)) {
            return true;
          }
        }
      }
    }

    // Try bottom layer
    if (lm <= 1) {
      let m = 0;
      let shapex = shape;
      while (true) {
        m += Shape.spBottomMove[shapex];
        shapex = m >> 4;
        m &= 0x0f;
        if (m >= 6) {
          break;
        }
        const prun = Shape.ShapePrun[shapex];
        if (prun > maxl) {
          break;
        } else if (prun < maxl) {
          this.move[depth] = -m;
          if (this.phase1(shapex, prun, maxl - 1, depth + 1, 2)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  private init2(): boolean {
    this.d.copy(this.c as FullCube);
    for (let i = 0; i < this.movelen1; i++) {
      this.d.doMove(this.move[i]);
    }
    this.d.getSquare(this.sq);

    const edge = this.sq.edgeperm;
    const corner = this.sq.cornperm;
    const ml = this.sq.ml;

    const prun = Math.max(Square.SquarePrun[(this.sq.edgeperm << 1) | ml],
      Square.SquarePrun[(this.sq.cornperm << 1) | ml]);

    for (let i = prun; i < this.maxlen2; i++) {
      if (this.phase2(edge, corner, this.sq.topEdgeFirst, this.sq.botEdgeFirst, ml, i, this.movelen1, 0)) {
        this.sol_string = this.move2string(i + this.movelen1);
        return true;
      }
    }

    return false;
  }

  private move2string(len: number): string {
    let s = '';
    const outputMoves: number[] = new Array<number>(len).fill(0);
    if ((this.verbose & Search.INVERSE_SOLUTION) != 0) {
      for (let i = len - 1; i >= 0; i--) {
        outputMoves[len - 1 - i] = this.move[i] > 0 ? (12 - this.move[i]) :
          this.move[i] < 0 ? (-12 - this.move[i]) : this.move[i];
      }
    } else {
      for (let i = 0; i < len; i++) {
        outputMoves[i] = this.move[i];
      }
    }

    let top = 0;
    let bottom = 0;
    for (let i = 0; i < len; i++) {
      const val = outputMoves[i];
      if (val > 0) {
        top = (val > 6) ? (val - 12) : val;
      } else if (val < 0) {
        bottom = (-val > 6) ? (-val - 12) : -val;
      } else {
        if (top == 0 && bottom == 0) {
          s += ' / ';
        } else {
          s += '(' + top + ',' + bottom + ') / ';
        }
        top = 0;
        bottom = 0;
      }
    }
    if (top != 0 || bottom != 0) {
      s += '(' + top + ',' + bottom + ')';
    }
    return s; // + " (" + len + "t)";
  }

  private phase2(edge: number, corner: number, topEdgeFirst: boolean, botEdgeFirst: boolean, ml: number,
    maxl: number, depth: number, lm: number): boolean {
    if (maxl == 0 && !topEdgeFirst && botEdgeFirst /*edge==0 && corner==0 && !topEdgeFirst && botEdgeFirst && ml==0*/) {
      return true;
    }

    // try each possible move. First twist;
    if (lm != 0 && topEdgeFirst == botEdgeFirst) {
      const edgex = Square.sqTwistMove[edge];
      const cornerx = Square.sqTwistMove[corner];

      if (Square.SquarePrun[(edgex << 1) | (1 - ml)] < maxl &&
        Square.SquarePrun[(cornerx << 1) | (1 - ml)] < maxl) {
        this.move[depth] = 0;
        if (this.phase2(edgex, cornerx, topEdgeFirst, botEdgeFirst, 1 - ml, maxl - 1, depth + 1, 0)) {
          return true;
        }
      }
    }

    // Try top layer
    if (lm <= 0) {
      let topEdgeFirstx = !topEdgeFirst;
      let edgex = topEdgeFirstx ? Square.sqTopMove[edge] : edge;
      let cornerx = topEdgeFirstx ? corner : Square.sqTopMove[corner];
      let m = topEdgeFirstx ? 1 : 2;
      let prun1 = Square.SquarePrun[(edgex << 1) | ml];
      let prun2 = Square.SquarePrun[(cornerx << 1) | ml];
      while (m < 12 && prun1 <= maxl && prun1 <= maxl) {
        if (prun1 < maxl && prun2 < maxl) {
          this.move[depth] = m;
          if (this.phase2(edgex, cornerx, topEdgeFirstx, botEdgeFirst, ml, maxl - 1, depth + 1, 1)) {
            return true;
          }
        }
        topEdgeFirstx = !topEdgeFirstx;
        if (topEdgeFirstx) {
          edgex = Square.sqTopMove[edgex];
          prun1 = Square.SquarePrun[(edgex << 1) | ml];
          m += 1;
        } else {
          cornerx = Square.sqTopMove[cornerx];
          prun2 = Square.SquarePrun[(cornerx << 1) | ml];
          m += 2;
        }
      }
    }

    if (lm <= 1) {
      let botEdgeFirstx = !botEdgeFirst;
      let edgex = botEdgeFirstx ? Square.sqBottomMove[edge] : edge;
      let cornerx = botEdgeFirstx ? corner : Square.sqBottomMove[corner];
      let m = botEdgeFirstx ? 1 : 2;
      let prun1 = Square.SquarePrun[(edgex << 1) | ml];
      let prun2 = Square.SquarePrun[(cornerx << 1) | ml];
      while (m < (maxl > 6 ? 6 : 12) && prun1 <= maxl && prun1 <= maxl) {
        if (prun1 < maxl && prun2 < maxl) {
          this.move[depth] = -m;
          if (this.phase2(edgex, cornerx, topEdgeFirst, botEdgeFirstx, ml, maxl - 1, depth + 1, 2)) {
            return true;
          }
        }
        botEdgeFirstx = !botEdgeFirstx;
        if (botEdgeFirstx) {
          edgex = Square.sqBottomMove[edgex];
          prun1 = Square.SquarePrun[(edgex << 1) | ml];
          m += 1;
        } else {
          cornerx = Square.sqBottomMove[cornerx];
          prun2 = Square.SquarePrun[(cornerx << 1) | ml];
          m += 2;
        }
      }
    }
    return false;
  }
}
