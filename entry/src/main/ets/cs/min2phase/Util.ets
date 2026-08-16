// Ported from cs/min2phase/Util.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { CubieCube } from './CubieCube';
import { Utils as SolverUtils } from '../../solver/Utils';

export class Util {
  // Moves
  static Ux1 = 0;
  static Ux2 = 1;
  static Ux3 = 2;
  static Rx1 = 3;
  static Rx2 = 4;
  static Rx3 = 5;
  static Fx1 = 6;
  static Fx2 = 7;
  static Fx3 = 8;
  static Dx1 = 9;
  static Dx2 = 10;
  static Dx3 = 11;
  static Lx1 = 12;
  static Lx2 = 13;
  static Lx3 = 14;
  static Bx1 = 15;
  static Bx2 = 16;
  static Bx3 = 17;

  // Facelets
  static U1 = 0;
  static U2 = 1;
  static U3 = 2;
  static U4 = 3;
  static U5 = 4;
  static U6 = 5;
  static U7 = 6;
  static U8 = 7;
  static U9 = 8;
  static R1 = 9;
  static R2 = 10;
  static R3 = 11;
  static R4 = 12;
  static R5 = 13;
  static R6 = 14;
  static R7 = 15;
  static R8 = 16;
  static R9 = 17;
  static F1 = 18;
  static F2 = 19;
  static F3 = 20;
  static F4 = 21;
  static F5 = 22;
  static F6 = 23;
  static F7 = 24;
  static F8 = 25;
  static F9 = 26;
  static D1 = 27;
  static D2 = 28;
  static D3 = 29;
  static D4 = 30;
  static D5 = 31;
  static D6 = 32;
  static D7 = 33;
  static D8 = 34;
  static D9 = 35;
  static L1 = 36;
  static L2 = 37;
  static L3 = 38;
  static L4 = 39;
  static L5 = 40;
  static L6 = 41;
  static L7 = 42;
  static L8 = 43;
  static L9 = 44;
  static B1 = 45;
  static B2 = 46;
  static B3 = 47;
  static B4 = 48;
  static B5 = 49;
  static B6 = 50;
  static B7 = 51;
  static B8 = 52;
  static B9 = 53;

  // Colors
  static U = 0;
  static R = 1;
  static F = 2;
  static D = 3;
  static L = 4;
  static B = 5;

  static cornerFacelet: number[][] = [
    [Util.U9, Util.R1, Util.F3], [Util.U7, Util.F1, Util.L3], [Util.U1, Util.L1, Util.B3], [Util.U3, Util.B1, Util.R3],
    [Util.D3, Util.F9, Util.R7], [Util.D1, Util.L9, Util.F7], [Util.D7, Util.B9, Util.L7], [Util.D9, Util.R9, Util.B7]
  ];

  static edgeFacelet: number[][] = [
    [Util.U6, Util.R2], [Util.U8, Util.F2], [Util.U4, Util.L2], [Util.U2, Util.B2], [Util.D6, Util.R8], [Util.D2, Util.F8],
    [Util.D4, Util.L8], [Util.D8, Util.B8], [Util.F6, Util.R4], [Util.F4, Util.L6], [Util.B6, Util.L4], [Util.B4, Util.R6]
  ];

  static permMult: number[][] = Util.initPermMult();
  static move2str: string[] = [
    'U', 'U2', "U'", 'R', 'R2', "R'", 'F', 'F2', "F'",
    'D', 'D2', "D'", 'L', 'L2', "L'", 'B', 'B2', "B'"
  ];
  static preMove: number[] = [-1, Util.Rx1, Util.Rx3, Util.Fx1, Util.Fx3, Util.Lx1, Util.Lx3, Util.Bx1, Util.Bx3];
  static ud2std: number[] = [Util.Ux1, Util.Ux2, Util.Ux3, Util.Rx2, Util.Fx2, Util.Dx1, Util.Dx2, Util.Dx3, Util.Lx2, Util.Bx2];
  static std2ud: number[] = new Array<number>(18).fill(0);
  static ckmv2: boolean[][] = Util.initCkmv2();

