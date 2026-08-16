function invertAlgorithm(alg: string): string {
  const tokens: string[] = alg.trim().split(/\s+/).filter((t: string): boolean => t.length > 0);
  const reversed: string[] = [];
  for (let i: number = tokens.length - 1; i >= 0; i--) {
    const t: string = tokens[i];
    if (t.length === 1) {
      reversed.push(t + "'");
    } else if (t.charAt(1) === "'") {
      reversed.push(t.charAt(0));
    } else if (t.charAt(1) === '2') {
      reversed.push(t);
    } else {
      reversed.push(t);
    }
  }
  return reversed.join(' ');
}

export interface TrainingCase {
  index: number;
  name: string;
  category: string;
  setup: string;
  solution: string;
}

export class TrainingSets {

  static OLL: TrainingCase[] = [
    { index: 1, name: "OLL 1", category: "oll", setup: invertAlgorithm("R U2 R2 F R F' U2 R' F R F'"), solution: "R U2 R2 F R F' U2 R' F R F'" },
    { index: 2, name: "OLL 2", category: "oll", setup: invertAlgorithm("F R U R' U' F' f R U R' U' f'"), solution: "F R U R' U' F' f R U R' U' f'" },
    { index: 3, name: "OLL 3", category: "oll", setup: invertAlgorithm("f R U R' U' f' U' F R U R' U' F'"), solution: "f R U R' U' f' U' F R U R' U' F'" },
    { index: 4, name: "OLL 4", category: "oll", setup: invertAlgorithm("f R U R' U' f' U F R U R' U' F'"), solution: "f R U R' U' f' U F R U R' U' F'" },
    { index: 5, name: "OLL 5", category: "oll", setup: invertAlgorithm("r' U2 R U R' U r"), solution: "r' U2 R U R' U r" },
    { index: 6, name: "OLL 6", category: "oll", setup: invertAlgorithm("r U2 R' U' R U' r'"), solution: "r U2 R' U' R U' r'" },
    { index: 7, name: "OLL 7", category: "oll", setup: invertAlgorithm("r U R' U R U2 r'"), solution: "r U R' U R U2 r'" },
    { index: 8, name: "OLL 8", category: "oll", setup: invertAlgorithm("l' U' L U' L' U2 l"), solution: "l' U' L U' L' U2 l" },
    { index: 9, name: "OLL 9", category: "oll", setup: invertAlgorithm("R U R' U' R' F R2 U R' U' F'"), solution: "R U R' U' R' F R2 U R' U' F'" },
    { index: 10, name: "OLL 10", category: "oll", setup: invertAlgorithm("R U R' U R' F R F' R U2 R'"), solution: "R U R' U R' F R F' R U2 R'" },
    { index: 11, name: "OLL 11", category: "oll", setup: invertAlgorithm("r U R' U R' F R F' R U2 r'"), solution: "r U R' U R' F R F' R U2 r'" },
    { index: 12, name: "OLL 12", category: "oll", setup: invertAlgorithm("M' R' U' R U' R' U2 R U' M"), solution: "M' R' U' R U' R' U2 R U' M" },
    { index: 13, name: "OLL 13", category: "oll", setup: invertAlgorithm("F U R U' R2 F' R U R U' R'"), solution: "F U R U' R2 F' R U R U' R'" },
    { index: 14, name: "OLL 14", category: "oll", setup: invertAlgorithm("R' F R U R' F' R F U' F'"), solution: "R' F R U R' F' R F U' F'" },
    { index: 15, name: "OLL 15", category: "oll", setup: invertAlgorithm("l' U' l L' U' L U l' U l"), solution: "l' U' l L' U' L U l' U l" },
    { index: 16, name: "OLL 16", category: "oll", setup: invertAlgorithm("r U r' R U R' U' r U' r'"), solution: "r U r' R U R' U' r U' r'" },
    { index: 17, name: "OLL 17", category: "oll", setup: invertAlgorithm("F R' F' R2 r' U R U' R' U' M'"), solution: "F R' F' R2 r' U R U' R' U' M'" },
    { index: 18, name: "OLL 18", category: "oll", setup: invertAlgorithm("r U R' U R U2 r2 U' R U' R' U2 r"), solution: "r U R' U R U2 r2 U' R U' R' U2 r" },
    { index: 19, name: "OLL 19", category: "oll", setup: invertAlgorithm("r' R U R U R' U' M' R' F R F'"), solution: "r' R U R U R' U' M' R' F R F'" },
    { index: 20, name: "OLL 20", category: "oll", setup: invertAlgorithm("r U R' U' M2 U R U' R' U' M'"), solution: "r U R' U' M2 U R U' R' U' M'" },
    { index: 21, name: "OLL 21", category: "oll", setup: invertAlgorithm("R U2 R' U' R U R' U' R U' R'"), solution: "R U2 R' U' R U R' U' R U' R'" },
    { index: 22, name: "OLL 22", category: "oll", setup: invertAlgorithm("R U2 R2 U' R2 U' R2 U2 R"), solution: "R U2 R2 U' R2 U' R2 U2 R" },
    { index: 23, name: "OLL 23", category: "oll", setup: invertAlgorithm("R2 D' R U2 R' D R U2 R"), solution: "R2 D' R U2 R' D R U2 R" },
    { index: 24, name: "OLL 24", category: "oll", setup: invertAlgorithm("r U R' U' r' F R F'"), solution: "r U R' U' r' F R F'" },
    { index: 25, name: "OLL 25", category: "oll", setup: invertAlgorithm("F' r U R' U' r' F R"), solution: "F' r U R' U' r' F R" },
    { index: 26, name: "OLL 26", category: "oll", setup: invertAlgorithm("R U2 R' U' R U' R'"), solution: "R U2 R' U' R U' R'" },
    { index: 27, name: "OLL 27", category: "oll", setup: invertAlgorithm("R U R' U R U2 R'"), solution: "R U R' U R U2 R'" },
    { index: 28, name: "OLL 28", category: "oll", setup: invertAlgorithm("r U R' U' r' R U R U' R'"), solution: "r U R' U' r' R U R U' R'" },
    { index: 29, name: "OLL 29", category: "oll", setup: invertAlgorithm("R U R' U' R U' R' F' U' F R U R'"), solution: "R U R' U' R U' R' F' U' F R U R'" },
    { index: 30, name: "OLL 30", category: "oll", setup: invertAlgorithm("F R' F R2 U' R' U' R U R' F2"), solution: "F R' F R2 U' R' U' R U R' F2" },
    { index: 31, name: "OLL 31", category: "oll", setup: invertAlgorithm("R' U' F U R U' R' F' R"), solution: "R' U' F U R U' R' F' R" },
    { index: 32, name: "OLL 32", category: "oll", setup: invertAlgorithm("L U F' U' L' U L F L'"), solution: "L U F' U' L' U L F L'" },
    { index: 33, name: "OLL 33", category: "oll", setup: invertAlgorithm("R U R' U' R' F R F'"), solution: "R U R' U' R' F R F'" },
    { index: 34, name: "OLL 34", category: "oll", setup: invertAlgorithm("R U R2 U' R' F R U R U' F'"), solution: "R U R2 U' R' F R U R U' F'" },
    { index: 35, name: "OLL 35", category: "oll", setup: invertAlgorithm("R U2 R' F R' F' R2 U2 R'"), solution: "R U2 R' F R' F' R2 U2 R'" },
    { index: 36, name: "OLL 36", category: "oll", setup: invertAlgorithm("L' U' L U' L' U L U L F' L' F"), solution: "L' U' L U' L' U L U L F' L' F" },
    { index: 37, name: "OLL 37", category: "oll", setup: invertAlgorithm("F R' F' R U R U' R'"), solution: "F R' F' R U R U' R'" },
    { index: 38, name: "OLL 38", category: "oll", setup: invertAlgorithm("R U R' U R U' R' U' R' F R F'"), solution: "R U R' U R U' R' U' R' F R F'" },
    { index: 39, name: "OLL 39", category: "oll", setup: invertAlgorithm("L F' L' U' L U F U' L'"), solution: "L F' L' U' L U F U' L'" },
    { index: 40, name: "OLL 40", category: "oll", setup: invertAlgorithm("R' F R U R' U' F' U R"), solution: "R' F R U R' U' F' U R" },
    { index: 41, name: "OLL 41", category: "oll", setup: invertAlgorithm("R U R' U R U2 R' F R U R' U' F'"), solution: "R U R' U R U2 R' F R U R' U' F'" },
    { index: 42, name: "OLL 42", category: "oll", setup: invertAlgorithm("R' U' R U' R' U2 R F R U R' U' F'"), solution: "R' U' R U' R' U2 R F R U R' U' F'" },
    { index: 43, name: "OLL 43", category: "oll", setup: invertAlgorithm("F' U' L' U L F"), solution: "F' U' L' U L F" },
    { index: 44, name: "OLL 44", category: "oll", setup: invertAlgorithm("F U R U' R' F'"), solution: "F U R U' R' F'" },
    { index: 45, name: "OLL 45", category: "oll", setup: invertAlgorithm("F R U R' U' F'"), solution: "F R U R' U' F'" },
    { index: 46, name: "OLL 46", category: "oll", setup: invertAlgorithm("R' U' R' F R F' U R"), solution: "R' U' R' F R F' U R" },
    { index: 47, name: "OLL 47", category: "oll", setup: invertAlgorithm("R' U' R' F R F' R' F R F' U R"), solution: "R' U' R' F R F' R' F R F' U R" },
    { index: 48, name: "OLL 48", category: "oll", setup: invertAlgorithm("F R U R' U' R U R' U' F'"), solution: "F R U R' U' R U R' U' F'" },
    { index: 49, name: "OLL 49", category: "oll", setup: invertAlgorithm("r U' r2 U r2 U r2 U' r"), solution: "r U' r2 U r2 U r2 U' r" },
    { index: 50, name: "OLL 50", category: "oll", setup: invertAlgorithm("r' U r2 U' r2 U' r2 U r'"), solution: "r' U r2 U' r2 U' r2 U r'" },
    { index: 51, name: "OLL 51", category: "oll", setup: invertAlgorithm("F U R U' R' U R U' R' F'"), solution: "F U R U' R' U R U' R' F'" },
    { index: 52, name: "OLL 52", category: "oll", setup: invertAlgorithm("R U R' U R U' B U' B' R'"), solution: "R U R' U R U' B U' B' R'" },
    { index: 53, name: "OLL 53", category: "oll", setup: invertAlgorithm("l' U2 L U L' U' L U L' U l"), solution: "l' U2 L U L' U' L U L' U l" },
    { index: 54, name: "OLL 54", category: "oll", setup: invertAlgorithm("r U2 R' U' R U R' U' R U' r'"), solution: "r U2 R' U' R U R' U' R U' r'" },
    { index: 55, name: "OLL 55", category: "oll", setup: invertAlgorithm("R U2 R2 U' R U' R' U2 F R F'"), solution: "R U2 R2 U' R U' R' U2 F R F'" },
    { index: 56, name: "OLL 56", category: "oll", setup: invertAlgorithm("r' U' r U' R' U R U' R' U R r' U r"), solution: "r' U' r U' R' U R U' R' U R r' U r" },
    { index: 57, name: "OLL 57", category: "oll", setup: invertAlgorithm("R U R' U' M' U R U' r'"), solution: "R U R' U' M' U R U' r'" },
  ];

