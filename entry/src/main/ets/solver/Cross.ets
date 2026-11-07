// Ported from solver/Cross.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';
import { EOline } from './EOline';

export class Cross {
  private static epm: number[][] = Cross.z2d(11880, 6);
  private static eom: number[][] = Cross.z2d(7920, 6);
  private static epd: number[] = new Array<number>(11880).fill(0);
  private static eod: number[] = new Array<number>(7920).fill(0);
  private static eofd: number[] = new Array<number>(7920).fill(0);
  private static ed: number[] = new Array<number>(23760).fill(0);
  private static fcm: number[][] = Cross.z2d(24, 6);
  private static fem: number[][] = Cross.z2d(24, 6);
  private static fecd: number[][] = Cross.z2d(4, 576);
  private static seq: number[] = new Array<number>(20).fill(0);
  private static solutions: string[] = [];
  static ini = false;
  static inif = false;
  private static color: string[] = ['D', 'U', 'L', 'R', 'F', 'B'];
  private static moveStr: string[][] = [
    ['UDLRFB', 'DURLFB', 'RLUDFB', 'LRDUFB', 'BFLRUD', 'FBLRDU'],
    ['UDLRFB', 'DURLFB', 'RLUDFB', 'LRDUFB', 'BFRLDU', 'FBRLUD'],
    ['UDLRFB', 'DURLFB', 'RLUDFB', 'LRDUFB', 'BFUDRL', 'FBUDLR'],
    ['UDLRFB', 'DURLFB', 'RLUDFB', 'LRDUFB', 'BFDULR', 'FBDURL'],
    ['UDLRFB', 'DULRBF', 'RLBFUD', 'LRFBUD', 'BFLRUD', 'FBRLUD'],
    ['UDLRFB', 'DULRBF', 'RLFBDU', 'LRBFDU', 'BFRLDU', 'FBLRDU']
  ];
  private static rotateStr: string[][] = [
    ['', 'z2', "z'", 'z', "x'", 'x'], ['z2', '', 'z', "z'", 'x', "x'"],
    ['z', "z'", '', 'z2', 'y', "y'"], ["z'", 'z', 'z2', '', "y'", 'y'],
    ['x', "x'", "y'", 'y', '', 'y2'], ["x'", 'x', 'y', "y'", 'y2', '']
  ];
  private static sideStr: string[] = ['D(FB)', 'D(LR)', 'U(FB)', 'U(LR)',
    'L(FB)', 'L(UD)', 'R(FB)', 'R(UD)', 'F(UD)', 'F(LR)', 'B(UD)', 'B(LR)'];

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  static circle(ary: number[], a: number, b: number, c: number, d: number, ori: number): void {
    const t = ary[a];
    ary[a] = ary[d] ^ ori;
    ary[d] = ary[c] ^ ori;
    ary[c] = ary[b] ^ ori;
    ary[b] = t ^ ori;
  }

  private static idxToComb1(arr: number[], s: number[], c: number, o: number): void {
    let q = 4;
    for (let i = 0; i < 12; i++) {
      if (c >= Utils.Cnk[11 - i][q]) {
        c -= Utils.Cnk[11 - i][q--];
        arr[i] = (s[q] << 1) | (o & 1);
        o >>= 1;
      } else {
        arr[i] = -1;
      }
    }
  }

  private static idxToComb2(arr: number[], s: number[], c: number, o: number, map: number[]): void {
    let q = 4;
    for (let t = 0; t < 12; t++) {
      if (c >= Utils.Cnk[11 - t][q]) {
        c -= Utils.Cnk[11 - t][q--];
        arr[t] = (map[s[q]] << 1) | (o & 1);
        o >>= 1;
      } else {
        arr[t] = -1;
      }
    }
  }

  private static getmv(c: number, po: number, f: number): number {
    const arr: number[] = new Array<number>(12).fill(0);
    const ps: number[] = new Array<number>(4).fill(0);
    Utils.idxToPerm(ps, po, 4, false);
    Cross.idxToComb1(arr, ps, c, po);
    Cross.edgemv(arr, f);
    let c2 = 0;
    let po2 = 0;
    let q = 4;
    for (let t = 0; t < 12; t++) {
      if (arr[t] >= 0) {
        c2 += Utils.Cnk[11 - t][q--];
        ps[q] = arr[t] >> 1;
        po2 |= (arr[t] & 1) << (3 - q);
      }
    }
    const i = Utils.permToIdx(ps, 4, false);
    return ((24 * c2 + i) << 4) | po2;
  }

