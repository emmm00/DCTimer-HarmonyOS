// Ported from solver/Cube2Layer.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';

export class Cube2Layer {
  private static cpm3: number[][] = Cube2Layer.z2d(210, 3);
  private static com3: number[][] = Cube2Layer.z2d(945, 3);
  private static cpm4: number[][] = Cube2Layer.z2d(840, 3);
  private static com4: number[][] = Cube2Layer.z2d(2835, 3);
  private static prun3: number[] = new Array<number>(5670).fill(0);
  private static prun4: number[] = new Array<number>(68040).fill(0);
  private static seq: number[] = new Array<number>(8).fill(0);
  private static solved: number[][] = [
    [38948, 39758, 40001, 40811, 52702, 53107, 53836, 54241, 66096, 66906, 67149, 67959],
    [39094, 39447, 40176, 40633, 52488, 53366, 53609, 54351, 66326, 66715, 67444, 67865],
    [38880, 39742, 39985, 40743, 52718, 53055, 53784, 54257, 66148, 66974, 67217, 68011]
  ];
  static inited = false;

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  static init(): void {
    if (Cube2Layer.inited) {
      return;
    }
    for (let i = 0; i < 35; i++) {
      for (let j = 0; j < 27; j++) {
        for (let k = 0; k < 3; k++) {
          const d = Cube2Layer.getmv(i, 3, j, k);
          const p = d >> 7;
          Cube2Layer.com3[i * 27 + j][k] = Math.floor(p / 6) * 27 + (d & 127);
          if (j < 6) {
            Cube2Layer.cpm3[i * 6 + j][k] = p;
          }
        }
      }
      for (let j = 0; j < 81; j++) {
        for (let k = 0; k < 3; k++) {
          const d = Cube2Layer.getmv(i, 4, j, k);
          const p = d >> 7;
          Cube2Layer.com4[i * 81 + j][k] = Math.floor(p / 24) * 81 + (d & 127);
          if (j < 24) {
            Cube2Layer.cpm4[i * 24 + j][k] = p;
          }
        }
      }
    }
    for (let i = 0; i < 5670; i++) {
      Cube2Layer.prun3[i] = -1;
    }
    Cube2Layer.prun3[0] = 0;
    Cube2Layer.prun3[7 * 162] = 0;
    Cube2Layer.prun3[14 * 162] = 0;
    let c = 3;
    for (let d = 0; d < 6; d++) {
      for (let i = 0; i < 210; i++) {
        for (let j = 0; j < 27; j++) {
          if (Cube2Layer.prun3[i * 27 + j] == d) {
            for (let l = 0; l < 3; l++) {
              let x = i;
              let y = j;
              for (let m = 0; m < 3; m++) {
                y = Cube2Layer.com3[Math.floor(x / 6) * 27 + y % 27][l] % 27;
                x = Cube2Layer.cpm3[x][l];
                if (Cube2Layer.prun3[x * 27 + y] < 0) {
                  Cube2Layer.prun3[x * 27 + y] = d + 1;
                  c++;
                }
              }
            }
          }
        }
      }
    }

    for (let i = 0; i < 68040; i++) {
      Cube2Layer.prun4[i] = -1;
    }
    for (let i = 0; i < 3; i++) {
      for (let j = 0; j < 12; j++) {
        Cube2Layer.prun4[Cube2Layer.solved[i][j]] = 0;
      }
    }
    c = 36;
    for (let d = 0; d < 6; d++) {
      for (let i = 0; i < 840; i++) {
        for (let j = 0; j < 81; j++) {
          if (Cube2Layer.prun4[i * 81 + j] == d) {
            for (let l = 0; l < 3; l++) {
              let x = i;
              let y = j;
              for (let m = 0; m < 3; m++) {
                y = Cube2Layer.com4[Math.floor(x / 24) * 81 + y % 81][l] % 81;
                x = Cube2Layer.cpm4[x][l];
                if (Cube2Layer.prun4[x * 81 + y] < 0) {
                  Cube2Layer.prun4[x * 81 + y] = d + 1;
                  c++;
                }
              }
            }
          }
        }
      }
    }
    Cube2Layer.inited = true;
  }

