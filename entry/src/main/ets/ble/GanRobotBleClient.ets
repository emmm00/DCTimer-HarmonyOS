// GAN 机器人 BLE 客户端
import { BLEGattHandle, BLEServiceHandle, BLECharacteristicHandle } from './SmartCubeProtocol';
import { GanRobotProtocol, GanRobotCodec } from './GanRobotProtocol';

export class GanRobotBleClient {
  private static gatt: BLEGattHandle | null = null;
  private static statusCharacteristic: BLECharacteristicHandle | null = null;
  private static moveCharacteristic: BLECharacteristicHandle | null = null;
  private static callback: RobotCallback | null = null;

  static setCallback(cb: RobotCallback): void {
    GanRobotBleClient.callback = cb;
  }

  static attach(gatt: BLEGattHandle, status: BLECharacteristicHandle, move: BLECharacteristicHandle): void {
    GanRobotBleClient.gatt = gatt;
    GanRobotBleClient.statusCharacteristic = status;
    GanRobotBleClient.moveCharacteristic = move;
  }

  static isReady(): boolean {
    return GanRobotBleClient.gatt !== null && GanRobotBleClient.statusCharacteristic !== null && GanRobotBleClient.moveCharacteristic !== null;
  }

  static clear(): void {
    GanRobotBleClient.statusCharacteristic = null;
    GanRobotBleClient.moveCharacteristic = null;
    GanRobotBleClient.gatt = null;
  }

  static disconnect(): void {
    if (GanRobotBleClient.gatt) {
      GanRobotBleClient.gatt.disconnect();
    }
  }

  static close(): void {
    const g = GanRobotBleClient.gatt;
    GanRobotBleClient.clear();
    if (g) g.close();
  }

  static writeMovePacket(packet: number[]): boolean {
    const gatt = GanRobotBleClient.gatt;
    const move = GanRobotBleClient.moveCharacteristic;
    if (!gatt || !move) return false;
    move.setValue(packet);
    return gatt.writeCharacteristic(move);
  }

  static readMovesRemaining(): number {
    const gatt = GanRobotBleClient.gatt;
    const status = GanRobotBleClient.statusCharacteristic;
    if (!gatt || !status) return 0;
    gatt.readCharacteristic(status);
    // 需要异步回调获取结果，简化返回
    return 0;
  }
}

export interface RobotCallback {
  onConnected(): void;
  onDisconnected(): void;
  onStatusChanged(movesRemaining: number): void;
}

// GAN 机器人会话状态
export class GanRobotSessionState {
  private static latestMainScramble: string = '';
  private static latestMainTargetState: string = '';
  private static latestSmartCubeState: string = '';
  private static robotMoving: boolean = false;
  private static stateChangeListener: OnRobotStateChangeListener | null = null;

  static setLatestSmartCubeState(cubeState: string): void {
    GanRobotSessionState.latestSmartCubeState = cubeState || '';
  }

  static getLatestSmartCubeState(): string {
    return GanRobotSessionState.latestSmartCubeState;
  }

  static setLatestMainScramble(scramble: string): void {
    GanRobotSessionState.latestMainScramble = scramble || '';
  }

  static getLatestMainScramble(): string {
    return GanRobotSessionState.latestMainScramble;
  }

  static setLatestMainTargetState(targetState: string): void {
    GanRobotSessionState.latestMainTargetState = targetState || '';
  }

  static getLatestMainTargetState(): string {
    return GanRobotSessionState.latestMainTargetState;
  }

  static setRobotMoving(moving: boolean): void {
    const wasMoving = GanRobotSessionState.robotMoving;
    GanRobotSessionState.robotMoving = moving;
    const listener = GanRobotSessionState.stateChangeListener;
    if (!wasMoving && moving && listener) {
      listener.onRobotExecutionStart();
    } else if (wasMoving && !moving && listener) {
      listener.onRobotExecutionEnd();
    }
  }

  static isRobotMoving(): boolean {
    return GanRobotSessionState.robotMoving;
  }

  static setStateChangeListener(listener: OnRobotStateChangeListener | null): void {
    GanRobotSessionState.stateChangeListener = listener;
  }
}

export interface OnRobotStateChangeListener {
  onRobotExecutionStart(): void;
  onRobotExecutionEnd(): void;
}

// GAN 机器人控制器
export class GanRobotController {
  static readonly ACTION_NONE = 0;
  static readonly ACTION_SOLVE = 1;
  static readonly ACTION_SCRAMBLE = 2;
  private static robotButtonAction: number = GanRobotController.ACTION_SOLVE;

  static getRobotButtonAction(): number {
    return GanRobotController.robotButtonAction;
  }

  static setRobotButtonAction(action: number): void {
    GanRobotController.robotButtonAction = action;
  }

  static handleRobotButtonEvent(rawValue: number[]): void {
    const action = GanRobotController.getRobotButtonAction();
    if (!GanRobotProtocol.isButtonPressEvent(rawValue)) return;
    if (action === GanRobotController.ACTION_NONE) return;
    if (GanRobotSessionState.isRobotMoving()) return;
    // 事件由外部回调处理
  }
}

// GAN 机器人执行器 (简化版)
export class GanRobotExecutor {
  private static listener: ExecutorListener | null = null;
  private static isSending: boolean = false;

  static setListener(l: ExecutorListener | null): void {
    GanRobotExecutor.listener = l;
  }

  static getSending(): boolean {
    return GanRobotExecutor.isSending;
  }

  static setSending(sending: boolean): void {
    GanRobotExecutor.isSending = sending;
  }

  static executeScramble(scramble: string): void {
    if (!scramble) return;
    GanRobotSessionState.setRobotMoving(true);
    GanRobotExecutor.setSending(true);
    try {
      const packets = GanRobotCodec.encodeScramble(scramble);
      for (let i = 0; i < packets.length; i++) {
        const success = GanRobotBleClient.writeMovePacket(packets[i]);
        if (!success) {
          GanRobotExecutor.listener?.onStatus('发送失败');
          break;
        }
        GanRobotExecutor.listener?.onStatus(`第 ${i + 1}/${packets.length} 组已发送`);
      }
      GanRobotExecutor.listener?.onStatus('发送完成');
    } catch (e) {
      GanRobotExecutor.listener?.onStatus('发送错误: ' + e);
    } finally {
      GanRobotExecutor.setSending(false);
      GanRobotSessionState.setRobotMoving(false);
      GanRobotExecutor.listener?.onSendingChanged();
    }
  }
}

export interface ExecutorListener {
  onStatus(message: string): void;
  onSendingChanged(): void;
}
