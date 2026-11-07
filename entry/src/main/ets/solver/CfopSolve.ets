// CfopSolve — CFOP full solve implementation (Cross -> F2L -> OLL -> PLL).
// Kept in its own module so a taskpool @Concurrent task (which may only use
// import/local variables, not same-module top-level functions) can import it.
// F2L is solved across ALL insertion orders; the shortest is picked, and the
// alternatives are returned so the UI can let the user switch order.
import {
  ensureReadyAsync, findRotation, rotateScrambleByIdx, cubeFromTokens, extractCrossState,
  solveCrossState, solveF2lTargets, pairStateOf, lookupOll, lookupPll, simplifyMoves,
  movesToStr, applyMoveIdx, isSolvedCube, setF2lSharedBudget,
  SolveOutput, StageResult, F2lAlternative
} from './SolverCore';
import { CubieCube } from '../cs/min2phase/CubieCube';

// F2L slot corner/edge piece ids (min2phase) and names
const SLOT_CORNER: number[] = [4, 5, 6, 7];
const SLOT_EDGE: number[] = [8, 9, 10, 11];
const SLOT_NAMES: string[] = ['FR', 'FL', 'BL', 'BR'];
const DEFAULT_ORDER: number[] = [0, 1, 2, 3];

export async function runCfopSolve(scramble: string, bottom: number, front: number,
  forcedOrder?: number[]): Promise<SolveOutput> {
  await ensureReadyAsync();
  const rotIdx = findRotation(bottom, front);
  if (rotIdx < 0) {
    return fail('无法确定底色方向');
  }
  const remapped = rotateScrambleByIdx(scramble, rotIdx);
  const cube = cubeFromTokens(remapped);
  const stages: StageResult[] = [];
  const solverAll: number[] = [];

  // cross
  const cs0 = extractCrossState(cube);
  const crossMoves = await solveCrossState(cs0.ep, cs0.eo);
  if (crossMoves == null) {
    return fail('十字无解');
  }
  for (let i = 0; i < crossMoves.length; i++) {
    applyMoveIdx(cube, crossMoves[i]);
  }
  for (let i = 0; i < crossMoves.length; i++) {
    solverAll.push(crossMoves[i]);
  }
  stages.push({ name: '十字', moves: crossMoves.slice() });
  const ck = extractCrossState(cube);
  if (ck.ep !== 1670 || ck.eo !== 1104) {
    return fail('十字校验失败');
  }

  // F2L: evaluate all insertion orders, pick the shortest, and expose the rest.
  let forced: boolean = false;
  let chosenOrder: number[] = DEFAULT_ORDER.slice();
  if (forcedOrder != null && forcedOrder.length === 4) {
    forced = true;
    chosenOrder = forcedOrder;
  }
  let f2lCands: F2lAlternative[] = [];
  let chosenSlots: number[][] | null = null;

  if (forced) {
    setF2lSharedBudget(false); // guaranteed path: budget per-call
    chosenSlots = await runF2l(cube, chosenOrder);
    if (chosenSlots == null) {
      return fail('F2L 无解');
    }
    f2lCands = [];
  } else {
    const all: F2lAlternative[] = await enumerateF2l(cube);
    if (all.length === 0) {
      return fail('F2L 无解');
    }
    f2lCands = all;
    chosenOrder = all[0].order;
    // 枚举阶段已经为该顺序逐槽求过解（slotMoves）：先在魔方副本上重放校验，
    // 通过就直接复用，省掉旧实现里"同一顺序再整段重搜一遍"的开销；
    // 仅在罕见的校验失败时才回落到逐槽重搜。
    const replay = new CubieCube(cube);
    let replayOk = true;
    for (let s = 0; s < 4; s++) {
      const sm = all[0].slotMoves[s];
      for (let i = 0; i < sm.length; i++) {
        applyMoveIdx(replay, sm[i]);
      }
      const st = pairStateOf(replay, chosenOrder[s]);
      if (st.c !== SLOT_CORNER[chosenOrder[s]] * 3 || st.e !== SLOT_EDGE[chosenOrder[s]] * 2) {
        replayOk = false;
        break;
      }
    }
    if (replayOk) {
      chosenSlots = [];
      for (let s = 0; s < 4; s++) {
        const sm = all[0].slotMoves[s];
        chosenSlots.push(sm.slice());
        for (let i = 0; i < sm.length; i++) {
          applyMoveIdx(cube, sm[i]);
        }
      }
    } else {
      setF2lSharedBudget(false);
      chosenSlots = await runF2l(cube, chosenOrder);
      if (chosenSlots == null) {
        return fail('F2L 无解');
      }
    }
  }

  for (let s = 0; s < 4; s++) {
    const sm = chosenSlots[s];
    for (let i = 0; i < sm.length; i++) {
      solverAll.push(sm[i]);
    }
    stages.push({ name: 'F2L-' + SLOT_NAMES[chosenOrder[s]], moves: sm.slice() });
  }
  {
    const ck2 = extractCrossState(cube);
    if (ck2.ep !== 1670 || ck2.eo !== 1104) {
      return fail('F2L 校验失败');
    }
    for (let j = 0; j < SLOT_CORNER.length; j++) {
      const st = pairStateOf(cube, j);
      if (st.c !== SLOT_CORNER[j] * 3 || st.e !== SLOT_EDGE[j] * 2) {
        return fail('F2L 校验失败');
      }
    }
  }

  // OLL
  const ollMoves = lookupOll(cube);
  if (ollMoves == null) {
    return fail('OLL 无匹配');
  }
  for (let i = 0; i < ollMoves.length; i++) {
    applyMoveIdx(cube, ollMoves[i]);
  }
  for (let i = 0; i < ollMoves.length; i++) {
    solverAll.push(ollMoves[i]);
  }
  stages.push({ name: 'OLL', moves: ollMoves.slice() });
  for (let i = 0; i < 4; i++) {
    if (cube.co[i] !== 0 || cube.eo[i] !== 0) {
      return fail('OLL 校验失败');
    }
  }

  // PLL
  const pllMoves = lookupPll(cube);
  if (pllMoves == null) {
    return fail('PLL 无匹配');
  }
  for (let i = 0; i < pllMoves.length; i++) {
    applyMoveIdx(cube, pllMoves[i]);
  }
  for (let i = 0; i < pllMoves.length; i++) {
    solverAll.push(pllMoves[i]);
  }
  stages.push({ name: 'PLL', moves: pllMoves.slice() });
  if (!isSolvedCube(cube)) {
    return fail('PLL 校验失败');
  }

  return buildOutput(stages, solverAll, rotIdx, f2lCands);
}

