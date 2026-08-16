// Ported from cs/min2phase/Tools.java (DCTimer-BLE -> HarmonyOS ArkTS)
// NOTE: import Util BEFORE CubieCube to guarantee module evaluation order.
import { Util } from './Util';
import { CubieCube } from './CubieCube';
import { Search } from './Search';
import { CoordCube } from './CoordCube';
import { Utils as SolverUtils } from '../../solver/Utils';
import { Cross } from '../../solver/Cross';
import { FileIO } from '../../util/FileIO';

export class Tools {
  private static gen: () => number = () => Math.random();
  static dataPath: string = '';

  static init(): void {
    if (Search.inited) {
      return;
    }
    if (Tools.dataPath.length > 0) {
      try {
        const buf = FileIO.readWhole(Tools.dataPath + 'twophase.dat');
        if (buf == null) {
          throw new Error('no cache file');
        }
        let pos = 0;
        pos = SolverUtils.readCharArr(CubieCube.FlipS2R, buf, pos);
        pos = SolverUtils.readCharArr(CubieCube.TwistS2R, buf, pos);
        pos = SolverUtils.readCharArr(CubieCube.EPermS2R, buf, pos);
        pos = SolverUtils.readCharArr(CubieCube.MtoEPerm, buf, pos);
        for (let i = 0; i < CubieCube.Perm2Comb.length; i++) {
          CubieCube.Perm2Comb[i] = buf[pos++];
        }
        pos = Tools.readCharArr2D(CoordCube.TwistMove, buf, pos);
        pos = Tools.readCharArr2D(CoordCube.FlipMove, buf, pos);
        pos = Tools.readCharArr2D(CoordCube.UDSliceMove, buf, pos);
        pos = Tools.readCharArr2D(CoordCube.UDSliceConj, buf, pos);
        pos = Tools.readCharArr2D(CoordCube.CPermMove, buf, pos);
        pos = Tools.readCharArr2D(CoordCube.EPermMove, buf, pos);
        pos = Tools.readCharArr2D(CoordCube.MPermMove, buf, pos);
        pos = Tools.readCharArr2D(CoordCube.MPermConj, buf, pos);
        pos = Tools.readCharArr2D(CoordCube.CCombMove, buf, pos);
        pos = Tools.readCharArr2D(CoordCube.CCombConj, buf, pos);
        pos = SolverUtils.readIntArr(CoordCube.MCPermPrun, buf, pos);
        pos = SolverUtils.readIntArr(CoordCube.MEPermPrun, buf, pos);
        pos = SolverUtils.readIntArr(CoordCube.EPermCCombPrun, buf, pos);
        pos = SolverUtils.readIntArr(CoordCube.UDSliceTwistPrun, buf, pos);
        SolverUtils.readIntArr(CoordCube.UDSliceFlipPrun, buf, pos);
        CubieCube.initSym();
      } catch (e) {
        Search.init();
        try {
          Tools.writeTables();
        } catch (e2) {
          // ignore
        }
      }
    } else {
      Search.init();
    }
    Search.inited = true;
  }

  static setRandomSource(fn: () => number): void {
    Tools.gen = fn;
  }

  static randomCube(): string {
    return Tools.randomState(null, null, null, null);
  }

  private static resolveOri(arr: number[], base: number): number {
    let sum = 0;
    let idx = 0;
    let lastUnknown = -1;
    for (let i = 0; i < arr.length; i++) {
      if (arr[i] == -1) {
        arr[i] = Math.floor(Tools.gen() * base);
        lastUnknown = i;
      }
      sum += arr[i];
    }
    if (sum % base != 0 && lastUnknown != -1) {
      arr[lastUnknown] = (30 + arr[lastUnknown] - sum) % base;
    }
    for (let i = 0; i < arr.length - 1; i++) {
      idx *= base;
      idx += arr[i];
    }
    return idx;
  }

  private static countUnknown(arr: number[]): number {
    if (arr == Tools.STATE_SOLVED) {
      return 0;
    }
    let cnt = 0;
    for (let i = 0; i < arr.length; i++) {
      if (arr[i] == -1) {
        cnt++;
      }
    }
    return cnt;
  }

