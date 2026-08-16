// Ported from com/dctimer/util/ScrambleSubitemDisplay.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { SmartCubeTraining } from '../model/SmartCubeTraining';

export class ScrambleSubitemDisplay {
  private static readonly CFOP_DISPLAY_ORDER: number[] = [
    SmartCubeTraining.SUB_F2L,
    SmartCubeTraining.SUB_OLL,
    SmartCubeTraining.SUB_PLL,
    SmartCubeTraining.SUB_LAST_LAYER,
    SmartCubeTraining.SUB_CLL,
    SmartCubeTraining.SUB_ELL,
    SmartCubeTraining.SUB_COLL,
    SmartCubeTraining.SUB_EOCP,
    SmartCubeTraining.SUB_2GLL,
    SmartCubeTraining.SUB_OLLCP,
    SmartCubeTraining.SUB_ZZLL,
    SmartCubeTraining.SUB_ZBLS,
    SmartCubeTraining.SUB_ZBLL
  ];

  static getDisplaySubIndices(realGroup: number, subCount: number): number[] {
    if (subCount <= 0) {
      return [];
    }
    if (realGroup != SmartCubeTraining.GROUP_333_CFOP) {
      const subs: number[] = new Array<number>(subCount).fill(0);
      for (let i = 0; i < subCount; i++) {
        subs[i] = i;
      }
      return subs;
    }
    const subs: number[] = new Array<number>(subCount).fill(0);
    const used: boolean[] = new Array<boolean>(subCount).fill(false);
    let position = 0;
    for (let o = 0; o < ScrambleSubitemDisplay.CFOP_DISPLAY_ORDER.length; o++) {
      const sub = ScrambleSubitemDisplay.CFOP_DISPLAY_ORDER[o];
      if (sub >= 0 && sub < subCount && !used[sub]) {
        subs[position++] = sub;
        used[sub] = true;
      }
    }
    for (let sub = 0; sub < subCount; sub++) {
      if (!used[sub]) {
        subs[position++] = sub;
      }
    }
    return subs;
  }

  static toDisplayPosition(realGroup: number, realSub: number, subCount: number): number {
    const subs = ScrambleSubitemDisplay.getDisplaySubIndices(realGroup, subCount);
    for (let i = 0; i < subs.length; i++) {
      if (subs[i] == realSub) {
        return i;
      }
    }
    return realSub >= 0 && realSub < subCount ? realSub : 0;
  }

  static toRealSub(realGroup: number, displayPosition: number, subCount: number): number {
    const subs = ScrambleSubitemDisplay.getDisplaySubIndices(realGroup, subCount);
    if (displayPosition < 0 || displayPosition >= subs.length) {
      return 0;
    }
    return subs[displayPosition];
  }

  static toDisplayNames(realGroup: number, realNames: string[] | null): string[] {
    if (realNames == null) {
      return [];
    }
    const subs = ScrambleSubitemDisplay.getDisplaySubIndices(realGroup, realNames.length);
    const names: string[] = new Array<string>(subs.length).fill('');
    for (let i = 0; i < subs.length; i++) {
      names[i] = realNames[subs[i]];
    }
    return names;
  }
}