// Solve F2L in the given insertion order. Mutates `cube` and returns the raw
// (un-simplified) per-slot move lists in that order.
async function runF2l(cube: CubieCube, order: number[]): Promise<number[][] | null> {
  const perSlot: number[][] = [[], [], [], []];
  for (let s = 0; s < 4; s++) {
    const targets: number[] = [];
    for (let t = 0; t <= s; t++) {
      targets.push(order[t]);
    }
    const m = await solveF2lTargets(cube, targets);
    if (m == null) {
      return null;
    }
    for (let i = 0; i < m.length; i++) {
      applyMoveIdx(cube, m[i]);
    }
    perSlot[s] = m.slice();
  }
  return perSlot;
}

// All 24 permutations of [0,1,2,3], emitted in lexicographic order so that the
// default order [0,1,2,3] comes first. (ArkTS forbids nested functions, so this
// is a constant table instead of a recursive generator.)
const F2L_ORDERS: number[][] = [
  [0, 1, 2, 3], [0, 1, 3, 2], [0, 2, 1, 3], [0, 2, 3, 1], [0, 3, 1, 2], [0, 3, 2, 1],
  [1, 0, 2, 3], [1, 0, 3, 2], [1, 2, 0, 3], [1, 2, 3, 0], [1, 3, 0, 2], [1, 3, 2, 0],
  [2, 0, 1, 3], [2, 0, 3, 1], [2, 1, 0, 3], [2, 1, 3, 0], [2, 3, 0, 1], [2, 3, 1, 0],
  [3, 0, 1, 2], [3, 0, 2, 1], [3, 1, 0, 2], [3, 1, 2, 0], [3, 2, 0, 1], [3, 2, 1, 0]
];

// 前缀树缓存节点：某插入前缀（如 "0,2"）求解一次后，其后继魔方状态与步序
// 对所有共享该前缀的顺序完全一致，可直接复用（只读，勿改动 after）。
interface F2lPrefixNode {
  // 从父前缀状态到本前缀状态的原始（未化简）步序
  moves: number[];
  // 应用 moves 后的魔方状态
  after: CubieCube;
}