  private static resolvePerm(arr: number[], cntU: number, parity: number): number {
    if (arr == Tools.STATE_SOLVED) {
      return 0;
    } else if (arr == Tools.STATE_RANDOM) {
      return parity == -1 ? Math.floor(Tools.gen() * 2) : parity;
    }
    const val: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    for (let i = 0; i < arr.length; i++) {
      if (arr[i] != -1) {
        val[arr[i]] = -1;
      }
    }
    let idx = 0;
    for (let i = 0; i < arr.length; i++) {
      if (val[i] != -1) {
        const j = Math.floor(Tools.gen() * (idx + 1));
        const temp = val[i];
        val[idx++] = val[j];
        val[j] = temp;
      }
    }
    let last = -1;
    for (idx = 0; idx < arr.length && cntU > 0; idx++) {
      if (arr[idx] == -1) {
        if (cntU == 2) {
          last = idx;
        }
        arr[idx] = val[--cntU];
      }
    }
    let p = Util.getNParity(Util.getNPerm(arr, arr.length), arr.length);
    if (p == 1 - parity && last != -1) {
      const temp = arr[idx - 1];
      arr[idx - 1] = arr[last];
      arr[last] = temp;
    }
    return p;
  }

  static STATE_RANDOM: number[] | null = null;
  static STATE_SOLVED: number[] = [];

  static randomState(cp: number[] | null, co: number[] | null, ep: number[] | null, eo: number[] | null): string {
    const cpArr = cp;
    const coArr = co;
    const epArr = ep;
    const eoArr = eo;
    let parity: number;
    const cntUE = epArr == Tools.STATE_RANDOM ? 12 : Tools.countUnknown(epArr as number[]);
    const cntUC = cpArr == Tools.STATE_RANDOM ? 8 : Tools.countUnknown(cpArr as number[]);
    let cpVal: number;
    let epVal: number;
    if (cntUE < 2) { // ep != STATE_RANDOM
      if (epArr == Tools.STATE_SOLVED) {
        epVal = 0;
        parity = 0;
      } else {
        parity = Tools.resolvePerm(epArr as number[], cntUE, -1);
        epVal = Util.getNPerm(epArr as number[], 12);
      }
      if (cpArr == Tools.STATE_SOLVED) {
        cpVal = 0;
      } else if (cpArr == Tools.STATE_RANDOM) {
        do {
          cpVal = Math.floor(Tools.gen() * 40320);
        } while (Util.getNParity(cpVal, 8) != parity);
      } else {
        Tools.resolvePerm(cpArr as number[], cntUC, parity);
        cpVal = Util.getNPerm(cpArr as number[], 8);
      }
    } else { // ep != STATE_SOLVED
      if (cpArr == Tools.STATE_SOLVED) {
        cpVal = 0;
        parity = 0;
      } else if (cpArr == Tools.STATE_RANDOM) {
        cpVal = Math.floor(Tools.gen() * 40320);
        parity = Util.getNParity(cpVal, 8);
      } else {
        parity = Tools.resolvePerm(cpArr as number[], cntUC, -1);
        cpVal = Util.getNPerm(cpArr as number[], 8);
      }
      if (epArr == Tools.STATE_RANDOM) {
        do {
          epVal = Math.floor(Tools.gen() * 479001600);
        } while (Util.getNParity(epVal, 12) != parity);
      } else {
        Tools.resolvePerm(epArr as number[], cntUE, parity);
        epVal = Util.getNPerm(epArr as number[], 12);
      }
    }
    return Util.toFaceCube(new CubieCube(
      cpVal,
      coArr == Tools.STATE_RANDOM ? Math.floor(Tools.gen() * 2187) : (coArr == Tools.STATE_SOLVED ? 0 : Tools.resolveOri(coArr as number[], 3)),
      epVal,
      eoArr == Tools.STATE_RANDOM ? Math.floor(Tools.gen() * 2048) : (eoArr == Tools.STATE_SOLVED ? 0 : Tools.resolveOri(eoArr as number[], 2))));
  }

  static randomLastLayer(): string {
    return Tools.randomState(
      [-1, -1, -1, -1, 4, 5, 6, 7],
      [-1, -1, -1, -1, 0, 0, 0, 0],
      [-1, -1, -1, -1, 4, 5, 6, 7, 8, 9, 10, 11],
      [-1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0]);
  }

  static randomPLL(): string {
    return Tools.randomState(
      [-1, -1, -1, -1, 4, 5, 6, 7],
      Tools.STATE_SOLVED,
      [-1, -1, -1, -1, 4, 5, 6, 7, 8, 9, 10, 11],
      Tools.STATE_SOLVED);
  }

