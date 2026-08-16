export enum TimerState {
  READY = 0,
  RUNNING = 1,
  INSPECTING = 2,
  STOP = 3
}

/**
 * DCTTimer 计时引擎
 * 时间单位为毫秒（与原版 DCTimer.java 一致），+2 惩罚 = 2000ms。
 * 支持分段计时：设置 phaseCount > 0 后，计时中每次触摸记录一段，最后一段停止。
 */
export class DCTTimer {
  state: TimerState = TimerState.READY;
  time: number = 0; // 当前计时（毫秒）
  timeStart: number = 0;
  timeEnd: number = 0;
  inspectionState: number = 0; // 1=观察中, 2=+2, 3=DNF
  penaltyTime: number = 0;
  isDNF: boolean = false;
  canStart: boolean = false;
  // 分段计时
  phaseCount: number = 0;      // 总分段数，0=不分段
  currentPhase: number = 0;    // 当前段（从0开始）
  phaseTimes: number[] = [];   // 已记录的各段成绩（毫秒）

  private timerId: number | null = null;
  private inspectId: number | null = null;
  private callback: ((time: number, state: TimerState) => void) | null = null;
  private inspectionCallback: ((state: number, remainingSec: number) => void) | null = null;
  private phaseCallback: ((phaseIndex: number, phaseTime: number) => void) | null = null;
  private inspectAlertCallback: ((elapsedSec: number) => void) | null = null;

  setCallback(cb: (time: number, state: TimerState) => void): void {
    this.callback = cb;
  }

  setInspectionCallback(cb: (state: number, remainingSec: number) => void): void {
    this.inspectionCallback = cb;
  }

  /** 分段完成回调：phaseIndex 从 0 开始，phaseTime 为该段用时 */
  setPhaseCallback(cb: (phaseIndex: number, phaseTime: number) => void): void {
    this.phaseCallback = cb;
  }

  /** 观察 8 秒 / 12 秒提醒回调 */
  setInspectAlertCallback(cb: (elapsedSec: number) => void): void {
    this.inspectAlertCallback = cb;
  }

  /** 设置分段数并开始新一轮（清除旧分段） */
  setPhases(count: number): void {
    this.phaseCount = count;
    this.currentPhase = 0;
    this.phaseTimes = [];
  }

  count(): void {
    if (this.state === TimerState.READY) {
      this.state = TimerState.RUNNING;
      this.timeStart = Date.now();
      this.currentPhase = 0;
      this.phaseTimes = [];
      this.startClock();
    } else if (this.state === TimerState.INSPECTING) {
      this.state = TimerState.RUNNING;
      this.timeStart = Date.now();
      this.currentPhase = 0;
      this.phaseTimes = [];
      this.stopInspection();
      this.startClock();
    } else if (this.state === TimerState.RUNNING) {
      // 分段计时：未到最后一段时记录分段继续计时
      if (this.phaseCount > 0 && this.currentPhase < this.phaseCount - 1) {
        const split: number = Date.now() - this.timeStart;
        this.phaseTimes.push(split);
        if (this.phaseCallback) {
          this.phaseCallback(this.currentPhase, split);
        }
        this.currentPhase++;
        return;
      }
      this.state = TimerState.STOP;
      this.timeEnd = Date.now();
      this.time = this.timeEnd - this.timeStart;
      if (this.time < 100) {
        this.time = 100;
      }
      if (this.phaseCount > 0) {
        this.phaseTimes.push(this.time);
      }
      this.stopClock();
      if (this.callback) {
        this.callback(this.time, this.state);
      }
    }
  }

  startInspection(): void {
    this.state = TimerState.INSPECTING;
    this.inspectionState = 1;
    this.time = 0;
    this.startInspectTask();
  }

  reset(): void {
    this.state = TimerState.READY;
    this.time = 0;
    this.canStart = false;
    this.inspectionState = 0;
    this.penaltyTime = 0;
    this.isDNF = false;
    this.currentPhase = 0;
    this.phaseTimes = [];
    this.stopClock();
    this.stopInspection();
  }

  getPenaltyTime(): number {
    return this.penaltyTime;
  }

  checkIsDNF(): boolean {
    return this.isDNF;
  }

  private startClock(): void {
    this.timerId = setInterval(() => {
      this.time = Date.now() - this.timeStart;
      if (this.callback) {
        this.callback(this.time, this.state);
      }
    }, 17);
  }

  private stopClock(): void {
    if (this.timerId !== null) {
      clearInterval(this.timerId);
      this.timerId = null;
    }
  }

  private startInspectTask(): void {
    const startTime: number = Date.now();
    let eightSecAlerted: boolean = false;
    let twelveSecAlerted: boolean = false;
    this.inspectId = setInterval(() => {
      const elapsed: number = Date.now() - startTime;
      this.time = elapsed;
      if (elapsed >= 8000 && !eightSecAlerted) {
        eightSecAlerted = true;
        if (this.inspectAlertCallback) {
          this.inspectAlertCallback(8);
        }
      }
      if (elapsed >= 12000 && !twelveSecAlerted) {
        twelveSecAlerted = true;
        if (this.inspectAlertCallback) {
          this.inspectAlertCallback(12);
        }
      }
      if (elapsed < 15000) {
        this.inspectionState = 1;
        const remaining: number = Math.ceil((15000 - elapsed) / 1000);
        if (this.inspectionCallback) {
          this.inspectionCallback(1, remaining);
        }
      } else if (elapsed < 17000) {
        this.inspectionState = 2;
        this.penaltyTime = 2000;
        if (this.inspectionCallback) {
          this.inspectionCallback(2, 0);
        }
      } else {
        this.inspectionState = 3;
        this.isDNF = true;
        if (this.inspectionCallback) {
          this.inspectionCallback(3, 0);
        }
      }
    }, 200);
  }

  private stopInspection(): void {
    if (this.inspectId !== null) {
      clearInterval(this.inspectId);
      this.inspectId = null;
    }
  }
}
