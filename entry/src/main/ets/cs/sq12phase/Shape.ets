// Ported from cs/sq12phase/Shape.java (DCTimer-BLE -> HarmonyOS ArkTS)
// android.util.Log removed; Search metric constants referenced as Search.FACE_TURN_METRIC
// / Search.WCA_TURN_METRIC (kept in Search as in Java).
import { Search } from './Search';
import { FullCube } from './FullCube';

export class Shape {
  // 1 = corner, 0 = edge.
  static halflayer: number[] = [0x00, 0x03, 0x06, 0x0c, 0x0f, 0x18, 0x1b, 0x1e,
    0x30, 0x33, 0x36, 0x3c, 0x3f];

  static ShapeIdx: number[] = new Array<number>(3678).fill(0);
  static ShapePrun: number[] = new Array<number>(3678 * 2).fill(0);
  static ShapePrunOpt: number[] = new Array<number>(3678 * 2).fill(0);

  static spTopMove: number[] = new Array<number>(3678 * 2).fill(0);
  static spBottomMove: number[] = new Array<number>(3678 * 2).fill(0);
  static spTwistMove: number[] = new Array<number>(3678 * 2).fill(0);

  top = 0;
  bottom = 0;
  parity = 0;

  private static binarySearch(arr: number[], key: number): number {
    let lo = 0;
    let hi = arr.length - 1;
    while (lo <= hi) {
      const mid = (lo + hi) >> 1;
      const midVal = arr[mid];
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

  private static bitCount(x: number): number {
    x = x - ((x >> 1) & 0x55555555);
    x = (x & 0x33333333) + ((x >> 2) & 0x33333333);
    x = (x + (x >> 4)) & 0x0f0f0f0f;
    return (x * 0x01010101) >> 24;
  }

  static getShape2Idx(shp: number): number {
    return (Shape.binarySearch(Shape.ShapeIdx, shp & 0xffffff) << 1) | (shp >> 24);
  }

  private getIdx(): number {
    return (Shape.binarySearch(Shape.ShapeIdx, (this.top << 12) | this.bottom) << 1) | this.parity;
  }

  private setIdx(idx: number): void {
    this.parity = idx & 1;
    this.top = Shape.ShapeIdx[idx >> 1];
    this.bottom = this.top & 0xfff;
    this.top >>= 12;
  }

  private topMove(): number {
    let move = 0;
    let moveParity = 0;
    do {
      if ((this.top & 0x800) == 0) {
        move += 1;
        this.top = this.top << 1;
      } else {
        move += 2;
        this.top = (this.top << 2) ^ 0x3003;
      }
      moveParity = 1 - moveParity;
    } while ((Shape.bitCount(this.top & 0x3f) & 1) != 0);
    if ((Shape.bitCount(this.top) & 2) == 0) {
      this.parity ^= moveParity;
    }
    return move;
  }

  private bottomMove(): number {
    let move = 0;
    let moveParity = 0;
    do {
      if ((this.bottom & 0x800) == 0) {
        move += 1;
        this.bottom = this.bottom << 1;
      } else {
        move += 2;
        this.bottom = (this.bottom << 2) ^ 0x3003;
      }
      moveParity = 1 - moveParity;
    } while ((Shape.bitCount(this.bottom & 0x3f) & 1) != 0);
    if ((Shape.bitCount(this.bottom) & 2) == 0) {
      this.parity ^= moveParity;
    }
    return move;
  }

  private twistMove(): void {
    const temp = this.top & 0x3f;
    const p1 = Shape.bitCount(temp);
    const p3 = Shape.bitCount(this.bottom & 0xfc0);
    this.parity ^= 1 & ((p1 & p3) >> 1);

    this.top = (this.top & 0xfc0) | ((this.bottom >> 6) & 0x3f);
    this.bottom = (this.bottom & 0x3f) | (temp << 6);
  }

  static inited = false;

  static initPruning(Prun: number[], done: number, metric: number): void {
    let done0 = 0;
    let depth = -1;
    while (done != done0) {
      done0 = done;
      ++depth;
      for (let i = 0; i < 3678 * 2; i++) {
        if (Prun[i] != depth) {
          continue;
        }
        // try twist
        {
          const idx = Shape.spTwistMove[i];
          if (Prun[idx] == -1) {
            ++done;
            Prun[idx] = depth + 1;
          }
        }

        if (metric == Search.FACE_TURN_METRIC) {
          // try top move
          for (let m = 0, inc = 0, idx = i; m != 12; m += inc) {
            idx = Shape.spTopMove[idx];
            inc = idx & 0xf;
            idx >>= 4;
            if (Prun[idx] == -1) {
              ++done;
              Prun[idx] = depth + 1;
            }
          }
          // try bottom
          for (let m = 0, inc = 0, idx = i; m != 12; m += inc) {
            idx = Shape.spBottomMove[idx];
            inc = idx & 0xf;
            idx >>= 4;
            if (Prun[idx] == -1) {
              ++done;
              Prun[idx] = depth + 1;
            }
          }
        } else if (metric == Search.WCA_TURN_METRIC) {
          // try top/bottom move
          for (let m = 0, inc = 0, idx = i; m != 12; m += inc) {
            idx = Shape.spTopMove[idx];
            inc = idx & 0xf;
            idx >>= 4;
            for (let m2 = 0, inc2 = 0, idx2 = idx; m2 != 12; m2 += inc2) {
              idx2 = Shape.spBottomMove[idx2];
              inc2 = idx2 & 0xf;
              idx2 >>= 4;
              if (Prun[idx2] == -1) {
                ++done;
                Prun[idx2] = depth + 1;
              }
            }
          }
        }
      }
    }
  }

  public static init(): void {
    if (Shape.inited) {
      return;
    }
    let count = 0;
    for (let i = 0; i < 13 * 13 * 13 * 13; i++) {
      const dr = Shape.halflayer[i % 13];
      const dl = Shape.halflayer[Math.floor(i / 13) % 13];
      const ur = Shape.halflayer[Math.floor(i / 13 / 13) % 13];
      const ul = Shape.halflayer[Math.floor(i / 13 / 13 / 13)];
      const value = (ul << 18) | (ur << 12) | (dl << 6) | dr;
      if (Shape.bitCount(value) == 16) {
        Shape.ShapeIdx[count++] = value;
      }
    }
    const s = new Shape();
    for (let i = 0; i < 3678 * 2; i++) {
      s.setIdx(i);
      Shape.spTopMove[i] = s.topMove();
      Shape.spTopMove[i] |= s.getIdx() << 4;
      s.setIdx(i);
      Shape.spBottomMove[i] = s.bottomMove();
      Shape.spBottomMove[i] |= s.getIdx() << 4;
      s.setIdx(i);
      s.twistMove();
      Shape.spTwistMove[i] = s.getIdx();
    }

    for (let i = 0; i < 3678 * 2; i++) {
      Shape.ShapePrun[i] = -1;
      Shape.ShapePrunOpt[i] = -1;
    }
    Shape.ShapePrun[Shape.getShape2Idx(0x0db66db)] = 0; // 0 110110110110 011011011011
    Shape.ShapePrun[Shape.getShape2Idx(0x1db6db6)] = 0; // 1 110110110110 110110110110
    Shape.ShapePrun[Shape.getShape2Idx(0x16db6db)] = 0; // 1 011011011011 011011011011
    Shape.ShapePrun[Shape.getShape2Idx(0x06dbdb6)] = 0; // 0 011011011011 110110110110
    Shape.initPruning(Shape.ShapePrun, 4, Search.FACE_TURN_METRIC);
    Shape.ShapePrunOpt[new FullCube().getShapeIdx()] = 0;
    Shape.initPruning(Shape.ShapePrunOpt, 1, Search.WCA_TURN_METRIC);
    Shape.inited = true;
  }
}