  private static getmv(c: number, k: number, po: number, f: number): number {
    const n: number[] = new Array<number>(7).fill(0);
    const s: number[] = new Array<number>(4).fill(0);
    const o: number[] = new Array<number>(4).fill(0);
    Utils.idxToPerm(s, po, k, false);
    Utils.idxToOri(o, po, k, false);
    let q = k;
    let t: number;
    for (t = 0; t < 7; t++) {
      if (c >= Utils.Cnk[6 - t][q]) {
        c -= Utils.Cnk[6 - t][q--];
        n[t] = (s[q] << 3) | o[k - 1 - q];
      } else {
        n[t] = -3;
      }
    }
    switch (f) {
      case 0: //U
        Utils.circle(n, 0, 1, 3, 2); break;
      case 1: //R
        Utils.circleOri(n, 0, 4, 5, 1, [2, 1, 2, 1]);
        break;
      case 2: //F
        Utils.circleOri(n, 0, 2, 6, 4, [1, 2, 1, 2]);
        break;
    }
    c = 0;
    po = 0;
    q = k;
    for (t = 0; t < 7; t++) {
      if (n[t] >= 0) {
        c += Utils.Cnk[6 - t][q--];
        s[q] = n[t] >> 3;
        po += (n[t] & 7) % 3;
        po *= 3;
      }
    }
    const i = Utils.permToIdx(s, k, false);
    return ((Utils.fact[k] * c + i) << 7) | Math.floor(po / 3);
  }

  private static search3(scp: number, sco: number, cp: number, co: number, d: number, lm: number): boolean {
    if (d == 0) {
      return cp == scp && co == sco;
    }
    if (Cube2Layer.prun3[cp * 27 + co % 27] > d) {
      return false;
    }
    for (let i = 0; i < 3; i++) {
      if (i != lm) {
        let x = cp;
        let y = co;
        for (let j = 0; j < 3; j++) {
          x = Cube2Layer.cpm3[x][i];
          y = Cube2Layer.com3[y][i];
          if (Cube2Layer.search3(scp, sco, x, y, d - 1, i)) {
            Cube2Layer.seq[d] = i * 3 + j;
            return true;
          }
        }
      }
    }
    return false;
  }

  private static search4(face: number, cp: number, co: number, d: number, lm: number): boolean {
    if (d == 0) {
      return Cube2Layer.check(face, cp * 81 + co % 81);
    }
    if (Cube2Layer.prun4[cp * 81 + co % 81] > d) {
      return false;
    }
    for (let i = 0; i < 3; i++) {
      if (i != lm) {
        let x = cp;
        let y = co;
        for (let j = 0; j < 3; j++) {
          x = Cube2Layer.cpm4[x][i];
          y = Cube2Layer.com4[y][i];
          if (Cube2Layer.search4(face, x, y, d - 1, i)) {
            Cube2Layer.seq[d] = i * 3 + j;
            return true;
          }
        }
      }
    }
    return false;
  }

  private static check(face: number, c: number): boolean {
    if (Cube2Layer.prun4[c] != 0) {
      return false;
    }
    const idx = face == 1 ? 0 : (face == 3 ? 1 : 2);
    return Cube2Layer.binarySearch(Cube2Layer.solved[idx], c) >= 0;
  }

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

  private static solvedCp: number[] = [0, 816, 42, 648, 480, 84];
  private static solvedCo: number[] = [0, 2754, 189, 2187, 1620, 378];
  private static color: string[] = ['D: ', 'U: ', 'L: ', 'R: ', 'F: ', 'B: '];

  private static solve(scramble: string, face: number): string {
    const s = scramble.split(' ');
    let cp = Cube2Layer.solvedCp[face];
    let co = Cube2Layer.solvedCo[face];
    for (let d = 0; d < s.length; d++) {
      if (s[d].length != 0) {
        const m = 'URF'.indexOf(s[d].charAt(0));
        let n = 1;
        if (s[d].length > 1) {
          n++;
          if (s[d].charAt(1) == "'") {
            n++;
          }
        }
        for (let i = 0; i < n; i++) {
          if (face == 0 || face == 2 || face == 5) {
            cp = Cube2Layer.cpm3[cp][m];
            co = Cube2Layer.com3[co][m];
          } else {
            cp = Cube2Layer.cpm4[cp][m];
            co = Cube2Layer.com4[co][m];
          }
        }
      }
    }
    if (face == 0 || face == 2 || face == 5) {
      for (let d = 0; d < 8; d++) {
        if (Cube2Layer.search3(Cube2Layer.solvedCp[face], Cube2Layer.solvedCo[face], cp, co, d, -1)) {
          return Cube2Layer.move2str(face, d);
        }
      }
    } else {
      for (let d = 0; d < 8; d++) {
        if (Cube2Layer.search4(face, cp, co, d, -1)) {
          return Cube2Layer.move2str(face, d);
        }
      }
    }
    return '\nerror';
  }

  private static move2str(face: number, d: number): string {
    let sb = '\n';
    sb += Cube2Layer.color[face];
    for (let i = d; i > 0; i--) {
      sb += 'URF'.charAt(Math.floor(Cube2Layer.seq[i] / 3)) + Utils.suff[Cube2Layer.seq[i] % 3] + ' ';
    }
    return sb;
  }

  public static solveFirstLayer(scramble: string, face: number): string {
    Cube2Layer.init();
    let sb = '\n';
    for (let i = 0; i < 6; i++) {
      if (((face >> i) & 1) != 0) {
        sb += Cube2Layer.solve(scramble, i);
      }
    }
    return sb;
  }
}