  private static initPermMult(): number[][] {
    const permMult: number[][] = [];
    const arr1: number[] = new Array<number>(4).fill(0);
    const arr2: number[] = new Array<number>(4).fill(0);
    const arr3: number[] = new Array<number>(4).fill(0);
    for (let i = 0; i < 24; i++) {
      const row: number[] = new Array<number>(24).fill(0);
      for (let j = 0; j < 24; j++) {
        Util.setNPerm(arr1, i, 4);
        Util.setNPerm(arr2, j, 4);
        for (let k = 0; k < 4; k++) {
          arr3[k] = arr1[arr2[k]];
        }
        row[j] = Util.getNPerm(arr3, 4);
      }
      permMult.push(row);
    }
    return permMult;
  }

  private static initCkmv2(): boolean[][] {
    for (let i = 0; i < 10; i++) {
      Util.std2ud[Util.ud2std[i]] = i;
    }
    const ckmv2: boolean[][] = [];
    for (let i = 0; i < 11; i++) {
      const row: boolean[] = new Array<boolean>(10).fill(false);
      ckmv2.push(row);
    }
    for (let i = 0; i < 10; i++) {
      for (let j = 0; j < 10; j++) {
        const ix = Util.ud2std[i];
        const jx = Util.ud2std[j];
        ckmv2[i][j] = (Math.floor(ix / 3) == Math.floor(jx / 3)) ||
          ((Math.floor(ix / 3) % 3 == Math.floor(jx / 3) % 3) && (ix >= jx));
      }
      ckmv2[10][i] = false;
    }
    return ckmv2;
  }

  static toCubieCube(facelets: string, ccRet: CubieCube): number {
    let count = 0x000000;
    const f: number[] = new Array<number>(54).fill(0);
    try {
      const center: string = facelets.charAt(4) + facelets.charAt(13) + facelets.charAt(22) +
        facelets.charAt(31) + facelets.charAt(40) + facelets.charAt(49);
      for (let i = 0; i < 54; i++) {
        f[i] = center.indexOf(facelets.charAt(i));
        if (f[i] == -1) {
          return -1;
        }
        count += 1 << (f[i] << 2);
      }
    } catch (e) {
      return -1;
    }
    if (count != 0x999999) {
      return -1;
    }
    Util.toCubieCubeArr(f, ccRet);
    return ccRet.verify();
  }

  private static toCubieCubeArr(f: number[], ccRet: CubieCube): void {
    for (let i = 0; i < 8; i++) {
      ccRet.cp[i] = 0; // invalidate corners
    }
    for (let i = 0; i < 12; i++) {
      ccRet.ep[i] = 0; // and edges
    }
    for (let i = 0; i < 8; i++) {
      let ori = 0;
      for (ori = 0; ori < 3; ori++) {
        if (f[Util.cornerFacelet[i][ori]] == Util.U || f[Util.cornerFacelet[i][ori]] == Util.D) {
          break;
        }
      }
      const col1 = f[Util.cornerFacelet[i][(ori + 1) % 3]];
      const col2 = f[Util.cornerFacelet[i][(ori + 2) % 3]];
      for (let j = 0; j < 8; j++) {
        if (col1 == Math.floor(Util.cornerFacelet[j][1] / 9) &&
          col2 == Math.floor(Util.cornerFacelet[j][2] / 9)) {
          ccRet.cp[i] = j;
          ccRet.co[i] = ori % 3;
          break;
        }
      }
    }
    for (let i = 0; i < 12; i++) {
      for (let j = 0; j < 12; j++) {
        if (f[Util.edgeFacelet[i][0]] == Math.floor(Util.edgeFacelet[j][0] / 9) &&
          f[Util.edgeFacelet[i][1]] == Math.floor(Util.edgeFacelet[j][1] / 9)) {
          ccRet.ep[i] = j;
          ccRet.eo[i] = 0;
          break;
        }
        if (f[Util.edgeFacelet[i][0]] == Math.floor(Util.edgeFacelet[j][1] / 9) &&
          f[Util.edgeFacelet[i][1]] == Math.floor(Util.edgeFacelet[j][0] / 9)) {
          ccRet.ep[i] = j;
          ccRet.eo[i] = 1;
          break;
        }
      }
    }
  }

