// 奇艺 QiYi 智能魔方协议
import { SmartCubeProtocol, BLEGattHandle, BLEServiceHandle, BLECharacteristicHandle, BLEDescriptorHandle } from './SmartCubeProtocol';
import { MoveCallback } from './Moyu32CubeProtocol';

export class QiyiCubeProtocol implements SmartCubeProtocol {
  static readonly SERVICE_UUID = '0000fff0-0000-1000-8000-00805f9b34fb';
  static readonly CUBE_UUID = '0000fff6-0000-1000-8000-00805f9b34fb';
  static readonly WRITE_UUID = '0000fff5-0000-1000-8000-00805f9b34fb';
  private static readonly CCCD_UUID = '00002902-0000-1000-8000-00805f9b34fb';
  private static readonly AES_KEY: number[] = [
    87, 177, 249, 171, 205, 90, 232, 167, 156, 185, 140, 231, 87, 140, 81, 8
  ];
  private static readonly MOVE_AXIS_MAP = [4, 1, 3, 0, 2, 5];
  private static readonly DEVICE_TIME_SCALE = 1.6;
  private static readonly MAX_MOVE_DELTA_MS = 0xffff;
  private static readonly FALLBACK_HELLO_DELAY_MS = 1500;
  private static readonly HELLO_RETRY_DELAY_MS = 3000;
  private static readonly WRITE_RETRY_DELAY_MS = 80;
  private static readonly MAX_HELLO_ATTEMPTS = 2;
  private static readonly REQUIRED_MTU = 64;
  private static readonly QYI_HISTORY_SLOT_COUNT = 11;
  private static readonly QYI_HISTORY_SLOT_START = 36;
  private static readonly QYI_HISTORY_SLOT_SIZE = 5;
  private static readonly GYRO_FRAME_HEADER = 0xcc;
  private static readonly GYRO_FRAME_LENGTH = 0x10;
  private static readonly GYRO_CRC_LENGTH = 14;
  private static readonly FACELET_ORDER = 'LRDUFB';

  private contextCallback: MoveCallback;
  private requestQueue: number[][] = [];
  private gatt: BLEGattHandle | null = null;
  private cubeCharacteristic: BLECharacteristicHandle | null = null;
  private writeCharacteristic: BLECharacteristicHandle | null = null;
  private notificationsReady: boolean = false;
  private writePending: boolean = false;
  private writeWithoutResponse: boolean = false;
  private mtuReady: boolean = false;
  private initialStateShown: boolean = false;
  private helloReceived: boolean = false;
  private fallbackHelloSent: boolean = false;
  private localResetActive: boolean = false;
  private protocolMismatchDetected: boolean = false;
  private deviceName: string = '';
  private activeMac: string = '';
  private fallbackMac: string = '';
  private lastTimestamp: number = -1;
  private nonProtocolMessageCount: number = 0;
  private helloAttemptCount: number = 0;

  constructor(callback: MoveCallback) {
    this.contextCallback = callback;
  }

  start(gatt: BLEGattHandle, service: BLEServiceHandle, deviceName: string, deviceAddress: string): boolean {
    this.clear();
    this.gatt = gatt;
    this.deviceName = (deviceName || '').trim();
    this.activeMac = this.normalizeMac(deviceAddress) || '';
    this.fallbackMac = this.getFallbackMac(this.deviceName) || '';
    this.cubeCharacteristic = service.getCharacteristic(QiyiCubeProtocol.CUBE_UUID);
    if (!this.cubeCharacteristic) return false;
    this.writeCharacteristic = this.resolveWriteCharacteristic(service, this.cubeCharacteristic);
    if (!this.writeCharacteristic) return false;
    if (this.requestMtuIfNeeded()) return true;
    this.setupNotifications();
    return true;
  }