  static PLL: TrainingCase[] = [
    { index: 1, name: "PLL Ua Perm", category: "pll", setup: invertAlgorithm("M2 U M U2 M' U M2"), solution: "M2 U M U2 M' U M2" },
    { index: 2, name: "PLL Ub Perm", category: "pll", setup: invertAlgorithm("M2 U' M U2 M' U' M2"), solution: "M2 U' M U2 M' U' M2" },
    { index: 3, name: "PLL H Perm", category: "pll", setup: invertAlgorithm("M2 U M2 U2 M2 U M2"), solution: "M2 U M2 U2 M2 U M2" },
    { index: 4, name: "PLL Z Perm", category: "pll", setup: invertAlgorithm("M' U M2 U M2 U M' U2 M2"), solution: "M' U M2 U M2 U M' U2 M2" },
    { index: 5, name: "PLL Aa Perm", category: "pll", setup: invertAlgorithm("x R' U R' D2 R U' R' D2 R2 x'"), solution: "x R' U R' D2 R U' R' D2 R2 x'" },
    { index: 6, name: "PLL Ab Perm", category: "pll", setup: invertAlgorithm("x R2 D2 R U R' D2 R U' R x'"), solution: "x R2 D2 R U R' D2 R U' R x'" },
    { index: 7, name: "PLL E Perm", category: "pll", setup: invertAlgorithm("x' R U' R' D R U R' D' R U R' D R U' R' D' x"), solution: "x' R U' R' D R U R' D' R U R' D R U' R' D' x" },
    { index: 8, name: "PLL T Perm", category: "pll", setup: invertAlgorithm("R U R' U' R' F R2 U' R' U' R U R' F'"), solution: "R U R' U' R' F R2 U' R' U' R U R' F'" },
    { index: 9, name: "PLL F Perm", category: "pll", setup: invertAlgorithm("R' U' F' R U R' U' R' F R2 U' R' U' R U R' U R"), solution: "R' U' F' R U R' U' R' F R2 U' R' U' R U R' U R" },
    { index: 10, name: "PLL Ja Perm", category: "pll", setup: invertAlgorithm("x R2 F R F' R U2 r' U r U2 x'"), solution: "x R2 F R F' R U2 r' U r U2 x'" },
    { index: 11, name: "PLL Jb Perm", category: "pll", setup: invertAlgorithm("R U R' F' R U R' U' R' F R2 U' R'"), solution: "R U R' F' R U R' U' R' F R2 U' R'" },
    { index: 12, name: "PLL Ra Perm", category: "pll", setup: invertAlgorithm("R U' R' U' R U R D R' U' R D' R' U2 R'"), solution: "R U' R' U' R U R D R' U' R D' R' U2 R'" },
    { index: 13, name: "PLL Rb Perm", category: "pll", setup: invertAlgorithm("R' U2 R' D' R U' R' D R U R' U' R U' R"), solution: "R' U2 R' D' R U' R' D R U R' U' R U' R" },
    { index: 14, name: "PLL V Perm", category: "pll", setup: invertAlgorithm("R' U R' U' y R' F' R2 U' R' U R' F R F"), solution: "R' U R' U' y R' F' R2 U' R' U R' F R F" },
    { index: 15, name: "PLL Y Perm", category: "pll", setup: invertAlgorithm("F R U' R' U' R U R' F' R U R' U' R' F R F'"), solution: "F R U' R' U' R U R' F' R U R' U' R' F R F'" },
    { index: 16, name: "PLL Na Perm", category: "pll", setup: invertAlgorithm("R U R' U R U R' F' R U R' U' R' F R2 U' R' U2 R U' R'"), solution: "R U R' U R U R' F' R U R' U' R' F R2 U' R' U2 R U' R'" },
    { index: 17, name: "PLL Nb Perm", category: "pll", setup: invertAlgorithm("R' U R U' R' F' U' F R U R' F R' F' R U' R"), solution: "R' U R U' R' F' U' F R U R' F R' F' R U' R" },
    { index: 18, name: "PLL Ga Perm", category: "pll", setup: invertAlgorithm("R2 U R' U R' U' R U' R2 U' D R' U R D'"), solution: "R2 U R' U R' U' R U' R2 U' D R' U R D'" },
    { index: 19, name: "PLL Gb Perm", category: "pll", setup: invertAlgorithm("R' U' R U D' R2 U R' U R U' R U' R2 D"), solution: "R' U' R U D' R2 U R' U R U' R U' R2 D" },
    { index: 20, name: "PLL Gc Perm", category: "pll", setup: invertAlgorithm("R2 U' R U' R U R' U R2 U D' R U' R' D"), solution: "R2 U' R U' R U R' U R2 U D' R U' R' D" },
    { index: 21, name: "PLL Gd Perm", category: "pll", setup: invertAlgorithm("R U R' U' D R2 U' R U' R' U R' U R2 D'"), solution: "R U R' U' D R2 U' R U' R' U R' U R2 D'" },
  ];