  static toFaceCube(cc: CubieCube): string {
    return cc.toFaceCube(Util.cornerFacelet, Util.edgeFacelet);
  }

  static binarySearchChar(arr: number[], key: number): number {
    const length = arr.length;
    if (key <= arr[length - 1]) {
      let l = 0;
      let r = length - 1;
      while (l <= r) {
        const mid = (l + r) >> 1;
        const val = arr[mid];
        if (key > val) {
          l = mid + 1;
        } else if (key < val) {
          r = mid - 1;
        } else {
          return mid;
        }
      }
    }
    return 0xffff;
  }

  static binarySearchInt(arr: number[], key: number): number {
    const length = arr.length;
    if (key <= arr[length - 1]) {
      let l = 0;
      let r = length - 1;
      while (l <= r) {
        const mid = (l + r) >> 1;
        const val = arr[mid];
        if (key > val) {
          l = mid + 1;
        } else if (key < val) {
          r = mid - 1;
        } else {
          return mid;
        }
      }
    }
    return 0xffff;
  }

  static getNParity(idx: number, n: number): number {
    let p = 0;
    for (let i = n - 2; i >= 0; i--) {
      p ^= idx % (n - i);
      idx = Math.floor(idx / (n - i));
    }
    return p & 1;
  }

  static setNPerm(arr: number[], idx: number, n: number): void {
    arr[n - 1] = 0;
    for (let i = n - 2; i >= 0; i--) {
      arr[i] = idx % (n - i);
      idx = Math.floor(idx / (n - i));
      for (let j = i + 1; j < n; j++) {
        if (arr[j] >= arr[i]) {
          arr[j]++;
        }
      }
    }
  }

  static getNPerm(arr: number[], n: number): number {
    let idx = 0;
    for (let i = 0; i < n; i++) {
      idx *= (n - i);
      for (let j = i + 1; j < n; j++) {
        if (arr[j] < arr[i]) {
          idx++;
        }
      }
    }
    return idx;
  }

  static getComb(arr: number[], mask: number): number {
    const end = arr.length - 1;
    let idxC = 0;
    let idxP = 0;
    let r = 4;
    let val = 0x0123;
    for (let i = end; i >= 0; i--) {
      if ((arr[i] & 0xc) == mask) {
        const v = (arr[i] & 3) << 2;
        idxP = r * idxP + ((val >> v) & 0xf);
        val -= 0x0111 >> (12 - v);
        idxC += SolverUtils.Cnk[i][r--];
      }
    }
    return (idxP << 9) | (SolverUtils.Cnk[arr.length][4] - 1 - idxC);
  }

  static setComb(arr: number[], idx: number, mask: number): void {
    const end = arr.length - 1;
    let r = 4;
    let fill = end;
    let val = 0x0123;
    let idxC = SolverUtils.Cnk[arr.length][4] - 1 - (idx & 0x1ff);
    let idxP = idx >> 9;
    for (let i = end; i >= 0; i--) {
      if (idxC >= SolverUtils.Cnk[i][r]) {
        idxC -= SolverUtils.Cnk[i][r--];
        const p = SolverUtils.fact[r];
        let v = Math.floor(idxP / p) << 2;
        idxP = idxP % p;
        arr[i] = ((val >> v) & 3) | mask;
        const m = (1 << v) - 1;
        val = (val & m) + ((val >> 4) & ~m);
      } else {
        if ((fill & 0xc) == mask) {
          fill -= 4;
        }
        arr[i] = fill--;
      }
    }
  }
}
