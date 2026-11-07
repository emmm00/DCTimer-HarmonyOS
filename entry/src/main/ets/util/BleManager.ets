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
import { BusinessError } from '@kit.BasicServicesKit';

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
  private scanErrorCount: number = 0;

  startScan(cb: BleCallbacks): void {
    this.callbacks = cb;
    this.scanResults = [];
    this.scanErrorCount = 0; // 每次扫描重置重试计数
    this.connectionState = CubeConnectionState.SCANNING;
    this.isScanning = true;

    // 先注销旧监听，避免重复注册导致首次扫描异常
    try {
      ble.off('BLEDeviceFind');
    } catch (_e) {
      // ignore
    }
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

    try {
      const scanOptions: ble.ScanOptions = {
        interval: 0,
        dutyMode: ble.ScanDuty.SCAN_MODE_LOW_POWER,
        matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE
      };
      ble.startBLEScan(null, scanOptions);
    } catch (e) {
      // 首次扫描常因权限/蓝牙状态尚未就绪失败，自动重试一次
      if (this.scanErrorCount < 1) {
        this.scanErrorCount++;
        setTimeout((): void => {
          try {
            ble.startBLEScan(null, {
              interval: 0,
              dutyMode: ble.ScanDuty.SCAN_MODE_LOW_POWER,
              matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE
            });
          } catch (_e2) {
            if (this.callbacks) {
              this.callbacks.onError('BLE 扫描启动失败');
            }
            this.isScanning = false;
          }
        }, 300);
        return;
      }
      if (this.callbacks) {
        this.callbacks.onError('BLE 扫描启动失败');
      }
      this.isScanning = false;
    }
  }

  stopScan(): void {
    this.isScanning = false;
    try {
      ble.stopBLEScan();
    } catch (_e) {
      // ignore
    }
    try {
      ble.off('BLEDeviceFind');
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
          this.setupNotifier();
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
    if (this.gattClient) {
      try {
        this.gattClient.off('BLECharacteristicChange');
      } catch (_e) {
        // ignore
      }
    }
    this.gattClient = null;
    this.connectedDevice = '';
    this.connectedDeviceName = '';
    this.connectionState = CubeConnectionState.DISCONNECTED;
  }

  // --- 通知订阅与转动解析 ---

  private setupNotifier(): void {
    const client = this.gattClient;
    if (client == null) {
      return;
    }
    try {
      client.on('BLECharacteristicChange', (characteristic: ble.BLECharacteristic): void => {
        this.handleNotify(characteristic);
      });
    } catch (_e) {
      // ignore
    }
    // 服务发现后订阅已知魔方数据特征
    client.getServices().then((services: Array<ble.GattService>): void => {
      for (const svc of services) {
        for (const ch of svc.characteristics) {
          if (this.isCubeCharacteristic(ch.characteristicUuid)) {
            try {
              client.setCharacteristicChangeNotification(ch, true);
            } catch (_e) {
              // ignore
            }
          }
        }
      }
    }).catch((err: BusinessError): void => {
      // 服务发现失败时保持界面可操作，不做额外处理
    });
  }

  private isCubeCharacteristic(uuid: string): boolean {
    const u: string = (uuid || '').toLowerCase();
    return u === GIIKER_SERVICES.CHARACTER_DATA.toLowerCase()
      || u === GAN_SERVICES.CHARACTER_F2.toLowerCase()
      || u === GAN_SERVICES.CHARACTER_F3.toLowerCase()
      || u === GAN_SERVICES.CHARACTER_F5.toLowerCase()
      || u === GAN_SERVICES.CHARACTER_F6.toLowerCase()
      || u === GAN_SERVICES.CHARACTER_F7.toLowerCase();
  }

  private handleNotify(characteristic: ble.BLECharacteristic): void {
    try {
      const arr: Uint8Array = new Uint8Array(characteristic.characteristicValue);
      const move: CubeMove | null = parseGiikerMove(arr);
      if (move != null) {
        this.dispatchCubeMove(move);
      }
    } catch (_e) {
      // ignore
    }
  }

  private dispatchCubeMove(move: CubeMove): void {
    if (this.moveCallback) {
      this.moveCallback(move);
    }
    if (this.callbacks) {
      this.callbacks.onCubeMove(move);
    }
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
