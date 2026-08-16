// BLE 蓝牙管理器 - 使用 @ohos.bluetoothManager 和 @ohos.bluetooth
import { ble } from '@kit.ConnectivityKit';
import { SmartCubeProtocol, BLEGattHandle, BLEServiceHandle, BLECharacteristicHandle, BLEDescriptorHandle } from './SmartCubeProtocol';
import { SmartTimerProtocol, TimerStateCallback } from './SmartTimerProtocol';
import { Moyu32CubeProtocol, MoveCallback } from './Moyu32CubeProtocol';
import { QiyiCubeProtocol } from './QiyiCubeProtocol';
import { GanCubeProtocol } from './GanCubeProtocol';
import { QiyiSmartTimerProtocol } from './QiyiSmartTimerProtocol';
import { GanRobotBleClient, GanRobotSessionState, GanRobotController } from './GanRobotBleClient';
import { GanRobotProtocol } from './GanRobotProtocol';

// 设备类型常量
export const BLE_TYPE_UNKNOWN = 0;
export const BLE_TYPE_MOYU32_CUBE = 1;
export const BLE_TYPE_QIYI_CUBE = 2;
export const BLE_TYPE_GANI_CUBE = 3;
export const BLE_TYPE_QIYI_TIMER = 4;
export const BLE_TYPE_GAN_ROBOT = 5;

// UUID 常量
const UUID_SUFFIX = '-0000-1000-8000-00805f9b34fb';

export interface BLEDeviceInfo {
  name: string;
  address: string;
  type: number;
  protocolAddress: string;
  connected: number; // 0=未连接, 1=已连接, 2=连接中
}

export interface BLEScanCallback {
  onDeviceFound(devices: BLEDeviceInfo[]): void;
  onScanFailed(): void;
}

export interface BLEConnectCallback {
  onConnected(deviceType: number): void;
  onDisconnected(device: BLEDeviceInfo): void;
  onConnectFailed(): void;
  onUnsupportedDevice(): void;
}

export class BluetoothManager {
  private scanCallback: BLEScanCallback | null = null;
  private connectCallback: BLEConnectCallback | null = null;
  private moveCallback: MoveCallback | null = null;
  private timerCallback: TimerStateCallback | null = null;
  private robotCallback: import('./GanRobotBleClient').RobotCallback | null = null;

  private scannedDevices: BLEDeviceInfo[] = [];
  private isScanning: boolean = false;
  private scanAllTimingDevices: boolean = false;
  private enterMode: number = 0; // 0=计时器, 3=智能魔方, 4=智能计时器
  private connectedIndex: number = -1;
  private gattDeviceId: string = '';

  private smartCubeProtocol: SmartCubeProtocol | null = null;
  private smartTimerProtocol: SmartTimerProtocol | null = null;

  setScanCallback(cb: BLEScanCallback | null): void { this.scanCallback = cb; }
  setConnectCallback(cb: BLEConnectCallback | null): void { this.connectCallback = cb; }
  setMoveCallback(cb: MoveCallback | null): void { this.moveCallback = cb; }
  setTimerCallback(cb: TimerStateCallback | null): void { this.timerCallback = cb; }
  setRobotCallback(cb: import('./GanRobotBleClient').RobotCallback | null): void { this.robotCallback = cb; }
  setEnterMode(mode: number): void { this.enterMode = mode; }
  setScanAllTimingDevices(value: boolean): void { this.scanAllTimingDevices = value; }

  startScan(): void {
    this.scannedDevices = [];
    this.isScanning = true;
    // 使用鸿蒙 BLE 扫描 API
    console.info('BluetoothManager startScan');
    // 模拟扫描结果 - 实际实现需要使用 ble.startBLEScan
  }

  stopScan(): void {
    this.isScanning = false;
    console.info('BluetoothManager stopScan');
  }

  connectDevice(index: number): void {
    if (this.isScanning) this.stopScan();
    this.connectedIndex = index;
    const device = this.scannedDevices[index];
    if (!device) return;
    console.info('BluetoothManager 连接设备: ' + device.name);
    // 实际 BLE GATT 连接
  }

  disconnect(): void {
    if (this.smartCubeProtocol) this.smartCubeProtocol.clear();
    if (this.smartTimerProtocol) this.smartTimerProtocol.clear();
    this.smartCubeProtocol = null;
    this.smartTimerProtocol = null;
    console.info('BluetoothManager 断开连接');
  }

  // 根据设备类型创建对应的协议
  private createSmartCubeProtocol(deviceType: number): SmartCubeProtocol | null {
    if (!this.moveCallback) return null;
    switch (deviceType) {
      case BLE_TYPE_MOYU32_CUBE: return new Moyu32CubeProtocol(this.moveCallback);
      case BLE_TYPE_QIYI_CUBE: return new QiyiCubeProtocol(this.moveCallback);
      case BLE_TYPE_GANI_CUBE: return new GanCubeProtocol(this.moveCallback);
    }
    return null;
  }

  private createSmartTimerProtocol(deviceType: number): SmartTimerProtocol | null {
    if (!this.timerCallback) return null;
    if (deviceType === BLE_TYPE_QIYI_TIMER) return new QiyiSmartTimerProtocol(this.timerCallback);
    return null;
  }

