// WarmCaches — 求解器表离线程预热入口。
// @Concurrent 任务只能引用 import 或局部变量，不能调用同模块顶层函数，
// 因此像 CfopSolve/RouxSolve 一样独立成模块（SolverCore 不回引本模块，
// 避免循环依赖）。
import { setSbJointCacheDir, getSbJointCacheDir, ensureReady, warmJointCaches } from './SolverCore';
import { taskpool } from '@kit.ArkTS';

@Concurrent
function warmCachesTask(cacheDir: string): void {
  setSbJointCacheDir(cacheDir);
  ensureReady(); // 命中 solver_core.dat 则读盘，否则在本 worker 现建并落盘
  warmJointCaches(); // 左/右桥联合表：读盘或触发后台构建
}

// 启动预热（离线程版）：在 taskpool worker 里加载/构建全部缓存文件，主线程
// 零阻塞。由 Index.initAlgorithmCache 在首帧渲染后延迟触发——旧版启动即在
// 主线程分段建表并同步读 16MB 联合表缓存，首页要 ~3s 才渲染完。
export function warmSolverCachesOffThread(): void {
  const dir = getSbJointCacheDir();
  if (dir.length === 0) {
    return;
  }
  try {
    const p = taskpool.execute(warmCachesTask, dir);
    p.then((): void => {
    }, (): void => {
    });
  } catch (e) {
    // taskpool 不可用：跳过预热（求解路径会按需构建/加载）
  }
}
