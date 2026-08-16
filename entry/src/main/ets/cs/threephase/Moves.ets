// Ported from cs/threephase/Moves.java (DCTimer-BLE -> HarmonyOS ArkTS)

export class Moves {
  static readonly U1 = 0;
  static readonly U2 = 1;
  static readonly U3 = 2;
  static readonly U4 = 3;
  static readonly U5 = 4;
  static readonly U6 = 5;
  static readonly U7 = 6;
  static readonly U8 = 7;
  static readonly U9 = 8;
  static readonly R1 = 9;
  static readonly R2 = 10;
  static readonly R3 = 11;
  static readonly R4 = 12;
  static readonly R5 = 13;
  static readonly R6 = 14;
  static readonly R7 = 15;
  static readonly R8 = 16;
  static readonly R9 = 17;
  static readonly F1 = 18;
  static readonly F2 = 19;
  static readonly F3 = 20;
  static readonly F4 = 21;
  static readonly F5 = 22;
  static readonly F6 = 23;
  static readonly F7 = 24;
  static readonly F8 = 25;
  static readonly F9 = 26;
  static readonly D1 = 27;
  static readonly D2 = 28;
  static readonly D3 = 29;
  static readonly D4 = 30;
  static readonly D5 = 31;
  static readonly D6 = 32;
  static readonly D7 = 33;
  static readonly D8 = 34;
  static readonly D9 = 35;
  static readonly L1 = 36;
  static readonly L2 = 37;
  static readonly L3 = 38;
  static readonly L4 = 39;
  static readonly L5 = 40;
  static readonly L6 = 41;
  static readonly L7 = 42;
  static readonly L8 = 43;
  static readonly L9 = 44;
  static readonly B1 = 45;
  static readonly B2 = 46;
  static readonly B3 = 47;
  static readonly B4 = 48;
  static readonly B5 = 49;
  static readonly B6 = 50;
  static readonly B7 = 51;
  static readonly B8 = 52;
  static readonly B9 = 53;

  static readonly U = 0;
  static readonly D = 1;
  static readonly F = 2;
  static readonly B = 3;
  static readonly R = 4;
  static readonly L = 5;

  static readonly Ux1 = 0;
  static readonly Ux2 = 1;
  static readonly Ux3 = 2;
  static readonly Rx1 = 3;
  static readonly Rx2 = 4;
  static readonly Rx3 = 5;
  static readonly Fx1 = 6;
  static readonly Fx2 = 7;
  static readonly Fx3 = 8;
  static readonly Dx1 = 9;
  static readonly Dx2 = 10;
  static readonly Dx3 = 11;
  static readonly Lx1 = 12;
  static readonly Lx2 = 13;
  static readonly Lx3 = 14;
  static readonly Bx1 = 15;
  static readonly Bx2 = 16;
  static readonly Bx3 = 17;
  static readonly ux1 = 18;
  static readonly ux2 = 19;
  static readonly ux3 = 20;
  static readonly rx1 = 21;
  static readonly rx2 = 22;
  static readonly rx3 = 23;
  static readonly fx1 = 24;
  static readonly fx2 = 25;
  static readonly fx3 = 26;
  static readonly dx1 = 27;
  static readonly dx2 = 28;
  static readonly dx3 = 29;
  static readonly lx1 = 30;
  static readonly lx2 = 31;
  static readonly lx3 = 32;
  static readonly bx1 = 33;
  static readonly bx2 = 34;
  static readonly bx3 = 35;
  static readonly eom = 36; // End Of Moves

  static readonly move2str: string[] = ['U', 'U2', "U'", 'R', 'R2', "R'", 'F', 'F2', "F'",
    'D', 'D2', "D'", 'L', 'L2', "L'", 'B', 'B2', "B'",
    'Uw', 'Uw2', "Uw'", 'Rw', 'Rw2', "Rw'", 'Fw', 'Fw2', "Fw'",
    'Dw', 'Dw2', "Dw'", 'Lw', 'Lw2', "Lw'", 'Bw', 'Bw2', "Bw'"];

