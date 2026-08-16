// Ported from scrambler/SQ1.java (DCTimer-BLE -> HarmonyOS ArkTS)

export class SQ1 {
  private static seq: number[] = [];
  private static posit: number[] = [];

  private static scramble(scrambleLen: number): void {
    SQ1.posit = [0, 0, 1, 2, 2, 3, 4, 4, 5, 6, 6, 7, 8, 9, 9, 10, 11, 11, 12, 13, 13, 14, 15, 15, 1];
    let ls = -1;
    let f = 0;
    SQ1.seq = new Array<number>(scrambleLen).fill(0);
    for (let i = 0; i < scrambleLen; i++) {
      let j: number;
      do {
        if (ls == 0) {
          j = Math.floor(Math.random() * 22) - 11;
          if (j >= 0) {
            j++;
          }
        } else if (ls == 1) {
          j = Math.floor(Math.random() * 12) - 11;
        } else if (ls == 2) {
          j = 0;
        } else {
          j = Math.floor(Math.random() * 23) - 11;
        }
      } while ((f > 1 && j >= -6 && j < 0) || SQ1.domove(j));
      if (j > 0) {
        ls = 1;
      } else if (j < 0) {
        ls = 2;
      } else {
        ls = 0;
        f++;
      }
      SQ1.seq[i] = j;
    }
  }

  static scramblestring(scrambleLen: number): string {
    SQ1.scramble(scrambleLen);
    SQ1.posit[24] = 1;
    let sb = '';
    let l = -1;
    for (let i = 0; i < SQ1.seq.length; i++) {
      const k = SQ1.seq[i];
      if (k == 0) {
        if (l == -1) {
          sb += '(0,0) / ';
        } else if (l == 1) {
          sb += '0) / ';
        } else if (l == 2) {
          sb += ') / ';
        }
        l = 0;
        SQ1.posit[24] = 1 - SQ1.posit[24];
      } else if (k > 0) {
        sb += '(' + (k > 6 ? k - 12 : k) + ',';
        l = 1;
      } else {
        if (l <= 0) {
          sb += '(0,';
        }
        sb += (k <= -6 ? k + 12 : k);
        l = 2;
      }
    }
    if (l == 1) {
      sb += '0';
    }
    if (l != 0) {
      sb += ')';
    }
    return sb;
  }

  private static domove(m: number): boolean {
    let f = m;
    const t: number[] = new Array<number>(12).fill(0);
    if (f == 0) {
      for (let i = 0; i < 6; i++) {
        const c = SQ1.posit[i + 12];
        SQ1.posit[i + 12] = SQ1.posit[i + 6];
        SQ1.posit[i + 6] = c;
      }
    } else if (f > 0) {
      f = 12 - f;
      if (SQ1.posit[f] == SQ1.posit[f - 1]) {
        return true;
      }
      if (f < 6 && SQ1.posit[f + 6] == SQ1.posit[f + 5]) {
        return true;
      }
      if (f > 6 && SQ1.posit[f - 6] == SQ1.posit[f - 7]) {
        return true;
      }
      if (f == 6 && SQ1.posit[0] == SQ1.posit[11]) {
        return true;
      }
      for (let i = 0; i < 12; i++) {
        t[i] = SQ1.posit[i];
      }
      let c = f;
      for (let i = 0; i < 12; i++) {
        SQ1.posit[i] = t[c];
        if (c == 11) {
          c = 0;
        } else {
          c++;
        }
      }
    } else {
      f = -f;
      if (SQ1.posit[f + 12] == SQ1.posit[f + 11]) {
        return true;
      }
      if (f < 6 && SQ1.posit[f + 18] == SQ1.posit[f + 17]) {
        return true;
      }
      if (f > 6 && SQ1.posit[f + 6] == SQ1.posit[f + 5]) {
        return true;
      }
      if (f == 6 && SQ1.posit[12] == SQ1.posit[23]) {
        return true;
      }
      for (let i = 0; i < 12; i++) {
        t[i] = SQ1.posit[i + 12];
      }
      let c = f;
      for (let i = 0; i < 12; i++) {
        SQ1.posit[i + 12] = t[c];
        if (c == 11) {
          c = 0;
        } else {
          c++;
        }
      }
    }
    return false;
  }

  static image(scramble: string): number[] {
    const s = scramble.split(' ');
    SQ1.posit = [0, 0, 1, 2, 2, 3, 4, 4, 5, 6, 6, 7, 8, 9, 9, 10, 11, 11, 12, 13, 13, 14, 15, 15, 1];
    for (let i = 0; i < s.length; i++) {
      if (s[i].length == 0) {
        continue;
      }
      if (s[i] == '/') {
        SQ1.domove(0);
        SQ1.posit[24] = 1 - SQ1.posit[24];
      } else {
        const m = /\((-?\d+),(-?\d+)\)/.exec(s[i]);
        if (m != null) {
          const top = parseInt(m[1]);
          if (top > 0) {
            SQ1.domove(top);
          } else if (top < 0) {
            SQ1.domove(top + 12);
          }
          const bottom = parseInt(m[2]);
          if (bottom > 0) {
            SQ1.domove(bottom - 12);
          } else if (bottom < 0) {
            SQ1.domove(bottom);
          }
        }
      }
    }
    return SQ1.posit;
  }
}