// Solve every insertion order (on a clone of the post-cross cube), collect the
// candidates and sort by total F2L length (ties keep the original order first
// because F2L_ORDERS emits [0,1,2,3] first and the sort is stable).
// 前缀树缓存：24 顺序 × 4 槽 = 96 次逐槽搜索中有 1/3 是重复的（同前缀后状态
// 相同）。按前缀去重后唯一搜索数 = 4+12+24+24 = 64 次，浅层（最便宜）搜索的
// 去重率最高；缓存命中不消耗共享预算（结果与重搜逐字节相同）。
async function enumerateF2l(postCross: CubieCube): Promise<F2lAlternative[]> {
  const out: F2lAlternative[] = [];
  const cache: Record<string, F2lPrefixNode> = {};
  const root: CubieCube = new CubieCube(postCross);
  for (let pi = 0; pi < F2L_ORDERS.length; pi++) {
    // The default order [0,1,2,3] is the first candidate and must always finish:
    // give it a guaranteed per-call budget (f2lSharedMode off).
    // All other orders share ONE single solve-wide budget pool, seeded ONCE at
    // pi==1 and depleted across the remaining 23 orders — NOT reset per order,
    // otherwise a hard scramble's full 24-order enumeration can still spend
    // ~34M+ nodes (~thousands of seconds) and OOM / trigger ANR. When the pool
    // runs out, later orders bail immediately, returning the best found so far.
    if (pi === 0) {
      setF2lSharedBudget(false);
    } else if (pi === 1) {
      setF2lSharedBudget(true); // seed the single shared pool here and keep it
    }
    const p = F2L_ORDERS[pi];
    const allMoves: number[] = [];
    const perSlot: number[][] = [];
    let cur: CubieCube = root;
    let ok = true;
    for (let s = 0; s < 4; s++) {
      // 前缀键：p[0],p[1],...,p[s]
      let key = '';
      for (let i = 0; i <= s; i++) {
        if (i > 0) {
          key += ',';
        }
        key += p[i];
      }
      let node: F2lPrefixNode | undefined = cache[key];
      if (node === undefined) {
        const targets: number[] = p.slice(0, s + 1);
        const work: CubieCube = new CubieCube(cur);
        const m = await solveF2lTargets(work, targets);
        if (m == null) {
          ok = false;
          break;
        }
        for (let i = 0; i < m.length; i++) {
          applyMoveIdx(work, m[i]);
        }
        node = { moves: m, after: work };
        cache[key] = node;
      }
      for (let i = 0; i < node.moves.length; i++) {
        allMoves.push(node.moves[i]);
      }
      perSlot.push(node.moves.slice());
      cur = node.after;
    }
    if (!ok) {
      continue;
    }
    const simp = simplifyMoves(allMoves);
    const labels: string[] = [];
    for (let i = 0; i < p.length; i++) {
      labels.push(SLOT_NAMES[p[i]]);
    }
    out.push({
      order: p.slice(), orderName: labels.join('→'),
      f2lSteps: simp.length, f2lAlg: movesToStr(simp),
      slotMoves: perSlot
    });
  }
  out.sort((a: F2lAlternative, b: F2lAlternative): number => a.f2lSteps - b.f2lSteps);
  return out;
}

function buildOutput(stages: StageResult[], solverAll: number[], rotIdx: number,
  f2lCands: F2lAlternative[]): SolveOutput {
  const stageSteps: number[] = [];
  const userMoves: number[] = [];
  for (let i = 0; i < stages.length; i++) {
    // 直接输出求解器帧 move（= 用户握姿坐标系：底面朝下、前面朝自己）。
    // 注意：不能再做 movesToUserFrame 转换——那会转回"打乱/标准坐标系"
    const simp = simplifyMoves(stages[i].moves);
    stageSteps.push(simp.length);
    for (let j = 0; j < simp.length; j++) {
      userMoves.push(simp[j]);
    }
  }
  const total = simplifyMoves(userMoves).length;
  const out: SolveOutput = {
    ok: true, error: '', totalSteps: total, stages: stages,
    stageSteps: stageSteps, userMoves: simplifyMoves(userMoves),
    userAlg: movesToStr(simplifyMoves(userMoves)), rotIdx: rotIdx
  };
  if (f2lCands.length > 0) {
    out.f2lAlternatives = f2lCands;
  }
  return out;
}

function fail(msg: string): SolveOutput {
  return { ok: false, error: msg, totalSteps: 0, stages: [],
    stageSteps: [], userMoves: [], userAlg: '', rotIdx: 0 };
}