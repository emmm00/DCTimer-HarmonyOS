// AltSolverRunner — 二阶 / 金字塔 / SQ1 / EOline / Petrus 求解的离线程入口。
//
// 为什么必须离线程：这些求解器首次调用要建查找表——
//   Cube2Face   10626 项（createPrun 逐层扩散）
//   Cube2Layer  同类量级
//   PyraminxV   3240 项
//   Sq1Shape    28561 项扫描 + 3678 项 BFS
// 在主线程建这些表会触发 ArkUI 的 watchdog（约 6s 杀应用），与 CfopSolver
// 的处理方式保持一致：能在 worker 里跑就在 worker 里跑，失败再回落主线程。
//
// @Concurrent 任务只允许引用 import 或局部变量，因此本模块独立成文件，
// 且每个任务只调用导入类的静态方法（与 CfopSolve / WarmCaches 同款写法）。
import { Cube2Face } from './Cube2Face';
import { Cube2Layer } from './Cube2Layer';
import { PyraminxV } from './PyraminxV';
import { Sq1Shape } from './Sq1Shape';
import { EOline } from './EOline';
import { Petrus } from './Petrus';
import { taskpool } from '@kit.ArkTS';

// ===== taskpool 任务 =====

@Concurrent
function cube2FaceTask(scramble: string, face: number): string {
  return Cube2Face.solveFace(scramble, face);
}

@Concurrent
function cube2LayerTask(scramble: string, face: number): string {
  return Cube2Layer.solveFirstLayer(scramble, face);
}

@Concurrent
function pyraminxTask(scramble: string, face: number): string {
  return PyraminxV.solveV(scramble, face);
}

@Concurrent
function sq1Task(type: number, scramble: string): string {
  return Sq1Shape.solve(type, scramble);
}

@Concurrent
function eolineTask(scramble: string, face: number): string {
  return EOline.solveEoline(scramble, face);
}

@Concurrent
function petrusTask(scramble: string, block: number): string {
  return Petrus.solvePetrus(scramble, block);
}

// ===== 对外入口：worker 优先，失败回落主线程 =====

/** 二阶「面法」：face 为 6 位掩码（D,U,L,R,F,B），返回每个选中面的解法 */
export async function solveTwoByTwoFace(scramble: string, face: number): Promise<string> {
  try {
    return await taskpool.execute(cube2FaceTask, scramble, face) as string;
  } catch (e) {
    return Cube2Face.solveFace(scramble, face);
  }
}

/** 二阶「一层法」：face 为 6 位掩码 */
export async function solveTwoByTwoLayer(scramble: string, face: number): Promise<string> {
  try {
    return await taskpool.execute(cube2LayerTask, scramble, face) as string;
  } catch (e) {
    return Cube2Layer.solveFirstLayer(scramble, face);
  }
}

/** 金字塔：face 为 4 位掩码，对应 D/L/R/F 四个朝向 */
export async function solvePyraminx(scramble: string, face: number): Promise<string> {
  try {
    return await taskpool.execute(pyraminxTask, scramble, face) as string;
  } catch (e) {
    return PyraminxV.solveV(scramble, face);
  }
}

/** SQ1：type 1 = FTM（按面计数），2 = TTM（按扭转计数） */
export async function solveSq1(scramble: string, type: number): Promise<string> {
  try {
    return await taskpool.execute(sq1Task, type, scramble) as string;
  } catch (e) {
    return Sq1Shape.solve(type, scramble);
  }
}

/** ZZ 法的 EOLine（棱定向 + 底棱） */
export async function solveEoline(scramble: string, face: number): Promise<string> {
  try {
    return await taskpool.execute(eolineTask, scramble, face) as string;
  } catch (e) {
    return EOline.solveEoline(scramble, face);
  }
}

/** Petrus 法前两阶段（2x2x2 块 + 扩到 2x2x3） */
export async function solvePetrus(scramble: string, block: number): Promise<string> {
  try {
    return await taskpool.execute(petrusTask, scramble, block) as string;
  } catch (e) {
    return Petrus.solvePetrus(scramble, block);
  }
}