  static edgemv(arr: number[], m: number): void {
    switch (m) {
      case 0: Cross.circle(arr, 0, 1, 2, 3, 0); break;
      case 1: Cross.circle(arr, 4, 7, 6, 5, 0); break;
      case 2: Cross.circle(arr, 2, 9, 6, 10, 0); break;
      case 3: Cross.circle(arr, 0, 11, 4, 8, 0); break;
      case 4: Cross.circle(arr, 1, 8, 5, 9, 1); break;
      case 5: Cross.circle(arr, 3, 10, 7, 11, 1); break;
    }
  }

  static init(): void {
    if (Cross.ini) {
      return;
    }
    for (let a = 0; a < 495; a++) {
      for (let b = 0; b < 24; b++) {
        for (let c = 0; c < 6; c++) {
          const d = Cross.getmv(a, b, c);
          Cross.epm[24 * a + b][c] = d >> 4;
          if (b < 16) {
            Cross.eom[16 * a + b][c] = (Math.floor(d / 384) << 4) | (d & 15);
          }
        }
      }
    }
    for (let a = 0; a < 11880; a++) {
      Cross.epd[a] = -1;
    }
    Cross.epd[1670] = 0;
    Utils.createPrun(Cross.epd, 6, Cross.epm, 3);
    for (let a = 0; a < 7920; a++) {
      Cross.eod[a] = -1;
      Cross.eofd[a] = -1;
    }
    Cross.eod[69 * 16] = 0;
    Utils.createPrun(Cross.eod, 7, Cross.eom, 3);
    for (let a = 0; a < 495; a++) {
      Cross.eofd[a << 4] = 0;
    }
    Utils.createPrun(Cross.eofd, 4, Cross.eom, 3);

    // xcross
    let p: number[][] = [
      [1, 0, 3, 0, 0, 4], [2, 1, 1, 5, 1, 0], [3, 2, 2, 1, 6, 2], [0, 3, 7, 3, 2, 3],
      [4, 7, 0, 4, 4, 5], [5, 4, 5, 6, 5, 1], [6, 5, 6, 2, 7, 6], [7, 6, 4, 7, 3, 7]
    ];
    let o: number[][] = [
      [0, 0, 1, 0, 0, 2], [0, 0, 0, 2, 0, 1], [0, 0, 0, 1, 2, 0], [0, 0, 2, 0, 1, 0],
      [0, 0, 2, 0, 0, 1], [0, 0, 0, 1, 0, 2], [0, 0, 0, 2, 1, 0], [0, 0, 1, 0, 2, 0]
    ];
    for (let a = 0; a < 8; a++) {
      for (let b = 0; b < 3; b++) {
        for (let c = 0; c < 6; c++) {
          Cross.fcm[a * 3 + b][c] = p[a][c] * 3 + ((o[a][c] + b) % 3);
        }
      }
    }
    p = [
      [0, 0, 7, 0, 0, 8], [1, 1, 1, 9, 1, 4], [2, 2, 2, 5, 10, 2], [3, 3, 11, 3, 6, 3],
      [5, 4, 4, 4, 4, 0], [6, 5, 5, 1, 5, 5], [7, 6, 6, 6, 2, 6], [4, 7, 3, 7, 7, 7],
      [8, 11, 8, 8, 8, 1], [9, 8, 9, 2, 9, 9], [10, 9, 10, 10, 3, 10], [11, 10, 0, 11, 11, 11]
    ];
    o = [
      [0, 0, 0, 0, 0, 1], [0, 0, 0, 0, 0, 1], [0, 0, 0, 0, 1, 0], [0, 0, 0, 0, 1, 0],
      [0, 0, 0, 0, 0, 1], [0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 1, 0], [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 1], [0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 1, 0], [0, 0, 0, 0, 0, 0]
    ];
    for (let a = 0; a < 12; a++) {
      for (let b = 0; b < 2; b++) {
        for (let c = 0; c < 6; c++) {
          Cross.fem[a * 2 + b][c] = p[a][c] * 2 + ((o[a][c] ^ b) | 0);
        }
      }
    }
    for (let f = 0; f < 4; f++) {
      for (let a = 0; a < 576; a++) {
        Cross.fecd[f][a] = -1;
      }
      Cross.fecd[f][f * 51 + 12] = 0;
      for (let d = 0; d < 6; d++) {
        for (let a = 0; a < 576; a++) {
          if (Cross.fecd[f][a] == d) {
            for (let b = 0; b < 6; b++) {
              let e = a;
              for (let c = 0; c < 3; c++) {
                e = 24 * Cross.fem[Math.floor(e / 24)][b] + Cross.fcm[e % 24][b];
                if (Cross.fecd[f][e] == -1) {
                  Cross.fecd[f][e] = d + 1;
                }
              }
            }
          }
        }
      }
    }
    Cross.ini = true;
  }