  // 设备名称匹配
  private guessDeviceType(deviceName: string): number {
    if (!deviceName) return BLE_TYPE_UNKNOWN;
    const normalized = deviceName.trim().toUpperCase();
    if (normalized.startsWith('WCU_MY3')) return BLE_TYPE_MOYU32_CUBE;
    if (normalized.startsWith('QY-QYSC') || normalized.startsWith('XMD-TORNADOV4-I')) return BLE_TYPE_QIYI_CUBE;
    if (GanCubeProtocol.matchesDeviceName(normalized)) return BLE_TYPE_GANI_CUBE;
    if (GanRobotProtocol.isCandidate(normalized)) return BLE_TYPE_GAN_ROBOT;
    return BLE_TYPE_UNKNOWN;
  }

  private isSmartCubeMode(): boolean { return this.enterMode === 3; }
  private isSmartTimerMode(): boolean { return this.enterMode === 4; }

  private shouldShowDeviceType(deviceType: number): boolean {
    if (this.scanAllTimingDevices) {
      return deviceType === BLE_TYPE_MOYU32_CUBE || deviceType === BLE_TYPE_QIYI_CUBE
        || deviceType === BLE_TYPE_GANI_CUBE || deviceType === BLE_TYPE_QIYI_TIMER;
    }
    if (this.isSmartCubeMode()) {
      return deviceType === BLE_TYPE_MOYU32_CUBE || deviceType === BLE_TYPE_QIYI_CUBE || deviceType === BLE_TYPE_GANI_CUBE;
    }
    if (this.isSmartTimerMode()) {
      return deviceType === BLE_TYPE_QIYI_TIMER;
    }
    return false;
  }

  // GATT 回调处理 (实际连接成功后调用)
  onGattConnected(deviceId: string, serviceUuids: string[], deviceName: string): void {
    this.gattDeviceId = deviceId;
    const deviceType = this.guessDeviceType(deviceName);
    if (deviceType === BLE_TYPE_GAN_ROBOT) {
      // GAN 机器人连接
      this.connectCallback?.onConnected(deviceType);
      return;
    }
    if (deviceType === BLE_TYPE_MOYU32_CUBE || deviceType === BLE_TYPE_QIYI_CUBE || deviceType === BLE_TYPE_GANI_CUBE) {
      this.smartCubeProtocol = this.createSmartCubeProtocol(deviceType);
    } else if (deviceType === BLE_TYPE_QIYI_TIMER) {
      this.smartTimerProtocol = this.createSmartTimerProtocol(deviceType);
    }
    if (this.smartCubeProtocol || this.smartTimerProtocol) {
      this.connectCallback?.onConnected(deviceType);
    }
  }

  onGattDisconnected(): void {
    this.disconnect();
    this.connectCallback?.onDisconnected({ name: '', address: '', type: 0, protocolAddress: '', connected: 0 });
  }
}

// 鸿蒙 BLE GATT 适配器实现
export class HarmonyGattHandle implements BLEGattHandle {
  deviceId: string = '';
  private serviceMap: Map<string, HarmonyServiceHandle> = new Map();

  constructor(deviceId: string) {
    this.deviceId = deviceId;
  }

  setCharacteristicNotification(characteristic: BLECharacteristicHandle, enable: boolean): boolean {
    // 实际实现: ble.setCharacteristicChangeNotification
    return true;
  }

  writeCharacteristic(characteristic: BLECharacteristicHandle): boolean {
    // 实际实现: ble.writeCharacteristicValue
    return true;
  }

  readCharacteristic(characteristic: BLECharacteristicHandle): boolean {
    // 实际实现: ble.readCharacteristicValue
    return true;
  }

  getService(uuid: string): BLEServiceHandle | null {
    const key = uuid.toUpperCase();
    let svc = this.serviceMap.get(key);
    if (!svc) {
      svc = new HarmonyServiceHandle(uuid);
      this.serviceMap.set(key, svc);
    }
    return svc;
  }

  requestMtu(mtu: number): boolean {
    // 实际实现: ble.setBLEMtuSize
    return true;
  }

  disconnect(): void { /* ble.disconnect */ }
  close(): void { /* ble.close */ }
}

class HarmonyServiceHandle implements BLEServiceHandle {
  serviceUuid: string;
  private charMap: Map<string, HarmonyCharacteristicHandle> = new Map();

  constructor(uuid: string) {
    this.serviceUuid = uuid;
  }

  getCharacteristic(uuid: string): BLECharacteristicHandle | null {
    const key = uuid.toUpperCase();
    let chr = this.charMap.get(key);
    if (!chr) {
      chr = new HarmonyCharacteristicHandle(uuid);
      this.charMap.set(key, chr);
    }
    return chr;
  }
}

class HarmonyCharacteristicHandle implements BLECharacteristicHandle {
  characteristicUuid: string;
  private valueBuffer: number[] = [];

  constructor(uuid: string) {
    this.characteristicUuid = uuid;
  }

  getValue(): number[] { return this.valueBuffer.slice(); }
  setValue(value: number[]): void { this.valueBuffer = value.slice(); }
  getDescriptor(uuid: string): BLEDescriptorHandle | null {
    return new HarmonyDescriptorHandle(uuid, this);
  }
}

class HarmonyDescriptorHandle implements BLEDescriptorHandle {
  descriptorUuid: string;
  private chr: BLECharacteristicHandle;
  private valueBuffer: number[] = [];

  constructor(uuid: string, chr: BLECharacteristicHandle) {
    this.descriptorUuid = uuid;
    this.chr = chr;
  }

  getCharacteristic(): BLECharacteristicHandle { return this.chr; }
  setValue(value: number[]): void { this.valueBuffer = value.slice(); }
}
