// Ported from solver/FifteenPuzzle.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';

export class FifteenPuzzle {
  private static pz: number[] = new Array<number>(16).fill(0);
  private static arr: number[] = new Array<number>(16).fill(0);
  private static moveIdx: number[][] = [
    [-1, 4, -1, 1], [-1, 5, 0, 2], [-1, 6, 1, 3], [-1, 7, 2, -1], [0, 8, -1, 5], [1, 9, 4, 6], [2, 10, 5, 7], [3, 11, 6, -1],
    [4, 12, -1, 9], [5, 13, 8, 10], [6, 14, 9, 11], [7, 15, 10, -1], [8, -1, -1, 13], [9, -1, 12, 14], [10, -1, 13, 15], [11, -1, 14, -1]
  ];

  private static randomPuz(rnd: () => number): void {
    for (let i = 0; i < 16; i++) {
      FifteenPuzzle.pz[i] = i;
    }
    for (let i = 0; i < 16; i++) {
      const n = i + Math.floor(rnd() * (16 - i));
      if (n != i) {
        Utils.swap2(FifteenPuzzle.pz, i, n);
      }
    }
    if (FifteenPuzzle.parity() != 0) {
      if (FifteenPuzzle.pz[0] == 15 || FifteenPuzzle.pz[1] == 15) {
        Utils.swap2(FifteenPuzzle.pz, 2, 3);
      } else {
        Utils.swap2(FifteenPuzzle.pz, 0, 1);
      }
    }
  }

  private static parity(): number {
    let s = 0;
    for (let i = 0; i < 15; i++) {
      if (FifteenPuzzle.pz[i] == 15) {
        continue;
      }
      for (let j = i + 1; j < 16; j++) {
        if (FifteenPuzzle.pz[j] == 15) {
          continue;
        }
        if (FifteenPuzzle.pz[i] > FifteenPuzzle.pz[j]) {
          s ^= 1;
        }
      }
    }
    return s;
  }

  public static image(scramble: string, pieceMove: boolean): number[] {
    for (let i = 0; i < 16; i++) {
      FifteenPuzzle.pz[i] = i;
    }
    let blank = 15;
    const s = scramble.split(' ');
    for (let i = 0; i < s.length; i++) {
      if (s[i].length > 0) {
        let move = 0;
        switch (s[i].charAt(0)) {
          case 'U':
            move = pieceMove ? 1 : 0;
            break;
          case 'D':
            move = pieceMove ? 0 : 1;
            break;
          case 'L':
            move = pieceMove ? 3 : 2;
            break;
          case 'R':
            move = pieceMove ? 2 : 3;
            break;
        }
        let next = FifteenPuzzle.moveIdx[blank][move];
        if (next != -1) {
          Utils.swap2(FifteenPuzzle.pz, blank, next);
          blank = next;
        }
        if (s[i].length > 1) {
          next = FifteenPuzzle.moveIdx[blank][move];
          if (next != -1) {
            Utils.swap2(FifteenPuzzle.pz, blank, next);
            blank = next;
          }
          if (s[i].charAt(1) == '3') {
            next = FifteenPuzzle.moveIdx[blank][move];
            if (next != -1) {
              Utils.swap2(FifteenPuzzle.pz, blank, next);
              blank = next;
            }
          }
        }
      }
    }
    return FifteenPuzzle.pz;
  }
}
