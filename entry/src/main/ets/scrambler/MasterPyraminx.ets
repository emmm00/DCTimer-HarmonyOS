// Ported from scrambler/MasterPyraminx.java (DCTimer-BLE -> HarmonyOS ArkTS)

export class MasterPyraminx {
  static colors: number[] = new Array<number>(64).fill(0);

  static initColor(): void {
    MasterPyraminx.colors = [
      1, 1, 1, 1, 1, 1, 1, 2, 3, 3, 3, 3, 3, 3, 3,
      1, 1, 1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 3,
      1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3,
      1, 2, 2, 2, 2, 2, 2, 2, 3,

      4, 4, 4, 4, 4, 4, 4,
      4, 4, 4, 4, 4,
      4, 4, 4,
      4
    ];
  }

  static move(m: number): void {
    switch (m) {
      case 8: // Lw
      case 0: // L
        break;
      case 9: // Rw
      case 1: // R
        break;
      case 10: // Bw
      case 2: // B
        break;
      case 11: // Uw
      case 3: // U
        break;
      case 4: // l
        break;
      case 5: // r
        break;
      case 6: // b
        break;
      case 7: // u
        break;
    }
  }

  image(scr: string): number[] {
    const s = scr.split(' ');
    MasterPyraminx.initColor();
    for (let i = 0; i < s.length; i++) {
      const suff = s[i].length;
      if (suff > 0) {
        const turn = 'LRBUlrbu'.indexOf(s[i].charAt(0));
        void turn;
        if (suff > 1) {
          if (s[i].charAt(1) == 'w') {
            // turn += 8;
          }
        }
      }
    }
    return MasterPyraminx.colors;
  }
}
