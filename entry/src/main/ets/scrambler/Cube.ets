// Ported from scrambler/Cube.java (DCTimer-BLE -> HarmonyOS ArkTS)
const CH_B3 = 0xb3;
const CH_B2 = 0xb2;

export class Cube {
  private static size = 3;
  private static seqLen = 0;
  private static seql = 0;
  private static mult = true;
  private static colors: number[] = [0, 5, 1, 3, 2, 4];
  private static seq: number[] = [];
  private static posit: number[] = [];
  private static colorPerm: number[] = [0, 1, 2, 3, 4, 5];
  private static img: number[] = [];

  static appendmoves(sq: number[], axsl: number[], tl: number, la: number): void {
    for (let sl = 0; sl < tl; sl++) { // for each move type
      if (axsl[sl] != 0) { // if it occurs
        let q = axsl[sl] - 1;
        let sa = la;
        let m = sl;
        if (sl + sl + 1 >= tl) { // if on rear half of this axis
          sa += 3; // get semi-axis (i.e. face of the move)
          m = tl - 1 - m; // slice number counting from that face
          q = 2 - q; // opposite direction when looking at that face
        }
        sq[Cube.seql++] = ((m * 6 + sa) * 4 + q);
      }
    }
  }

  private static scramble(): void {
    let i: number;
    let tl = Cube.size;
    if (Cube.mult || (Cube.size & 1) != 0) {
      tl--;
    }
    const axsl: number[] = new Array<number>(tl).fill(0);
    const axam: number[] = [0, 0, 0];
    let la = -1;
    Cube.seq = new Array<number>(Cube.seqLen).fill(0);
    Cube.seql = 0;
    let moved = 0;
    while (Cube.seql + moved < Cube.seqLen) {
      let ax: number;
      let sl: number;
      let q: number;
      do {
        do {
          ax = Math.floor(Math.random() * 3);
          sl = Math.floor(Math.random() * tl);
          q = Math.floor(Math.random() * 3);
        } while (ax == la && axsl[sl] != 0);
      } while (ax == la
        && !Cube.mult
        && tl == Cube.size
        && (2 * axam[0] == tl ||
          2 * axam[1] == tl ||
          2 * axam[2] == tl ||
          (2 * (axam[q] + 1) == tl
            && axam[0] + axam[1] + axam[2] - axam[q] > 0
          )
        )
      );
      if (ax != la) {
        Cube.appendmoves(Cube.seq, axsl, tl, la);
        for (i = 0; i < tl; i++) {
          axsl[i] = 0;
        }
        axam[0] = 0;
        axam[1] = 0;
        axam[2] = 0;
        moved = 0;
        la = ax;
      }
      axam[q]++;
      moved++;
      axsl[sl] = q + 1;
    }
    Cube.appendmoves(Cube.seq, axsl, tl, la);
  }

  static scramblestring(siz: number, sel: number): string {
    Cube.seqLen = sel;
    Cube.size = siz;
    Cube.scramble();
    let sb = '';
    for (let i = 0; i < Cube.seqLen; i++) {
      if (i != 0) {
        sb += ' ';
      }
      let k = Cube.seq[i] >> 2;
      const j = k % 6;
      k = Math.floor((k - j) / 6);
      if (Cube.size <= 5) {
        sb += 'DLBURF'.charAt(j);
        if (k > 0) {
          sb += 'w';
        }
      } else {
        if (k > 0) {
          sb += (k + 1).toString();
        }
        sb += 'DLBURF'.charAt(j);
      }
      const q = Cube.seq[i] & 3;
      if (q != 0) {
        sb += " 2'".charAt(q);
      }
    }
    return sb;
  }

