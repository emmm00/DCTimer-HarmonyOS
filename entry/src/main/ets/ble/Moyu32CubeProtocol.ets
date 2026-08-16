// 魔域 MoYu32 智能魔方协议
import { Moyu32Cipher } from './Moyu32Cipher';
import { SmartCubeProtocol, BLEGattHandle, BLEServiceHandle, BLECharacteristicHandle, BLEDescriptorHandle } from './SmartCubeProtocol';

export class Moyu32CubeProtocol implements SmartCubeProtocol {
  static readonly SERVICE_UUID = '0783b03e-7735-b5a0-1760-a305d2795cb0';
  static readonly READ_UUID = '0783b03e-7735-b5a0-1760-a305d2795cb1';
  static readonly WRITE_UUID = '0783b03e-7735-b5a0-1760-a305d2795cb2';
  private static readonly CCCD_UUID = '00002902-0000-1000-8000-00805f9b34fb';
  private static readonly GYRO_SCALE = 1073741824;

  private cipher = new Moyu32Cipher();
  private requestQueue: number[][] = [];
  private gatt: BLEGattHandle | null = null;
  private readCharacteristic: BLECharacteristicHandle | null = null;
  private writeCharacteristic: BLECharacteristicHandle | null = null;
  private notificationsReady: boolean = false;
  private writePending: boolean = false;
  private fallbackTried: boolean = false;
  private initialStateShown: boolean = false;
  private deviceName: string = '';
  private deviceMac: string = '';
  private moveCnt: number = -1;
  private prevMoveCnt: number = -1;
  private contextCallback: MoveCallback | null = null;

  constructor(callback: MoveCallback) {
    this.contextCallback = callback;
  }

  start(gatt: BLEGattHandle, service: BLEServiceHandle, deviceName: string, deviceAddress: string): boolean {
    this.gatt = gatt;
    this.deviceName = (deviceName || '').trim();
    this.deviceMac = deviceAddress;
    this.moveCnt = -1;
    this.prevMoveCnt = -1;
    this.notificationsReady = false;
    this.writePending = false;
    this.fallbackTried = false;
    this.initialStateShown = false;
    this.requestQueue = [];
    this.readCharacteristic = service.getCharacteristic(Moyu32CubeProtocol.READ_UUID);
    this.writeCharacteristic = service.getCharacteristic(Moyu32CubeProtocol.WRITE_UUID);
    if (!this.readCharacteristic || !this.writeCharacteristic) return false;
    this.tryInitCipher(deviceAddress);
    if (!gatt.setCharacteristicNotification(this.readCharacteristic, true)) return false;
    const descriptor = this.readCharacteristic.getDescriptor(Moyu32CubeProtocol.CCCD_UUID);
    if (descriptor) {
      const CCCD_ENABLE = [0x01, 0x00];
      descriptor.setValue(CCCD_ENABLE);
      // 通知开启将在 onNotificationsEnabled 中处理
      this.onNotificationsEnabled();
    } else {
      this.onNotificationsEnabled();
    }
    return true;
  }

  clear(): void {
    this.requestQueue = [];
    this.notificationsReady = false;
    this.writePending = false;
    this.readCharacteristic = null;
    this.writeCharacteristic = null;
    this.gatt = null;
    this.deviceName = '';
    this.deviceMac = '';
    this.moveCnt = -1;
    this.prevMoveCnt = -1;
    this.fallbackTried = false;
    this.initialStateShown = false;
  }

  onDescriptorWrite(descriptor: BLEDescriptorHandle, status: number): void {
    if (!descriptor) return;
  }

  onCharacteristicWrite(characteristic: BLECharacteristicHandle, status: number): void {
    if (!characteristic || !this.writeCharacteristic) return;
    this.writePending = false;
    this.sendNextRequest();
  }

  onCharacteristicChanged(characteristic: BLECharacteristicHandle): void {
    if (!characteristic || !this.readCharacteristic) return;
    try {
      this.parseData(characteristic.getValue());
    } catch (e) {
      console.error('MoYu32 数据解析失败:' + e);
    }
  }

  onMtuChanged(mtu: number, status: number): void { }
  onLocalCubeReset(cubeState: string): void { }

