export class PyraminxImage {
  private static readonly COLORS: string[] = [
    '#FF0000',
    '#009900',
    '#0000FF',
    '#FFFF00'
  ];

  private static colmap: number[] = [];

  private static circle3(arr: number[], a: number, b: number, c: number): void {
    const t: number = arr[a];
    arr[a] = arr[b];
    arr[b] = arr[c];
    arr[c] = t;
  }

  private static rotate3(v1: number, v2: number, v3: number, clockwise: number): void {
    if (clockwise === 2) {
      PyraminxImage.circle3(PyraminxImage.colmap, v3, v2, v1);
    } else {
      PyraminxImage.circle3(PyraminxImage.colmap, v1, v2, v3);
    }
  }

  private static picmove(type: number, dir: number): void {
    if (type === 0) {
      PyraminxImage.rotate3(14, 58, 18, dir);
      PyraminxImage.rotate3(15, 57, 31, dir);
      PyraminxImage.rotate3(16, 70, 32, dir);
      PyraminxImage.rotate3(30, 28, 56, dir);
    } else if (type === 4) {
      PyraminxImage.rotate3(30, 28, 56, dir);
    } else if (type === 1) {
      PyraminxImage.rotate3(32, 72, 22, dir);
      PyraminxImage.rotate3(33, 59, 23, dir);
      PyraminxImage.rotate3(20, 58, 24, dir);
      PyraminxImage.rotate3(34, 60, 36, dir);
    } else if (type === 5) {
      PyraminxImage.rotate3(34, 60, 36, dir);
    } else if (type === 2) {
      PyraminxImage.rotate3(14, 10, 72, dir);
      PyraminxImage.rotate3(1, 11, 71, dir);
      PyraminxImage.rotate3(2, 24, 70, dir);
      PyraminxImage.rotate3(0, 12, 84, dir);
    } else if (type === 6) {
      PyraminxImage.rotate3(0, 12, 84, dir);
    } else if (type === 3) {
      PyraminxImage.rotate3(2, 18, 22, dir);
      PyraminxImage.rotate3(3, 19, 9, dir);
      PyraminxImage.rotate3(16, 20, 10, dir);
      PyraminxImage.rotate3(4, 6, 8, dir);
    } else if (type === 7) {
      PyraminxImage.rotate3(4, 6, 8, dir);
    }
  }

  static image(scramble: string): number[] {
    PyraminxImage.colmap = [
      1, 1, 1, 1, 1, 0, 2, 0, 3, 3, 3, 3, 3,
      0, 1, 1, 1, 0, 2, 2, 2, 0, 3, 3, 3, 0,
      0, 0, 1, 0, 2, 2, 2, 2, 2, 0, 3, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 4, 4, 4, 4, 4, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 4, 4, 4, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0
    ];

    const faces: string = 'LRBUlrbu';
    const tokens: string[] = scramble.split(' ');
    for (let i: number = 0; i < tokens.length; i++) {
      const t: string = tokens[i];
      if (t.length === 0) continue;
      const turn: number = faces.indexOf(t.charAt(0));
      if (turn < 0) continue;
      PyraminxImage.picmove(turn, t.length);
    }

    const img: number[] = [];
    for (let i: number = 0; i < PyraminxImage.colmap.length; i++) {
      img.push(PyraminxImage.colmap[i] - 1);
    }
    return img;
  }

  static getColors(): string[] {
    return PyraminxImage.COLORS;
  }
}
