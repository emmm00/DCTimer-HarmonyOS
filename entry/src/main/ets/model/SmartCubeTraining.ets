// Ported from com.dctimer.model.SmartCubeTraining.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { SmartCubeOrientation } from '../util/SmartCubeOrientation';

export class SmartCubeTraining {
  static readonly GROUP_333_CFOP = 21;
  static readonly GROUP_333_ROUX = 22;
  static readonly SUB_OLL = 0;
  static readonly SUB_PLL = 1;
  static readonly SUB_LAST_LAYER = 2;
  static readonly SUB_F2L = 3;
  static readonly SUB_ZBLL = 4;
  static readonly SUB_ZZLL = 5;
  static readonly SUB_2GLL = 6;
  static readonly SUB_ELL = 7;
  static readonly SUB_ZBLS = 8;
  static readonly SUB_COLL = 9;
  static readonly SUB_OLLCP = 10;
  static readonly SUB_EOCP = 11;
  static readonly SUB_CLL = 12;
  static readonly SUB_COUNT = 13;
  static readonly SUB_ROUX_CMLL = 0;
  static readonly SUB_ROUX_LSE = 1;
  static readonly SUB_ROUX_L10P = 2;
  static readonly ROUX_SUB_COUNT = 3;
  static readonly CATEGORY_333_CFOP_BASE = SmartCubeTraining.GROUP_333_CFOP << 5;
  static readonly CATEGORY_333_ROUX_BASE = SmartCubeTraining.GROUP_333_ROUX << 5;
  static readonly DEFAULT_TRAINING_ORIENTATION = 13;

  private static readonly F2L_MASK: number[][] = SmartCubeTraining.toEqus('----U-------RRRRRR---FFFFFFDDDDDDDDD---LLLLLL---BBBBBB');
  private static readonly OLL_MASK: number[][] = SmartCubeTraining.toEqus('UUUUUUUUU---RRRRRR---FFFFFFDDDDDDDDD---LLLLLL---BBBBBB');
  private static readonly EOLL_MASK: number[][] = SmartCubeTraining.toEqus('-U-UUU-U----RRRRRR---FFFFFFDDDDDDDDD---LLLLLL---BBBBBB');
  private static readonly CPLL_MASK: number[][] = SmartCubeTraining.toEqus('UUUUUUUUUr-rRRRRRRf-fFFFFFFDDDDDDDDDl-lLLLLLLb-bBBBBBB');
  private static readonly CLL_MASK: number[][] = SmartCubeTraining.toEqus('U-U-U-U-Ur-rRRRRRRf-fFFFFFFDDDDDDDDDl-lLLLLLLb-bBBBBBB');
  private static readonly ROUX_CMLL_MASK: number[][] = SmartCubeTraining.toEqus('U-U---U-Ur-rRRRRRRf-fF-FF-FD-DD-DD-Dl-lLLLLLLb-bB-BB-B');
  private static readonly SOLVED_MASK: number[][] = SmartCubeTraining.toEqus(SmartCubeOrientation.SOLVED_FACELET);
  private static readonly U_CORNER_FACELETS: number[][] = [
    [8, 9, 20], [6, 18, 38], [0, 36, 47], [2, 45, 11]
  ];

  static is333Cfop(scrambleIdx: number): boolean {
    return (scrambleIdx >> 5) == SmartCubeTraining.GROUP_333_CFOP;
  }

  static is333Roux(scrambleIdx: number): boolean {
    return (scrambleIdx >> 5) == SmartCubeTraining.GROUP_333_ROUX;
  }

  static isSmart333Training(scrambleIdx: number): boolean {
    return SmartCubeTraining.is333Cfop(scrambleIdx) || SmartCubeTraining.is333Roux(scrambleIdx);
  }

  static is333CfopSub(scrambleIdx: number, sub: number): boolean {
    return SmartCubeTraining.is333Cfop(scrambleIdx) && (scrambleIdx & 0x1f) == sub;
  }

  static is333RouxSub(scrambleIdx: number, sub: number): boolean {
    return SmartCubeTraining.is333Roux(scrambleIdx) && (scrambleIdx & 0x1f) == sub;
  }

  static isStageCompleteMode(scrambleIdx: number): boolean {
    const sub = scrambleIdx & 0x1f;
    return (SmartCubeTraining.is333Cfop(scrambleIdx) && (sub == SmartCubeTraining.SUB_OLL || sub == SmartCubeTraining.SUB_F2L ||
      sub == SmartCubeTraining.SUB_ZBLS || sub == SmartCubeTraining.SUB_COLL || sub == SmartCubeTraining.SUB_OLLCP ||
      sub == SmartCubeTraining.SUB_EOCP || sub == SmartCubeTraining.SUB_CLL)) ||
      (SmartCubeTraining.is333Roux(scrambleIdx) && sub == SmartCubeTraining.SUB_ROUX_CMLL);
  }