  clear(): void {
    this.requestQueue = [];
    this.notificationsReady = false;
    this.writePending = false;
    this.writeWithoutResponse = false;
    this.mtuReady = false;
    this.initialStateShown = false;
    this.helloReceived = false;
    this.fallbackHelloSent = false;
    this.localResetActive = false;
    this.cubeCharacteristic = null;
    this.writeCharacteristic = null;
    this.gatt = null;
    this.deviceName = '';
    this.activeMac = '';
    this.fallbackMac = '';
    this.lastTimestamp = -1;
    this.protocolMismatchDetected = false;
    this.nonProtocolMessageCount = 0;
    this.helloAttemptCount = 0;
  }

  onDescriptorWrite(descriptor: BLEDescriptorHandle, status: number): void {
    if (!descriptor) return;
    this.onNotificationsEnabled();
  }

  onCharacteristicWrite(characteristic: BLECharacteristicHandle, status: number): void {
    if (!characteristic || !this.writeCharacteristic) return;
    this.writePending = false;
    this.sendNextRequest();
  }

  onCharacteristicChanged(characteristic: BLECharacteristicHandle): void {
    if (!characteristic) return;
    try {
      this.parseMessage(characteristic.getValue());
    } catch (e) {
      console.error('QiYi 数据解析失败: ' + e);
    }
  }

  onMtuChanged(mtu: number, status: number): void {
    this.mtuReady = true;
    if (!this.notificationsReady) this.setupNotifications();
  }

  onLocalCubeReset(cubeState: string): void {
    this.localResetActive = true;
    this.lastTimestamp = -1;
    const syncState = this.buildSyncStateContent(cubeState);
    if (syncState) this.enqueueMessage(syncState, true);
  }

  private requestMtuIfNeeded(): boolean {
    if (!this.gatt) return false;
    const requested = this.gatt.requestMtu(QiyiCubeProtocol.REQUIRED_MTU);
    if (!requested) this.mtuReady = true;
    return requested;
  }

  private setupNotifications(): void {
    if (!this.gatt || !this.cubeCharacteristic) return;
    if (!this.gatt.setCharacteristicNotification(this.cubeCharacteristic, true)) return;
    const descriptor = this.cubeCharacteristic.getDescriptor(QiyiCubeProtocol.CCCD_UUID);
    if (descriptor) {
      const CCCD_ENABLE = [0x01, 0x00];
      descriptor.setValue(CCCD_ENABLE);
      this.onNotificationsEnabled();
    } else {
      this.onNotificationsEnabled();
    }
  }

  private onNotificationsEnabled(): void {
    if (this.notificationsReady) return;
    this.notificationsReady = true;
    const helloMac = this.activeMac || this.fallbackMac;
    if (!helloMac) return;
    this.activeMac = helloMac;
    this.enqueueHello(true, '初始化');
    if (this.fallbackMac && this.fallbackMac.toUpperCase() !== this.activeMac.toUpperCase()) {
      setTimeout(() => this.onFallbackHello(), QiyiCubeProtocol.FALLBACK_HELLO_DELAY_MS);
    }
  }

  private onFallbackHello(): void {
    if (this.helloReceived || this.fallbackHelloSent || !this.fallbackMac || this.protocolMismatchDetected) return;
    this.fallbackHelloSent = true;
    this.activeMac = this.fallbackMac;
    this.enqueueHello(true, '备用 MAC');
  }

  private enqueueHello(priority: boolean, reason: string): void {
    if (!this.activeMac || this.protocolMismatchDetected) return;
    if (this.helloAttemptCount >= QiyiCubeProtocol.MAX_HELLO_ATTEMPTS) return;
    this.helloAttemptCount++;
    this.enqueueMessage(this.buildHelloContent(this.activeMac), priority);
  }

  private enqueueMessage(content: number[], priority: boolean): void {
    if (!content || content.length === 0) return;
    const message = this.buildMessage(content);
    if (priority) {
      this.requestQueue.unshift(message);
    } else {
      this.requestQueue.push(message);
    }
    this.sendNextRequest();
  }

