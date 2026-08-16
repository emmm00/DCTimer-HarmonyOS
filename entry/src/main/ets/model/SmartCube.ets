/**
 * 智能魔方模型 - 对应 Android SmartCube.java
 * 注：鸿蒙中不包含 Java min2phase/CubieCube 库，核心状态通过字符串面块表示
 */

import { SmartCubeSolveReconstruction } from './SmartCubeSolveReconstruction';

export interface StateChangedCallback {
  onScrambled(cube: SmartCube): void;
  onSolved(cube: SmartCube): void;
}

export interface CompletionChecker {
  isComplete(cube: SmartCube): boolean;
}

/**
 * 工具函数：检查两个面块字符串是否一致（忽略整体旋转）
 * 在完整实现中需要完整的魔方旋转判断逻辑，此处提供接口
 */
function isSolvedIgnoringRotation(facelets: string): boolean {
  const solved: string = 'UUUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB';
  if (facelets === solved) {
    return true;
  }
  // 简单实现：只检查完全相等
  // 完整的旋转不变判断需通过 Utils 实现
  return false;
}

function isSameStateIgnoringRotation(state: string, target: string): boolean {
  if (state === target) {
    return true;
  }
  // 简单实现
  return false;
}

export class SmartCube {
  private type: number = 0;
  private version: number = 0;
  private deviceName: string = '';
  private cubeState: string = '';
  private batteryValue: number = 0;
  private rawData: number[] = [];
  private preIdx: number = 0;
  private result: number = 0;
  private moves: number = 0;
  private reconstructedMoves: number = 0;
  private preMoveList: number[] = [];
  private moveList: number[] = [];
  private solveStartState: string = '';
  private reconstruction: SmartCubeSolveReconstruction | null = null;
  private callback: StateChangedCallback | null = null;
  private completionChecker: CompletionChecker | null = null;
  private targetState: string = '';
  private scrambledNotified: boolean = false;

  constructor() {
    this.rawData = [];
  }

  getType(): number {
    return this.type;
  }

  setType(type: number): void {
    this.type = type;
  }

  getDeviceName(): string {
    return this.deviceName;
  }

  setDeviceName(deviceName: string): void {
    this.deviceName = deviceName;
  }

  getCubeState(): string {
    return this.cubeState;
  }

  setCubeState(state: string): number {
    this.cubeState = state;
    // 注：完整的 CubieCube 转换逻辑依赖 min2phase 库
    // 此处仅做状态检查和回调触发
    const check = 0; // 假设转换成功

    if (check === 0 && this.isTargetScrambleState(this.cubeState)) {
      this.scrambledNotified = true;
      if (this.callback) {
        this.callback.onScrambled(this);
      }
    }
    if (check === 0 && this.callback && this.completionChecker && this.isSolveComplete()) {
      this.callback.onSolved(this);
    }
    return check;
  }

  getVersion(): number {
    return this.version;
  }

  setVersion(version: number): void {
    this.version = version;
  }

  getBatteryValue(): number {
    return this.batteryValue;
  }

  setBatteryValue(batteryValue: number): void {
    this.batteryValue = batteryValue;
  }

  getResult(): number {
    return this.result;
  }

  setStateChangedCallback(callback: StateChangedCallback): void {
    this.callback = callback;
  }

  setCompletionChecker(completionChecker: CompletionChecker): void {
    this.completionChecker = completionChecker;
  }

  getMovesCount(): number {
    return this.moves;
  }

  getReconstructedMovesCount(): number {
    return this.reconstructedMoves;
  }

  getReconstruction(): SmartCubeSolveReconstruction | null {
    return this.reconstruction;
  }

  applyMove(move: number, time: number, scramble: string): void {
    this.rawData.push(move << 16 | time);
    // cc = cc.move(move) - 依赖 CubieCube，此处简化
    // cubeState = Util.toFaceCube(cc)

    if (scramble && scramble !== this.targetState) {
      this.targetState = scramble;
      this.scrambledNotified = false;
    }
    if (this.isTargetScrambleState(this.cubeState)) {
      this.scrambledNotified = true;
      if (this.callback) {
        this.callback.onScrambled(this);
      }
    }
    if (this.callback && this.isSolveComplete()) {
      this.callback.onSolved(this);
    }
  }

