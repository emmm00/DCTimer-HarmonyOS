// Ported from solver/Sq1Shape.java (DCTimer-BLE -> HarmonyOS ArkTS)

export class Sq1Shape {
  private static halfLayer: number[] = [0x15, 0x17, 0x1B, 0x1D, 0x1F, 0x2B, 0x2D, 0x2F,
    0x35, 0x37, 0x3B, 0x3D, 0x3F];
  private static shapeIdx: number[] = new Array<number>(3678).fill(0);
  private static solved = 7191405;
  private static prunTrn: number[] = new Array<number>(3678).fill(0);
  private static prunTws: number[] = new Array<number>(3678).fill(0);
  private static sol: number[] = new Array<number>(24).fill(0);
  private static sollen = 0;

  private static binarySearch(a: number[], key: number): number {
    let lo = 0;
    let hi = a.length - 1;
    while (lo <= hi) {
      const mid = Math.floor((lo + hi) / 2);
      const midVal = a[mid];
      if (midVal < key) {
        lo = mid + 1;
      } else if (midVal > key) {
        hi = mid - 1;
      } else {
        return mid;
      }
    }
    return -(lo + 1);
  }

  private static getShape2Idx(shp: number): number {
    return Sq1Shape.binarySearch(Sq1Shape.shapeIdx, shp);
  }

  private static bitCount(x: number): number {
    let n = x - ((x >> 1) & 0x55555555);
    n = (n & 0x33333333) + ((n >> 2) & 0x33333333);
    n = (n + (n >> 4)) & 0x0f0f0f0f;
    return (n * 0x01010101) >> 24;
  }

  private static rotate(layer: number): number {
    return ((layer << 1) & 0xFFE) | ((layer >> 11) & 1);
  }

  private static getTop(index: number): number {
    return index & 0xFFF;
  }

  private static getBottom(index: number): number {
    return (index >> 12) & 0xFFF;
  }

  private static rotateTop(idx: number): number {
    return (Sq1Shape.getBottom(idx) << 12) | Sq1Shape.rotate(Sq1Shape.getTop(idx));
  }

  private static rotateBottom(idx: number): number {
    return (Sq1Shape.rotate(Sq1Shape.getBottom(idx)) << 12) | Sq1Shape.getTop(idx);
  }

  private static twist(idx: number): number {
    const newTop = (Sq1Shape.getTop(idx) & 0xF80) | (Sq1Shape.getBottom(idx) & 0x7F);
    const newBottom = (Sq1Shape.getBottom(idx) & 0xF80) | (Sq1Shape.getTop(idx) & 0x7F);
    return (newBottom << 12) | newTop;
  }

  private static canTwist(idx: number): boolean {
    const top = Sq1Shape.getTop(idx);
    const bottom = Sq1Shape.getBottom(idx);
    return (top & 1) != 0 && (top & (1 << 6)) != 0 &&
    (bottom & 1) != 0 && (bottom & (1 << 6)) != 0;
  }

  public static applyMove(state: number, move: string): number {
    if (move.length == 0) {
      return state;
    }
    if (move == '/') {
      state = Sq1Shape.twist(state);
    } else {
      const matcher = /\((-?\d+),(-?\d+)\)/.exec(move);
      if (matcher != null) {
        const top = Number(matcher[1]);
        for (let i = 0; i < top + 12; i++) {
          state = Sq1Shape.rotateTop(state);
        }
        const bottom = Number(matcher[2]);
        for (let i = 0; i < bottom + 12; i++) {
          state = Sq1Shape.rotateBottom(state);
        }
      }
    }
    return state;
  }

  public static applySequence(sequence: string[]): number {
    let state = Sq1Shape.solved;
    for (const move of sequence) {
      state = Sq1Shape.applyMove(state, move);
    }
    return state;
  }

  private static ini = false;

