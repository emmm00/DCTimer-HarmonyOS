/**
 * 蓝牙设备模型 - 对应 Android BLEDevice.java
 */

export class BLEDevice {
  static readonly TYPE_UNKNOWN: number = -1;
  static readonly TYPE_GIIKER_CUBE: number = 0;
  static readonly TYPE_GANI_CUBE: number = 1;
  static readonly TYPE_GAN_ROBOT: number = 3;
  static readonly TYPE_MOYU32_CUBE: number = 4;
  static readonly TYPE_QIYI_CUBE: number = 5;
  static readonly TYPE_QIYI_TIMER: number = 6;

  private name: string;
  private address: string;
  private protocolAddress: string;
  private connected: number;
  private type: number;
  private rssi: number;

  constructor(name: string, address: string) {
    this.name = name;
    this.address = address;
    this.protocolAddress = address;
    this.type = BLEDevice.TYPE_UNKNOWN;
  }

  getName(): string {
    return this.name;
  }

  setName(name: string): void {
    this.name = name;
  }

  getAddress(): string {
    return this.address;
  }

  setAddress(address: string): void {
    this.address = address;
  }

  getProtocolAddress(): string {
    return this.protocolAddress;
  }

  setProtocolAddress(protocolAddress: string): void {
    this.protocolAddress = protocolAddress;
  }

  getConnected(): number {
    return this.connected;
  }

  setConnected(connected: number): void {
    this.connected = connected;
  }

  getType(): number {
    return this.type;
  }

  setType(type: number): void {
    this.type = type;
  }

  getRssi(): number {
    return this.rssi;
  }

  setRssi(rssi: number): void {
    this.rssi = rssi;
  }
}
