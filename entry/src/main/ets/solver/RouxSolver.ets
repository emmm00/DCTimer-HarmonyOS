// RouxSolver — Roux full solve off-thread entry.
// Runs the heavy solve (FB -> SB -> CMLL -> LSE) on a taskpool worker so the
// ArkUI main thread is never blocked by the CPU-heavy block solves. The worker
// has its own SolverCore instance and builds/reuses its pruning tables there;
// only the plain-data SolveOutput crosses the worker boundary.
import { SolveOutput } from './SolverCore';
import { runRouxSolve } from './RouxSolve';
import { setSolverInWorker, setSbJointCacheDir, warmJointCaches, getSbJointCacheDir } from './SolverCore';
import { taskpool } from '@kit.ArkTS';

@Concurrent
async function rouxSolveTask(scramble: string, bottom: number, left: number,
  cacheDir: string): Promise<SolveOutput> {
  setSolverInWorker(true);
  try {
    // 工作线程持有独立的模块状态，必须显式把缓存目录传进来再加载，
    // 否则左桥/右桥联合剪枝表在每个 Roux 求解任务里都被现场重建（主因）。
    // 注意：cacheDir 必须是目录本身（getSbJointCacheDir 返回值），
    // setSbJointCacheDir 内部会自行拼接各表文件名。
    setSbJointCacheDir(cacheDir);
    warmJointCaches();
    return await runRouxSolve(scramble, bottom, left);
  } finally {
    setSolverInWorker(false);
  }
}

export async function solveRoux(scramble: string, bottom: number, left: number): Promise<SolveOutput> {
  const cacheDir: string = getSbJointCacheDir();
  try {
    return await taskpool.execute(rouxSolveTask, scramble, bottom, left, cacheDir) as SolveOutput;
  } catch (e) {
    // taskpool unavailable/failed — cooperative main-thread fallback (non-blocking)
    // 主线程的联合剪枝表已在启动时预热落盘；主线程回退路径直接复用内存表
    return await runRouxSolve(scramble, bottom, left);
  }
}