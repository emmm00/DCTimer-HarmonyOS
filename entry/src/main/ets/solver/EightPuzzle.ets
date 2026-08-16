// Ported from solver/EightPuzzle.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';

export class EightPuzzle {
  private static prun: number[] = new Array<number>(362880).fill(0);
  private static pz: number[] = new Array<number>(9).fill(0);
  static seq: number[] = new Array<number>(25).fill(0);
  private static suff: string[] = [' ', '2 '];
  private static ini = false;
  private static moveIdx: number[][] = [
    [-1, 3, -1, 1], [-1, 4, 0, 2], [-1, 5, 1, -1],
    [0, 6, -1, 4], [1, 7, 3, 5], [2, 8, 4, -1],
    [3, -1, -1, 7], [4, -1, 6, 8], [5, -1, 7, -1]
  ];

  static init(): void {
    if (EightPuzzle.ini) {
      return;
    }
    const arr: number[] = new Array<number>(9).fill(0);
    for (let i = 0; i < 362880; i++) {
      EightPuzzle.prun[i] = -1;
    }
    EightPuzzle.prun[0] = 0;
    let c = 1;
    for (let d = 0; d < 24; d++) {
      for (let i = 0; i < 362880; i++) {
        if (EightPuzzle.prun[i] == d) {
          Utils.set11Perm(arr, i, 9);
          for (let m = 0; m < 4; m++) {
            for (let n = 0; n < 9; n++) {
              EightPuzzle.pz[n] = arr[n];
            }
            for (let n = 0; n < 2; n++) {
              let next = EightPuzzle.move(m);
              if (next == -1) {
                break;
              }
              next = Utils.get11Perm(EightPuzzle.pz, 9);
              if (EightPuzzle.prun[next] < 0) {
                EightPuzzle.prun[next] = d + 1;
                c++;
              }
            }
          }
        }
      }
    }
    EightPuzzle.ini = true;
  }

  private static move(m: number): number {
    let pos = 0;
    for (; pos < 9; pos++) {
      if (EightPuzzle.pz[pos] == 8) {
        break;
      }
    }
    const next = EightPuzzle.moveIdx[pos][m];
    if (next != -1) {
      Utils.swap2(EightPuzzle.pz, pos, next);
    }
    return next;
  }

  static search(state: number, d: number): boolean {
    if (d == 0) {
      return state == 0;
    }
    if (EightPuzzle.prun[state] > d) {
      return false;
    }
    const arr: number[] = new Array<number>(9).fill(0);
    Utils.set11Perm(arr, state, 9);
    for (let m = 0; m < 4; m++) {
      for (let n = 0; n < 9; n++) {
        EightPuzzle.pz[n] = arr[n];
      }
      for (let n = 0; n < 2; n++) {
        let next = EightPuzzle.move(m);
        if (next == -1) {
          break;
        }
        next = Utils.get11Perm(EightPuzzle.pz, 9);
        if (EightPuzzle.search(next, d - 1)) {
          EightPuzzle.seq[d] = (m << 1) | n;
          return true;
        }
      }
    }
    return false;
  }

  public static scramble(rnd: () => number): string {
    EightPuzzle.init();
    let n: number;
    do {
      n = Math.floor(rnd() * 362880);
    } while (EightPuzzle.prun[n] < 4);
    for (let d = 0; d < 24; d++) {
      if (EightPuzzle.search(n, d)) {
        let sb = '';
        for (let i = 1; i <= d; i++) {
          sb += 'UDLR'.charAt(EightPuzzle.seq[i] >> 1) + EightPuzzle.suff[EightPuzzle.seq[i] & 1];
        }
        return sb;
      }
    }
    return 'error';
  }

  public static image(scramble: string): number[] {
    for (let i = 0; i < 9; i++) {
      EightPuzzle.pz[i] = i;
    }
    let blank = 8;
    const s = scramble.split(' ');
    for (let i = 0; i < s.length; i++) {
      if (s[i].length > 0) {
        const move = 'DURL'.indexOf(s[i].charAt(0));
        let next = EightPuzzle.moveIdx[blank][move];
        if (next != -1) {
          Utils.swap2(EightPuzzle.pz, blank, next);
          blank = next;
        }
        if (s[i].length > 1 && s[i].charAt(1) == '2') {
          next = EightPuzzle.moveIdx[blank][move];
          if (next != -1) {
            Utils.swap2(EightPuzzle.pz, blank, next);
            blank = next;
          }
        }
      }
    }
    return EightPuzzle.pz;
  }
}
