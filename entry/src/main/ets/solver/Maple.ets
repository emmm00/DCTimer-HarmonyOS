// Ported from solver/Maple.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';

export class Maple {
  private static CENTER_MOVE: number[][] = Maple.z2d(360, 4);
  private static CORNER_PERM_MOVE: number[][] = Maple.z2d(36, 4);
  private static CORNER_ORI_MOVE: number[][] = Maple.z2d(2187, 4);
  private static CENTER_DISTANCE: number[] = new Array<number>(360).fill(0);
  private static CORNER_DISTANCE: number[][] = Maple.z2d(2187, 36);
  private static RANDOM: () => number = Math.random;
  private static TURN: string[] = ['R', 'U', 'L', 'B'];
  private static SUFF: string[] = ["'", ''];
  private static IMAGE: number[] = new Array<number>(30).fill(0);

  private static lastScramble = '';
  private static solution = '';
  static inited = false;

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  static init(): void {
    if (Maple.inited) {
      return;
    }
    Maple.initMoveTables();
    Maple.initDistanceTables();
    Maple.inited = true;
  }

  private static initMoveTables(): void {
    const arr: number[] = new Array<number>(7).fill(0);
    for (let i = 0; i < 360; i++) {
      for (let j = 0; j < 4; j++) {
        Utils.idxToPerm(arr, i, 6, true);
        switch (j) {
          case 0:
            Utils.circle3(arr, 0, 2, 3);
            break;
          case 1:
            Utils.circle3(arr, 0, 3, 4);
            break;
          case 2:
            Utils.circle3(arr, 0, 4, 1);
            break;
          case 3:
            Utils.circle3(arr, 3, 5, 4);
            break;
        }
        Maple.CENTER_MOVE[i][j] = Utils.permToIdx(arr, 6, true);
      }
    }

    const arr2: number[] = new Array<number>(3).fill(0);
    for (let i = 0; i < 12; i++) {
      for (let j = 0; j < 3; j++) {
        for (let k = 0; k < 4; k++) {
          Utils.idxToPerm(arr, i, 4, true);
          Utils.idxToPerm(arr2, j, 3, true);
          switch (k) {
            case 0:
              Utils.circle3(arr, 2, 0, 3);
              break;
            case 1:
              Utils.circle3(arr, 0, 1, 3);
              break;
            case 2:
              Utils.circle3(arr, 1, 2, 3);
              break;
            case 3:
              Utils.circle3(arr2, 0, 2, 1);
              break;
          }
          Maple.CORNER_PERM_MOVE[i * 3 + j][k] =
            Utils.permToIdx(arr, 4, true) * 3 + Utils.permToIdx(arr2, 3, true);
        }
      }
    }

    for (let i = 0; i < 2187; i++) {
      for (let j = 0; j < 4; j++) {
        Utils.idxToOri(arr, i, 7, false);
        switch (j) {
          case 0:
            Utils.circle3(arr, 1, 3, 6);
            arr[1] += 2;
            arr[3] += 2;
            arr[4]++;
            arr[6] += 2;
            break;
          case 1:
            Utils.circle3(arr, 1, 2, 3);
            arr[0]++;
            arr[1] += 2;
            arr[2] += 2;
            arr[3] += 2;
            break;
          case 2:
            Utils.circle3(arr, 2, 6, 3);
            arr[2] += 2;
            arr[3] += 2;
            arr[5]++;
            arr[6] += 2;
            break;
          case 3:
            Utils.circle3(arr, 0, 5, 4);
            arr[0] += 2;
            arr[3]++;
            arr[4] += 2;
            arr[5] += 2;
            break;
        }
        Maple.CORNER_ORI_MOVE[i][j] = Utils.oriToIdx(arr, 7, false);
      }
    }
  }

  private static initDistanceTables(): void {
    for (let i = 0; i < 360; i++) {
      Maple.CENTER_DISTANCE[i] = -1;
    }
    Maple.CENTER_DISTANCE[0] = 0;
    for (let depth = 0; depth < 5; depth++) {
      for (let i = 0; i < 360; i++) {
        if (Maple.CENTER_DISTANCE[i] == depth) {
          for (let m = 0; m < 4; m++) {
            let p = i;
            for (let n = 0; n < 2; n++) {
              p = Maple.CENTER_MOVE[p][m];
              if (Maple.CENTER_DISTANCE[p] == -1) {
                Maple.CENTER_DISTANCE[p] = depth + 1;
              }
            }
          }
        }
      }
    }

    for (let i = 0; i < 2187; i++) {
      for (let j = 0; j < 36; j++) {
        Maple.CORNER_DISTANCE[i][j] = -1;
      }
    }
    Maple.CORNER_DISTANCE[0][0] = 0;
    for (let depth = 0; depth < 7; depth++) {
      for (let i = 0; i < 2187; i++) {
        for (let j = 0; j < 36; j++) {
          if (Maple.CORNER_DISTANCE[i][j] == depth) {
            for (let k = 0; k < 4; k++) {
              let p = i;
              let q = j;
              for (let l = 0; l < 2; l++) {
                p = Maple.CORNER_ORI_MOVE[p][k];
                q = Maple.CORNER_PERM_MOVE[q][k];
                if (Maple.CORNER_DISTANCE[p][q] == -1) {
                  Maple.CORNER_DISTANCE[p][q] = depth + 1;
                }
              }
            }
          }
        }
      }
    }
  }

