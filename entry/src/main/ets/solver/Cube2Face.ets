// Ported from solver/Cube2Face.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';

export class Cube2Face {
  private static facemv: number[][] = Cube2Face.z2d(10626, 3);
  private static prun: number[] = new Array<number>(10626).fill(0);
  private static seq: number[] = new Array<number>(7).fill(0);
  private static solved: number[] = [1819, 0, 4844, 69, 494, 10625];
  static inited = false;

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  static init(): void {
    if (Cube2Face.inited) {
      return;
    }
    const arr: number[] = new Array<number>(24).fill(0);
    for (let i = 0; i < 10626; i++) {
      Cube2Face.prun[i] = -1;
      for (let j = 0; j < 3; j++) {
        Utils.idxToComb(arr, i, 4, 24);
        switch (j) {
          case 0: //U
            Utils.circle(arr, 0, 2, 3, 1);
            Utils.circle(arr, 4, 20, 16, 8);
            Utils.circle(arr, 5, 21, 17, 9);
            break;
          case 1: //R
            Utils.circle(arr, 4, 6, 7, 5);
            Utils.circle(arr, 1, 9, 13, 22);
            Utils.circle(arr, 3, 11, 15, 20);
            break;
          case 2: //F
            Utils.circle(arr, 8, 10, 11, 9);
            Utils.circle(arr, 2, 19, 13, 4);
            Utils.circle(arr, 3, 17, 12, 6);
            break;
        }
        Cube2Face.facemv[i][j] = Utils.combToIdx(arr, 4, 24);
      }
    }
    for (let i = 0; i < 6; i++) {
      Cube2Face.prun[Cube2Face.solved[i]] = 0;
    }
    Utils.createPrun(Cube2Face.prun, 5, Cube2Face.facemv, 3);
    Cube2Face.inited = true;
  }

  private static search(face: number, d: number, lm: number): boolean {
    if (d == 0) {
      return Cube2Face.prun[face] == 0;
    }
    if (Cube2Face.prun[face] > d) {
      return false;
    }
    for (let i = 0; i < 3; i++) {
      if (i != lm) {
        let x = face;
        for (let j = 0; j < 3; j++) {
          x = Cube2Face.facemv[x][i];
          if (Cube2Face.search(x, d - 1, i)) {
            Cube2Face.seq[d] = i * 3 + j;
            return true;
          }
        }
      }
    }
    return false;
  }

  private static color: string[] = ['D: ', 'U: ', 'L: ', 'R: ', 'F: ', 'B: '];

  private static solve(scramble: string, face: number): string {
    const s = scramble.split(' ');
    let fc = Cube2Face.solved[face];
    let d: number;
    for (d = 0; d < s.length; d++) {
      if (s[d].length != 0) {
        const m = 'URF'.indexOf(s[d].charAt(0));
        fc = Cube2Face.facemv[fc][m];
        if (s[d].length > 1) {
          fc = Cube2Face.facemv[fc][m];
          if (s[d].charAt(1) == "'") {
            fc = Cube2Face.facemv[fc][m];
          }
        }
      }
    }
    for (d = 0; d < 7; d++) {
      if (Cube2Face.search(fc, d, -1)) {
        let sb = '\n';
        sb += Cube2Face.color[face];
        for (let i = d; i > 0; i--) {
          sb += 'URF'.charAt(Math.floor(Cube2Face.seq[i] / 3)) + Utils.suff[Cube2Face.seq[i] % 3] + ' ';
        }
        return sb;
      }
    }
    return 'error';
  }

  public static solveFace(scramble: string, face: number): string {
    Cube2Face.init();
    let sb = '\n';
    for (let i = 0; i < 6; i++) {
      if (((face >> i) & 1) != 0) {
        sb += Cube2Face.solve(scramble, i);
      }
    }
    return sb;
  }
}
