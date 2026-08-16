// Ported from com/dctimer/util/ScrambleGroupDisplay.java (DCTimer-BLE -> HarmonyOS ArkTS)
export class ScrambleGroupDisplay {
  static readonly WCA_GROUP: number = -1;
  static readonly GROUP_222: number = 0;
  static readonly GROUP_333: number = 1;
  static readonly GROUP_333_CFOP: number = 21;
  static readonly GROUP_333_ROUX: number = 22;

  static getDisplayGroupIndices(groupCount: number): number[] {
    if (groupCount <= 0) {
      return [];
    }
    const groups: number[] = new Array<number>(groupCount).fill(0);
    let position = 0;
    groups[position++] = ScrambleGroupDisplay.WCA_GROUP;
    const normalGroupCount = groupCount - 1;
    const hasCfopGroup = ScrambleGroupDisplay.GROUP_333_CFOP < normalGroupCount;
    const hasRouxGroup = ScrambleGroupDisplay.GROUP_333_ROUX < normalGroupCount;
    for (let realGroup = 0; realGroup < normalGroupCount; realGroup++) {
      if ((hasCfopGroup && realGroup == ScrambleGroupDisplay.GROUP_333_CFOP)
        || (hasRouxGroup && realGroup == ScrambleGroupDisplay.GROUP_333_ROUX)) {
        continue;
      }
      groups[position++] = realGroup;
      if (realGroup == ScrambleGroupDisplay.GROUP_333) {
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
      if (groups[i] == realGroup) {
        return i;
      }
    }
    return realGroup == ScrambleGroupDisplay.WCA_GROUP ? 0 : Math.max(0, realGroup + 1);
  }

  static toRealGroup(displayPosition: number, groupCount: number): number {
    const groups = ScrambleGroupDisplay.getDisplayGroupIndices(groupCount);
    if (displayPosition < 0 || displayPosition >= groups.length) {
      return ScrambleGroupDisplay.WCA_GROUP;
    }
    return groups[displayPosition];
  }

  static toDisplayNames(realNames: string[] | null): string[] {
    if (realNames == null) {
      return [];
    }
    const groups = ScrambleGroupDisplay.getDisplayGroupIndices(realNames.length);
    const names: string[] = new Array<string>(groups.length).fill('');
    for (let i = 0; i < groups.length; i++) {
      names[i] = realNames[groups[i] + 1];
    }
    return names;
  }
}
