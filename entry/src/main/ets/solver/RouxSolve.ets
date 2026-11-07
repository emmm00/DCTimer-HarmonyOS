// RouxSolve — Roux full solve implementation (FB -> SB -> CMLL -> LSE).
// Kept in its own module so a taskpool @Concurrent task (which may only use
// import/local variables, not same-module top-level functions) can import it.
import {
  ensureReadyAsync, ensureRouxJointsAsync, findRotationRoux, rotateScrambleByIdx, cubeFromTokens,
  FB, SB, solveSB, lookupCmllOri, lookupCmllPer, solveLSE,
  simplifyMoves, movesToStr, applyMoveIdx, isSolvedCube,
  SolveOutput, StageResult
} from './SolverCore';

export async function runRouxSolve(scramble: string, bottom: number, left: number): Promise<SolveOutput> {
  await ensureReadyAsync();
  // 左桥 + 右桥联合剪枝表一起就绪：内存/磁盘缓存命中则毫秒级返回；
  // 首次（无缓存）时两张表在 taskpool 并行构建，墙钟时间约等于单张。
  await ensureRouxJointsAsync();
  const rotIdx = findRotationRoux(bottom, left);
  if (rotIdx < 0) {
    return fail('无法确定桥式方向');
  }
  const remapped = rotateScrambleByIdx(scramble, rotIdx);
  const cube = cubeFromTokens(remapped);
  const stages: StageResult[] = [];
  const solverAll: number[] = [];

  // FB (left block)
  const fb0 = FB.extract(cube);
  if (fb0 == null) {
    return fail('左桥提取失败');
  }
  const fbMoves = FB.solve(fb0.c, fb0.e, 12);
  if (fbMoves == null) {
    return fail('左桥无解');
  }
  for (let i = 0; i < fbMoves.length; i++) {
    applyMoveIdx(cube, fbMoves[i]);
  }
  for (let i = 0; i < fbMoves.length; i++) {
    solverAll.push(fbMoves[i]);
  }
  stages.push({ name: '左桥', moves: fbMoves.slice() });
  {
    const chk = FB.extract(cube);
    if (chk == null || !FB.isSolved(chk.c, chk.e)) {
      return fail('左桥校验失败');
    }
  }

  // SB (right block, preserving FB)
  const sbMoves = await solveSB(cube);
  if (sbMoves == null) {
    return fail('右桥无解');
  }
  for (let i = 0; i < sbMoves.length; i++) {
    applyMoveIdx(cube, sbMoves[i]);
  }
  for (let i = 0; i < sbMoves.length; i++) {
    solverAll.push(sbMoves[i]);
  }
  stages.push({ name: '右桥', moves: sbMoves.slice() });
  {
    const chk = FB.extract(cube);
    const chk2 = SB.extract(cube);
    if (chk == null || !FB.isSolved(chk.c, chk.e) || chk2 == null || !SB.isSolved(chk2.c, chk2.e)) {
      return fail('右桥校验失败');
    }
  }

  // CMLL step 1: orient U corners
  const oriMoves = lookupCmllOri(cube);
  if (oriMoves == null) {
    return fail('CMLL 方向无匹配');
  }
  for (let i = 0; i < oriMoves.length; i++) {
    applyMoveIdx(cube, oriMoves[i]);
  }
  for (let i = 0; i < oriMoves.length; i++) {
    solverAll.push(oriMoves[i]);
  }
  stages.push({ name: 'CMLL·朝向', moves: oriMoves.slice() });
  for (let i = 0; i < 4; i++) {
    if (cube.co[i] !== 0) {
      return fail('CMLL 方向校验失败');
    }
  }

  // CMLL step 2: permute U corners (co already 0)
  const perMoves = lookupCmllPer(cube);
  if (perMoves == null) {
    return fail('CMLL 排列无匹配');
  }
  for (let i = 0; i < perMoves.length; i++) {
    applyMoveIdx(cube, perMoves[i]);
  }
  for (let i = 0; i < perMoves.length; i++) {
    solverAll.push(perMoves[i]);
  }
  stages.push({ name: 'CMLL·排列', moves: perMoves.slice() });
  {
    const chk = FB.extract(cube);
    const chk2 = SB.extract(cube);
    if (chk == null || !FB.isSolved(chk.c, chk.e) || chk2 == null || !SB.isSolved(chk2.c, chk2.e)) {
      return fail('CMLL 破坏桥');
    }
    for (let i = 0; i < 4; i++) {
      if (cube.cp[i] !== i || cube.co[i] !== 0) {
        return fail('CMLL 校验失败');
      }
    }
  }

  // LSE
  const lseMoves = solveLSE(cube);
  if (lseMoves == null) {
    return fail('LSE 无解');
  }
  for (let i = 0; i < lseMoves.length; i++) {
    applyMoveIdx(cube, lseMoves[i]);
  }
  for (let i = 0; i < lseMoves.length; i++) {
    solverAll.push(lseMoves[i]);
  }
  stages.push({ name: 'LSE', moves: lseMoves.slice() });
  if (!isSolvedCube(cube)) {
    return fail('LSE 校验失败');
  }

  return buildOutput(stages, solverAll, rotIdx);
}

function buildOutput(stages: StageResult[], solverAll: number[], rotIdx: number): SolveOutput {
  const stageSteps: number[] = [];
  const userMoves: number[] = [];
  for (let i = 0; i < stages.length; i++) {
    // 直接输出求解器帧 move（= 用户握姿坐标系：底面朝下、前面/左侧朝自己）。
    const simp = simplifyMoves(stages[i].moves);
    stageSteps.push(simp.length);
    for (let j = 0; j < simp.length; j++) {
      userMoves.push(simp[j]);
    }
  }
  const final = simplifyMoves(userMoves);
  return {
    ok: true, error: '', totalSteps: final.length, stages: stages,
    stageSteps: stageSteps, userMoves: final,
    userAlg: movesToStr(final), rotIdx: rotIdx
  };
}

function fail(msg: string): SolveOutput {
  return { ok: false, error: msg, totalSteps: 0, stages: [],
    stageSteps: [], userMoves: [], userAlg: '', rotIdx: 0 };
}