  private sendNextRequest(): void {
    if (!this.notificationsReady || !this.mtuReady || this.writePending || !this.gatt || !this.writeCharacteristic || this.requestQueue.length === 0) return;
    const request = this.requestQueue.shift()!;
    try {
      const encoded = this.encrypt(request);
      this.prepareWriteCharacteristic(encoded);
      const writeIssued = this.gatt.writeCharacteristic(this.writeCharacteristic);
      if (!writeIssued) {
        this.requestQueue.unshift(request);
        this.writePending = false;
        setTimeout(() => this.sendNextRequest(), QiyiCubeProtocol.WRITE_RETRY_DELAY_MS);
        return;
      }
      if (this.writeWithoutResponse) {
        this.writePending = false;
        if (this.requestQueue.length > 0) {
          setTimeout(() => this.sendNextRequest(), QiyiCubeProtocol.WRITE_RETRY_DELAY_MS);
        }
      } else {
        this.writePending = true;
      }
    } catch (e) {
      console.error('QiYi 请求加密失败: ' + e);
      this.writePending = false;
    }
  }

  private parseMessage(value: number[]): void {
    if (!value || value.length === 0 || value.length % 16 !== 0) return;
    const decoded = this.decrypt(value);
    if (decoded.length < 2) return;
    if ((decoded[0] & 0xff) === QiyiCubeProtocol.GYRO_FRAME_HEADER && (decoded[1] & 0xff) === QiyiCubeProtocol.GYRO_FRAME_LENGTH) {
      const quaternion = this.parseGyroQuaternion(decoded);
      if (quaternion) this.contextCallback?.onSmartCubeGyroChanged(quaternion[0], quaternion[1], quaternion[2], quaternion[3]);
      return;
    }
    const msgLength = decoded[1] & 0xff;
    if (msgLength < 3 || msgLength > decoded.length) return;
    const msg = decoded.slice(0, msgLength);
    if (QiyiCubeProtocol.crc16Modbus(msg, msg.length) !== 0) return;
    if ((msg[0] & 0xff) !== 0xfe) {
      this.handleNonProtocolMessage(msg);
      return;
    }
    this.nonProtocolMessageCount = 0;
    const opcode = msg[2] & 0xff;
    const timestamp = QiyiCubeProtocol.readUint32(msg, 3);
    switch (opcode) {
      case 0x02: this.handleHello(msg, timestamp); break;
      case 0x03: this.handleStateChange(msg, timestamp); break;
      case 0x04: this.handleSyncConfirmation(msg, timestamp); break;
    }
  }

  private handleHello(msg: number[], timestamp: number): void {
    this.helloReceived = true;
    this.nonProtocolMessageCount = 0;
    this.sendAck(msg);
    if (msg.length < 36) return;
    const facelet = this.parseFacelet(msg, 7);
    if (this.contextCallback.setCubeState(facelet) !== 0) return;
    this.lastTimestamp = timestamp;
    this.contextCallback.setBatteryValue(msg[35] & 0xff);
    this.contextCallback.refreshSmartCubeStateUi();
    this.showInitialStateDialogIfNeeded();
  }

  private handleStateChange(msg: number[], timestamp: number): void {
    this.helloReceived = true;
    this.nonProtocolMessageCount = 0;
    this.sendAck(msg);
    if (msg.length < 36) return;
    const facelet = this.parseFacelet(msg, 7);
    // 简化处理: 直接用 facelet 更新状态
    const previousTimestamp = this.lastTimestamp;
    const currentMoves = QiyiCubeProtocol.collectStateChangeMoves(msg, previousTimestamp, timestamp);
    for (const moveSample of currentMoves) {
      const move = QiyiCubeProtocol.convertMove(moveSample.move);
      const delta = this.calcMoveDelta(moveSample.timestamp);
      this.contextCallback.moveCube(move, delta);
    }
    if (facelet !== this.contextCallback.getCubeState?.()) {
      if (!this.localResetActive) {
        this.contextCallback.setCubeState(facelet);
        this.contextCallback.refreshSmartCubeStateUi();
      }
    }
    this.contextCallback.setBatteryValue(msg[35] & 0xff);
    this.showInitialStateDialogIfNeeded();
    this.lastTimestamp = Math.max(this.lastTimestamp, timestamp);
  }