  private static idacross(ep: number, eo: number, d: number, lm: number): boolean {
    if (d == 0) {
      return ep == 1670 && eo == 1104;
    }
    if (Cross.epd[ep] > d || Cross.eod[eo] > d) {
      return false;
    }
    for (let i = 0; i < 6; i++) {
      if (i != lm) {
        let epx = ep;
        let eox = eo;
        for (let j = 0; j < 3; j++) {
          epx = Cross.epm[epx][i];
          eox = Cross.eom[eox][i];
          if (Cross.idacross(epx, eox, d - 1, i)) {
            Cross.seq[d] = i * 3 + j;
            return true;
          }
        }
      }
    }
    return false;
  }

  private static idacrossPath(ep: number, eo: number, d: number, lm: number, face: number, path: number[]): void {
    if (d == 0) {
      if (ep == 1670 && eo == 1104) {
        let sb = Cross.rotateStr[0][face];
        let qtm = 0;
        for (let i = path.length - 1; i > 0; i--) {
          sb += ' ' + Cross.moveStr[0][0].charAt(Math.floor(path[i] / 3)) + Utils.suff[path[i] % 3];
          if (path[i] % 3 == 1) {
            qtm += 2;
          } else {
            qtm++;
          }
        }
        sb += '\t' + (path.length - 1) + 'f, ' + qtm + 'q';
        Cross.solutions.push(sb);
      }
      return;
    }
    if (Cross.epd[ep] > d || Cross.eod[eo] > d) {
      return;
    }
    for (let i = 0; i < 6; i++) {
      if (i != lm && !(Math.floor(i / 2) == Math.floor(lm / 2) && i < lm)) {
        let epx = ep;
        let eox = eo;
        for (let j = 0; j < 3; j++) {
          epx = Cross.epm[epx][i];
          eox = Cross.eom[eox][i];
          path[d] = i * 3 + j;
          Cross.idacrossPath(epx, eox, d - 1, i, face, path);
        }
      }
    }
  }

  private static idaeofc(ep: number, eo: number, eof: number, d: number, lm: number): boolean {
    if (d == 0) {
      return ep == 1670 && eo == 1104 && (eof & 15) == 0;
    }
    if (Cross.epd[ep] > d || Cross.eod[eo] > d || Cross.eofd[eof] > d) {
      return false;
    }
    for (let i = 0; i < 6; i++) {
      if (i != lm) {
        let epx = ep;
        let eox = eo;
        let eofx = eof;
        for (let j = 0; j < 3; j++) {
          epx = Cross.epm[epx][i];
          eox = Cross.eom[eox][i];
          eofx = Cross.eom[eofx][i];
          if (Cross.idaeofc(epx, eox, eofx, d - 1, i)) {
            Cross.seq[d] = i * 3 + j;
            return true;
          }
        }
      }
    }
    return false;
  }

  private static idaxcross(ep: number, eo: number, co: number, feo: number, slot: number, d: number,
    lm: number): boolean {
    if (d == 0) {
      return ep == 1670 && eo == 1104 && co == (slot + 4) * 3 && feo == slot * 2;
    }
    if (Cross.epd[ep] > d || Cross.eod[eo] > d || Cross.fecd[slot][feo * 24 + co] > d) {
      return false;
    }
    for (let i = 0; i < 6; i++) {
      if (i != lm) {
        let cox = co;
        let epx = ep;
        let eox = eo;
        let fx = feo;
        for (let j = 0; j < 3; j++) {
          cox = Cross.fcm[cox][i];
          fx = Cross.fem[fx][i];
          epx = Cross.epm[epx][i];
          eox = Cross.eom[eox][i];
          if (Cross.idaxcross(epx, eox, cox, fx, slot, d - 1, i)) {
            Cross.seq[d] = i * 3 + j;
            return true;
          }
        }
      }
    }
    return false;
  }

