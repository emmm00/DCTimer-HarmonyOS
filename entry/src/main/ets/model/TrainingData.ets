/**
 * TrainingData — 公式专项训练的数据层
 *
 * 数据源直接用 SolverCore 里的 OLL_ALGS(57) / PLL_ALGS(21)，避免另抄一份导致两处不一致。
 * 训练用的「打乱」统一由公式反推（invertAlg），保证 打乱 → 执行公式 → 复原 这条链是自洽的，
 * 不需要手工维护 90 条 setup 串。
 *
 * 命名说明：PLL 的 21 条顺序与标准命名完全一致（Ua/Ub/H/Z/Aa/Ab/E/T/F/Ja/Jb/Ra/Rb/V/Y/Ga/Gb/Gc/Gd/Na/Nb），
 * 所以显示标准名；OLL 内置表的顺序并非官方 1~57 编号（前几条对得上，后面就分散了），
 * 所以只按表内序号显示「第 N 条」，不冒充官方编号。
 */

import { OLL_ALGS, PLL_ALGS } from '../solver/SolverCore';

export interface TrainCase {
  /** 在集合里的序号（1 起） */
  idx: number;
  /** 显示名 */
  name: string;
  /** 参考解法（正序执行即复原） */
  alg: string;
}

export interface TrainSet {
  id: number;
  title: string;
  /** 集合说明，显示在卡片右上角 */
  hint: string;
  cases: TrainCase[];
}

/** PLL 标准命名，顺序与 PLL_ALGS 一一对应 */
export const PLL_NAMES: string[] =
  ['Ua', 'Ub', 'H', 'Z', 'Aa', 'Ab', 'E', 'T', 'F', 'Ja', 'Jb',
    'Ra', 'Rb', 'V', 'Y', 'Ga', 'Gb', 'Gc', 'Gd', 'Na', 'Nb'];

/** F2L 常用 12 个基础 case（解法侧），打乱同样由反推得到 */
const F2L_ALGS: string[] = [
  "U R U' R'",
  "R U R' U'",
  "y' R' U2 R U R' U' R",
  "y U' L U L' U2 L U' L'",
  "U' R U2 R' U2 R U' R'",
  "U R U' R' U R U' R'",
  "y U L U L' U2 L U L'",
  "U' R U R' U' R U R'",
  "R' U R U2 R' U R",
  "y' R' U' R U R' U2 R U R' U' R",
  "R' U R U' R' U' R",
  "U' R U R' U R U R'"
];

/** 把一条公式反过来：倒序 + 每个 token 取逆（R→R'，R'→R，R2→R2） */
export function invertAlg(alg: string): string {
  const raw: string[] = alg.trim().split(' ');
  const toks: string[] = [];
  for (let i: number = 0; i < raw.length; i++) {
    if (raw[i].length > 0) {
      toks.push(raw[i]);
    }
  }
  const out: string[] = [];
  for (let i: number = toks.length - 1; i >= 0; i--) {
    out.push(invertToken(toks[i]));
  }
  return out.join(' ');
}

function invertToken(tok: string): string {
  const last: string = tok.charAt(tok.length - 1);
  if (last === "'") {
    return tok.substring(0, tok.length - 1);
  }
  if (last === '2') {
    return tok;
  }
  return tok + "'";
}

/** 生成一次训练用的打乱：正序执行它就会摆出该 case */
export function setupOf(c: TrainCase): string {
  return invertAlg(c.alg);
}

function buildOllSet(): TrainSet {
  const cases: TrainCase[] = [];
  for (let i: number = 0; i < OLL_ALGS.length; i++) {
    cases.push({ idx: i + 1, name: '第 ' + (i + 1) + ' 条', alg: OLL_ALGS[i] });
  }
  return { id: 0, title: 'OLL', hint: '顶层朝向 · ' + OLL_ALGS.length + ' 条', cases: cases };
}

function buildPllSet(): TrainSet {
  const cases: TrainCase[] = [];
  for (let i: number = 0; i < PLL_ALGS.length; i++) {
    const nm: string = i < PLL_NAMES.length ? PLL_NAMES[i] : ('第 ' + (i + 1) + ' 条');
    cases.push({ idx: i + 1, name: nm, alg: PLL_ALGS[i] });
  }
  return { id: 1, title: 'PLL', hint: '顶层排列 · ' + PLL_ALGS.length + ' 条', cases: cases };
}

function buildF2lSet(): TrainSet {
  const cases: TrainCase[] = [];
  for (let i: number = 0; i < F2L_ALGS.length; i++) {
    cases.push({ idx: i + 1, name: '第 ' + (i + 1) + ' 条', alg: F2L_ALGS[i] });
  }
  return { id: 2, title: 'F2L', hint: '底层两组 · ' + F2L_ALGS.length + ' 条', cases: cases };
}

/** 全部训练集合，顺序即页面上 chips 的顺序 */
export const TRAIN_SETS: TrainSet[] = [buildOllSet(), buildPllSet(), buildF2lSet()];
