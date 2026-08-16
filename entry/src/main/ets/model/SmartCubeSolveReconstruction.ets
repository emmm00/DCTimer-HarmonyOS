/**
 * 智能魔方解法重构模型 - 对应 Android SmartCubeSolveReconstruction.java
 * 注：完整的 min2phase/CubieCube 依赖在鸿蒙中需要额外 C/ArkTS 实现，
 * 此处保留完整的数据结构和核心逻辑框架
 */

export class SmartCubeSolveReconstruction {
  static readonly SLICE_COMBO_WINDOW_MS: number = 100;
  static readonly METHOD_CFOP: number = 0;
  static readonly METHOD_ROUX: number = 1;
  static readonly SOLVED_FACELET: string = 'UUUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB';
  static readonly PRETTY_FACES: string = 'URFDLBEMS';
  static readonly SUFFIXES: string = ' 2\'';
  static readonly CFOP_PHASE_NAMES: string[] = ['Cross', 'F2L 1', 'F2L 2', 'F2L 3', 'F2L 4', 'OLL', 'PLL'];
  static readonly ROUX_PHASE_NAMES: string[] = ['FB', 'SB', 'CMLL', 'L6E'];

  static readonly CENTER_ROT: number[][] = [
    [0, 2, 4, 3, 5, 1], // y'
    [5, 1, 0, 2, 4, 3], // x'
    [4, 0, 2, 1, 3, 5]  // z
  ];

  private rawMoves: MoveEvent[];
  private reconstructedMoves: PrettyMove[];
  private phases: Phase[];
  private solveMethod: number;
  private prettySolve: string;
  private moveSequence: string;
  private moveCount: number;

  private constructor(
    rawMoves: MoveEvent[],
    reconstructedMoves: PrettyMove[],
    phases: Phase[],
    solveMethod: number
  ) {
    this.rawMoves = rawMoves;
    this.reconstructedMoves = reconstructedMoves;
    this.phases = phases;
    this.solveMethod = solveMethod;
    this.prettySolve = this.buildPrettySolve(phases, reconstructedMoves);
    this.moveSequence = this.buildMoveSequence(reconstructedMoves);
    this.moveCount = this.countNonRotationMoves(reconstructedMoves);
  }

  static fromRawMoves(startFacelet: string, rawMoves: MoveEvent[]): SmartCubeSolveReconstruction {
    // 注：完整实现依赖 Utils.orientSmartCubeMove 和 CubieCube 计算阶段，
    // 此处保留数据结构和接口框架
    const displayRawMoves = rawMoves;
    const solveMethod = 0; // 默认 CFOP

    // 构建空阶段列表
    const phaseNames = SmartCubeSolveReconstruction.CFOP_PHASE_NAMES;
    const phases: Phase[] = [];
    for (const name of phaseNames) {
      phases.push(new Phase(name, '', 0, 0, 0));
    }

    return new SmartCubeSolveReconstruction(displayRawMoves, [], phases, solveMethod);
  }

  getPrettySolve(): string {
    return this.prettySolve;
  }

  getPrettySolve(solveTimeMs: number): string {
    return this.appendSolveStats(this.prettySolve, solveTimeMs);
  }

  getMoveSequence(): string {
    return this.moveSequence;
  }

  getMoveCount(): number {
    return this.moveCount;
  }

  toJson(solveTimeMs: number): string {
    let sb = '';
    sb += '{';
    sb += this.jsonField('version', '1');
    sb += ',';
    sb += this.jsonField('method', this.getMethodId(this.solveMethod));
    sb += ',';
    sb += '"moveCount":' + this.moveCount;
    sb += ',';
    sb += '"solveTimeMs":' + Math.max(0, solveTimeMs);
    sb += ',';
    sb += this.jsonField('moves', this.moveSequence);
    sb += ',';
    sb += this.jsonField('prettySolve', this.getPrettySolve(solveTimeMs));
    sb += ',';
    sb += '"phases":[';
    for (let i = 0; i < this.phases.length; i++) {
      if (i > 0) sb += ',';
      const phase = this.phases[i];
      sb += '{';
      sb += this.jsonField('name', phase.name);
      sb += ',';
      sb += '"moveCount":' + phase.moveCount;
      sb += ',';
      sb += '"startMs":' + phase.startMs;
      sb += ',';
      sb += '"endMs":' + phase.endMs;
      sb += ',';
      sb += this.jsonField('moves', phase.moves);
      sb += '}';
    }
    sb += ']';
    sb += '}';
    return sb;
  }

