// 智能魔方协议基类接口
export interface SmartCubeProtocol {
  start(gatt: BLEGattHandle, service: BLEServiceHandle, deviceName: string, deviceAddress: string): boolean;
  clear(): void;
  onDescriptorWrite(descriptor: BLEDescriptorHandle, status: number): void;
  onCharacteristicWrite(characteristic: BLECharacteristicHandle, status: number): void;
  onCharacteristicChanged(characteristic: BLECharacteristicHandle): void;
  onMtuChanged(mtu: number, status: number): void;
  onLocalCubeReset(cubeState: string): void;
}

// 智能计时器协议基类接口
export interface SmartTimerProtocol {
  start(gatt: BLEGattHandle, service: BLEServiceHandle, deviceName: string, deviceAddress: string): boolean;
  clear(): void;
  onDescriptorWrite(descriptor: BLEDescriptorHandle, status: number): void;
  onCharacteristicWrite(characteristic: BLECharacteristicHandle, status: number): void;
  onCharacteristicChanged(characteristic: BLECharacteristicHandle): void;
  onMtuChanged(mtu: number, status: number): void;
}

export interface TimerStateCallback {
  onTimerIdle(time: number): void;
  onTimerReady(time: number): void;
  onTimerRunning(time: number): void;
  onTimerStopped(time: number): void;
  onTimerDisconnected(): void;
}

// BLE 抽象句柄 (适配 @ohos.bluetooth)
export interface BLEGattHandle {
  deviceId: string;
  setCharacteristicNotification(characteristic: BLECharacteristicHandle, enable: boolean): boolean;
  writeCharacteristic(characteristic: BLECharacteristicHandle): boolean;
  readCharacteristic(characteristic: BLECharacteristicHandle): boolean;
  getService(uuid: string): BLEServiceHandle | null;
  requestMtu(mtu: number): boolean;
  disconnect(): void;
  close(): void;
}

export interface BLEServiceHandle {
  serviceUuid: string;
  getCharacteristic(uuid: string): BLECharacteristicHandle | null;
}

export interface BLECharacteristicHandle {
  characteristicUuid: string;
  getValue(): number[];
  setValue(value: number[]): void;
  getDescriptor(uuid: string): BLEDescriptorHandle | null;
}

export interface BLEDescriptorHandle {
  descriptorUuid: string;
  getCharacteristic(): BLECharacteristicHandle;
  setValue(value: number[]): void;
}