  private static idaxcrossPath(ep: number, eo: number, co: number, feo: number, slot: number, d: number,
    lm: number, face: number, path: number[]): void {
    if (d == 0) {
      if (ep == 1670 && eo == 1104 && co == (slot + 4) * 3 && feo == slot * 2) {
        let sb = Cross.rotateStr[0][face];
        let qtm = 0;
        for (let i = path.length - 1; i > 0; i--) {
          sb += ' ' + Cross.moveStr[0][0].charAt(Math.floor(path[i] / 3)) + Utils.suff[path[i] % 3];
          if (path[i] % 3 == 1) {
            qtm += 2;
          } else {
            qtm++;
          }
        }
        sb += '\t' + (path.length - 1) + 'f, ' + qtm + 'q';
        Cross.solutions.push(sb);
      }
      return;
    }
    if (Cross.epd[ep] > d || Cross.eod[eo] > d || Cross.fecd[slot][feo * 24 + co] > d) {
      return;
    }
    for (let i = 0; i < 6; i++) {
      if (i != lm && !(Math.floor(i / 2) == Math.floor(lm / 2) && i < lm)) {
        let cox = co;
        let epx = ep;
        let eox = eo;
        let fx = feo;
        for (let j = 0; j < 3; j++) {
          cox = Cross.fcm[cox][i];
          fx = Cross.fem[fx][i];
          epx = Cross.epm[epx][i];
          eox = Cross.eom[eox][i];
          path[d] = i * 3 + j;
          Cross.idaxcrossPath(epx, eox, cox, fx, slot, d - 1, i, face, path);
        }
      }
    }
  }

  private static cross(scramble: string, side: number, face: number): string {
    const s = scramble.split(' ');
    let ep = 1670;
    let eo = 1104;
    for (let i = 0; i < s.length; i++) {
      if (s[i].length != 0) {
        const m = Cross.moveStr[side][face].indexOf(s[i].charAt(0));
        eo = Cross.eom[eo][m];
        ep = Cross.epm[ep][m];
        if (s[i].length > 1) {
          eo = Cross.eom[eo][m];
          ep = Cross.epm[ep][m];
          if (s[i].charAt(1) == "'") {
            eo = Cross.eom[eo][m];
            ep = Cross.epm[ep][m];
          }
        }
      }
    }
    for (let d = 0; d < 9; d++) {
      if (Cross.idacross(ep, eo, d, -1)) {
        let sb = Cross.rotateStr[side][face];
        for (let i = d; i > 0; i--) {
          sb += ' ' + Cross.moveStr[0][side].charAt(Math.floor(Cross.seq[i] / 3)) + Utils.suff[Cross.seq[i] % 3];
        }
        return sb;
      }
    }
    return 'error';
  }

  static solveCross(scramble: string, face: number): string {
    Cross.init();
    let sb = '\n';
    for (let i = 0; i < 6; i++) {
      if (((face >> i) & 1) != 0) {
        sb += '\nCross(' + Cross.color[i] + '): ' + Cross.cross(scramble, 0, i);
      }
    }
    return sb;
  }

  static solveCrossAll(scramble: string): string {
    Cross.init();
    let sb = '';
    for (let face = 0; face < 6; face++) {
      sb += Cross.color[face] + ': ' + Cross.cross(scramble, 0, face) + '\n';
    }
    return sb;
  }

  static solveCrossf(scramble: string): string {
    Cross.init();
    const s = scramble.split(' ');
    let sb = '';
    for (let face = 0; face < 6; face++) {
      let ep = 1670;
      let eo = 1104;
      for (let i = 0; i < s.length; i++) {
        if (s[i].length != 0) {
          const m = Cross.moveStr[0][face].indexOf(s[i].charAt(0));
          eo = Cross.eom[eo][m];
          ep = Cross.epm[ep][m];
          if (s[i].length > 1) {
            eo = Cross.eom[eo][m];
            ep = Cross.epm[ep][m];
            if (s[i].charAt(1) == "'") {
              eo = Cross.eom[eo][m];
              ep = Cross.epm[ep][m];
            }
          }
        }
      }
      Cross.solutions = [];
      for (let d = 0; d < 9; d++) {
        const path: number[] = new Array<number>(d + 1).fill(0);
        Cross.idacrossPath(ep, eo, d, -1, face, path);
        if (Cross.solutions.length > 0) {
          sb += Cross.color[face] + ':\n';
          for (const sol of Cross.solutions) {
            const idx = sol.indexOf('\t');
            sb += '  ' + sol.substring(0, idx) + '\n';
          }
          sb += '\n';
          break;
        }
      }
    }
    return sb;
  }