  private isSolveComplete(): boolean {
    if (this.completionChecker) {
      return this.completionChecker.isComplete(this);
    }
    return isSolvedIgnoringRotation(this.cubeState);
  }

  private isTargetScrambleState(state: string): boolean {
    if (this.scrambledNotified || !this.callback || !state || !this.targetState ||
      state.length === 0 || this.targetState.length === 0) {
      return false;
    }
    return state === this.targetState || isSameStateIgnoringRotation(state, this.targetState);
  }

  markScrambled(): void {
    this.preIdx = this.rawData.length;
    this.solveStartState = this.cubeState;
    this.scrambledNotified = true;
  }

  markSolveStarted(startState: string): void {
    if (this.rawData.length === 0) {
      this.preIdx = 0;
    } else {
      this.preIdx = this.rawData.length - 1;
    }
    this.solveStartState = startState;
  }

  markSolved(): void {
    this.cubeState = 'UUUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB';
    this.rawData = [];
    this.preIdx = 0;
    this.solveStartState = '';
    this.targetState = '';
    this.scrambledNotified = false;
  }

  resetSolveTracking(): void {
    this.rawData = [];
    this.preIdx = 0;
    this.solveStartState = this.cubeState;
    this.targetState = '';
    this.scrambledNotified = false;
  }

  clearLastReconstruction(): void {
    this.reconstruction = null;
    this.reconstructedMoves = 0;
  }

  calcResult(): void {
    this.result = 0;
    this.moves = this.rawData.length - this.preIdx;
    this.reconstructedMoves = 0;
    this.reconstruction = null;
    this.preMoveList = [];
    this.moveList = [];

    const solveMoves: SmartCubeSolveReconstruction.MoveEvent[] = [];
    let elapsed = 0;

    for (let i = 0; i < this.preIdx; i++) {
      const move = this.rawData[i] >> 16;
      if (this.preMoveList.length === 0) {
        this.preMoveList.push(move);
      } else if (this.preMoveList[this.preMoveList.length - 1] === move) {
        if (move % 3 === 1) {
          this.preMoveList.push(move);
        } else {
          const turn = Math.floor(move / 3);
          this.preMoveList.push(turn * 3 + 1);
        }
      } else {
        this.preMoveList.push(move);
      }
    }

    for (let i = this.preIdx; i < this.rawData.length; i++) {
      const delta = this.rawData[i] & 0xffff;
      if (i !== this.preIdx) {
        this.result += delta;
        elapsed += delta;
      }
      const move = this.rawData[i] >> 16;
      solveMoves.push(new SmartCubeSolveReconstruction.MoveEvent(move, delta, elapsed));

      if (this.moveList.length === 0) {
        this.moveList.push(move);
      } else if (this.moveList[this.moveList.length - 1] === move) {
        if (move % 3 === 1) {
          this.moveList.push(move);
        } else {
          const turn = Math.floor(move / 3);
          this.moveList[this.moveList.length - 1] = turn * 3 + 1;
        }
      } else {
        this.moveList.push(move);
      }
    }

    this.reconstruction = SmartCubeSolveReconstruction.fromRawMoves(this.solveStartState, solveMoves);
    this.reconstructedMoves = this.reconstruction.getMoveCount();
  }

  getMoveSequence(): string {
    if (this.reconstruction && this.reconstruction.getPrettySolve() &&
      this.reconstruction.getPrettySolve().length > 0) {
      return this.reconstruction.getPrettySolve(this.result);
    }
    const suff = ['', '2', '\''];
    let sb = '';
    for (let i = 0; i < this.moveList.length; i++) {
      const move = this.moveList[i];
      sb += 'URFDLB'.charAt(Math.floor(move / 3)) + suff[move % 3] + ' ';
    }
    return sb;
  }

  getSolveMeta(): string | null {
    if (!this.reconstruction) {
      return null;
    }
    return this.reconstruction.toJson(this.result);
  }
}
