// Ported from scrambler/LatchCube.java (DCTimer-BLE -> HarmonyOS ArkTS)

export class LatchCube {
  private static moveFaces: number[] = [];
  private static moveTimes: number[] = [];
  private static moveNames: string[] = [];

  private static moveCount = 0;
  private static currentMove = -1;
  private static currentFace = -1;
  private static currentTime = 0;
  private static movableFaces: number[] = new Array<number>(6).fill(0);
  private static specialForbiddenFaces: number[] = new Array<number>(6).fill(0);
  private static movableFaceCount = 0;
  private static bothDirections = false;
  private static sequence = '';

  private static label: number[][] = LatchCube.z2d(6, 4);

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  private static check(face: number): boolean {
    let sum = 0;
    let count = 0;
    for (let i = 0; i < 4; ++i) {
      sum += LatchCube.label[face][i];
      count += Math.abs(LatchCube.label[face][i]);
    }
    sum = Math.abs(sum);
    return sum == count;
  }

  private static isCounterClockwise(face: number): boolean {
    let sum = 0;
    for (let i = 0; i < 4; ++i) {
      sum += LatchCube.label[face][i];
    }
    LatchCube.bothDirections = sum == 0;
    return sum < 0;
  }

  private static determineMovableFaces(): void {
    LatchCube.movableFaceCount = 0;
    for (let i = 0; i < 6; ++i) {
      LatchCube.movableFaces[i] = ((LatchCube.check(i)) ? i : -1);
    }
    for (let i = 0; i < 6; ++i) {
      if (LatchCube.specialForbiddenFaces[i] == i) {
        LatchCube.movableFaces[i] = -1;
      }
    }
    for (let i = 0; i < 6; ++i) {
      LatchCube.movableFaceCount += ((LatchCube.movableFaces[i] >= 0) ? 1 : 0);
    }
  }

  private static moveU(times: number): void {
    for (let i = 0; i < times; ++i) {
      let tmp = LatchCube.label[0][0];
      LatchCube.label[0][0] = LatchCube.label[0][1];
      LatchCube.label[0][1] = LatchCube.label[0][3];
      LatchCube.label[0][3] = LatchCube.label[0][2];
      LatchCube.label[0][2] = tmp;

      tmp = LatchCube.label[4][0];
      LatchCube.label[4][0] = LatchCube.label[3][0];
      LatchCube.label[3][0] = LatchCube.label[5][0];
      LatchCube.label[5][0] = LatchCube.label[2][0];
      LatchCube.label[2][0] = tmp;
    }
  }

  private static moveD(times: number): void {
    for (let i = 0; i < times; ++i) {
      let tmp = LatchCube.label[1][0];
      LatchCube.label[1][0] = LatchCube.label[1][1];
      LatchCube.label[1][1] = LatchCube.label[1][3];
      LatchCube.label[1][3] = LatchCube.label[1][2];
      LatchCube.label[1][2] = tmp;

      tmp = LatchCube.label[4][3];
      LatchCube.label[4][3] = LatchCube.label[2][3];
      LatchCube.label[2][3] = LatchCube.label[5][3];
      LatchCube.label[5][3] = LatchCube.label[3][3];
      LatchCube.label[3][3] = tmp;
    }
  }

  private static moveL(times: number): void {
    for (let i = 0; i < times; ++i) {
      let tmp = LatchCube.label[2][0];
      LatchCube.label[2][0] = LatchCube.label[2][1];
      LatchCube.label[2][1] = LatchCube.label[2][3];
      LatchCube.label[2][3] = LatchCube.label[2][2];
      LatchCube.label[2][2] = tmp;

      tmp = LatchCube.label[0][1];
      LatchCube.label[0][1] = LatchCube.label[5][2];
      LatchCube.label[5][2] = LatchCube.label[1][1];
      LatchCube.label[1][1] = LatchCube.label[4][1];
      LatchCube.label[4][1] = tmp;
    }
  }

