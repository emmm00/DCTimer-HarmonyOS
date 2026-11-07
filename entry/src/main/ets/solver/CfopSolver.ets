// CfopSolver — CFOP full solve off-thread entry.
// The heavy solve (Cross -> F2L -> OLL -> PLL, 24 insertion-order enumeration)
// runs on a taskpool worker so the ArkUI main thread is never blocked: the
// main-thread watchdog kills the app past ~6s on slow devices, and a hard
// scramble's full 24-order enumeration takes ~10-80s. The worker owns its own
// SolverCore module instance (builds/reuses all pruning tables there); only the
// plain-data SolveOutput crosses the worker boundary. Falls back to a
// cooperative main-thread solve if taskpool is unavailable.
import { SolveOutput } from './SolverCore';
import { runCfopSolve } from './CfopSolve';
import { setSolverInWorker, setSbJointCacheDir, getSbJointCacheDir } from './SolverCore';
import { taskpool } from '@kit.ArkTS';

@Concurrent
async function cfopSolveTask(scramble: string, bottom: number, front: number,
  forcedJson: string, cacheDir: string): Promise<SolveOutput> {
  // inside the worker there is no UI to yield to: swap the per-node
  // setTimeout yields for no-op microtasks (see SolverCore.setSolverInWorker)
  setSolverInWorker(true);
  try {
    if (cacheDir.length > 0) {
      // worker 持有独立模块状态：显式设置缓存目录，ensureReadyAsync 才能命中
      // solver_core.dat（否则首次求解要在 worker 现建全部表，慢数秒）。
      // cacheDir 是目录本身（getSbJointCacheDir 返回值），文件名由内部拼接。
      setSbJointCacheDir(cacheDir);
    }
    let forced: number[] | undefined = undefined;
    if (forcedJson.length > 0) {
      forced = JSON.parse(forcedJson) as number[];
    }
    return await runCfopSolve(scramble, bottom, front, forced);
  } finally {
    setSolverInWorker(false);
  }
}

export async function solveCFOP(scramble: string, bottom: number, front: number,
  forcedOrder?: number[]): Promise<SolveOutput> {
  const forcedJson: string = forcedOrder != null ? JSON.stringify(forcedOrder) : '';
  const cacheDir: string = getSbJointCacheDir();
  try {
    return await taskpool.execute(cfopSolveTask, scramble, bottom, front, forcedJson,
      cacheDir) as SolveOutput;
  } catch (e) {
    // taskpool unavailable/failed — cooperative main-thread fallback (non-blocking)
    // 主线程的缓存目录已在启动时设置，ensureReadyAsync 会先尝试读盘
    return await runCfopSolve(scramble, bottom, front, forcedOrder);
  }
}