  private handleSyncConfirmation(msg: number[], timestamp: number): void {
    this.nonProtocolMessageCount = 0;
    if (msg.length < 36) return;
    const facelet = this.parseFacelet(msg, 7);
    if (this.contextCallback.setCubeState(facelet) !== 0) return;
    this.localResetActive = false;
    this.lastTimestamp = timestamp;
    this.contextCallback.setBatteryValue(msg[35] & 0xff);
    this.contextCallback.refreshSmartCubeStateUi();
    this.showInitialStateDialogIfNeeded();
  }

  private sendAck(msg: number[]): void {
    if (msg.length >= 7) {
      this.enqueueMessage(msg.slice(2, 7), false);
    }
  }

  private showInitialStateDialogIfNeeded(): void {
    if (this.initialStateShown) return;
    this.initialStateShown = true;
    this.contextCallback?.showCubeStateDialog();
  }

  // 公有的静态解析方法 + 辅助方法
  static convertMove(rawMove: number): number {
    if (rawMove <= 0) return -1;
    const axisIndex = (rawMove - 1) >> 1;
    if (axisIndex < 0 || axisIndex >= QiyiCubeProtocol.MOVE_AXIS_MAP.length) return -1;
    const axis = QiyiCubeProtocol.MOVE_AXIS_MAP[axisIndex];
    const power = (rawMove & 1) === 0 ? 0 : 2;
    return axis * 3 + power;
  }

  static collectStateChangeMoves(msg: number[], lastTimestamp: number, frameTimestamp: number): MoveSample[] {
    if (!msg || msg.length < 35) return [];
    const candidates: MoveSample[] = [];
    candidates.push(new MoveSample(msg[34] & 0xff, QiyiCubeProtocol.readUint32(msg, 3)));
    for (let i = 0; i < QiyiCubeProtocol.QYI_HISTORY_SLOT_COUNT; i++) {
      const offset = QiyiCubeProtocol.QYI_HISTORY_SLOT_START + QiyiCubeProtocol.QYI_HISTORY_SLOT_SIZE * i;
      if (offset + QiyiCubeProtocol.QYI_HISTORY_SLOT_SIZE > msg.length) break;
      if (QiyiCubeProtocol.isEmptyHistorySlot(msg, offset)) continue;
      candidates.push(new MoveSample(msg[offset + 4] & 0xff, QiyiCubeProtocol.readUint32(msg, offset)));
    }
    candidates.sort((a, b) => a.timestamp - b.timestamp);
    const result: MoveSample[] = [];
    for (const candidate of candidates) {
      if (candidate.timestamp <= lastTimestamp || candidate.timestamp > frameTimestamp || QiyiCubeProtocol.convertMove(candidate.move) < 0) continue;
      let duplicate = false;
      for (const r of result) {
        if (r.move === candidate.move && r.timestamp === candidate.timestamp) { duplicate = true; break; }
      }
      if (!duplicate) result.push(candidate);
    }
    return result;
  }

  static parseGyroQuaternion(msg: number[]): number[] | null {
    if (!msg || msg.length < QiyiCubeProtocol.GYRO_FRAME_LENGTH) return null;
    if ((msg[0] & 0xff) !== QiyiCubeProtocol.GYRO_FRAME_HEADER || (msg[1] & 0xff) !== QiyiCubeProtocol.GYRO_FRAME_LENGTH) return null;
    const expectedCrc = QiyiCubeProtocol.crc16Modbus(msg, QiyiCubeProtocol.GYRO_CRC_LENGTH);
    const actualCrc = (msg[14] & 0xff) | ((msg[15] & 0xff) << 8);
    if (expectedCrc !== actualCrc) return null;
    const ax = QiyiCubeProtocol.readInt16BE(msg, 6) / 1000;
    const ay = QiyiCubeProtocol.readInt16BE(msg, 8) / 1000;
    const az = QiyiCubeProtocol.readInt16BE(msg, 10) / 1000;
    const aw = QiyiCubeProtocol.readInt16BE(msg, 12) / 1000;
    const norm = Math.sqrt(ax * ax + ay * ay + az * az + aw * aw);
    if (norm < 1.0e-6 || isNaN(norm) || !isFinite(norm)) return null;
    return [ax / norm, ay / norm, az / norm, aw / norm];
  }

