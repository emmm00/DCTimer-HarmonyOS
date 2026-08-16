/**
 * 蓝牙 BLE 管理器（简化版）
 *
 * 负责智能魔方的扫描、连接、数据接收。
 * 使用 HarmonyOS @kit.ConnectivityKit 的 BLE API。
 *
 * 注意: 完整的魔方协议解析需在实际硬件上调试，
 * BLE API 的具体回调签名取决于 SDK 版本。
 *
 * 参考: DCTimer-BLE BluetoothTools.java
 */

import { ble } from '@kit.ConnectivityKit';
import {
  CubeType, CubeDeviceInfo, CubeConnectionState, CubeMove,
  guessCubeType, parseGiikerMove, GIIKER_SERVICES, GAN_SERVICES
} from './SmartCubeProtocol';

/** BLE 状态变化回调 */
export interface BleCallbacks {
  onDeviceFound: (devices: CubeDeviceInfo[]) => void;
  onConnectionStateChange: (state: CubeConnectionState, deviceName: string) => void;
  onCubeMove: (move: CubeMove) => void;
  onBatteryChange: (level: number) => void;
  onError: (message: string) => void;
}

export class BleManager {
  private callbacks: BleCallbacks | null = null;
  private scanResults: CubeDeviceInfo[] = [];
  private connectionState: CubeConnectionState = CubeConnectionState.DISCONNECTED;
  private connectedDevice: string = '';
  private connectedDeviceName: string = '';
  private gattClient: ble.GattClientDevice | null = null;
  private isScanning: boolean = false;
  private moveCallback: ((move: CubeMove) => void) | null = null;

  // --- 扫描 ---

  startScan(cb: BleCallbacks): void {
    this.callbacks = cb;
    this.scanResults = [];
    this.connectionState = CubeConnectionState.SCANNING;
    this.isScanning = true;

    try {
      const scanOptions: ble.ScanOptions = {
        interval: 0,
        dutyMode: ble.ScanDuty.SCAN_MODE_LOW_POWER,
        matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE
      };
      ble.startBLEScan(null, scanOptions);
    } catch (e) {
      if (this.callbacks) {
        this.callbacks.onError('BLE 扫描启动失败');
      }
      return;
    }

    // 监听扫描结果 — BLEDeviceFind 是 HarmonyOS 标准的 BLE 扫描事件
    ble.on('BLEDeviceFind', (data: Array<ble.ScanResult>): void => {
      if (!this.isScanning) {
        return;
      }
      for (const result of data) {
        const name: string = result.deviceName || '';
        const addr: string = result.deviceId;
        const type: CubeType = guessCubeType(name);
        if (type === CubeType.UNKNOWN) {
          continue;
        }
        // 去重
        const exists: boolean = this.scanResults.some((d: CubeDeviceInfo): boolean => d.address === addr);
        if (exists) {
          continue;
        }
        const dev: CubeDeviceInfo = {
          address: addr,
          name: name,
          type: type,
          rssi: result.rssi || -100
        };
        this.scanResults.push(dev);
        if (this.callbacks) {
          this.callbacks.onDeviceFound([...this.scanResults]);
        }
      }
    });
  }

  stopScan(): void {
    this.isScanning = false;
    try {
      ble.stopBLEScan();
    } catch (_e) {
      // ignore
    }
  }

  getScanResults(): CubeDeviceInfo[] {
    return [...this.scanResults];
  }

  // --- 连接 ---

  connect(device: CubeDeviceInfo): void {
    this.stopScan();
    this.connectionState = CubeConnectionState.CONNECTING;
    this.connectedDevice = device.address;
    this.connectedDeviceName = device.name;
    if (this.callbacks) {
      this.callbacks.onConnectionStateChange(CubeConnectionState.CONNECTING, device.name);
    }

    try {
      this.gattClient = ble.createGattClientDevice(device.address);

      // 监听连接状态变化
      this.gattClient.on('BLEConnectionStateChange',
        (data: ble.BLEConnectionChangeState): void => {
        if (data.state === 2) {
          // 已连接 - 自动标记为就绪
          this.connectionState = CubeConnectionState.READY;
          if (this.callbacks) {
            this.callbacks.onConnectionStateChange(
              CubeConnectionState.READY, this.connectedDeviceName);
          }
        } else if (data.state === 0) {
          // 断开连接
          this.connectionState = CubeConnectionState.DISCONNECTED;
          if (this.callbacks) {
            this.callbacks.onConnectionStateChange(
              CubeConnectionState.DISCONNECTED, this.connectedDeviceName);
          }
          this.cleanupConnection();
        }
      });

      // 连接
      this.gattClient.connect();
    } catch (e) {
      this.connectionState = CubeConnectionState.DISCONNECTED;
      if (this.callbacks) {
        this.callbacks.onError('连接失败');
      }
    }
  }

  disconnect(): void {
    this.stopScan();
    if (this.gattClient) {
      try {
        this.gattClient.disconnect();
        this.gattClient.close();
      } catch (_e) {
        // ignore
      }
    }
    this.cleanupConnection();
  }

  private cleanupConnection(): void {
    this.gattClient = null;
    this.connectedDevice = '';
    this.connectedDeviceName = '';
    this.connectionState = CubeConnectionState.DISCONNECTED;
  }

  getConnectionState(): CubeConnectionState {
    return this.connectionState;
  }

  getConnectedDeviceName(): string {
    return this.connectedDeviceName;
  }

  getConnectedDeviceAddress(): string {
    return this.connectedDevice;
  }

  setMoveCallback(cb: ((move: CubeMove) => void) | null): void {
    this.moveCallback = cb;
  }

  destroy(): void {
    this.disconnect();
    this.callbacks = null;
    this.moveCallback = null;
    this.scanResults = [];
  }
}

/** 全局单例 */
export const bleManager: BleManager = new BleManager();