  static F2L: TrainingCase[] = [
    { index: 1, name: "F2L 1", category: "f2l", setup: invertAlgorithm("R U R'"), solution: "R U R'" },
    { index: 2, name: "F2L 2", category: "f2l", setup: invertAlgorithm("y L' U' L y'"), solution: "y L' U' L y'" },
    { index: 3, name: "F2L 3", category: "f2l", setup: invertAlgorithm("y L U L' y'"), solution: "y L U L' y'" },
    { index: 4, name: "F2L 4", category: "f2l", setup: invertAlgorithm("R' U' R"), solution: "R' U' R" },
    { index: 5, name: "F2L 5", category: "f2l", setup: invertAlgorithm("U' R U R' U2 R U' R'"), solution: "U' R U R' U2 R U' R'" },
    { index: 6, name: "F2L 6", category: "f2l", setup: invertAlgorithm("y' U R' U R U' R' U' R y"), solution: "y' U R' U R U' R' U' R y" },
    { index: 7, name: "F2L 7", category: "f2l", setup: invertAlgorithm("R U' R' U R U' R'"), solution: "R U' R' U R U' R'" },
    { index: 8, name: "F2L 8", category: "f2l", setup: invertAlgorithm("y' R' U R U' R' U' R y"), solution: "y' R' U R U' R' U' R y" },
    { index: 9, name: "F2L 9", category: "f2l", setup: invertAlgorithm("R U R' U' R U R'"), solution: "R U R' U' R U R'" },
    { index: 10, name: "F2L 10", category: "f2l", setup: invertAlgorithm("R U R' U2 R U R'"), solution: "R U R' U2 R U R'" },
    { index: 11, name: "F2L 11", category: "f2l", setup: invertAlgorithm("y' R' U' R U R' U' R y"), solution: "y' R' U' R U R' U' R y" },
    { index: 12, name: "F2L 12", category: "f2l", setup: invertAlgorithm("y' R' U' R U2 R' U' R y"), solution: "y' R' U' R U2 R' U' R y" },
    { index: 13, name: "F2L 13", category: "f2l", setup: invertAlgorithm("U' R U2 R' U2 R U' R'"), solution: "U' R U2 R' U2 R U' R'" },
    { index: 14, name: "F2L 14", category: "f2l", setup: invertAlgorithm("y' U R' U2 R U2 R' U R y"), solution: "y' U R' U2 R U2 R' U R y" },
    { index: 15, name: "F2L 15", category: "f2l", setup: invertAlgorithm("U' R U' R' U R U R'"), solution: "U' R U' R' U R U R'" },
    { index: 16, name: "F2L 16", category: "f2l", setup: invertAlgorithm("y' U R' U R U' R' U' R y"), solution: "y' U R' U R U' R' U' R y" },
    { index: 17, name: "F2L 17", category: "f2l", setup: invertAlgorithm("R U' R' U' R U R'"), solution: "R U' R' U' R U R'" },
    { index: 18, name: "F2L 18", category: "f2l", setup: invertAlgorithm("R U R' U' R U' R'"), solution: "R U R' U' R U' R'" },
    { index: 19, name: "F2L 19", category: "f2l", setup: invertAlgorithm("y' R' U R U R' U' R y"), solution: "y' R' U R U R' U' R y" },
    { index: 20, name: "F2L 20", category: "f2l", setup: invertAlgorithm("y' R' U' R U R' U R y"), solution: "y' R' U' R U R' U R y" },
    { index: 21, name: "F2L 21", category: "f2l", setup: invertAlgorithm("U R U' R' U' R U R'"), solution: "U R U' R' U' R U R'" },
    { index: 22, name: "F2L 22", category: "f2l", setup: invertAlgorithm("y' U' R' U R U R' U' R y"), solution: "y' U' R' U R U R' U' R y" },
    { index: 23, name: "F2L 23", category: "f2l", setup: invertAlgorithm("U2 R U R' U R U' R'"), solution: "U2 R U R' U R U' R'" },
    { index: 24, name: "F2L 24", category: "f2l", setup: invertAlgorithm("y' U2 R' U' R U' R' U R y"), solution: "y' U2 R' U' R U' R' U R y" },
    { index: 25, name: "F2L 25", category: "f2l", setup: invertAlgorithm("U' R U2 R' U F' U' F"), solution: "U' R U2 R' U F' U' F" },
    { index: 26, name: "F2L 26", category: "f2l", setup: invertAlgorithm("y' U R' U2 R U' F R' F' R y"), solution: "y' U R' U2 R U' F R' F' R y" },
    { index: 27, name: "F2L 27", category: "f2l", setup: invertAlgorithm("R U' R' U' F' U' F"), solution: "R U' R' U' F' U' F" },
    { index: 28, name: "F2L 28", category: "f2l", setup: invertAlgorithm("R U R' U R U' R'"), solution: "R U R' U R U' R'" },
    { index: 29, name: "F2L 29", category: "f2l", setup: invertAlgorithm("R U' R' U' R U2 R' U' R U R'"), solution: "R U' R' U' R U2 R' U' R U R'" },
    { index: 30, name: "F2L 30", category: "f2l", setup: invertAlgorithm("R U' R' U R U2 R' U R U' R'"), solution: "R U' R' U R U2 R' U R U' R'" },
    { index: 31, name: "F2L 31", category: "f2l", setup: invertAlgorithm("R U R' U2 R U' R' U R U' R'"), solution: "R U R' U2 R U' R' U R U' R'" },
    { index: 32, name: "F2L 32", category: "f2l", setup: invertAlgorithm("R U R' U' R U2 R' U' R U R'"), solution: "R U R' U' R U2 R' U' R U R'" },
    { index: 33, name: "F2L 33", category: "f2l", setup: invertAlgorithm("R U2 R' U' R U R' U' R U' R'"), solution: "R U2 R' U' R U R' U' R U' R'" },
    { index: 34, name: "F2L 34", category: "f2l", setup: invertAlgorithm("R U2 R' U' R U2 R' U' R U R'"), solution: "R U2 R' U' R U2 R' U' R U R'" },
    { index: 35, name: "F2L 35", category: "f2l", setup: invertAlgorithm("R U R' U2 R' F R F'"), solution: "R U R' U2 R' F R F'" },
    { index: 36, name: "F2L 36", category: "f2l", setup: invertAlgorithm("R U' R' U2 F' U' F"), solution: "R U' R' U2 F' U' F" },
    { index: 37, name: "F2L 37", category: "f2l", setup: invertAlgorithm("R U' R' U' R U' R' U2 R U' R'"), solution: "R U' R' U' R U' R' U2 R U' R'" },
    { index: 38, name: "F2L 38", category: "f2l", setup: invertAlgorithm("R U R' U2 R U' R' U' R U R'"), solution: "R U R' U2 R U' R' U' R U R'" },
    { index: 39, name: "F2L 39", category: "f2l", setup: invertAlgorithm("R U' R' U F' U2 F"), solution: "R U' R' U F' U2 F" },
    { index: 40, name: "F2L 40", category: "f2l", setup: invertAlgorithm("R U R' U' R U2 R' U2 R U' R'"), solution: "R U R' U' R U2 R' U2 R U' R'" },
    { index: 41, name: "F2L 41", category: "f2l", setup: invertAlgorithm("R U' R' U2 F' U2 F"), solution: "R U' R' U2 F' U2 F" },
  ];
}
