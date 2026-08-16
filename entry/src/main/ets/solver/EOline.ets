// Ported from solver/EOline.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';
import { Cross } from './Cross';

export class EOline {
  private static eom: number[][] = EOline.z2d(2048, 6);
  private static epm: number[][] = EOline.z2d(132, 6);
  private static eod: number[] = new Array<number>(2048).fill(0);
  private static epd: number[] = new Array<number>(132).fill(0);
  private static seq: number[] = new Array<number>(10).fill(0);

  static sideStr: string[] = ['DF DB', 'DL DR', 'UF UB', 'UL UR',
    'LF LB', 'LU LD', 'RF RB', 'RU RD', 'FU FD', 'FL FR', 'BU BD', 'BL BR'];
  static moveStr: string[] = ['UDLRFB', 'UDFBRL', 'DURLFB', 'DUFBLR',
    'RLUDFB', 'RLFBDU', 'LRDUFB', 'LRFBUD', 'BFLRUD', 'BFUDRL', 'FBLRDU', 'FBDURL'];
  static rotateStr: string[] = ['', 'y', 'z2', 'z2 y', "z'", "z' y", 'z', 'z y', "x'", "x' y", 'x', 'x y'];

  static inited = false;

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  static init(): void {
    if (EOline.inited) {
      return;
    }
    const arr: number[] = new Array<number>(12).fill(0);
    for (let i = 0; i < 2048; i++) {
      for (let j = 0; j < 6; j++) {
        Utils.idxToFlip(arr, i, 12, true);
        Cross.edgemv(arr, j);
        EOline.eom[i][j] = Utils.flipToIdx(arr, 12, true);
      }
    }
    for (let i = 0; i < 66; i++) {
      for (let j = 0; j < 2; j++) {
        for (let k = 0; k < 6; k++) {
          EOline.epm[i * 2 + j][k] = EOline.getEpm(i, j, k);
        }
      }
    }
    for (let i = 1; i < 2048; i++) {
      EOline.eod[i] = -1;
    }
    EOline.eod[0] = 0;
    Utils.createPrun(EOline.eod, 7, EOline.eom, 3);
    for (let i = 0; i < 132; i++) {
      EOline.epd[i] = -1;
    }
    EOline.epd[106] = 0;
    Utils.createPrun(EOline.epd, 4, EOline.epm, 3);
    EOline.inited = true;
  }

  private static getEpm(eci: number, epi: number, k: number): number {
    const combination: number[] = new Array<number>(12).fill(0);
    Utils.idxToComb(combination, eci, 2, 12);
    const permutation: number[] = new Array<number>(2).fill(0);
    Utils.idxToPerm(permutation, epi, 2, false);
    const selectedEdges: number[] = [8, 10];
    let next = 0;
    const ep: number[] = [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1];
    for (let i = 0; i < 12; i++) {
      if (combination[i] != 0) {
        ep[i] = selectedEdges[permutation[next++]];
      }
    }
    switch (k) {
      case 0: Utils.circle(ep, 4, 7, 6, 5); break;
      case 1: Utils.circle(ep, 8, 9, 10, 11); break;
      case 2: Utils.circle(ep, 7, 3, 11, 2); break;
      case 3: Utils.circle(ep, 5, 1, 9, 0); break;
      case 4: Utils.circle(ep, 6, 2, 10, 1); break;
      case 5: Utils.circle(ep, 4, 0, 8, 3); break;
    }
    const edgesMapping: number[] = [0, 1, 2, 3];
    const ec: number[] = new Array<number>(12).fill(0);
    for (let i = 0; i < 12; i++) {
      ec[i] = ep[i] > 0 ? 1 : 0;
    }
    const eci2 = Utils.combToIdx(ec, 2, 12);
    const edgesPermutation: number[] = new Array<number>(2).fill(0);
    next = 0;
    for (let i = 0; i < 12; i++) {
      if (ec[i] != 0) {
        edgesPermutation[next++] = ep[i] > -1 ? edgesMapping[ep[i] - 8] : -1;
      }
    }
    const epi2 = Utils.permToIdx(edgesPermutation, 2, false);
    return eci2 * 2 + epi2;
  }

  private static search(eo: number, ep: number, depth: number, l: number): boolean {
    if (depth == 0) {
      return eo == 0 && ep == 106;
    }
    if (EOline.eod[eo] > depth || EOline.epd[ep] > depth) {
      return false;
    }
    for (let i = 0; i < 6; i++) {
      if (i != l) {
        let x = eo;
        let y = ep;
        for (let j = 0; j < 3; j++) {
          x = EOline.eom[x][i];
          y = EOline.epm[y][i];
          if (EOline.search(x, y, depth - 1, i)) {
            EOline.seq[depth] = i * 3 + j;
            return true;
          }
        }
      }
    }
    return false;
  }

  private static eoline(scramble: string, face: number): string {
    const s = scramble.split(' ');
    let ep = 106;
    let eo = 0;
    for (let d = 0; d < s.length; d++) {
      if (s[d].length > 0) {
        const o = EOline.moveStr[face].indexOf(s[d].charAt(0));
        ep = EOline.epm[ep][o];
        eo = EOline.eom[eo][o];
        if (s[d].length > 1) {
          eo = EOline.eom[eo][o];
          ep = EOline.epm[ep][o];
          if (s[d].charAt(1) == "'") {
            eo = EOline.eom[eo][o];
            ep = EOline.epm[ep][o];
          }
        }
      }
    }
    for (let d = 0; d < 10; d++) {
      if (EOline.search(eo, ep, d, -1)) {
        let sb = '';
        for (let j = d; j > 0; j--) {
          sb += ' ' + Utils.turn[Math.floor(EOline.seq[j] / 3)] + Utils.suff[EOline.seq[j] % 3];
        }
        return '\n' + EOline.sideStr[face] + ': ' + EOline.rotateStr[face] + sb;
      }
    }
    return '\nerror';
  }

  static solveEoline(scramble: string, face: number): string {
    EOline.init();
    let sb = '\n';
    for (let i = 0; i < 6; i++) {
      if (((face >> i) & 1) != 0) {
        sb += EOline.eoline(scramble, i * 2) + EOline.eoline(scramble, i * 2 + 1);
      }
    }
    return sb;
  }
}