  static isComplete(scrambleIdx: number, facelets: string, orientationIndex: number): boolean {
    if (!SmartCubeTraining.isSmart333Training(scrambleIdx) || facelets == null || facelets.length == 0) {
      return false;
    }
    const oriented = SmartCubeOrientation.orientFacelets(facelets, orientationIndex);
    if (SmartCubeTraining.is333Roux(scrambleIdx)) {
      switch (scrambleIdx & 0x1f) {
        case SmartCubeTraining.SUB_ROUX_CMLL:
          return SmartCubeTraining.matchesMask(oriented, SmartCubeTraining.ROUX_CMLL_MASK);
        case SmartCubeTraining.SUB_ROUX_LSE:
        case SmartCubeTraining.SUB_ROUX_L10P:
          return SmartCubeTraining.matchesMask(oriented, SmartCubeTraining.SOLVED_MASK);
        default:
          return false;
      }
    }
    switch (scrambleIdx & 0x1f) {
      case SmartCubeTraining.SUB_OLL:
        return SmartCubeTraining.matchesMask(oriented, SmartCubeTraining.OLL_MASK);
      case SmartCubeTraining.SUB_PLL:
      case SmartCubeTraining.SUB_LAST_LAYER:
      case SmartCubeTraining.SUB_ZBLL:
      case SmartCubeTraining.SUB_ZZLL:
      case SmartCubeTraining.SUB_2GLL:
      case SmartCubeTraining.SUB_ELL:
        return SmartCubeTraining.matchesMask(oriented, SmartCubeTraining.SOLVED_MASK);
      case SmartCubeTraining.SUB_F2L:
        return SmartCubeTraining.matchesMask(oriented, SmartCubeTraining.F2L_MASK);
      case SmartCubeTraining.SUB_ZBLS:
        return SmartCubeTraining.matchesMask(oriented, SmartCubeTraining.EOLL_MASK);
      case SmartCubeTraining.SUB_COLL:
      case SmartCubeTraining.SUB_OLLCP:
        return SmartCubeTraining.matchesMask(oriented, SmartCubeTraining.CPLL_MASK);
      case SmartCubeTraining.SUB_EOCP:
        return SmartCubeTraining.matchesEOCP(oriented);
      case SmartCubeTraining.SUB_CLL:
        return SmartCubeTraining.matchesMask(oriented, SmartCubeTraining.CLL_MASK);
      default:
        return false;
    }
  }

  static hasF2L(facelets: string): boolean {
    return SmartCubeTraining.matchesMask(facelets, SmartCubeTraining.F2L_MASK);
  }

  static hasOLL(facelets: string): boolean {
    return SmartCubeTraining.matchesMask(facelets, SmartCubeTraining.OLL_MASK);
  }

  static hasEOLL(facelets: string): boolean {
    return SmartCubeTraining.matchesMask(facelets, SmartCubeTraining.EOLL_MASK);
  }

  static hasCPLL(facelets: string): boolean {
    return SmartCubeTraining.matchesMask(facelets, SmartCubeTraining.CPLL_MASK);
  }

  static hasEOCP(facelets: string): boolean {
    return SmartCubeTraining.matchesEOCP(facelets);
  }

  static hasCLL(facelets: string): boolean {
    return SmartCubeTraining.matchesMask(facelets, SmartCubeTraining.CLL_MASK);
  }

  static hasRouxCMLL(facelets: string): boolean {
    return SmartCubeTraining.matchesMask(facelets, SmartCubeTraining.ROUX_CMLL_MASK);
  }

  private static matchesEOCP(facelets: string): boolean {
    if (!SmartCubeTraining.matchesMask(facelets, SmartCubeTraining.EOLL_MASK)) {
      return false;
    }
    const u = facelets.charAt(4);
    const cornerColors: string[][] = [
      [u, facelets.charAt(13), facelets.charAt(22)],
      [u, facelets.charAt(22), facelets.charAt(40)],
      [u, facelets.charAt(40), facelets.charAt(49)],
      [u, facelets.charAt(49), facelets.charAt(13)]
    ];
    for (let auf = 0; auf < 4; auf++) {
      let matches = true;
      for (let i = 0; i < SmartCubeTraining.U_CORNER_FACELETS.length; i++) {
        const facelet = SmartCubeTraining.U_CORNER_FACELETS[i];
        const colors = cornerColors[(i + auf) % cornerColors.length];
        if (!SmartCubeTraining.hasCornerColors(facelets, facelet[0], facelet[1], facelet[2], colors[0], colors[1], colors[2])) {
          matches = false;
          break;
        }
      }
      if (matches) {
        return true;
      }
    }
    return false;
  }

  private static hasCornerColors(facelets: string, a: number, b: number, c: number, x: string, y: string, z: string): boolean {
    return SmartCubeTraining.containsAll(facelets.charAt(a), facelets.charAt(b), facelets.charAt(c), x, y, z);
  }

  private static containsAll(a: string, b: string, c: string, x: string, y: string, z: string): boolean {
    return SmartCubeTraining.contains(a, b, c, x) && SmartCubeTraining.contains(a, b, c, y) && SmartCubeTraining.contains(a, b, c, z);
  }

  private static contains(a: string, b: string, c: string, x: string): boolean {
    return a == x || b == x || c == x;
  }

  private static matchesMask(facelets: string, mask: number[][]): boolean {
    if (facelets == null || facelets.length < 54) {
      return false;
    }
    for (const equ of mask) {
      const color = facelets.charAt(equ[0]);
      for (let i = 1; i < equ.length; i++) {
        if (facelets.charAt(equ[i]) != color) {
          return false;
        }
      }
    }
    return true;
  }

  private static toEqus(mask: string): number[][] {
    const buckets: number[][] = [];
    const counts: number[] = new Array<number>(128).fill(0);
    for (let i = 0; i < mask.length; i++) {
      const color = mask.charCodeAt(i);
      if (color == 0x2d) { // '-'
        continue;
      }
      if (buckets[color] == null) {
        buckets[color] = new Array<number>(54).fill(0);
      }
      buckets[color][counts[color]++] = i;
    }
    let groupCount = 0;
    for (let color = 0; color < counts.length; color++) {
      if (counts[color] > 1) {
        groupCount++;
      }
    }
    const equs: number[][] = [];
    for (let color = 0; color < counts.length; color++) {
      if (counts[color] > 1) {
        const group: number[] = new Array<number>(counts[color]).fill(0);
        for (let i = 0; i < counts[color]; i++) {
          group[i] = buckets[color][i];
        }
        equs.push(group);
      }
    }
    return equs;
  }
}