  static crc16Modbus(data: number[], length: number): number {
    let crc = 0xffff;
    for (let i = 0; i < length; i++) {
      crc ^= data[i] & 0xff;
      for (let j = 0; j < 8; j++) {
        if ((crc & 0x1) !== 0) crc = (crc >> 1) ^ 0xa001;
        else crc >>= 1;
      }
    }
    return crc & 0xffff;
  }

  private calcMoveDelta(moveTimestamp: number): number {
    if (this.lastTimestamp < 0) { this.lastTimestamp = moveTimestamp; return 0; }
    const rawDelta = moveTimestamp - this.lastTimestamp;
    this.lastTimestamp = moveTimestamp;
    if (rawDelta <= 0) return 0;
    const delta = Math.round(rawDelta / QiyiCubeProtocol.DEVICE_TIME_SCALE);
    return Math.min(delta, QiyiCubeProtocol.MAX_MOVE_DELTA_MS);
  }

  private static isEmptyHistorySlot(msg: number[], offset: number): boolean {
    for (let i = 0; i < QiyiCubeProtocol.QYI_HISTORY_SLOT_SIZE; i++) {
      if ((msg[offset + i] & 0xff) !== 0xff) return false;
    }
    return true;
  }

  private static readUint32(data: number[], offset: number): number {
    return ((data[offset] & 0xff) << 24) | ((data[offset + 1] & 0xff) << 16) | ((data[offset + 2] & 0xff) << 8) | (data[offset + 3] & 0xff);
  }

  private static readInt16BE(data: number[], offset: number): number {
    const val = ((data[offset] & 0xff) << 8) | (data[offset + 1] & 0xff);
    return val > 0x7fff ? val - 0x10000 : val;
  }

  private parseFacelet(msg: number[], offset: number): string {
    let state = '';
    for (let i = 0; i < 54; i++) {
      const value = ((msg[offset + (i >> 1)] & 0xff) >> ((i & 1) << 2)) & 0x0f;
      state += QiyiCubeProtocol.FACELET_ORDER.charAt(value);
    }
    return state;
  }

  private buildHelloContent(mac: string): number[] {
    const macBytes = this.parseMac(mac);
    const header = [0x00, 0x6b, 0x01, 0x00, 0x00, 0x22, 0x06, 0x00, 0x02, 0x08, 0x00];
    const content: number[] = new Array<number>(17);
    for (let i = 0; i < header.length; i++) content[i] = header[i];
    for (let i = 0; i < 6; i++) content[header.length + i] = macBytes[5 - i];
    return content;
  }

  private buildSyncStateContent(cubeState: string): number[] | null {
    const stateBytes = this.encodeFacelet(cubeState);
    if (!stateBytes) return null;
    const prefix = [0x04, 0x17, 0x88, 0x8b, 0x31];
    const suffix = [0x00, 0x00];
    const content: number[] = [];
    for (const b of prefix) content.push(b);
    for (const b of stateBytes) content.push(b);
    for (const b of suffix) content.push(b);
    return content;
  }

  private encodeFacelet(facelet: string): number[] | null {
    if (!facelet || facelet.length < 54) return null;
    const encoded: number[] = new Array<number>(27).fill(0);
    for (let i = 0; i < 54; i++) {
      const value = QiyiCubeProtocol.FACELET_ORDER.indexOf(facelet.charAt(i));
      if (value < 0) return null;
      const byteIndex = i >> 1;
      if ((i & 1) === 0) {
        encoded[byteIndex] = value & 0x0f;
      } else {
        encoded[byteIndex] = (encoded[byteIndex] & 0x0f) | ((value & 0x0f) << 4);
      }
    }
    return encoded;
  }