  private static xcross(scramble: string, face: number): string {
    const s = scramble.split(' ');
    const co: number[] = new Array<number>(4).fill(0);
    const feo: number[] = new Array<number>(4).fill(0);
    for (let i = 0; i < 4; i++) {
      co[i] = (i + 4) * 3;
      feo[i] = i * 2;
    }
    let ep = 1670;
    let eo = 1104;
    for (let d = 0; d < s.length; d++) {
      if (s[d].length != 0) {
        const m = Cross.moveStr[0][face].indexOf(s[d].charAt(0));
        for (let i = 0; i < 4; i++) {
          co[i] = Cross.fcm[co[i]][m];
          feo[i] = Cross.fem[feo[i]][m];
        }
        ep = Cross.epm[ep][m];
        eo = Cross.eom[eo][m];
        if (s[d].length > 1) {
          for (let i = 0; i < 4; i++) {
            co[i] = Cross.fcm[co[i]][m];
            feo[i] = Cross.fem[feo[i]][m];
          }
          eo = Cross.eom[eo][m];
          ep = Cross.epm[ep][m];
          if (s[d].charAt(1) == "'") {
            for (let i = 0; i < 4; i++) {
              co[i] = Cross.fcm[co[i]][m];
              feo[i] = Cross.fem[feo[i]][m];
            }
            eo = Cross.eom[eo][m];
            ep = Cross.epm[ep][m];
          }
        }
      }
    }
    for (let d = 0; d < 11; d++) {
      for (let slot = 0; slot < 4; slot++) {
        if (Cross.idaxcross(ep, eo, co[slot], feo[slot], slot, d, -1)) {
          let sb = Cross.rotateStr[0][face];
          for (let i = d; i > 0; i--) {
            sb += ' ' + Cross.moveStr[0][0].charAt(Math.floor(Cross.seq[i] / 3)) + Utils.suff[Cross.seq[i] % 3];
          }
          return sb;
        }
      }
    }
    return 'error';
  }

  static solveXcross(scramble: string, face: number): string {
    Cross.init();
    let sb = '\n';
    for (let i = 0; i < 6; i++) {
      if (((face >> i) & 1) != 0) {
        sb += '\nXCross(' + Cross.color[i] + '): ' + Cross.xcross(scramble, i);
      }
    }
    return sb;
  }

  static solveXcrossAll(scramble: string): string {
    Cross.init();
    let sb = '';
    for (let face = 0; face < 6; face++) {
      sb += Cross.color[face] + ': ' + Cross.xcross(scramble, face) + '\n';
    }
    return sb;
  }

  static solveXcrossf(scramble: string): string {
    Cross.init();
    const s = scramble.split(' ');
    let sb = '';
    for (let face = 0; face < 6; face++) {
      const co: number[] = new Array<number>(4).fill(0);
      const feo: number[] = new Array<number>(4).fill(0);
      for (let i = 0; i < 4; i++) {
        co[i] = (i + 4) * 3;
        feo[i] = i * 2;
      }
      let ep = 1670;
      let eo = 1104;
      for (let d = 0; d < s.length; d++) {
        if (s[d].length != 0) {
          const m = Cross.moveStr[0][face].indexOf(s[d].charAt(0));
          for (let i = 0; i < 4; i++) {
            co[i] = Cross.fcm[co[i]][m];
            feo[i] = Cross.fem[feo[i]][m];
          }
          ep = Cross.epm[ep][m];
          eo = Cross.eom[eo][m];
          if (s[d].length > 1) {
            for (let i = 0; i < 4; i++) {
              co[i] = Cross.fcm[co[i]][m];
              feo[i] = Cross.fem[feo[i]][m];
            }
            eo = Cross.eom[eo][m];
            ep = Cross.epm[ep][m];
            if (s[d].charAt(1) == "'") {
              for (let i = 0; i < 4; i++) {
                co[i] = Cross.fcm[co[i]][m];
                feo[i] = Cross.fem[feo[i]][m];
              }
              eo = Cross.eom[eo][m];
              ep = Cross.epm[ep][m];
            }
          }
        }
      }
      Cross.solutions = [];
      for (let d = 0; d < 11; d++) {
        for (let slot = 0; slot < 4; slot++) {
          const path: number[] = new Array<number>(d + 1).fill(0);
          Cross.idaxcrossPath(ep, eo, co[slot], feo[slot], slot, d, -1, face, path);
        }
        if (Cross.solutions.length > 0) {
          sb += Cross.color[face] + ':\n';
          for (const sol of Cross.solutions) {
            const idx = sol.indexOf('\t');
            sb += '  ' + sol.substring(0, idx) + '\n';
          }
          sb += '\n';
          break;
        }
      }
    }
    return sb;
  }