  private buildPrettySolve(phases: Phase[], moves: PrettyMove[]): string {
    if (phases.length === 0) {
      return this.buildMoveSequence(moves);
    }
    let sb = '';
    for (const phase of phases) {
      if (!phase.moves || phase.moves.length === 0) {
        continue;
      }
      if (sb.length > 0) sb += '\n';
      sb += phase.moves + ' // ' + phase.name;
    }
    if (sb.length === 0) {
      return this.buildMoveSequence(moves);
    }
    return sb;
  }

  private appendSolveStats(solveText: string, solveTimeMs: number): string {
    let sb = '';
    if (solveText && solveText.length > 0) {
      sb += solveText.trim() + '\n';
    }
    sb += 'STM: ' + this.moveCount + ' moves\n';
    const tps = solveTimeMs > 0 ? (this.moveCount * 1000 / solveTimeMs) : 0;
    sb += 'TPS: ' + tps.toFixed(1);
    return sb;
  }

  private buildMoveSequence(moves: PrettyMove[]): string {
    if (!moves || moves.length === 0) {
      return '';
    }
    let sb = '';
    for (const move of moves) {
      if (sb.length > 0) sb += ' ';
      sb += move.notation().trim();
    }
    return sb;
  }

  private countNonRotationMoves(moves: PrettyMove[], start: number = 0, end?: number): number {
    if (!moves || moves.length === 0) {
      return 0;
    }
    let count = 0;
    const safeEnd = end !== undefined ? Math.min(end, moves.length - 1) : moves.length - 1;
    for (let i = Math.max(0, start); i <= safeEnd; i++) {
      if (!moves[i].isRotation()) {
        count++;
      }
    }
    return count;
  }

  private getMethodId(solveMethod: number): string {
    return solveMethod === SmartCubeSolveReconstruction.METHOD_ROUX ? '333-smart-roux' : '333-smart-cf4op';
  }

  private jsonField(key: string, value: string): string {
    return '"' + SmartCubeSolveReconstruction.escapeJson(key) + '":"' +
      SmartCubeSolveReconstruction.escapeJson(value) + '"';
  }

  static escapeJson(value: string): string {
    if (!value) {
      return '';
    }
    let sb = '';
    for (let i = 0; i < value.length; i++) {
      const ch = value.charAt(i);
      switch (ch) {
        case '\\':
          sb += '\\\\';
          break;
        case '"':
          sb += '\\"';
          break;
        case '\n':
          sb += '\\n';
          break;
        case '\r':
          sb += '\\r';
          break;
        case '\t':
          sb += '\\t';
          break;
        default:
          if (ch.charCodeAt(0) < 0x20) {
            const hex = ch.charCodeAt(0).toString(16);
            sb += '\\u' + ('0000' + hex).slice(-4);
          } else {
            sb += ch;
          }
          break;
      }
    }
    return sb;
  }
}

// 内嵌类

export namespace SmartCubeSolveReconstruction {
  export class MoveEvent {
    move: number;
    deltaMs: number;
    elapsedMs: number;

    constructor(move: number, deltaMs: number, elapsedMs: number) {
      this.move = move;
      this.deltaMs = deltaMs;
      this.elapsedMs = elapsedMs;
    }
  }
}

class PrettyMove {
  axis: number;
  pow: number;
  startRawIndex: number;
  endRawIndex: number;
  startMs: number;
  endMs: number;

  constructor(axis: number, pow: number, startRawIndex: number, endRawIndex: number, startMs: number, endMs: number) {
    this.axis = axis;
    this.pow = pow;
    this.startRawIndex = startRawIndex;
    this.endRawIndex = endRawIndex;
    this.startMs = startMs;
    this.endMs = endMs;
  }

  notation(): string {
    return SmartCubeSolveReconstruction.PRETTY_FACES.charAt(this.axis) +
      SmartCubeSolveReconstruction.SUFFIXES.charAt(this.pow);
  }

  isRotation(): boolean {
    return false;
  }
}

class Phase {
  name: string;
  moves: string;
  moveCount: number;
  startMs: number;
  endMs: number;

  constructor(name: string, moves: string, moveCount: number, startMs: number, endMs: number) {
    this.name = name;
    this.moves = moves;
    this.moveCount = moveCount;
    this.startMs = startMs;
    this.endMs = endMs;
  }
}