  private buildMessage(content: number[]): number[] {
    const msgLength = 4 + content.length;
    const paddedLength = ((msgLength + 15) >> 4) << 4;
    const msg: number[] = new Array<number>(paddedLength).fill(0);
    msg[0] = 0xfe;
    msg[1] = msgLength;
    for (let i = 0; i < content.length; i++) msg[2 + i] = content[i];
    const crc = QiyiCubeProtocol.crc16Modbus(msg, 2 + content.length);
    msg[2 + content.length] = crc & 0xff;
    msg[3 + content.length] = (crc >> 8) & 0xff;
    return msg;
  }

  private handleNonProtocolMessage(msg: number[]): void {
    this.nonProtocolMessageCount++;
    if (!this.helloReceived && (msg[0] & 0xff) === 0xcc && this.nonProtocolMessageCount >= 3 && !this.protocolMismatchDetected) {
      this.protocolMismatchDetected = true;
      this.requestQueue = [];
    }
  }

  private resolveWriteCharacteristic(service: BLEServiceHandle, notifyCh: BLECharacteristicHandle): BLECharacteristicHandle | null {
    // 简化: 直接尝试用 cube 特征写入
    return notifyCh;
  }

  private prepareWriteCharacteristic(encoded: number[]): void {
    if (!this.writeCharacteristic) return;
    this.writeWithoutResponse = true;
    this.writeCharacteristic.setValue(encoded);
  }

  private encrypt(value: number[]): number[] {
    return QiyiCubeProtocol.aesEncrypt(value, QiyiCubeProtocol.AES_KEY);
  }

  private decrypt(value: number[]): number[] {
    return QiyiCubeProtocol.aesDecrypt(value, QiyiCubeProtocol.AES_KEY);
  }

  private static aesEncrypt(value: number[], key: number[]): number[] {
    // 简化 XOR 加密 (替换为 cryptoFramework AES/ECB)
    const result = value.slice();
    for (let i = 0; i < result.length; i++) {
      result[i] = (result[i] ^ key[i % key.length]) & 0xff;
    }
    return result;
  }

  private static aesDecrypt(value: number[], key: number[]): number[] {
    return QiyiCubeProtocol.aesEncrypt(value, key);
  }

  private parseMac(mac: string): number[] {
    if (!mac) throw new Error('QiYi mac 为空');
    const parts = mac.split(':');
    if (parts.length !== 6) throw new Error('QiYi mac 非法: ' + mac);
    const bytes: number[] = new Array<number>(6);
    for (let i = 0; i < parts.length; i++) bytes[i] = parseInt(parts[i], 16);
    return bytes;
  }

  private normalizeMac(mac: string): string | null {
    if (!mac) return null;
    const normalized = mac.trim().toUpperCase();
    return /^[0-9A-F]{2}(:[0-9A-F]{2}){5}$/.test(normalized) ? normalized : null;
  }

  private getFallbackMac(name: string): string | null {
    if (!name) return null;
    const normalized = name.trim().toUpperCase();
    if (!(normalized.startsWith('QY-QYSC-') || normalized.startsWith('XMD-TORNADOV4-I-'))) return null;
    const suffix = normalized.substring(normalized.length - 4);
    if (!/[0-9A-F]{4}/.test(suffix)) return null;
    return `CC:A3:00:00:${suffix.substring(0, 2)}:${suffix.substring(2, 4)}`;
  }

  // 获取当前魔方状态 (需要外部注入)
  getCubeState?(): string;
}

export class MoveSample {
  move: number;
  timestamp: number;
  constructor(move: number, timestamp: number) {
    this.move = move;
    this.timestamp = timestamp;
  }
}
