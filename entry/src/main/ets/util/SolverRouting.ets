/**
 * SolverRouting — 魔方编码 → 可用求解器 的路由规则（单一事实来源）。
 *
 * 为什么单独成文件：求解按钮的显示条件（Index.ets）和求解弹窗的页签构成
 * （MethodSolverView.ets）必须用同一套判断，否则会出现"按钮在但弹窗没页签"
 * 或反过来的错位。此前两处各写一份，Pyraminx/Square-1 的独立分类编码
 * （1124~1126 / 1156~1160）就漏掉过一次。
 *
 * 编码来源：Index.ets 的 PUZZLE_CATEGORIES（WCA 组 + 各魔方独立组）。
 */

/** 三阶项目（支持十字/CFOP/桥式/ZZ/Petrus） */
export function is333Solver(code: number): boolean {
  return code === 33 || code === 31 || code === 32 || code === 34 || code === 35;
}

/** 二阶项目：WCA 二阶速拧 22 + 2x2 分类 900~910（random state/3-gen/CLL training 等） */
export function is222Solver(code: number): boolean {
  return code === 22 || (code >= 900 && code <= 910);
}

/** 金字塔：WCA 70 + Pyraminx 分类 1124~1126 */
export function isPyraminxSolver(code: number): boolean {
  return code === 70 || (code >= 1124 && code <= 1126);
}

/** Square-1：WCA 40 + Square-1 分类 1156~1160 */
export function isSq1Solver(code: number): boolean {
  return code === 40 || (code >= 1156 && code <= 1160);
}

/** 当前项目是否显示「求解」按钮 */
export function hasSolver(code: number): boolean {
  return is333Solver(code) || is222Solver(code) || isPyraminxSolver(code) || isSq1Solver(code);
}

/** 是否走 AltSolverView（非三阶：二阶/金字塔/SQ1 整体由一个组件承接） */
export function isAltSolver(code: number): boolean {
  return is222Solver(code) || isPyraminxSolver(code) || isSq1Solver(code);
}

/** 求解弹窗的页签名；三阶固定五页，其余由 AltSolverView 自管 */
export function solverTabLabels(code: number): string[] {
  if (is222Solver(code)) {
    return ['面法', '一层法'];
  }
  if (isPyraminxSolver(code)) {
    return ['金字塔'];
  }
  if (isSq1Solver(code)) {
    return ['SQ1'];
  }
  return ['十字', 'CFOP', '桥式', 'ZZ', 'Petrus'];
}