  static image(scramble: string, size: number): number[] {
    Cube.size = size;
    switch (size) {
      case 3:
        scramble = scramble.replace("M'", "r R'").replace('M2', 'r2 R2').replace('M', "r' R")
          .replace("x'", "r' L").replace('x2', 'r2 L2').replace('x', "r L'")
          .replace("y'", "u' D").replace('y2', 'u2 D2').replace('y', "u D'")
          .replace("z'", "f' B").replace('z2', 'f2 B2').replace('z', "f B'");
        break;
      case 4:
        scramble = scramble.replace("x'", "r' l").replace('x2', 'r2 l2').replace('x', "r l'")
          .replace("y'", "u' d").replace('y2', 'u2 d2').replace('y', "u d'")
          .replace("z'", "f' b").replace('z2', 'f2 b2').replace('z', "f b'");
        break;
      case 6:
      case 7:
        break;
    }
    const s = scramble.split(' ');
    const len = s.length;
    if (len > 0) {
      Cube.seq = new Array<number>(len).fill(0);
      let count = 0;
      for (let i = 0; i < len; i++) {
        let k = 0;
        if (s[i].length > 0) {
          switch (s[i].charAt(0)) {
            case '5': k = 4; break;
            case '4': k = 3; break;
            case '3': k = 2; break;
            case '2': k = 1; break;
            case 'R': Cube.seq[count] = 16; break;
            case 'L': Cube.seq[count] = 4; break;
            case 'U': Cube.seq[count] = 12; break;
            case 'D': Cube.seq[count] = 0; break;
            case 'F': Cube.seq[count] = 20; break;
            case 'B': Cube.seq[count] = 8; break;
            case 'r': Cube.seq[count] = 16; k = 1; break;
            case 'l': Cube.seq[count] = 4; k = 1; break;
            case 'u': Cube.seq[count] = 12; k = 1; break;
            case 'd': Cube.seq[count] = 0; k = 1; break;
            case 'f': Cube.seq[count] = 20; k = 1; break;
            case 'b': Cube.seq[count] = 8; k = 1; break;
          }
          if (s[i].includes('top') || s[i].includes('顶') || s[i].includes('頂')) {
            Cube.seq[count] = 12;
          }
          if (s[i].includes('bottom') || s[i].includes('底')) {
            Cube.seq[count] = 0;
          }
          if (s[i].includes('left') || s[i].includes('左')) {
            Cube.seq[count] = 4;
          }
          if (s[i].includes('right') || s[i].includes('右')) {
            Cube.seq[count] = 16;
          }
          if (s[i].includes('front') || s[i].includes('前')) {
            Cube.seq[count] = 20;
          }
          if (s[i].includes('back') || s[i].includes('后') || s[i].includes('後')) {
            Cube.seq[count] = 8;
          }
          if (s[i].includes('180 deg') || s[i].includes('180度')) {
            Cube.seq[count]++;
          } else if (s[i].includes('counter') || s[i].includes('逆')) {
            Cube.seq[count] += 2;
          }
          if (s[i].length > 1) {
            switch (s[i].charCodeAt(1)) {
              case 0x27: Cube.seq[count] += 2; break;
              case 0x32: Cube.seq[count]++; break;
              case CH_B3: k = 2; break;
              case CH_B2: k = 1; break;
              case 0x77: Cube.seq[count] += 24; break;
              case 0x72:
              case 0x52: Cube.seq[count] = 16; break;
              case 0x6c:
              case 0x4c: Cube.seq[count] = 4; break;
              case 0x75:
              case 0x55: Cube.seq[count] = 12; break;
              case 0x64:
              case 0x44: Cube.seq[count] = 0; break;
              case 0x66:
              case 0x46: Cube.seq[count] = 20; break;
              case 0x62:
              case 0x42: Cube.seq[count] = 8; break;
            }
            if (s[i].length > 2) {
              switch (s[i].charCodeAt(2)) {
                case 0x27: Cube.seq[count] += 2; break;
                case 0x32: Cube.seq[count]++; break;
              }
              if (s[i].length > 3) {
                switch (s[i].charCodeAt(3)) {
                  case 0x27: Cube.seq[count] += 2; break;
                  case 0x32: Cube.seq[count]++; break;
                }
              }
            }
          }
          Cube.seq[count++] += k * 24;
        }
      }
    }
    return Cube.imageFromSeq();
  }