  static readonly moveIstr: string[] = ["U' ", 'U2 ', 'U  ', "R' ", 'R2 ', 'R  ', "F' ", 'F2 ', 'F  ',
    "D' ", 'D2 ', 'D  ', "L' ", 'L2 ', 'L  ', "B' ", 'B2 ', 'B  ',
    "Uw'", 'Uw2', 'Uw ', "Rw'", 'Rw2', 'Rw ', "Fw'", 'Fw2', 'Fw ',
    "Dw'", 'Dw2', 'Dw ', "Lw'", 'Lw2', 'Lw ', "Bw'", 'Bw2', 'Bw '];

  static readonly move2std: number[] = [Moves.Ux1, Moves.Ux2, Moves.Ux3, Moves.Rx1, Moves.Rx2, Moves.Rx3,
    Moves.Fx1, Moves.Fx2, Moves.Fx3,
    Moves.Dx1, Moves.Dx2, Moves.Dx3, Moves.Lx1, Moves.Lx2, Moves.Lx3, Moves.Bx1, Moves.Bx2, Moves.Bx3,
    Moves.ux2, Moves.rx1, Moves.rx2, Moves.rx3, Moves.fx2, Moves.dx2, Moves.lx1, Moves.lx2, Moves.lx3,
    Moves.bx2, Moves.eom];

  static readonly move3std: number[] = [Moves.Ux1, Moves.Ux2, Moves.Ux3, Moves.Rx2, Moves.Fx1, Moves.Fx2,
    Moves.Fx3, Moves.Dx1, Moves.Dx2, Moves.Dx3, Moves.Lx2, Moves.Bx1, Moves.Bx2, Moves.Bx3,
    Moves.ux2, Moves.rx2, Moves.fx2, Moves.dx2, Moves.lx2, Moves.bx2, Moves.eom];

  static std2move: number[] = new Array<number>(37).fill(0);
  static std3move: number[] = new Array<number>(37).fill(0);

  static ckmv: boolean[][] = Moves.z2dBool(37, 36);
  static ckmv2: boolean[][] = Moves.z2dBool(29, 28);
  static ckmv3: boolean[][] = Moves.z2dBool(21, 20);

  static skipAxis: number[] = new Array<number>(36).fill(0);
  static skipAxis2: number[] = new Array<number>(28).fill(0);
  static skipAxis3: number[] = new Array<number>(20).fill(0);

  private static inited = false;

  private static z2dBool(r: number, c: number): boolean[][] {
    const a: boolean[][] = [];
    for (let i = 0; i < r; i++) {
      a.push(new Array<boolean>(c).fill(false));
    }
    return a;
  }

  static init(): void {
    if (Moves.inited) {
      return;
    }
    for (let i = 0; i < 29; i++) {
      Moves.std2move[Moves.move2std[i]] = i;
    }
    for (let i = 0; i < 21; i++) {
      Moves.std3move[Moves.move3std[i]] = i;
    }
    for (let i = 0; i < 36; i++) {
      for (let j = 0; j < 36; j++) {
        Moves.ckmv[i][j] = (Math.floor(i / 3) == Math.floor(j / 3)) ||
          ((Math.floor(i / 3) % 3 == Math.floor(j / 3) % 3) && (i > j));
      }
      Moves.ckmv[36][i] = false;
    }
    for (let i = 0; i < 29; i++) {
      for (let j = 0; j < 28; j++) {
        Moves.ckmv2[i][j] = Moves.ckmv[Moves.move2std[i]][Moves.move2std[j]];
      }
    }
    for (let i = 0; i < 21; i++) {
      for (let j = 0; j < 20; j++) {
        Moves.ckmv3[i][j] = Moves.ckmv[Moves.move3std[i]][Moves.move3std[j]];
      }
    }
    for (let i = 0; i < 36; i++) {
      Moves.skipAxis[i] = 36;
      for (let j = i; j < 36; j++) {
        if (!Moves.ckmv[i][j]) {
          Moves.skipAxis[i] = j - 1;
          break;
        }
      }
    }
    for (let i = 0; i < 28; i++) {
      Moves.skipAxis2[i] = 28;
      for (let j = i; j < 28; j++) {
        if (!Moves.ckmv2[i][j]) {
          Moves.skipAxis2[i] = j - 1;
          break;
        }
      }
    }
    for (let i = 0; i < 20; i++) {
      Moves.skipAxis3[i] = 20;
      for (let j = i; j < 20; j++) {
        if (!Moves.ckmv3[i][j]) {
          Moves.skipAxis3[i] = j - 1;
          break;
        }
      }
    }
    Moves.inited = true;
  }
}

Moves.init();
