// Ported from cs/sq12phase/Square.java (DCTimer-BLE -> HarmonyOS ArkTS)
// android.util.Log removed.
import { Utils as SolverUtils } from '../../solver/Utils';

export class Square {
  edgeperm = 0; // number encoding the edge permutation 0-40319
  cornperm = 0; // number encoding the corner permutation 0-40319
  topEdgeFirst = false; // true if top layer starts with edge left of seam
  botEdgeFirst = false; // true if bottom layer starts with edge right of seam
  ml = 0; // shape of middle layer (+/-1, or 0 if ignored)

  static SquarePrun: number[] = new Array<number>(40320 * 2).fill(0); // pruning table; #twists to solve corner|edge permutation

  static sqTwistMove: number[] = new Array<number>(40320).fill(0); // transition table for twists
  static sqTopMove: number[] = new Array<number>(40320).fill(0); // transition table for top layer turns
  static sqBottomMove: number[] = new Array<number>(40320).fill(0); // transition table for bottom layer turns

  static ini = false;

  public static init(): void {
    if (Square.ini) {
      return;
    }
    const pos: number[] = new Array<number>(8).fill(0);
    let temp = 0;

    for (let i = 0; i < 40320; i++) {
      // twist
      SolverUtils.set8Perm(pos, 8, i);

      temp = pos[2]; pos[2] = pos[4]; pos[4] = temp;
      temp = pos[3]; pos[3] = pos[5]; pos[5] = temp;
      Square.sqTwistMove[i] = SolverUtils.get8Perm(pos, 8);

      // top layer turn
      SolverUtils.set8Perm(pos, 8, i);
      temp = pos[0]; pos[0] = pos[1]; pos[1] = pos[2]; pos[2] = pos[3]; pos[3] = temp;
      Square.sqTopMove[i] = SolverUtils.get8Perm(pos, 8);

      // bottom layer turn
      SolverUtils.set8Perm(pos, 8, i);
      temp = pos[4]; pos[4] = pos[5]; pos[5] = pos[6]; pos[6] = pos[7]; pos[7] = temp;
      Square.sqBottomMove[i] = SolverUtils.get8Perm(pos, 8);
    }

    for (let i = 0; i < 40320 * 2; i++) {
      Square.SquarePrun[i] = -1;
    }
    Square.SquarePrun[0] = 0;
    let depth = 0;
    let done = 1;
    while (done < 40320 * 2) {
      const inv = depth >= 11;
      const find = inv ? -1 : depth;
      const check = inv ? depth : -1;
      ++depth;
      for (let i = 0; i < 40320 * 2; i++) {
        if (Square.SquarePrun[i] != find) {
          continue;
        }
        let perm = i >> 1;
        const ml = i & 1;

        // try twist
        const idx = (Square.sqTwistMove[perm] << 1) | (1 - ml);
        if (Square.SquarePrun[idx] == check) {
          ++done;
          Square.SquarePrun[inv ? i : idx] = depth;
          if (inv) continue;
        }

        // try turning top layer (Java: labeled continue OUT)
        let out = false;
        for (let m = 0; m < 4; m++) {
          perm = Square.sqTopMove[perm];
          const idx2 = (perm << 1) | ml;
          if (Square.SquarePrun[idx2] == check) {
            ++done;
            Square.SquarePrun[inv ? i : idx2] = depth;
            if (inv) {
              out = true;
              break;
            }
          }
        }
        if (out) {
          continue;
        }
        // try turning bottom layer
        for (let m = 0; m < 4; m++) {
          perm = Square.sqBottomMove[perm];
          const idx3 = (perm << 1) | ml;
          if (Square.SquarePrun[idx3] == check) {
            ++done;
            Square.SquarePrun[inv ? i : idx3] = depth;
            if (inv) {
              break;
            }
          }
        }
      }
    }
    Square.ini = true;
  }
}