  static imageFromSeq(): number[] {
    const size = Cube.size;
    Cube.img = new Array<number>(size * size * 6).fill(0);
    Cube.posit = new Array<number>(size * size * 6).fill(0);
    let i: number;
    let l = 0;
    let f: number;
    let q: number;
    let d = 0;
    for (i = 0; i < 6; i++) {
      for (f = 0; f < size * size; f++) {
        Cube.posit[d++] = i;
      }
    }
    for (i = 0; i < Cube.seq.length; i++) {
      q = Cube.seq[i] & 3;
      f = Cube.seq[i] >> 2;
      d = 0;
      while (f > 5) {
        f -= 6;
        d++;
      }
      do {
        Cube.doslice(f, d, q + 1);
        d--;
      } while (Cube.mult && d >= 0);
    }
    const flat2posit: number[] = new Array<number>(12 * size * size).fill(-1);
    for (i = 0; i < size; i++) {
      for (let j = 0; j < size; j++) {
        flat2posit[4 * size * (3 * size - i - 1) + size + j] = i * size + j; // D
        flat2posit[4 * size * (size + i) + size - j - 1] = (size + i) * size + j; // L
        flat2posit[4 * size * (size + i) + 4 * size - j - 1] = (2 * size + i) * size + j; // B
        flat2posit[4 * size * i + size + j] = (3 * size + i) * size + j; // U
        flat2posit[4 * size * (size + i) + 2 * size + j] = (4 * size + i) * size + j; // R
        flat2posit[4 * size * (size + i) + size + j] = (5 * size + i) * size + j; // F
      }
    }
    d = 0;
    for (i = 0; i < 3 * size; i++) {
      for (f = 0; f < 4 * size; f++) {
        if (flat2posit[d] >= 0) {
          const c = Cube.colorPerm[Cube.posit[flat2posit[d]]];
          Cube.img[l++] = Cube.colors[c];
        }
        d++;
      }
    }
    return Cube.img;
  }

  private static doslice(f: number, d: number, q: number): void {
    const size = Cube.size;
    let f1 = 0;
    let f2 = 0;
    let f3 = 0;
    let f4 = 0;
    const s2 = size * size;
    let i: number;
    let j: number;
    let k: number;
    let c: number;
    if (f > 5) {
      f -= 6;
    }
    for (k = 0; k < q; k++) {
      for (i = 0; i < size; i++) {
        if (f == 0) {
          f1 = 6 * s2 - size * d - size + i;
          f2 = 2 * s2 - size * d - 1 - i;
          f3 = 3 * s2 - size * d - 1 - i;
          f4 = 5 * s2 - size * d - size + i;
        } else if (f == 1) {
          f1 = 3 * s2 + d + size * i;
          f2 = 3 * s2 + d - size * (i + 1);
          f3 = s2 + d - size * (i + 1);
          f4 = 5 * s2 + d + size * i;
        } else if (f == 2) {
          f1 = 3 * s2 + d * size + i;
          f2 = 4 * s2 + size - 1 - d + size * i;
          f3 = d * size + size - 1 - i;
          f4 = 2 * s2 - 1 - d - size * i;
        } else if (f == 3) {
          f1 = 4 * s2 + d * size + size - 1 - i;
          f2 = 2 * s2 + d * size + i;
          f3 = s2 + d * size + i;
          f4 = 5 * s2 + d * size + size - 1 - i;
        } else if (f == 4) {
          f1 = 6 * s2 - 1 - d - size * i;
          f2 = size - 1 - d + size * i;
          f3 = 2 * s2 + size - 1 - d + size * i;
          f4 = 4 * s2 - 1 - d - size * i;
        } else if (f == 5) {
          f1 = 4 * s2 - size - d * size + i;
          f2 = 2 * s2 - size + d - size * i;
          f3 = s2 - 1 - d * size - i;
          f4 = 4 * s2 + d + size * i;
        }
        c = Cube.posit[f1];
        Cube.posit[f1] = Cube.posit[f2];
        Cube.posit[f2] = Cube.posit[f3];
        Cube.posit[f3] = Cube.posit[f4];
        Cube.posit[f4] = c;
      }
      if (d == 0) {
        for (i = 0; i + i < size; i++) {
          for (j = 0; j + j < size - 1; j++) {
            f1 = f * s2 + i + j * size;
            f3 = f * s2 + (size - 1 - i) + (size - 1 - j) * size;
            if (f < 3) {
              f2 = f * s2 + (size - 1 - j) + i * size;
              f4 = f * s2 + j + (size - 1 - i) * size;
            } else {
              f4 = f * s2 + (size - 1 - j) + i * size;
              f2 = f * s2 + j + (size - 1 - i) * size;
            }
            c = Cube.posit[f1];
            Cube.posit[f1] = Cube.posit[f2];
            Cube.posit[f2] = Cube.posit[f3];
            Cube.posit[f3] = Cube.posit[f4];
            Cube.posit[f4] = c;
          }
        }
      }
    }
  }
}