  private onNotificationsEnabled(): void {
    if (this.notificationsReady) return;
    this.notificationsReady = true;
    this.enqueueSimpleRequest(161);
    this.enqueueSimpleRequest(163);
    this.enqueueSimpleRequest(164);
    this.enqueueSimpleRequest(161);
    this.enqueueSimpleRequest(163);
    this.enqueueSimpleRequest(164);
    this.enqueueGyroEnableRequest();
    this.enqueueSimpleRequest(163);
  }

  private enqueueSimpleRequest(opcode: number): void {
    const req: number[] = new Array<number>(20).fill(0);
    req[0] = opcode;
    this.requestQueue.push(req);
    this.sendNextRequest();
  }

  private enqueueGyroEnableRequest(): void {
    const req: number[] = new Array<number>(20).fill(0);
    req[0] = 172;
    req[2] = 1;
    this.requestQueue.push(req);
    this.sendNextRequest();
  }

  private sendNextRequest(): void {
    if (!this.notificationsReady || this.writePending || !this.gatt || !this.writeCharacteristic || this.requestQueue.length === 0) return;
    const request = this.requestQueue.shift()!;
    try {
      const encoded = this.cipher.encode(request);
      this.writeCharacteristic.setValue(encoded);
      this.writePending = this.gatt.writeCharacteristic(this.writeCharacteristic);
    } catch (e) {
      console.error('MoYu32 请求加密失败: ' + e);
    }
  }

  private parseData(value: number[]): void {
    const decoded = this.cipher.decode(value);
    if (decoded.length >= 17 && (decoded[0] & 0xff) === 171) {
      this.handleGyro(decoded);
      return;
    }
    let bits = '';
    for (let i = 0; i < decoded.length; i++) {
      bits += (decoded[i] & 0xff).toString(2).padStart(8, '0');
    }
    const msgType = parseInt(bits.substring(0, 8), 2);
    switch (msgType) {
      case 161: console.info('收到 MoYu32 设备信息'); break;
      case 163: this.handleInitialState(bits); break;
      case 164: this.handleBattery(bits); break;
      case 165: this.handleMove(bits); break;
      case 171: this.handleGyro(decoded); break;
      default:
        console.info('未知 MoYu32 消息类型: ' + msgType);
        if (this.prevMoveCnt === -1) this.tryFallbackCipher();
        break;
    }
  }

  private handleInitialState(bits: string): void {
    if (this.prevMoveCnt !== -1) return;
    this.moveCnt = this.parseBits(bits, 152, 8);
    const facelet = this.parseFacelet(bits.substring(8, 152));
    if (!this.contextCallback || this.contextCallback.setCubeState(facelet) !== 0) {
      console.error('MoYu32 初始状态校验失败');
      if (!this.tryFallbackCipher()) {
        this.contextCallback?.setCubeState('UUUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB');
      }
      return;
    }
    this.prevMoveCnt = this.moveCnt;
    console.info('MoYu32 初始状态: ' + facelet);
    if (!this.initialStateShown) {
      this.initialStateShown = true;
      this.contextCallback?.showCubeStateDialog();
    }
  }

  private handleBattery(bits: string): void {
    const battery = this.parseBits(bits, 8, 8);
    this.contextCallback?.setBatteryValue(battery);
    this.contextCallback?.refreshSmartCubeStateUi();
  }

  private handleMove(bits: string): void {
    this.moveCnt = this.parseBits(bits, 88, 8);
    if (this.prevMoveCnt === -1 || this.moveCnt === this.prevMoveCnt) return;
    const timeOffsets: number[] = new Array<number>(5);
    const rawMoves: number[] = new Array<number>(5);
    let invalidMove = false;
    for (let i = 0; i < 5; i++) {
      timeOffsets[i] = this.parseBits(bits, 8 + i * 16, 16);
      rawMoves[i] = this.parseBits(bits, 96 + i * 5, 5);
      if (rawMoves[i] >= 12) invalidMove = true;
    }
    if (invalidMove) return;
    let moveDiff = (this.moveCnt - this.prevMoveCnt) & 0xff;
    this.prevMoveCnt = this.moveCnt;
    if (moveDiff > rawMoves.length) moveDiff = rawMoves.length;
    for (let i = moveDiff - 1; i >= 0; i--) {
      const move = this.convertMove(rawMoves[i]);
      this.contextCallback?.moveCube(move, timeOffsets[i]);
    }
  }