  static randomLastSlot(): string {
    return Tools.randomState(
      [-1, -1, -1, -1, -1, 5, 6, 7],
      [-1, -1, -1, -1, -1, 0, 0, 0],
      [-1, -1, -1, -1, 4, 5, 6, 7, -1, 9, 10, 11],
      [-1, -1, -1, -1, 0, 0, 0, 0, -1, 0, 0, 0]);
  }

  static randomZBLastLayer(): string {
    return Tools.randomState(
      [-1, -1, -1, -1, 4, 5, 6, 7],
      [-1, -1, -1, -1, 0, 0, 0, 0],
      [-1, -1, -1, -1, 4, 5, 6, 7, 8, 9, 10, 11],
      Tools.STATE_SOLVED);
  }

  static randomZBLastSlot(): string {
    return Tools.randomState(
      [-1, -1, -1, -1, -1, 5, 6, 7],
      [-1, -1, -1, -1, -1, 0, 0, 0],
      [-1, -1, -1, -1, 4, 5, 6, 7, -1, 9, 10, 11],
      [-1, -1, -1, -1, 0, 0, 0, 0, -1, 0, 0, 0]);
  }

  static randomZZLastLayer(): string {
    const auf = Math.floor(Tools.gen() * 4);
    return Tools.randomState(
      [-1, -1, -1, -1, 4, 5, 6, 7],
      [-1, -1, -1, -1, 0, 0, 0, 0],
      auf == 0 ? [-1, 1, -1, 3, 4, 5, 6, 7, 8, 9, 10, 11] :
        auf == 1 ? [-1, 3, -1, 1, 4, 5, 6, 7, 8, 9, 10, 11] :
          auf == 2 ? [1, -1, 3, -1, 4, 5, 6, 7, 8, 9, 10, 11] :
            [3, -1, 1, -1, 4, 5, 6, 7, 8, 9, 10, 11],
      Tools.STATE_SOLVED);
  }

  static randomCornerOfLastLayer(): string {
    return Tools.randomState(
      [-1, -1, -1, -1, 4, 5, 6, 7],
      [-1, -1, -1, -1, 0, 0, 0, 0],
      Tools.STATE_SOLVED, Tools.STATE_SOLVED);
  }

  static randomEdgeOfLastLayer(): string {
    return Tools.randomState(Tools.STATE_SOLVED, Tools.STATE_SOLVED,
      [-1, -1, -1, -1, 4, 5, 6, 7, 8, 9, 10, 11],
      [-1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0]);
  }

  static randomCrossSolved(): string {
    return Tools.randomState(Tools.STATE_RANDOM, Tools.STATE_RANDOM,
      [-1, -1, -1, -1, 4, 5, 6, 7, -1, -1, -1, -1],
      [-1, -1, -1, -1, 0, 0, 0, 0, -1, -1, -1, -1]);
  }

  static random3Corner(): string {
    const c: number[] = new Array<number>(8).fill(0);
    SolverUtils.idxToComb(c, Math.floor(Tools.gen() * 56), 3, 8);
    const cp: number[] = new Array<number>(8).fill(0);
    const co: number[] = new Array<number>(8).fill(0);
    for (let i = 0; i < 8; i++) {
      if (c[i] != 0) {
        co[i] = -1;
        cp[i] = -1;
      } else {
        cp[i] = i;
        co[i] = 0;
      }
    }
    return Tools.randomState(cp, co, Tools.STATE_SOLVED, Tools.STATE_SOLVED);
  }

  static random3Edge(): string {
    const e: number[] = new Array<number>(12).fill(0);
    SolverUtils.idxToComb(e, Math.floor(Tools.gen() * 220), 3, 12);
    const ep: number[] = new Array<number>(12).fill(0);
    const eo: number[] = new Array<number>(12).fill(0);
    for (let i = 0; i < 12; i++) {
      if (e[i] != 0) {
        eo[i] = -1;
        ep[i] = -1;
      } else {
        ep[i] = i;
        eo[i] = 0;
      }
    }
    return Tools.randomState(Tools.STATE_SOLVED, Tools.STATE_SOLVED, ep, eo);
  }

