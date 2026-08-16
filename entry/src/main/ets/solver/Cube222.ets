// Ported from solver/Cube222.java (DCTimer-BLE -> HarmonyOS ArkTS)
import { Utils } from './Utils';

export class Cube222 {
  private static state: number[][] = Cube222.z2d(2, 8);
  private static perm: number[] = new Array<number>(5040).fill(0);
  private static twst: number[] = new Array<number>(729).fill(0);
  private static permmv: number[][] = Cube222.z2d(5040, 3);
  private static twstmv: number[][] = Cube222.z2d(729, 3);

  private static turn: string[] = ['U', 'R', 'F'];
  private static cFacelet: number[][] = [
    [3, 4, 9], [1, 20, 5], [2, 8, 17], [0, 16, 21],
    [13, 11, 6], [15, 7, 22], [12, 19, 10], [14, 23, 18]
  ];
  private static rnd: () => number = Math.random;
  static inited = false;

  private static z2d(r: number, c: number): number[][] {
    const a: number[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<number>(c).fill(0));
    }
    return a;
  }

  static init(): void {
    if (Cube222.inited) {
      return;
    }
    Cube222.calcperm();
    Cube222.inited = true;
  }

  private static permMove(ps: number[], m: number): void {
    switch (m) {
      case 0: Utils.circle(ps, 0, 1, 3, 2); break;	//U
      case 1: Utils.circle(ps, 0, 4, 5, 1); break;	//R
      case 2: Utils.circle(ps, 0, 2, 6, 4); break;	//F
      case 3: Utils.circle(ps, 4, 6, 7, 5); break;	//D
      case 4: Utils.circle(ps, 2, 3, 7, 6); break;	//L
      case 5: Utils.circle(ps, 1, 5, 7, 3); break;	//B
    }
  }

  private static twistMove(ps: number[], m: number): void {
    switch (m) {
      case 0:
        Utils.circle(ps, 0, 1, 3, 2);	//U
        break;
      case 1:
        Utils.circleOri(ps, 0, 4, 5, 1, [2, 1, 2, 1]);   //R
        break;
      case 2:
        Utils.circleOri(ps, 0, 2, 6, 4, [1, 2, 1, 2]);   //F
        break;
      case 3:
        Utils.circle(ps, 4, 6, 7, 5);	//D
        break;
      case 4:
        Utils.circleOri(ps, 2, 3, 7, 6, [1, 2, 1, 2]);   //L
        break;
      case 5:
        Utils.circleOri(ps, 1, 5, 7, 3, [2, 1, 2, 1]);   //B
        break;
    }
  }

  private static doMove(m: number, n: number): void {
    n %= 4;
    if (n > 0) {
      switch (m) {
        case 0:	//U
        case 1:	//R
        case 2:	//F
        case 3:	//D
        case 4:	//L
        case 5:	//B
          for (let i = 0; i < n; i++) {
            Cube222.permMove(Cube222.state[0], m);
            Cube222.twistMove(Cube222.state[1], m);
          }
          break;
        case 6:	//y
        case 7:	//x
        case 8:	//z
          for (let i = 0; i < n; i++) {
            Cube222.permMove(Cube222.state[0], m - 6);
            Cube222.twistMove(Cube222.state[1], m - 6);
          }
          for (let i = 0; i < 4 - n; i++) {
            Cube222.permMove(Cube222.state[0], m - 3);
            Cube222.twistMove(Cube222.state[1], m - 3);
          }
          break;
      }
    }
  }

  private static swap(first: number, second: number): void {
    if (first < 0 || second < 0 || first > 7 || second > 7 || first == second) {
      return;
    }
    //位置交换
    let tmp = Cube222.state[0][first];
    Cube222.state[0][first] = Cube222.state[0][second];
    Cube222.state[0][second] = tmp;
    //色相交换
    tmp = Cube222.state[1][first];
    Cube222.state[1][first] = Cube222.state[1][second];
    Cube222.state[1][second] = tmp;
  }

  private static twist(corner: number, value: number): void {
    if (value < 0) {
      return;
    }
    Cube222.state[1][corner] += value;
  }

  private static reset(): void {
    for (let i = 0; i < 8; i++) {
      Cube222.state[0][i] = i;
      Cube222.state[1][i] = 0;
    }
  }

  private static getprmmv(p: number, m: number): number {
    //given position p<5040 and move m<3, return new position number
    const ps: number[] = new Array<number>(7).fill(0);
    Utils.set8Perm(ps, 7, p);
    Cube222.permMove(ps, m);
    return Utils.get8Perm(ps, 7);
  }

  private static gettwsmv(p: number, m: number): number {
    //given orientation p<729 and move m<3, return new orientation number
    const ps: number[] = new Array<number>(7).fill(0);
    Utils.idxToOri(ps, p, 7, true);
    Cube222.twistMove(ps, m);
    return Utils.oriToIdx(ps, 7, true);
  }

  private static calcperm(): void {
    //calculate solving arrays
    //first permutation
    for (let p = 0; p < 5040; p++) {
      Cube222.perm[p] = -1;
      for (let m = 0; m < 3; m++) {
        Cube222.permmv[p][m] = Cube222.getprmmv(p, m);
      }
    }
    Cube222.perm[0] = 0;
    Utils.createPrun(Cube222.perm, 7, Cube222.permmv, 3);

    //then twist
    for (let p = 0; p < 729; p++) {
      Cube222.twst[p] = -1;
      for (let m = 0; m < 3; m++) {
        Cube222.twstmv[p][m] = Cube222.gettwsmv(p, m);
      }
    }
    Cube222.twst[0] = 0;
    Utils.createPrun(Cube222.twst, 6, Cube222.twstmv, 3);
  }

  private static search(p: number, t: number, l: number, lm: number, seq: number[]): boolean {
    //searches for solution, from position p|t, in l moves exactly. last move was lm, current depth=d
    if (l == 0) {
      return p == 0 && t == 0;
    }
    if (Cube222.perm[p] > l || Cube222.twst[t] > l) {
      return false;
    }
    if (lm == -2) {
      let n = Math.floor(Cube222.rnd() * 9);
      const m = Math.floor(n / 3);
      n %= 3;
      let q = p;
      let s = t;
      for (let a = 0; a <= n; a++) {
        q = Cube222.permmv[q][m];
        s = Cube222.twstmv[s][m];
      }
      if (Cube222.search(q, s, l - 1, m, seq)) {
        seq[l] = m * 3 + n;
        return true;
      }
    } else {
      for (let m = 0; m < 3; m++) {
        if (m != lm) {
          let q = p;
          let s = t;
          for (let a = 0; a < 3; a++) {
            q = Cube222.permmv[q][m];
            s = Cube222.twstmv[s][m];
            if (Cube222.search(q, s, l - 1, m, seq)) {
              seq[l] = m * 3 + a;
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  private static solve(p: number, o: number): string {
    const seq: number[] = new Array<number>(12).fill(0);
    for (let l = 0; l < 12; l++) {
      if (Cube222.search(p, o, l, -1, seq)) {
        if (l < 2) {
          return 'error';
        }
        if (l < 5) {
          continue;
        }
        let sol = '';
        for (let i = 1; i <= l; i++) {
          sol += Cube222.turn[Math.floor(seq[i] / 3)] + Utils.suffInv[seq[i] % 3] + ' ';
        }
        return sol;
      }
    }
    return 'error';
  }

  private static checkNobar(perm: number[], ori: number[]): boolean {
    const ts: number[] = [1, 2, 4, 8, 16, 32];
    const f: number[] = new Array<number>(24).fill(0);
    Utils.fillFacelet(Cube222.cFacelet, f, perm, ori, ts, 4);
    for (let i = 0; i < 24; i += 4) {
      if (((f[i] | f[i + 3]) & (f[i + 1] | f[i + 2])) != 0) {
        return false;
      }
    }
    return true;
  }

  public static randomEG(type: number, olls: string): void {
    Cube222.reset();
    //整体转动
    Cube222.doMove(6, Math.floor(Cube222.rnd() * 4));
    //交换底层2块
    switch (type) {
      case 4:	//不交换
        break;
      case 2:	//交换相邻两块
        Cube222.swap(4, 6);
        break;
      case 1:	//交换相对两块
        Cube222.swap(5, 6);
        break;
      case 6:	//不交换或交换相邻块
        if (Math.floor(Cube222.rnd() * 2) == 1) {
          Cube222.swap(4, 5);
        }
        break;
      case 5:	//不交换或交换相对块
        if (Math.floor(Cube222.rnd() * 2) == 1) {
          Cube222.swap(5, 6);
        }
        break;
      case 3:	//交换任意两块
        Cube222.swap(4 + Math.floor(Cube222.rnd() * 2), 6);
        break;
      default:
        switch (Math.floor(Cube222.rnd() * 3)) {
          case 0:
            break;
          case 1:
            Cube222.swap(4, 6);
            break;
          case 2:
            Cube222.swap(5, 6);
            break;
        }
        break;
    }
    //随机顶层
    for (let i = 0; i < 4; i++) {
      Cube222.swap(i, i + Math.floor(Cube222.rnd() * (4 - i)));
    }
    if (olls == '') {
      Utils.idxToOri(Cube222.state[1], Math.floor(Cube222.rnd() * 27), 4, true);
    } else if (olls == 'X' || olls == 'PHUTLSA') {
      Utils.idxToOri(Cube222.state[1], Math.floor(Cube222.rnd() * 26) + 1, 4, true);
    } else {
      const oll = olls.charAt(Math.floor(Cube222.rnd() * olls.length));
      switch (oll) {
        case 'P':
          Cube222.twist(0, 2); Cube222.twist(1, 1); Cube222.twist(2, 2); Cube222.twist(3, 1);
          break;
        case 'H':
          Cube222.twist(0, 2); Cube222.twist(1, 1); Cube222.twist(2, 1); Cube222.twist(3, 2);
          break;
        case 'U':
          Cube222.twist(2, 2); Cube222.twist(3, 1);
          break;
        case 'T':
          Cube222.twist(2, 1); Cube222.twist(3, 2);
          break;
        case 'L':
          Cube222.twist(0, 2); Cube222.twist(3, 1);
          break;
        case 'S':
          Cube222.twist(0, 2); Cube222.twist(1, 2); Cube222.twist(3, 2);
          break;
        case 'A':
          Cube222.twist(0, 1); Cube222.twist(1, 1); Cube222.twist(2, 1);
          break;
        case 'N':
          break;
      }
    }
    Cube222.doMove(0, Math.floor(Cube222.rnd() * 4));
    //将DBL块放到D层
    while (Cube222.state[0][4] != 7 && Cube222.state[0][5] != 7 && Cube222.state[0][6] != 7 && Cube222.state[0][7] != 7) {
      Cube222.doMove(7, 1);
    }
    //将DBL块放回原位
    while (Cube222.state[0][7] != 7) {
      Cube222.doMove(6, 1);
    }
    //调整DBL块色向
    while (Cube222.state[1][7] % 3 != 0) {
      Cube222.doMove(7, 1);
      Cube222.doMove(6, 1);
    }
  }

  public static randomTEG(type: number, twist: number): void {
    Cube222.reset();
    //整体转动
    Cube222.doMove(6, Math.floor(Cube222.rnd() * 4));
    //交换底层2块
    switch (type) {
      case 4:	//不交换
        break;
      case 2:	//交换相邻两块
        Cube222.swap(4, 6);
        break;
      case 1:	//交换相对两块
        Cube222.swap(5, 6);
        break;
      case 6:	//不交换或交换相邻块
        if (Math.floor(Cube222.rnd() * 2) == 1) {
          Cube222.swap(4, 5);
        }
        break;
      case 5:	//不交换或交换相对块
        if (Math.floor(Cube222.rnd() * 2) == 1) {
          Cube222.swap(5, 6);
        }
        break;
      case 3:	//交换任意两块
        Cube222.swap(4 + Math.floor(Cube222.rnd() * 2), 6);
        break;
      default:
        switch (Math.floor(Cube222.rnd() * 3)) {
          case 0:
            break;
          case 1:
            Cube222.swap(4, 6);
            break;
          case 2:
            Cube222.swap(5, 6);
            break;
        }
        break;
    }
    //随机顶层
    for (let i = 0; i < 4; i++) {
      Cube222.swap(i, i + Math.floor(Cube222.rnd() * (4 - i)));
    }
    Utils.idxToOri(Cube222.state[1], Math.floor(Cube222.rnd() * 27), 4, true);
    //一个底角翻转
    Cube222.twist(4, twist);
    //随机一个顶角翻转
    Cube222.twist(Math.floor(Cube222.rnd() * 4), 3 - twist);
    Cube222.doMove(0, Math.floor(Cube222.rnd() * 4));
    //将DBL块放到D层
    while (Cube222.state[0][4] != 7 && Cube222.state[0][5] != 7 && Cube222.state[0][6] != 7
    && Cube222.state[0][7] != 7) {
      Cube222.doMove(7, 1);
    }
    //将DBL块放回原位
    while (Cube222.state[0][7] != 7) {
      Cube222.doMove(6, 1);
    }
    //调整DBL块色向
    while (Cube222.state[1][7] % 3 != 0) {
      Cube222.doMove(7, 1);
      Cube222.doMove(6, 1);
    }
  }

  public static scramble(): string {
    Cube222.init();
    let scramble: string;
    do {
      const p = Math.floor(Cube222.rnd() * 5040);
      const o = Math.floor(Cube222.rnd() * 729);
      scramble = Cube222.solve(p, o);
    } while (scramble == 'error');
    return scramble;
  }

  public static scrambleEG(type: number): string {
    Cube222.init();
    let scramble: string;
    do {
      switch (type) {
        case 0:
          Cube222.randomEG(4, 'X');
          break;
        case 1:
          Cube222.randomEG(2, 'X');
          break;
        case 2:
          Cube222.randomEG(1, 'X');
          break;
      }
      const p = Utils.get8Perm(Cube222.state[0], 7);
      const o = Utils.oriToIdx(Cube222.state[1], 7, true);
      scramble = Cube222.solve(p, o);
    } while (scramble == 'error');
    return scramble;
  }

  public static scramblePBL(): string {
    Cube222.init();
    let scramble: string;
    do {
      Cube222.randomEG(0, 'N');
      const p = Utils.get8Perm(Cube222.state[0], 7);
      const o = Utils.oriToIdx(Cube222.state[1], 7, true);
      scramble = Cube222.solve(p, o);
    } while (scramble == 'error');
    return scramble;
  }

  public static scrambleTCLL(twist: number): string {
    Cube222.init();
    let scramble: string;
    do {
      Cube222.randomTEG(4, twist);
      const p = Utils.get8Perm(Cube222.state[0], 7);
      const o = Utils.oriToIdx(Cube222.state[1], 7, true);
      scramble = Cube222.solve(p, o);
    } while (scramble == 'error');
    return scramble;
  }

  public static scrambleTEG1(twist: number): string {
    Cube222.init();
    let scramble: string;
    do {
      Cube222.randomTEG(2, twist);
      const p = Utils.get8Perm(Cube222.state[0], 7);
      const o = Utils.oriToIdx(Cube222.state[1], 7, true);
      scramble = Cube222.solve(p, o);
    } while (scramble == 'error');
    return scramble;
  }

  public static scrambleTEG2(twist: number): string {
    Cube222.init();
    let scramble: string;
    do {
      Cube222.randomTEG(1, twist);
      const p = Utils.get8Perm(Cube222.state[0], 7);
      const o = Utils.oriToIdx(Cube222.state[1], 7, true);
      scramble = Cube222.solve(p, o);
    } while (scramble == 'error');
    return scramble;
  }

  public static scrambleEG1(type: number, olls: string): string {
    Cube222.init();
    let scramble: string;
    do {
      Cube222.randomEG(type, olls);
      const p = Utils.get8Perm(Cube222.state[0], 7);
      const o = Utils.oriToIdx(Cube222.state[1], 7, true);
      scramble = Cube222.solve(p, o);
    } while (scramble == 'error');
    return scramble;
  }

  public static scrambleNobar(): string {
    Cube222.init();
    const perm: number[] = new Array<number>(8).fill(0);
    const ori: number[] = new Array<number>(8).fill(0);
    perm[7] = 7;
    let p: number;
    let o: number;
    do {
      p = Math.floor(Cube222.rnd() * 5040);
      o = Math.floor(Cube222.rnd() * 729);
      Utils.idxToPerm(perm, p, 7, false);
      Utils.idxToOri(ori, o, 7, true);
    } while (!Cube222.checkNobar(perm, ori));
    return Cube222.solve(p, o);
  }

  private static scramble1(minLen: number): string {
    Cube222.init();
    const p = Math.floor(Cube222.rnd() * 5040);
    const o = Math.floor(Cube222.rnd() * 729);
    const seq: number[] = new Array<number>(12).fill(0);
    for (let l = 0; l < 12; l++) {
      if (Cube222.search(p, o, l, -1, seq)) {
        if (l < minLen) {
          return 'error';
        }
        if (l < 11) {
          Cube222.search(p, o, 11, -2, seq);
        }
        let sol = '';
        let last = -1;
        for (let i = 1; i <= 11; i++) {
          if (last == Math.floor(seq[i] / 3)) {
            return 'error';
          }
          sol += Cube222.turn[Math.floor(seq[i] / 3)] + Utils.suffInv[seq[i] % 3] + ' ';
          last = Math.floor(seq[i] / 3);
        }
        return sol;
      }
    }
    return 'error';
  }

  public static scrambleWCA(): string {
    let scramble: string;
    do {
      scramble = Cube222.scramble1(4);
    } while (scramble == 'error');
    return scramble;
  }
}