  static init(): void {
    if (Sq1Shape.ini) {
      return;
    }
    let count = 0;
    for (let i = 0; i < 28561; i++) {
      const dr = Sq1Shape.halfLayer[i % 13];
      const dl = Sq1Shape.halfLayer[Math.floor(i / 13) % 13];
      const ur = Sq1Shape.halfLayer[Math.floor(Math.floor(i / 13) / 13) % 13];
      const ul = Sq1Shape.halfLayer[Math.floor(Math.floor(Math.floor(i / 13) / 13) / 13)];
      const value = (ul << 18) | (ur << 12) | (dl << 6) | dr;
      if (Sq1Shape.bitCount(value) == 16) {
        Sq1Shape.shapeIdx[count++] = value;
      }
    }
    Sq1Shape.ini = true;
  }

  private static inif = false;

  static initf(): void {
    if (Sq1Shape.inif) {
      return;
    }
    Sq1Shape.init();
    for (let i = 0; i < 3678; i++) {
      Sq1Shape.prunTrn[i] = -1;
    }
    Sq1Shape.prunTrn[Sq1Shape.getShape2Idx(Sq1Shape.solved)] = 0;
    let tol = 1;
    for (let d = 0; d < 14; d++) {
      for (let i = 0; i < 3678; i++) {
        if (Sq1Shape.prunTrn[i] == d) {
          const state = Sq1Shape.shapeIdx[i];
          // twist
          if (Sq1Shape.canTwist(state)) {
            const next = Sq1Shape.twist(state);
            const temp = Sq1Shape.getShape2Idx(next);
            if (Sq1Shape.prunTrn[temp] == -1) {
              Sq1Shape.prunTrn[temp] = d + 1;
              tol++;
            }
          }
          // rotate top
          let nextTop = Sq1Shape.shapeIdx[i];
          for (let j = 0; j < 11; j++) {
            nextTop = Sq1Shape.rotateTop(nextTop);
            if (Sq1Shape.canTwist(nextTop)) {
              const temp = Sq1Shape.getShape2Idx(nextTop);
              if (Sq1Shape.prunTrn[temp] == -1) {
                Sq1Shape.prunTrn[temp] = d + 1;
                tol++;
              }
            }
          }
          // rotate bottom
          let nextBottom = Sq1Shape.shapeIdx[i];
          for (let j = 0; j < 11; j++) {
            nextBottom = Sq1Shape.rotateBottom(nextBottom);
            if (Sq1Shape.canTwist(nextBottom)) {
              const temp = Sq1Shape.getShape2Idx(nextBottom);
              if (Sq1Shape.prunTrn[temp] == -1) {
                Sq1Shape.prunTrn[temp] = d + 1;
                tol++;
              }
            }
          }
        }
      }
    }
    Sq1Shape.inif = true;
  }

  private static initDone = false;

  static initt(): void {
    if (Sq1Shape.initDone) {
      return;
    }
    Sq1Shape.init();
    for (let i = 0; i < 3678; i++) {
      Sq1Shape.prunTws[i] = -1;
    }
    Sq1Shape.prunTws[1170] = 0;
    Sq1Shape.prunTws[1192] = 0;
    Sq1Shape.prunTws[2640] = 0;
    Sq1Shape.prunTws[2662] = 0;
    let tol = 4;
    //twist
    for (let d = 0; d < 7; d++) {
      for (let i = 0; i < 3678; i++) {
        if (Sq1Shape.prunTws[i] == d) {
          let next = Sq1Shape.twist(Sq1Shape.shapeIdx[i]);
          if (Sq1Shape.prunTws[Sq1Shape.getShape2Idx(next)] == -1) {
            Sq1Shape.prunTws[Sq1Shape.getShape2Idx(next)] = d + 1;
            tol++;
            for (let a = 0; a < 13; a++) {
              for (let b = 0; b < 13; b++) {
                if (Sq1Shape.canTwist(next)) {
                  const temp = Sq1Shape.getShape2Idx(next);
                  if (Sq1Shape.prunTws[temp] == -1) {
                    Sq1Shape.prunTws[temp] = d + 1;
                    tol++;
                  }
                }
                next = Sq1Shape.rotateBottom(next);
              }
              next = Sq1Shape.rotateTop(next);
            }
          }
        }
      }
    }
    Sq1Shape.initDone = true;
  }