  static randomEdgeSolved(): string {
    return Tools.randomState(Tools.STATE_RANDOM, Tools.STATE_RANDOM, Tools.STATE_SOLVED, Tools.STATE_SOLVED);
  }

  static randomCornerSolved(): string {
    return Tools.randomState(Tools.STATE_SOLVED, Tools.STATE_SOLVED, Tools.STATE_RANDOM, Tools.STATE_RANDOM);
  }

  static randomEdgePerm(): string {
    return Tools.randomState(Tools.STATE_SOLVED, Tools.STATE_SOLVED, Tools.STATE_RANDOM, Tools.STATE_SOLVED);
  }

  static randomEdgeOri(): string {
    return Tools.randomState(Tools.STATE_SOLVED, Tools.STATE_SOLVED, Tools.STATE_SOLVED, Tools.STATE_RANDOM);
  }

  static randomCornerPerm(): string {
    return Tools.randomState(Tools.STATE_RANDOM, Tools.STATE_SOLVED, Tools.STATE_SOLVED, Tools.STATE_SOLVED);
  }

  static randomCornerOri(): string {
    return Tools.randomState(Tools.STATE_SOLVED, Tools.STATE_RANDOM, Tools.STATE_SOLVED, Tools.STATE_SOLVED);
  }

  static randomPermutation(): string {
    return Tools.randomState(Tools.STATE_RANDOM, Tools.STATE_SOLVED, Tools.STATE_RANDOM, Tools.STATE_SOLVED);
  }

  static randomOrientation(): string {
    return Tools.randomState(Tools.STATE_SOLVED, Tools.STATE_RANDOM, Tools.STATE_SOLVED, Tools.STATE_RANDOM);
  }

  static superFlip(): string {
    return Util.toFaceCube(new CubieCube(0, 0, 0, 2047));
  }

  static randomEasyCross(depth: number): string {
    const e = Cross.easyCross(depth);
    return Tools.randomState(Tools.STATE_RANDOM, Tools.STATE_RANDOM, e[0], e[1]);
  }

  static fromScrambleArr(scramble: number[]): string {
    let c1 = new CubieCube();
    let c2 = new CubieCube();
    let tmp: CubieCube;
    for (let i = 0; i < scramble.length; i++) {
      CubieCube.CornMult(c1, CubieCube.moveCube[scramble[i]], c2);
      CubieCube.EdgeMult(c1, CubieCube.moveCube[scramble[i]], c2);
      tmp = c1;
      c1 = c2;
      c2 = tmp;
    }
    return Util.toFaceCube(c1);
  }

  static fromScramble(s: string): string {
    const arr: number[] = new Array<number>(s.length).fill(0);
    let j = 0;
    let axis = -1;
    for (let i = 0, length = s.length; i < length; i++) {
      switch (s.charAt(i)) {
        case 'U': axis = 0; break;
        case 'R': axis = 3; break;
        case 'F': axis = 6; break;
        case 'D': axis = 9; break;
        case 'L': axis = 12; break;
        case 'B': axis = 15; break;
        case ' ':
          if (axis != -1) {
            arr[j++] = axis;
          }
          axis = -1;
          break;
        case '2': axis++; break;
        case "'": axis += 2; break;
        default: continue;
      }
    }
    if (axis != -1) {
      arr[j++] = axis;
    }
    const ret: number[] = new Array<number>(j).fill(0);
    while (--j >= 0) {
      ret[j] = arr[j];
    }
    return Tools.fromScrambleArr(ret);
  }

  static getCorrectionFacelet(currentFacelets: string, targetFacelets: string): string | null {
    const current = new CubieCube();
    const target = new CubieCube();
    if (Util.toCubieCube(currentFacelets, current) != 0 || Util.toCubieCube(targetFacelets, target) != 0) {
      return null;
    }
    const inverseTarget = new CubieCube(target);
    inverseTarget.invCubieCube();
    const correction = new CubieCube();
    CubieCube.CornMult(inverseTarget, current, correction);
    CubieCube.EdgeMult(inverseTarget, current, correction);
    return Util.toFaceCube(correction);
  }