  static solveEofc(scramble: string, side: number): string {
    Cross.init();
    let sb = '\n';
    for (let i = 0; i < 6; i++) {
      if (((side >> i) & 1) != 0) {
        sb += Cross.eofc(scramble, i * 2) + Cross.eofc(scramble, i * 2 + 1);
      }
    }
    return sb;
  }

  static eofc(scramble: string, side: number): string {
    const s = scramble.split(' ');
    let ep = 1670;
    let eo = 1104;
    let eof = 0;
    for (let i = 0; i < s.length; i++) {
      if (s[i].length != 0) {
        const m = EOline.moveStr[side].indexOf(s[i].charAt(0));
        eo = Cross.eom[eo][m];
        ep = Cross.epm[ep][m];
        eof = Cross.eom[eof][m];
        if (s[i].length > 1) {
          eo = Cross.eom[eo][m];
          ep = Cross.epm[ep][m];
          eof = Cross.eom[eof][m];
          if (s[i].charAt(1) == "'") {
            eo = Cross.eom[eo][m];
            ep = Cross.epm[ep][m];
            eof = Cross.eom[eof][m];
          }
        }
      }
    }
    for (let d = 0; d < 13; d++) {
      if (Cross.idaeofc(ep, eo, eof, d, -1)) {
        let sb = '\n';
        sb += Cross.sideStr[side] + ': ' + EOline.rotateStr[side];
        for (let i = d; i > 0; i--) {
          sb += ' ' + Cross.moveStr[0][0].charAt(Math.floor(Cross.seq[i] / 3)) + Utils.suff[Cross.seq[i] % 3];
        }
        return sb;
      }
    }
    return '\nerror';
  }

  static easyCross(depth: number): number[][] {
    if (!Cross.inif) {
      Cross.init();
      for (let i = 0; i < 23760; i++) {
        Cross.ed[i] = -1;
      }
      Utils.setPruning(Cross.ed, 494 * 384, 0);
      for (let d = 0; d < 8; d++) {
        for (let i = 0; i < 190080; i++) {
          if (Utils.getPruning(Cross.ed, i) == d) {
            for (let m = 0; m < 6; m++) {
              let x = i;
              for (let n = 0; n < 3; n++) {
                const p = Cross.epm[x >> 4][m];
                const o = Cross.eom[(Math.floor(x / 384) << 4) | (x & 15)][m];
                x = (p << 4) | (o & 15);
                if (Utils.getPruning(Cross.ed, x) == 0xf) {
                  Utils.setPruning(Cross.ed, x, d + 1);
                }
              }
            }
          }
        }
      }
      Cross.inif = true;
    }
    let i: number;
    if (depth == 0) {
      i = 494 * 384;
    } else {
      do {
        i = Math.floor(Math.random() * 190080);
      } while (Utils.getPruning(Cross.ed, i) > depth);
    }
    const comb = Math.floor(i / 384);
    const perm = (i >> 4) % 24;
    const ori = i & 15;
    const c: number[] = new Array<number>(12).fill(0);
    const p: number[] = new Array<number>(4).fill(0);
    Utils.idxToPerm(p, perm, 4, false);
    Cross.idxToComb2(c, p, comb, ori, [3, 2, 1, 0]);
    const arr: number[][] = [new Array<number>(12).fill(0), new Array<number>(12).fill(0)];
    for (i = 0; i < 12; i++) {
      if (c[i] < 0) {
        arr[0][i] = -1;
        arr[1][i] = -1;
      } else {
        arr[0][i] = c[i] >> 1;
        arr[1][i] = c[i] & 1;
      }
    }
    return arr;
  }
}