  private handleGyro(decoded: number[]): void {
    if (!decoded || decoded.length < 17) return;
    const w = this.readInt32LE(decoded, 1) / Moyu32CubeProtocol.GYRO_SCALE;
    const x = this.readInt32LE(decoded, 5) / Moyu32CubeProtocol.GYRO_SCALE;
    const y = this.readInt32LE(decoded, 9) / Moyu32CubeProtocol.GYRO_SCALE;
    const z = this.readInt32LE(decoded, 13) / Moyu32CubeProtocol.GYRO_SCALE;
    const length = Math.sqrt(w * w + x * x + y * y + z * z);
    if (length <= 0 || isNaN(length) || !isFinite(length)) return;
    this.contextCallback?.onSmartCubeGyroChanged(x / length, z / length, -y / length, w / length);
  }

  private readInt32LE(data: number[], offset: number): number {
    const b = data;
    return (b[offset] & 0xff) | ((b[offset + 1] & 0xff) << 8) | ((b[offset + 2] & 0xff) << 16) | ((b[offset + 3] & 0xff) << 24);
  }

  private convertMove(rawMove: number): number {
    const face = 'FBUDLR'.charAt(rawMove >> 1);
    const suffix = (rawMove & 1) === 0 ? 0 : 2;
    return 'URFDLB'.indexOf(face) * 3 + suffix;
  }

  private parseBits(bits: string, start: number, len: number): number {
    return parseInt(bits.substring(start, start + len), 2);
  }

  private parseFacelet(faceletBits: string): string {
    let state = '';
    const faces = [2, 5, 0, 3, 4, 1];
    for (let i = 0; i < 6; i++) {
      const face = faceletBits.substring(faces[i] * 24, faces[i] * 24 + 24);
      for (let j = 0; j < 8; j++) {
        state += 'FBUDLR'.charAt(this.parseBits(face, j * 3, 3));
        if (j === 3) state += 'FBUDLR'.charAt(faces[i]);
      }
    }
    return state;
  }

  private tryInitCipher(mac: string): void {
    if (!mac) return;
    try {
      this.cipher.init(mac);
      console.info('MoYu32 使用地址初始化: ' + mac);
    } catch (e) {
      console.error('MoYu32 初始化地址失败: ' + mac);
    }
  }

  private tryFallbackCipher(): boolean {
    if (this.fallbackTried) return false;
    const fallbackMac = this.getFallbackMac(this.deviceName);
    if (!fallbackMac || fallbackMac.toUpperCase() === (this.deviceMac || '').toUpperCase()) {
      this.fallbackTried = true;
      return false;
    }
    this.fallbackTried = true;
    try {
      this.cipher.init(fallbackMac);
      this.deviceMac = fallbackMac;
      this.moveCnt = -1;
      this.prevMoveCnt = -1;
      this.requestQueue = [];
      this.writePending = false;
      this.enqueueSimpleRequest(163);
      this.enqueueSimpleRequest(164);
      console.info('MoYu32 使用备用 MAC: ' + fallbackMac);
      return true;
    } catch (e) {
      console.error('MoYu32 备用 MAC 初始化失败');
      return false;
    }
  }

  private getFallbackMac(deviceName: string): string | null {
    if (!deviceName || !/^WCU_MY32_[0-9A-Fa-f]{4}$/.test(deviceName)) return null;
    const suffix = deviceName.substring(deviceName.length - 4).toUpperCase();
    return `CF:30:16:00:${suffix.substring(0, 2)}:${suffix.substring(2, 4)}`;
  }
}

// 回调接口
export interface MoveCallback {
  setCubeState(state: string): number;
  setBatteryValue(battery: number): void;
  moveCube(move: number, delta: number): void;
  refreshSmartCubeStateUi(): void;
  showCubeStateDialog(): void;
  onSmartCubeGyroChanged(x: number, y: number, z: number, w: number): void;
}