  private static searchTws(shape: number, d: number, lm: number): boolean {
    if (d == 0) {
      return shape == Sq1Shape.solved;
    }
    if (Sq1Shape.prunTws[Sq1Shape.getShape2Idx(shape)] > d) {
      return false;
    }
    //top move
    for (let i = 0; i < 12; i++) {
      if (i != 0) {
        Sq1Shape.sol[Sq1Shape.sollen++] = i;
      }
      //bottom move
      for (let j = 0; j < 12; j++) {
        if (j != 0) {
          Sq1Shape.sol[Sq1Shape.sollen++] = -j;
        }
        //twist
        if ((lm != 0 || (i != 0 || j != 0)) && Sq1Shape.canTwist(shape)) {
          const next = Sq1Shape.twist(shape);
          Sq1Shape.sol[Sq1Shape.sollen++] = 0;
          if (Sq1Shape.searchTws(next, d - 1, 0)) {
            return true;
          }
          Sq1Shape.sollen--;
        }
        if (j != 0) {
          Sq1Shape.sollen--;
        }
        shape = Sq1Shape.rotateBottom(shape);
      }
      if (i != 0) {
        Sq1Shape.sollen--;
      }
      shape = Sq1Shape.rotateTop(shape);
    }
    return false;
  }

  private static move2string(): string {
    let sb = '\n\nttm: ';
    let top = 0;
    let bottom = 0;
    for (let i = 0; i < Sq1Shape.sollen; i++) {
      const val = Sq1Shape.sol[i];
      if (val > 0) {
        top = (val > 6) ? (val - 12) : val;
      } else if (val < 0) {
        bottom = (val < -6) ? (-12 - val) : -val;
      } else {
        if (top == 0 && bottom == 0) {
          sb += ' / ';
        } else {
          sb += '(' + top + ',' + bottom + ') / ';
        }
        top = 0;
        bottom = 0;
      }
    }
    if (top != 0 || bottom != 0) {
      sb += '(' + top + ',' + bottom + ')';
    }
    return sb;
  }

  public static solve(type: number, scr: string): string {
    if (type == 0) {
      return '';
    }
    Sq1Shape.init();
    const state = Sq1Shape.applySequence(scr.split(' '));
    if (type == 1) {
      return Sq1Shape.solveTrn(state);
    }
    return Sq1Shape.solveTws(state);
  }

  private static solveTrn(state: number): string {
    Sq1Shape.initf();
    let sequence = '\n\nftm: ';
    let st = state;
    while (Sq1Shape.prunTrn[Sq1Shape.getShape2Idx(st)] > 0) {
      // twist
      if (Sq1Shape.canTwist(st)) {
        const next = Sq1Shape.twist(st);
        if (Sq1Shape.prunTrn[Sq1Shape.getShape2Idx(next)] == Sq1Shape.prunTrn[Sq1Shape.getShape2Idx(st)] - 1) {
          sequence += '/ ';
          st = next;
        }
      }
      // rotate top
      let x = 0;
      let nextTop = st;
      for (let i = 0; i < 12; i++) {
        const temp = Sq1Shape.getShape2Idx(nextTop);
        if (temp >= 0 && Sq1Shape.prunTrn[temp] == Sq1Shape.prunTrn[Sq1Shape.getShape2Idx(st)] - 1) {
          x = i;
          st = nextTop;
          break;
        }
        nextTop = Sq1Shape.rotateTop(nextTop);
      }
      // rotate bottom
      let y = 0;
      let nextBottom = st;
      for (let j = 0; j < 12; j++) {
        const temp = Sq1Shape.getShape2Idx(nextBottom);
        if (temp >= 0 && Sq1Shape.prunTrn[temp] == Sq1Shape.prunTrn[Sq1Shape.getShape2Idx(st)] - 1) {
          y = j;
          st = nextBottom;
          break;
        }
        nextBottom = Sq1Shape.rotateBottom(nextBottom);
      }
      if (x != 0 || y != 0) {
        sequence += '(' + (x <= 6 ? x : x - 12) + ',' + (y <= 6 ? y : y - 12) + ') ';
      }
    }
    return sequence;
  }

  private static solveTws(state: number): string {
    Sq1Shape.initt();
    Sq1Shape.sollen = 0;
    for (let d = 0; ; d++) {
      if (Sq1Shape.searchTws(state, d, -1)) {
        return Sq1Shape.move2string();
      }
    }
  }
}