  private static moveR(times: number): void {
    for (let i = 0; i < times; ++i) {
      let tmp = LatchCube.label[3][0];
      LatchCube.label[3][0] = LatchCube.label[3][1];
      LatchCube.label[3][1] = LatchCube.label[3][3];
      LatchCube.label[3][3] = LatchCube.label[3][2];
      LatchCube.label[3][2] = tmp;

      tmp = LatchCube.label[0][2];
      LatchCube.label[0][2] = LatchCube.label[4][2];
      LatchCube.label[4][2] = LatchCube.label[1][2];
      LatchCube.label[1][2] = LatchCube.label[5][1];
      LatchCube.label[5][1] = tmp;
    }
  }

  private static moveF(times: number): void {
    for (let i = 0; i < times; ++i) {
      let tmp = LatchCube.label[4][0];
      LatchCube.label[4][0] = LatchCube.label[4][1];
      LatchCube.label[4][1] = LatchCube.label[4][3];
      LatchCube.label[4][3] = LatchCube.label[4][2];
      LatchCube.label[4][2] = tmp;

      tmp = LatchCube.label[0][3];
      LatchCube.label[0][3] = LatchCube.label[2][2];
      LatchCube.label[2][2] = LatchCube.label[1][0];
      LatchCube.label[1][0] = LatchCube.label[3][1];
      LatchCube.label[3][1] = tmp;
    }
  }

  private static moveB(times: number): void {
    for (let i = 0; i < times; ++i) {
      let tmp = LatchCube.label[5][0];
      LatchCube.label[5][0] = LatchCube.label[5][1];
      LatchCube.label[5][1] = LatchCube.label[5][3];
      LatchCube.label[5][3] = LatchCube.label[5][2];
      LatchCube.label[5][2] = tmp;

      tmp = LatchCube.label[0][0];
      LatchCube.label[0][0] = LatchCube.label[3][2];
      LatchCube.label[3][2] = LatchCube.label[1][3];
      LatchCube.label[1][3] = LatchCube.label[2][1];
      LatchCube.label[2][1] = tmp;
    }
  }

  private static reset(scrambleLen: number): void {
    LatchCube.label = [[0, -1, -1, 0], [0, 1, 1, 0], [0, -1, -1, 0],
    [0, 1, 1, 0], [-1, 0, 0, -1], [1, 0, 0, 1]];
    LatchCube.moveFaces = new Array<number>(scrambleLen).fill(-1);
    LatchCube.moveTimes = new Array<number>(scrambleLen).fill(0);
    LatchCube.moveNames = new Array<string>(scrambleLen).fill('');
    LatchCube.currentMove = -1;
    LatchCube.currentFace = -1;
    LatchCube.currentTime = 0;
    LatchCube.movableFaceCount = 0;
    for (let i = 0; i < 6; ++i) {
      LatchCube.movableFaces[i] = i;
      LatchCube.specialForbiddenFaces[i] = -1;
    }
    LatchCube.moveCount = 0;
    LatchCube.sequence = '';
  }

  private static undoLastMove(): void {
    switch (LatchCube.moveFaces[LatchCube.moveCount - 1]) {
      case 0:
        LatchCube.moveU((4 - LatchCube.moveTimes[LatchCube.moveCount - 1]) % 4);
        break;
      case 1:
        LatchCube.moveD((4 - LatchCube.moveTimes[LatchCube.moveCount - 1]) % 4);
        break;
      case 2:
        LatchCube.moveL((4 - LatchCube.moveTimes[LatchCube.moveCount - 1]) % 4);
        break;
      case 3:
        LatchCube.moveR((4 - LatchCube.moveTimes[LatchCube.moveCount - 1]) % 4);
        break;
      case 4:
        LatchCube.moveF((4 - LatchCube.moveTimes[LatchCube.moveCount - 1]) % 4);
        break;
      case 5:
        LatchCube.moveB((4 - LatchCube.moveTimes[LatchCube.moveCount - 1]) % 4);
    }
    LatchCube.moveFaces[LatchCube.moveCount - 1] = -1;
    LatchCube.moveTimes[LatchCube.moveCount - 1] = 0;
    LatchCube.moveNames[LatchCube.moveCount - 1] = '';
    LatchCube.moveCount--;
  }

