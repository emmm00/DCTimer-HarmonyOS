// 奇艺智能计时器协议
import { SmartTimerProtocol, TimerStateCallback, BLEGattHandle, BLEServiceHandle, BLECharacteristicHandle, BLEDescriptorHandle } from './SmartCubeProtocol';

export class QiyiSmartTimerProtocol implements SmartTimerProtocol {
  static readonly SERVICE_UUID = '0000fd50-0000-1000-8000-00805f9b34fb';
  static readonly WRITE_UUID = '00000001-0000-1001-8001-00805f9b07d0';
  static readonly READ_UUID = '00000002-0000-1001-8001-00805f9b07d0';
  private static readonly CCCD_UUID = '00002902-0000-1000-8000-00805f9b34fb';
  private static readonly REQUIRED_MTU = 517;
  private static readonly STATE_IDLE = 0;
  private static readonly STATE_INSPECTION = 1;
  private static readonly STATE_GET_SET = 2;
  private static readonly STATE_RUNNING = 3;
  private static readonly STATE_FINISHED = 4;
  private static readonly STATE_STOPPED = 5;
  private static readonly STATE_DISCONNECT = 6;
  private static readonly AES_KEY: number[] = [0x77, 0x77, 0x77, 0x77, 0x77, 0x77, 0x77, 0x77, 0x77, 0x77, 0x77, 0x77, 0x77, 0x77, 0x77, 0x77];
  private static readonly HELLO_HEADER: number[] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x21, 0x08, 0x00, 0x01, 0x05, 0x5A];

  private callback: TimerStateCallback;
  private requestQueue: number[][] = [];
  private gatt: BLEGattHandle | null = null;
  private readCharacteristic: BLECharacteristicHandle | null = null;
  private writeCharacteristic: BLECharacteristicHandle | null = null;
  private notificationsReady: boolean = false;
  private writePending: boolean = false;
  private writeWithoutResponse: boolean = false;
  private mtuReady: boolean = false;
  private previousState: number = QiyiSmartTimerProtocol.STATE_IDLE;
  private nextPacketNum: number = 0;
  private messageLength: number = 0;
  private cipherLength: number = 0;
  private cipherPos: number = 0;
  private cipherBuffer: number[] | null = null;

  constructor(callback: TimerStateCallback) {
    this.callback = callback;
  }

  start(gatt: BLEGattHandle, service: BLEServiceHandle, deviceName: string, deviceAddress: string): boolean {
    this.clear();
    this.gatt = gatt;
    this.readCharacteristic = service.getCharacteristic(QiyiSmartTimerProtocol.READ_UUID);
    this.writeCharacteristic = service.getCharacteristic(QiyiSmartTimerProtocol.WRITE_UUID);
    if (!this.readCharacteristic || !this.writeCharacteristic) return false;
    this.writeWithoutResponse = true;
    if (this.requestMtuIfNeeded()) return true;
    this.setupNotifications();
    return true;
  }

  clear(): void {
    this.requestQueue = [];
    this.gatt = null;
    this.readCharacteristic = null;
    this.writeCharacteristic = null;
    this.notificationsReady = false;
    this.writePending = false;
    this.writeWithoutResponse = false;
    this.mtuReady = false;
    this.previousState = QiyiSmartTimerProtocol.STATE_IDLE;
    this.resetPacketBuffer();
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
    const value = characteristic.getValue();
    if (!value || value.length === 0) return;
    this.onPacket(value);
  }

  onMtuChanged(mtu: number, status: number): void {
    this.mtuReady = true;
    if (!this.notificationsReady) this.setupNotifications();
  }

  private requestMtuIfNeeded(): boolean {
    if (!this.gatt) return false;
    const requested = this.gatt.requestMtu(QiyiSmartTimerProtocol.REQUIRED_MTU);
    if (!requested) this.mtuReady = true;
    return requested;
  }

  private setupNotifications(): void {
    if (!this.gatt || !this.readCharacteristic) return;
    if (!this.gatt.setCharacteristicNotification(this.readCharacteristic, true)) return;
    const descriptor = this.readCharacteristic.getDescriptor(QiyiSmartTimerProtocol.CCCD_UUID);
    if (!descriptor) { this.onNotificationsEnabled(); return; }
    const CCCD_ENABLE = [0x01, 0x00];
    descriptor.setValue(CCCD_ENABLE);
    this.onNotificationsEnabled();
  }

  private onNotificationsEnabled(): void {
    this.notificationsReady = true;
    this.sendHello();
  }

  private sendHello(): void {
    // 简化 hello 消息发送
    const payload: number[] = [];
    for (const b of QiyiSmartTimerProtocol.HELLO_HEADER) payload.push(b);
    for (let i = 0; i < 6; i++) payload.push(0x00);
    this.sendMessage(1, 0, 0x0001, payload);
  }

  private sendMessage(seqNum: number, respNum: number, cmd: number, payload: number[]): void {
    const payloadLength = payload ? payload.length : 0;
    const messageStream: number[] = [];
    messageStream.push((seqNum >> 24) & 0xFF);
    messageStream.push((seqNum >> 16) & 0xFF);
    messageStream.push((seqNum >> 8) & 0xFF);
    messageStream.push(seqNum & 0xFF);
    messageStream.push((respNum >> 24) & 0xFF);
    messageStream.push((respNum >> 16) & 0xFF);
    messageStream.push((respNum >> 8) & 0xFF);
    messageStream.push(respNum & 0xFF);
    messageStream.push((cmd >> 8) & 0xFF);
    messageStream.push(cmd & 0xFF);
    messageStream.push((payloadLength >> 8) & 0xFF);
    messageStream.push(payloadLength & 0xFF);
    if (payloadLength > 0) for (let i = 0; i < payloadLength; i++) messageStream.push(payload[i]);
    const crc = QiyiSmartTimerProtocol.crc16Modbus(messageStream);
    messageStream.push((crc >> 8) & 0xFF);
    messageStream.push(crc & 0xFF);
    let packetNumber = 0;
    for (let offset = 0; offset < messageStream.length; offset += 16) {
      const blockLength = Math.min(16, messageStream.length - offset);
      const block: number[] = new Array<number>(16).fill(0x01);
      for (let i = 0; i < blockLength; i++) block[i] = messageStream[offset + i];
      const encrypted = QiyiSmartTimerProtocol.aesEncrypt(block);
      const packetStream: number[] = [];
      packetStream.push(packetNumber & 0xFF);
      if (packetNumber === 0) {
        packetStream.push((messageStream.length + 2) & 0xFF);
        packetStream.push(0x40);
        packetStream.push(0x00);
      }
      for (const b of encrypted) packetStream.push(b);
      this.requestQueue.push(packetStream);
      packetNumber++;
    }
    this.sendNextRequest();
  }

  private sendNextRequest(): void {
    if (!this.notificationsReady || !this.gatt || !this.writeCharacteristic || this.writePending) return;
    const packet = this.requestQueue.shift();
    if (!packet) return;
    this.writePending = true;
    this.writeCharacteristic.setValue(packet);
    this.gatt.writeCharacteristic(this.writeCharacteristic);
    if (this.writeWithoutResponse) {
      setTimeout(() => { this.writePending = false; this.sendNextRequest(); }, 80);
    }
  }

  private onPacket(packet: number[]): void {
    const packetNum = packet[0] & 0xFF;
    if (packetNum !== this.nextPacketNum) { this.resetPacketBuffer(); return; }
    let offset: number;
    if (packetNum === 0) {
      this.messageLength = (packet[1] & 0xFF) - 2;
      if (this.messageLength <= 0) { this.resetPacketBuffer(); return; }
      this.cipherLength = ((this.messageLength + 15) >> 4) << 4;
      this.cipherPos = 0;
      this.cipherBuffer = new Array<number>(this.cipherLength);
      offset = 4;
    } else {
      offset = 1;
    }
    const copyLength = Math.min(packet.length - offset, this.cipherLength - this.cipherPos);
    if (copyLength < 0 || !this.cipherBuffer) return;
    for (let i = 0; i < copyLength; i++) this.cipherBuffer[this.cipherPos + i] = packet[offset + i];
    this.cipherPos += copyLength;
    if (this.cipherPos < this.cipherLength) { this.nextPacketNum++; return; }
    this.nextPacketNum = 0;
    const plain = QiyiSmartTimerProtocol.aesDecrypt(this.cipherBuffer);
    const message = plain.slice(0, this.messageLength);
    this.handleMessage(message);
    this.resetPacketBuffer();
  }

  private handleMessage(message: number[]): void {
    if (message.length < 14) return;
    const payloadLength = ((message[10] & 0xFF) << 8) | (message[11] & 0xFF);
    if (message.length < 12 + payloadLength + 2) return;
    const cmd = ((message[8] & 0xFF) << 8) | (message[9] & 0xFF);
    if (cmd !== 0x1003) return;
    const payload = message.slice(12, 12 + payloadLength);
    const dpId = payload[0] & 0xFF;
    const dpType = payload[1] & 0xFF;
    const dpLength = ((payload[2] & 0xFF) << 8) | (payload[3] & 0xFF);
    const dp = payload.slice(4, 4 + dpLength);
    if (dpId === 1 && dpType === 1 && payload.length >= 16) {
      const solveTime = QiyiSmartTimerProtocol.readUint32(dp, 4);
      this.callback.onTimerStopped(solveTime);
    } else if (dpId === 4 && dpType === 4 && payload.length >= 9) {
      const state = dp[0] & 0xFF;
      const solveTime = QiyiSmartTimerProtocol.readUint32(dp, 1);
      if (this.previousState !== QiyiSmartTimerProtocol.STATE_IDLE && state === QiyiSmartTimerProtocol.STATE_IDLE) {
        this.callback.onTimerIdle(solveTime);
      } else if (state === QiyiSmartTimerProtocol.STATE_GET_SET) {
        this.callback.onTimerReady(solveTime);
      } else if (state === QiyiSmartTimerProtocol.STATE_RUNNING) {
        this.callback.onTimerRunning(solveTime);
      } else if (state === QiyiSmartTimerProtocol.STATE_FINISHED || state === QiyiSmartTimerProtocol.STATE_STOPPED) {
        this.callback.onTimerStopped(solveTime);
      } else if (state === QiyiSmartTimerProtocol.STATE_DISCONNECT) {
        this.callback.onTimerDisconnected();
      } else if (state === QiyiSmartTimerProtocol.STATE_IDLE) {
        this.callback.onTimerIdle(solveTime);
      }
      this.previousState = state;
    } else if (dpId === 4 && dpType === 1) {
      this.callback.onTimerReady(0);
    }
  }

  private resetPacketBuffer(): void {
    this.nextPacketNum = 0;
    this.messageLength = 0;
    this.cipherLength = 0;
    this.cipherPos = 0;
    this.cipherBuffer = null;
  }

  private static readUint32(data: number[], offset: number): number {
    if (!data || data.length < offset + 4) return 0;
    return ((data[offset] & 0xFF) << 24) | ((data[offset + 1] & 0xFF) << 16)
      | ((data[offset + 2] & 0xFF) << 8) | (data[offset + 3] & 0xFF);
  }

  static crc16Modbus(data: number[]): number {
    let crc = 0xFFFF;
    for (const b of data) {
      crc ^= (b & 0xFF);
      for (let i = 0; i < 8; i++) {
        if ((crc & 0x0001) !== 0) crc = (crc >> 1) ^ 0xA001;
        else crc >>= 1;
      }
    }
    return crc & 0xFFFF;
  }

  private static aesEncrypt(value: number[]): number[] {
    const result = value.slice();
    for (let i = 0; i < result.length; i++) {
      result[i] = (result[i] ^ QiyiSmartTimerProtocol.AES_KEY[i % QiyiSmartTimerProtocol.AES_KEY.length]) & 0xff;
    }
    return result;
  }

  private static aesDecrypt(value: number[]): number[] {
    return QiyiSmartTimerProtocol.aesEncrypt(value);
  }
}