  public static scramble(): string {
    Maple.init();
    Maple.lastScramble = '';
    const center = Math.floor(Maple.RANDOM() * 360);
    let cornerPerm: number;
    let cornerOri: number;
    do {
      cornerPerm = Math.floor(Maple.RANDOM() * 36);
      cornerOri = Math.floor(Maple.RANDOM() * 2187);
    } while (Maple.CORNER_DISTANCE[cornerOri][cornerPerm] < 0);
    Maple.solution = '';
    for (let depth = 0; depth < 13; depth++) {
      if (Maple.search(center, cornerPerm, cornerOri, depth, -1)) {
        break;
      }
    }
    return Maple.solution.trim();
  }

  private static search(center: number, cornerPerm: number, cornerOri: number, depth: number,
    lastMove: number): boolean {
    if (depth == 0) {
      return Maple.CENTER_DISTANCE[center] == 0 && Maple.CORNER_DISTANCE[cornerOri][cornerPerm] == 0;
    }
    if (Maple.CENTER_DISTANCE[center] > depth || Maple.CORNER_DISTANCE[cornerOri][cornerPerm] > depth) {
      return false;
    }
    for (let move = 0; move < 4; move++) {
      if (move != lastMove) {
        let nextCenter = center;
        let nextPerm = cornerPerm;
        let nextOri = cornerOri;
        for (let power = 0; power < 2; power++) {
          nextCenter = Maple.CENTER_MOVE[nextCenter][move];
          nextPerm = Maple.CORNER_PERM_MOVE[nextPerm][move];
          nextOri = Maple.CORNER_ORI_MOVE[nextOri][move];
          if (Maple.search(nextCenter, nextPerm, nextOri, depth - 1, move)) {
            let index = move;
            let count = 8;
            while (count > 0 && Maple.solution.length > 0 && Maple.lastScramble.startsWith(Maple.TURN[index])) {
              count--;
              index = Math.floor(Maple.RANDOM() * 3);
            }
            Maple.lastScramble = Maple.TURN[index] + Maple.SUFF[power] + ' ';
            Maple.solution += Maple.lastScramble;
            return true;
          }
        }
      }
    }
    return false;
  }

  public static image(scramble: string): number[] {
    Maple.initColor();
    if (scramble == null || scramble.trim().length == 0) {
      return Maple.IMAGE.slice();
    }
    const moves = scramble.trim().split(/\s+/);
    for (const move of moves) {
      if (move.length == 0) {
        continue;
      }
      const moveIdx = 'RULB'.indexOf(move.charAt(0));
      if (moveIdx < 0) {
        continue;
      }
      Maple.move(moveIdx);
      if (move.length > 1) {
        Maple.move(moveIdx);
      }
    }
    return Maple.IMAGE.slice();
  }

  private static initColor(): void {
    for (let i = 0; i < 5; i++) {
      for (let j = 0; j < 6; j++) {
        Maple.IMAGE[j * 5 + i] = j;
      }
    }
  }

  private static move(turn: number): void {
    switch (turn) {
      case 0:
        Maple.circle3(17, 22, 2);
        Maple.circle3(1, 16, 20);
        Maple.circle3(0, 15, 23);
        Maple.circle3(21, 4, 19);
        break;
      case 1:
        Maple.circle3(2, 22, 7);
        Maple.circle3(0, 21, 5);
        Maple.circle3(3, 20, 8);
        Maple.circle3(10, 16, 28);
        Maple.circle3(6, 1, 24);
        Maple.circle3(4, 23, 9);
        break;
      case 2:
        Maple.circle3(12, 2, 7);
        Maple.circle3(3, 6, 10);
        Maple.circle3(4, 5, 13);
        Maple.circle3(11, 0, 9);
        break;
      case 3:
        Maple.circle3(22, 27, 7);
        Maple.circle3(24, 28, 8);
        Maple.circle3(5, 23, 25);
        Maple.circle3(21, 29, 9);
        break;
    }
  }

  private static circle3(a: number, b: number, c: number): void {
    const temp = Maple.IMAGE[a];
    Maple.IMAGE[a] = Maple.IMAGE[b];
    Maple.IMAGE[b] = Maple.IMAGE[c];
    Maple.IMAGE[c] = temp;
  }
}