  static scramble(scrambleLen: number): string {
    LatchCube.reset(scrambleLen);
    for (let i = 0; i < scrambleLen; LatchCube.moveCount++) {
      LatchCube.determineMovableFaces();
      LatchCube.currentMove = Math.floor(Math.random() * 18);
      LatchCube.currentFace = Math.floor(LatchCube.currentMove / 3);
      LatchCube.currentTime = LatchCube.currentMove % 3 + 1;
      if (LatchCube.movableFaces[LatchCube.currentFace] == -1) {
        --i;
        LatchCube.moveCount -= 1;
      } else if (LatchCube.movableFaceCount < 2) {
        LatchCube.undoLastMove();
        --i;
        --i;
        LatchCube.moveCount -= 1;
      } else if ((LatchCube.movableFaceCount < 3) &&
        (LatchCube.moveCount > 1) &&
        (Math.floor(LatchCube.moveFaces[LatchCube.moveCount - 1] / 2) == Math.floor(LatchCube.moveFaces[LatchCube.moveCount - 2] / 2))) {
        LatchCube.undoLastMove();
        LatchCube.undoLastMove();
        i -= 3;
        LatchCube.moveCount -= 1;
      } else if ((LatchCube.moveCount > 0) && (LatchCube.currentFace == LatchCube.moveFaces[LatchCube.moveCount - 1])) {
        --i;
        LatchCube.moveCount -= 1;
      } else if ((LatchCube.moveCount > 1) &&
        (Math.floor(LatchCube.currentFace / 2) == Math.floor(LatchCube.moveFaces[LatchCube.moveCount - 1] / 2)) &&
        (Math.floor(LatchCube.currentFace / 2) == Math.floor(LatchCube.moveFaces[LatchCube.moveCount - 2] / 2))) {
        --i;
        LatchCube.moveCount -= 1;
      } else {
        LatchCube.addMove(LatchCube.currentFace, LatchCube.currentTime);
      }
      ++i;
    }
    for (let i = 0; i < scrambleLen; ++i) {
      LatchCube.sequence += LatchCube.moveNames[i];
    }
    return LatchCube.sequence;
  }

  private static addMove(face: number, time: number): void {
    switch (face) {
      case 0:
        LatchCube.moveU(time);
        LatchCube.moveNames[LatchCube.moveCount] = 'U';
        break;
      case 1:
        LatchCube.moveD(time);
        LatchCube.moveNames[LatchCube.moveCount] = 'D';
        break;
      case 2:
        LatchCube.moveL(time);
        LatchCube.moveNames[LatchCube.moveCount] = 'L';
        break;
      case 3:
        LatchCube.moveR(time);
        LatchCube.moveNames[LatchCube.moveCount] = 'R';
        break;
      case 4:
        LatchCube.moveF(time);
        LatchCube.moveNames[LatchCube.moveCount] = 'F';
        break;
      case 5:
        LatchCube.moveB(time);
        LatchCube.moveNames[LatchCube.moveCount] = 'B';
    }
    if (LatchCube.isCounterClockwise(face)) {
      time -= 4;
    }
    LatchCube.moveFaces[LatchCube.moveCount] = face;
    LatchCube.moveTimes[LatchCube.moveCount] = time;
    switch (time) {
      case -3:
        LatchCube.moveNames[LatchCube.moveCount] = (LatchCube.moveNames[LatchCube.moveCount] + "3' ");
        break;
      case -2:
        LatchCube.moveNames[LatchCube.moveCount] = (LatchCube.moveNames[LatchCube.moveCount] + "2' ");
        break;
      case -1:
        LatchCube.moveNames[LatchCube.moveCount] = (LatchCube.moveNames[LatchCube.moveCount] + "' ");
        break;
      case 1:
        LatchCube.moveNames[LatchCube.moveCount] = (LatchCube.moveNames[LatchCube.moveCount] + ' ');
        break;
      case 2:
        LatchCube.moveNames[LatchCube.moveCount] = (LatchCube.moveNames[LatchCube.moveCount] + '2 ');
        break;
      case 3:
        if (LatchCube.bothDirections) {
          LatchCube.moveNames[LatchCube.moveCount] = (LatchCube.moveNames[LatchCube.moveCount] + "' ");
        } else {
          LatchCube.moveNames[LatchCube.moveCount] = (LatchCube.moveNames[LatchCube.moveCount] + '3 ');
        }
    }
  }
}
