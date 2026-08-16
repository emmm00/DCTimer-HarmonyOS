// 打乱显示工具（合并 ScrambleGroupDisplay + ScrambleSubitemDisplay）
export class ScrambleGroupDisplay {
  static readonly WCA_GROUP = -1;
  static readonly GROUP_222 = 0;
  static readonly GROUP_333 = 1;
  static readonly GROUP_333_CFOP = 21;
  static readonly GROUP_333_ROUX = 22;

  static getDisplayGroupIndices(groupCount: number): number[] {
    if (groupCount <= 0) return [];
    const groups: number[] = new Array<number>(groupCount);
    let position = 0;
    groups[position++] = ScrambleGroupDisplay.WCA_GROUP;
    const normalGroupCount = groupCount - 1;
    const hasCfopGroup = ScrambleGroupDisplay.GROUP_333_CFOP < normalGroupCount;
    const hasRouxGroup = ScrambleGroupDisplay.GROUP_333_ROUX < normalGroupCount;
    for (let realGroup = 0; realGroup < normalGroupCount; realGroup++) {
      if ((hasCfopGroup && realGroup === ScrambleGroupDisplay.GROUP_333_CFOP)
        || (hasRouxGroup && realGroup === ScrambleGroupDisplay.GROUP_333_ROUX)) {
        continue;
      }
      groups[position++] = realGroup;
      if (realGroup === ScrambleGroupDisplay.GROUP_333) {
        if (hasCfopGroup) {
          groups[position++] = ScrambleGroupDisplay.GROUP_333_CFOP;
        }
        if (hasRouxGroup) {
          groups[position++] = ScrambleGroupDisplay.GROUP_333_ROUX;
        }
      }
    }
    return groups;
  }

  static toDisplayPosition(realGroup: number, groupCount: number): number {
    const groups = ScrambleGroupDisplay.getDisplayGroupIndices(groupCount);
    for (let i = 0; i < groups.length; i++) {
      if (groups[i] === realGroup) return i;
    }
    return realGroup === ScrambleGroupDisplay.WCA_GROUP ? 0 : Math.max(0, realGroup + 1);
  }

  static toRealGroup(displayPosition: number, groupCount: number): number {
    const groups = ScrambleGroupDisplay.getDisplayGroupIndices(groupCount);
    if (displayPosition < 0 || displayPosition >= groups.length) return ScrambleGroupDisplay.WCA_GROUP;
    return groups[displayPosition];
  }

  static toDisplayNames(realNames: string[]): string[] {
    if (!realNames) return [];
    const groups = ScrambleGroupDisplay.getDisplayGroupIndices(realNames.length);
    const names: string[] = [];
    for (let i = 0; i < groups.length; i++) {
      names[i] = realNames[groups[i] + 1];
    }
    return names;
  }
}

export class ScrambleSubitemDisplay {
  // SmartCube 子项顺序常量
  static readonly SUB_F2L = 0;
  static readonly SUB_OLL = 1;
  static readonly SUB_PLL = 2;
  static readonly SUB_LAST_LAYER = 3;
  static readonly SUB_CLL = 4;
  static readonly SUB_ELL = 5;
  static readonly SUB_COLL = 6;
  static readonly SUB_EOCP = 7;
  static readonly SUB_2GLL = 8;
  static readonly SUB_OLLCP = 9;
  static readonly SUB_ZZLL = 10;
  static readonly SUB_ZBLS = 11;
  static readonly SUB_ZBLL = 12;

  private static readonly CFOP_DISPLAY_ORDER = [
    ScrambleSubitemDisplay.SUB_F2L,
    ScrambleSubitemDisplay.SUB_OLL,
    ScrambleSubitemDisplay.SUB_PLL,
    ScrambleSubitemDisplay.SUB_LAST_LAYER,
    ScrambleSubitemDisplay.SUB_CLL,
    ScrambleSubitemDisplay.SUB_ELL,
    ScrambleSubitemDisplay.SUB_COLL,
    ScrambleSubitemDisplay.SUB_EOCP,
    ScrambleSubitemDisplay.SUB_2GLL,
    ScrambleSubitemDisplay.SUB_OLLCP,
    ScrambleSubitemDisplay.SUB_ZZLL,
    ScrambleSubitemDisplay.SUB_ZBLS,
    ScrambleSubitemDisplay.SUB_ZBLL
  ];

  static getDisplaySubIndices(realGroup: number, subCount: number): number[] {
    if (subCount <= 0) return [];
    if (realGroup !== ScrambleGroupDisplay.GROUP_333_CFOP) {
      const subs: number[] = new Array<number>(subCount);
      for (let i = 0; i < subCount; i++) subs[i] = i;
      return subs;
    }
    const subs: number[] = new Array<number>(subCount);
    const used: boolean[] = new Array<boolean>(subCount).fill(false);
    let position = 0;
    for (const sub of ScrambleSubitemDisplay.CFOP_DISPLAY_ORDER) {
      if (sub >= 0 && sub < subCount && !used[sub]) {
        subs[position++] = sub;
        used[sub] = true;
      }
    }
    for (let sub = 0; sub < subCount; sub++) {
      if (!used[sub]) subs[position++] = sub;
    }
    return subs;
  }

  static toDisplayPosition(realGroup: number, realSub: number, subCount: number): number {
    const subs = ScrambleSubitemDisplay.getDisplaySubIndices(realGroup, subCount);
    for (let i = 0; i < subs.length; i++) {
      if (subs[i] === realSub) return i;
    }
    return realSub >= 0 && realSub < subCount ? realSub : 0;
  }

  static toRealSub(realGroup: number, displayPosition: number, subCount: number): number {
    const subs = ScrambleSubitemDisplay.getDisplaySubIndices(realGroup, subCount);
    if (displayPosition < 0 || displayPosition >= subs.length) return 0;
    return subs[displayPosition];
  }

  static toDisplayNames(realGroup: number, realNames: string[]): string[] {
    if (!realNames) return [];
    const subs = ScrambleSubitemDisplay.getDisplaySubIndices(realGroup, realNames.length);
    const names: string[] = [];
    for (let i = 0; i < subs.length; i++) {
      names[i] = realNames[subs[i]];
    }
    return names;
  }
}