  static getScrambleFacelet(currentFacelets: string, targetFacelets: string): string | null {
    const current = new CubieCube();
    const target = new CubieCube();
    if (Util.toCubieCube(currentFacelets, current) != 0 || Util.toCubieCube(targetFacelets, target) != 0) {
      return null;
    }
    const inverseCurrent = new CubieCube(current);
    inverseCurrent.invCubieCube();
    const scramble = new CubieCube();
    CubieCube.CornMult(inverseCurrent, target, scramble);
    CubieCube.EdgeMult(inverseCurrent, target, scramble);
    return Util.toFaceCube(scramble);
  }

  static verify(facelets: string): number {
    return Util.toCubieCube(facelets, new CubieCube());
  }

  // ============ twophase.dat cache writer ============
  private static writeTables(): void {
    const parts: Uint8Array[] = [];
    parts.push(Tools.packCharArr(CubieCube.FlipS2R));
    parts.push(Tools.packCharArr(CubieCube.TwistS2R));
    parts.push(Tools.packCharArr(CubieCube.EPermS2R));
    parts.push(Tools.packCharArr(CubieCube.MtoEPerm));
    parts.push(Tools.packBytes(CubieCube.Perm2Comb));
    parts.push(Tools.packCharArr2D(CoordCube.TwistMove));
    parts.push(Tools.packCharArr2D(CoordCube.FlipMove));
    parts.push(Tools.packCharArr2D(CoordCube.UDSliceMove));
    parts.push(Tools.packCharArr2D(CoordCube.UDSliceConj));
    parts.push(Tools.packCharArr2D(CoordCube.CPermMove));
    parts.push(Tools.packCharArr2D(CoordCube.EPermMove));
    parts.push(Tools.packCharArr2D(CoordCube.MPermMove));
    parts.push(Tools.packCharArr2D(CoordCube.MPermConj));
    parts.push(Tools.packCharArr2D(CoordCube.CCombMove));
    parts.push(Tools.packCharArr2D(CoordCube.CCombConj));
    parts.push(Tools.packIntArr(CoordCube.MCPermPrun));
    parts.push(Tools.packIntArr(CoordCube.MEPermPrun));
    parts.push(Tools.packIntArr(CoordCube.EPermCCombPrun));
    parts.push(Tools.packIntArr(CoordCube.UDSliceTwistPrun));
    parts.push(Tools.packIntArr(CoordCube.UDSliceFlipPrun));
    let total = 0;
    for (const p of parts) {
      total += p.length;
    }
    const out = new Uint8Array(total);
    let pos = 0;
    for (const p of parts) {
      out.set(p, pos);
      pos += p.length;
    }
    FileIO.writeWhole(Tools.dataPath + 'twophase.dat', out);
  }

  private static readCharArr2D(arr: number[][], buf: Uint8Array, pos: number): number {
    const len = arr[0].length;
    for (let i = 0; i < arr.length; i++) {
      for (let j = 0; j < len; j++) {
        arr[i][j] = (buf[pos + j * 2] & 0xff) | ((buf[pos + j * 2 + 1] << 8) & 0xff00);
      }
      pos += len * 2;
    }
    return pos;
  }

  private static packCharArr(arr: number[]): Uint8Array {
    const out = new Uint8Array(arr.length * 2);
    let pos = 0;
    for (let i = 0; i < arr.length; i++) {
      out[pos++] = arr[i] & 0xff;
      out[pos++] = (arr[i] >>> 8) & 0xff;
    }
    return out;
  }

  private static packBytes(arr: number[]): Uint8Array {
    const out = new Uint8Array(arr.length);
    for (let i = 0; i < arr.length; i++) {
      out[i] = arr[i] & 0xff;
    }
    return out;
  }

  private static packCharArr2D(arr: number[][]): Uint8Array {
    const len = arr[0].length;
    const out = new Uint8Array(arr.length * len * 2);
    let pos = 0;
    for (let i = 0; i < arr.length; i++) {
      for (let j = 0; j < len; j++) {
        out[pos++] = arr[i][j] & 0xff;
        out[pos++] = (arr[i][j] >>> 8) & 0xff;
      }
    }
    return out;
  }

  private static packIntArr(arr: number[]): Uint8Array {
    const out = new Uint8Array(arr.length * 4);
    let pos = 0;
    for (let i = 0; i < arr.length; i++) {
      out[pos++] = arr[i] & 0xff;
      out[pos++] = (arr[i] >>> 8) & 0xff;
      out[pos++] = (arr[i] >>> 16) & 0xff;
      out[pos++] = (arr[i] >>> 24) & 0xff;
    }
    return out;
  }
}