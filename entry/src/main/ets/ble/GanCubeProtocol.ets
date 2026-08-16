// GAN 智能魔方协议
import { GanCubeCipher } from './GanCubeCipher';
import { SmartCubeProtocol, BLEGattHandle, BLEServiceHandle, BLECharacteristicHandle, BLEDescriptorHandle } from './SmartCubeProtocol';
import { MoveCallback } from './Moyu32CubeProtocol';

export class GanCubeProtocol implements SmartCubeProtocol {
  static readonly SERVICE_UUID_V2 = '6e400001-b5a3-f393-e0a9-e50e24dc4179';
  static readonly CHRCT_UUID_V2READ = '28be4cb6-cd67-11e9-a32f-2a2ae2dbcce4';
  static readonly CHRCT_UUID_V2WRITE = '28be4a4a-cd67-11e9-a32f-2a2ae2dbcce4';
  static readonly SERVICE_UUID_V3 = '8653000a-43e6-47b7-9cb0-5fc21d4ae340';
  static readonly CHRCT_UUID_V3READ = '8653000b-43e6-47b7-9cb0-5fc21d4ae340';
  static readonly CHRCT_UUID_V3WRITE = '8653000c-43e6-47b7-9cb0-5fc21d4ae340';
  static readonly SERVICE_UUID_V4 = '00000010-0000-fff7-fff6-fff5fff4fff0';
  static readonly CHRCT_UUID_V4READ = '0000fff6-0000-1000-8000-00805f9b34fb';
  static readonly CHRCT_UUID_V4WRITE = '0000fff5-0000-1000-8000-00805f9b34fb';
  private static readonly CCCD_UUID = '00002902-0000-1000-8000-00805f9b34fb';

  private static readonly BASE_KEY: number[] = [1, 2, 66, 40, 49, 145, 22, 7, 32, 5, 24, 84, 66, 17, 18, 83];
  private static readonly BASE_IV: number[] = [17, 3, 50, 40, 33, 1, 118, 39, 32, 149, 120, 20, 50, 18, 2, 67];
  private static readonly AXIS_MASKS = [2, 32, 8, 1, 16, 4];
  private static readonly MAX_MOVE_DELTA_MS = 0xffff;

  private contextCallback: MoveCallback;
  private cipher = new GanCubeCipher();
  private requestQueue: number[][] = [];
  private moveBuffer: MoveEvent[] = [];
  private gatt: BLEGattHandle | null = null;
  private readCharacteristic: BLECharacteristicHandle | null = null;
  private writeCharacteristic: BLECharacteristicHandle | null = null;
  private variant: number = 0; // 0=V2, 1=V3, 2=V4
  private deviceName: string = '';
  private deviceMac: string = '';
  private notificationsReady: boolean = false;
  private writePending: boolean = false;
  private initialStateShown: boolean = false;
  private prevMoveCnt: number = -1;
  private currentMoveCnt: number = -1;
  private lastEmittedDeviceTs: number = -1;
  private lastEmittedLocTime: number = -1;
  private prevMoveLocTime: number = -1;
  private batteryLevel: number = 0;

  constructor(callback: MoveCallback) {
    this.contextCallback = callback;
  }

  static matchesDeviceName(deviceName: string): boolean {
    if (!deviceName) return false;
    const normalized = deviceName.trim().toUpperCase();
    return normalized.startsWith('GAN') || normalized.startsWith('MG') || normalized.startsWith('AICUBE');
  }

  static findPrimaryService(gatt: BLEGattHandle): BLEServiceHandle | null {
    if (!gatt) return null;
    let s = gatt.getService(GanCubeProtocol.SERVICE_UUID_V2);
    if (s) return s;
    s = gatt.getService(GanCubeProtocol.SERVICE_UUID_V3);
    if (s) return s;
    return gatt.getService(GanCubeProtocol.SERVICE_UUID_V4);
  }

  start(gatt: BLEGattHandle, service: BLEServiceHandle, deviceName: string, deviceAddress: string): boolean {
    this.clear();
    this.gatt = gatt;
    this.deviceName = (deviceName || '').trim();
    this.deviceMac = this.normalizeMac(deviceAddress) || '';
    this.variant = this.resolveVariant(service);
    if (this.variant < 0 || !this.deviceMac) return false;
    if (!this.initCipher()) return false;
    if (!this.bindCharacteristics(service)) return false;
    if (!gatt.setCharacteristicNotification(this.readCharacteristic!, true)) return false;
    const descriptor = this.readCharacteristic!.getDescriptor(GanCubeProtocol.CCCD_UUID);
    if (descriptor) {
      const CCCD_ENABLE = [0x01, 0x00];
      descriptor.setValue(CCCD_ENABLE);
      this.onNotificationsEnabled();
    } else {
      this.onNotificationsEnabled();
    }
    return true;
  }

  clear(): void {
    this.requestQueue = [];
    this.moveBuffer = [];
    this.gatt = null;
    this.readCharacteristic = null;
    this.writeCharacteristic = null;
    this.deviceName = '';
    this.deviceMac = '';
    this.notificationsReady = false;
    this.writePending = false;
    this.initialStateShown = false;
    this.prevMoveCnt = -1;
    this.currentMoveCnt = -1;
    this.lastEmittedDeviceTs = -1;
    this.lastEmittedLocTime = -1;
    this.prevMoveLocTime = -1;
    this.batteryLevel = 0;
  }

  onDescriptorWrite(descriptor: BLEDescriptorHandle, status: number): void { }
  onCharacteristicWrite(characteristic: BLECharacteristicHandle, status: number): void {
    if (!characteristic || !this.writeCharacteristic) return;
    this.writePending = false;
    this.sendNextRequest();
  }
  onCharacteristicChanged(characteristic: BLECharacteristicHandle): void {
    if (!characteristic || !this.readCharacteristic) return;
    try {
      const value = characteristic.getValue();
      switch (this.variant) {
        case 0: this.parseV2Data(value); break;
        case 1: this.parseV3Data(value); break;
        case 2: this.parseV4Data(value); break;
      }
    } catch (e) {
      console.error('GAN 数据解析失败: ' + e);
    }
  }
  onMtuChanged(mtu: number, status: number): void { }
  onLocalCubeReset(cubeState: string): void { }

  private resolveVariant(service: BLEServiceHandle): number {
    if (!service) return -1;
    const uuid = service.serviceUuid.toUpperCase();
    if (uuid === GanCubeProtocol.SERVICE_UUID_V2.toUpperCase()) return 0;
    if (uuid === GanCubeProtocol.SERVICE_UUID_V3.toUpperCase()) return 1;
    if (uuid === GanCubeProtocol.SERVICE_UUID_V4.toUpperCase()) return 2;
    return -1;
  }

  private initCipher(): boolean {
    try {
      this.cipher.init(GanCubeProtocol.BASE_KEY, GanCubeProtocol.BASE_IV, this.deviceMac);
      return true;
    } catch (e) {
      return false;
    }
  }

  private bindCharacteristics(service: BLEServiceHandle): boolean {
    switch (this.variant) {
      case 0:
        this.readCharacteristic = service.getCharacteristic(GanCubeProtocol.CHRCT_UUID_V2READ);
        this.writeCharacteristic = service.getCharacteristic(GanCubeProtocol.CHRCT_UUID_V2WRITE);
        break;
      case 1:
        this.readCharacteristic = service.getCharacteristic(GanCubeProtocol.CHRCT_UUID_V3READ);
        this.writeCharacteristic = service.getCharacteristic(GanCubeProtocol.CHRCT_UUID_V3WRITE);
        break;
      case 2:
        this.readCharacteristic = service.getCharacteristic(GanCubeProtocol.CHRCT_UUID_V4READ);
        this.writeCharacteristic = service.getCharacteristic(GanCubeProtocol.CHRCT_UUID_V4WRITE);
        break;
    }
    return this.readCharacteristic !== null && this.writeCharacteristic !== null;
  }

  private onNotificationsEnabled(): void {
    if (this.notificationsReady) return;
    this.notificationsReady = true;
    switch (this.variant) {
      case 0:
        this.enqueueRequest(this.v2SimpleRequest(5));
        this.enqueueRequest(this.v2SimpleRequest(4));
        this.enqueueRequest(this.v2SimpleRequest(9));
        break;
      case 1:
        this.enqueueRequest(this.v3SimpleRequest(4));
        this.enqueueRequest(this.v3SimpleRequest(1));
        this.enqueueRequest(this.v3SimpleRequest(7));
        break;
      case 2:
        this.enqueueRequest(this.v4RequestHardwareInfo());
        this.enqueueRequest(this.v4RequestFacelets());
        this.enqueueRequest(this.v4RequestBattery());
        break;
    }
  }

  private enqueueRequest(request: number[]): void {
    if (!request) return;
    this.requestQueue.push(request);
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
      console.error('GAN 请求加密失败: ' + e);
      this.writePending = false;
    }
  }

  private v2SimpleRequest(opcode: number): number[] {
    const req: number[] = new Array<number>(20).fill(0);
    req[0] = opcode;
    return req;
  }

  private v3SimpleRequest(opcode: number): number[] {
    const req: number[] = new Array<number>(16).fill(0);
    req[0] = 0x68;
    req[1] = opcode;
    return req;
  }

  private v4RequestHardwareInfo(): number[] {
    const req: number[] = new Array<number>(20).fill(0);
    req[0] = 0xDF;
    req[1] = 0x03;
    return req;
  }

  private v4RequestFacelets(): number[] {
    const req: number[] = new Array<number>(20).fill(0);
    req[0] = 0xDD;
    req[1] = 0x04;
    req[3] = 0xED;
    return req;
  }

  private v4RequestBattery(): number[] {
    const req: number[] = new Array<number>(20).fill(0);
    req[0] = 0xDD;
    req[1] = 0x04;
    req[3] = 0xEF;
    return req;
  }

  private parseV2Data(value: number[]): void {
    const bits = this.toBitString(this.cipher.decode(value));
    const mode = this.parseBits(bits, 0, 4);
    if (mode === 2) this.handleV2Move(bits);
    else if (mode === 4) this.handleV2Facelets(bits);
    else if (mode === 9) this.updateBatteryLevel(this.parseBits(bits, 8, 8));
  }

  private handleV2Facelets(bits: string): void {
    if (this.prevMoveCnt !== -1) return;
    const moveCnt = this.parseBits(bits, 4, 8);
    const facelet = this.parseFacelet(bits, 12, 33, 47, 91);
    if (!facelet) return;
    if (this.contextCallback.setCubeState(facelet) !== 0) return;
    this.prevMoveCnt = moveCnt;
    this.showInitialStateDialogIfNeeded();
  }

  private handleV2Move(bits: string): void {
    const moveCnt = this.parseBits(bits, 4, 8);
    if (moveCnt === this.prevMoveCnt || this.prevMoveCnt === -1) return;
    const moves: number[] = new Array<number>(7);
    const timeOffsets: number[] = new Array<number>(7);
    for (let i = 0; i < 7; i++) {
      const rawMove = this.parseBits(bits, 12 + i * 5, 5);
      if (rawMove >= 12) return;
      moves[i] = this.convertQuarterMove(rawMove >> 1, rawMove & 1);
      timeOffsets[i] = this.parseBits(bits, 47 + i * 16, 16);
    }
    let moveDiff = (moveCnt - this.prevMoveCnt) & 0xff;
    this.prevMoveCnt = moveCnt;
    if (moveDiff > moves.length) moveDiff = moves.length;
    for (let i = moveDiff - 1; i >= 0; i--) {
      this.emitMove(moves[i], timeOffsets[i]);
    }
  }

  private parseV3Data(value: number[]): void {
    const locTime = Date.now();
    const bits = this.toBitString(this.cipher.decode(value));
    const magic = this.parseBits(bits, 0, 8);
    const mode = this.parseBits(bits, 8, 8);
    const len = this.parseBits(bits, 16, 8);
    if (magic !== 0x55 || len <= 0) return;
    if (mode === 1) this.handleV3Move(bits, locTime);
    else if (mode === 2) this.handleV3Facelets(bits, locTime);
    else if (mode === 16) this.updateBatteryLevel(this.parseBits(bits, 24, 8));
  }

  private parseV4Data(value: number[]): void {
    const locTime = Date.now();
    const bits = this.toBitString(this.cipher.decode(value));
    const mode = this.parseBits(bits, 0, 8);
    const len = this.parseBits(bits, 8, 8);
    if (mode === 0x01) this.handleV4Move(bits, locTime);
    else if (mode === 0xED) this.handleV4Facelets(bits, locTime);
    else if (mode === 0xEF) this.updateBatteryLevel(this.parseBits(bits, 8 + len * 8, 8));
  }

  private updateBatteryLevel(level: number): void {
    this.batteryLevel = level;
    this.contextCallback.setBatteryValue(this.batteryLevel);
    this.contextCallback.refreshSmartCubeStateUi();
  }

  private handleV3Move(bits: string, locTime: number): void {
    let moveCnt = (this.parseBits(bits, 64, 8) << 8) | this.parseBits(bits, 56, 8);
    moveCnt &= 0xff;
    this.currentMoveCnt = moveCnt;
    this.prevMoveLocTime = locTime;
    if (moveCnt === this.prevMoveCnt || this.prevMoveCnt === -1) return;
    let ts = this.parseBits(bits, 48, 8);
    ts = (ts << 8) | this.parseBits(bits, 40, 8);
    ts = (ts << 8) | this.parseBits(bits, 32, 8);
    ts = (ts << 8) | this.parseBits(bits, 24, 8);
    const pow = this.parseBits(bits, 72, 2);
    const axis = this.decodeAxisMask(this.parseBits(bits, 74, 6));
    if (axis < 0) return;
    const move = this.convertQuarterMove(axis, pow);
    this.emitMove(move, this.computeDelta(ts));
    this.prevMoveCnt = moveCnt;
  }

  private handleV4Move(bits: string, locTime: number): void {
    for (let offset = 0; offset + 72 <= bits.length; offset += 72) {
      if (this.parseBits(bits, offset, 8) !== 0x01) break;
      let moveCnt = (this.parseBits(bits, offset + 56, 8) << 8) | this.parseBits(bits, offset + 48, 8);
      moveCnt &= 0xff;
      this.currentMoveCnt = moveCnt;
      this.prevMoveLocTime = locTime;
      if (moveCnt === this.prevMoveCnt || this.prevMoveCnt === -1) continue;
      let ts = this.parseBits(bits, offset + 40, 8);
      ts = (ts << 8) | this.parseBits(bits, offset + 32, 8);
      ts = (ts << 8) | this.parseBits(bits, offset + 24, 8);
      ts = (ts << 8) | this.parseBits(bits, offset + 16, 8);
      const pow = this.parseBits(bits, offset + 64, 2);
      const axis = this.decodeAxisMask(this.parseBits(bits, offset + 66, 6));
      if (axis < 0) break;
      this.emitMove(this.convertQuarterMove(axis, pow), this.computeDelta(ts));
      this.prevMoveCnt = moveCnt;
    }
  }

  private handleV3Facelets(bits: string, locTime: number): void {
    const moveCnt = ((this.parseBits(bits, 32, 8) << 8) | this.parseBits(bits, 24, 8)) & 0xff;
    this.currentMoveCnt = moveCnt;
    if (this.prevMoveCnt !== -1) return;
    const facelet = this.parseFacelet(bits, 40, 61, 77, 121);
    if (!facelet) return;
    if (this.contextCallback.setCubeState(facelet) !== 0) return;
    this.prevMoveCnt = moveCnt;
    this.lastEmittedDeviceTs = -1;
    this.showInitialStateDialogIfNeeded();
  }

  private handleV4Facelets(bits: string, locTime: number): void {
    const moveCnt = ((this.parseBits(bits, 24, 8) << 8) | this.parseBits(bits, 16, 8)) & 0xff;
    this.currentMoveCnt = moveCnt;
    if (this.prevMoveCnt !== -1) return;
    const facelet = this.parseFacelet(bits, 32, 53, 69, 113);
    if (!facelet) return;
    if (this.contextCallback.setCubeState(facelet) !== 0) return;
    this.prevMoveCnt = moveCnt;
    this.lastEmittedDeviceTs = -1;
    this.showInitialStateDialogIfNeeded();
  }

  private parseFacelet(bits: string, cpStart: number, coStart: number, epStart: number, eoStart: number): string | null {
    const cp: number[] = new Array<number>(8);
    const co: number[] = new Array<number>(8);
    const ep: number[] = new Array<number>(12);
    const eo: number[] = new Array<number>(12);
    let cchk = 0xf00;
    for (let i = 0; i < 7; i++) {
      const perm = this.parseBits(bits, cpStart + i * 3, 3);
      const ori = this.parseBits(bits, coStart + i * 2, 2);
      cchk -= ori << 3;
      cchk ^= perm;
      cp[i] = perm;
      co[i] = ori;
    }
    cp[7] = cchk & 0x7;
    co[7] = ((cchk & 0xff8) % 24) >> 3;
    let echk = 0;
    for (let i = 0; i < 11; i++) {
      const perm = this.parseBits(bits, epStart + i * 4, 4);
      const ori = this.parseBits(bits, eoStart + i, 1);
      echk ^= (perm << 1) | ori;
      ep[i] = perm;
      eo[i] = ori;
    }
    ep[11] = echk >> 1;
    eo[11] = echk & 1;
    return this.cubeToFacelet(cp, co, ep, eo);
  }

  private cubeToFacelet(cp: number[], co: number[], ep: number[], eo: number[]): string | null {
    // 简化: 使用标准面片转换
    const cornerFacelet = [[8, 9, 20], [6, 18, 38], [0, 36, 47], [2, 45, 11],
                           [29, 26, 15], [27, 44, 24], [33, 53, 42], [35, 17, 51]];
    const edgeFacelet = [[5, 10], [7, 19], [3, 37], [1, 46], [32, 16], [28, 25],
                         [30, 43], [34, 52], [50, 39], [48, 14], [12, 23], [41, 21]];
    const facelet: string[] = new Array<string>(54).fill('U');
    const centerOrder = 'URFDLB';
    for (let i = 0; i < 6; i++) { facelet[i * 9 + 4] = centerOrder[i]; }
    const cornerOriMap = [
      [1, 2, 0], [2, 0, 1], [0, 1, 2], [2, 0, 1], [2, 0, 1], [1, 2, 0], [0, 1, 2], [1, 2, 0]
    ];
    const colors = ['U', 'R', 'F', 'D', 'L', 'B'];
    for (let c = 0; c < 8; c++) {
      const perm = cp[c];
      const ori = co[c];
      for (let i = 0; i < 3; i++) {
        const mapped = cornerOriMap[c][(i + ori) % 3];
        const target = cornerFacelet[c][mapped];
        facelet[target] = colors[Math.floor(perm / 9) % 6];
      }
    }
    for (let e = 0; e < 12; e++) {
      const perm = ep[e];
      const ori = eo[e];
      facelet[edgeFacelet[e][ori]] = colors[Math.floor(perm / 9) % 6];
      facelet[edgeFacelet[e][1 - ori]] = colors[Math.floor(perm / 9 + 1) % 6 + 3 * (Math.floor(perm / 9) >= 3 ? 1 : 0)];
    }
    return facelet.join('');
  }

  private emitMove(move: number, delta: number): void {
    this.contextCallback.moveCube(move, Math.max(0, Math.min(delta, GanCubeProtocol.MAX_MOVE_DELTA_MS)));
  }

  private computeDelta(deviceTs: number): number {
    const current = deviceTs;
    if (this.lastEmittedDeviceTs < 0) { this.lastEmittedDeviceTs = current; return 0; }
    let delta = current - this.lastEmittedDeviceTs;
    this.lastEmittedDeviceTs = current;
    if (delta < 0) return 0;
    return Math.min(delta, GanCubeProtocol.MAX_MOVE_DELTA_MS);
  }

  private decodeAxisMask(mask: number): number {
    for (let i = 0; i < GanCubeProtocol.AXIS_MASKS.length; i++) {
      if (GanCubeProtocol.AXIS_MASKS[i] === mask) return i;
    }
    return -1;
  }

  private convertQuarterMove(axis: number, pow: number): number {
    return axis * 3 + (pow === 0 ? 0 : 2);
  }

  private toBitString(bytes: number[]): string {
    let sb = '';
    for (let i = 0; i < bytes.length; i++) {
      sb += (bytes[i] & 0xff).toString(2).padStart(8, '0');
    }
    return sb;
  }

  private parseBits(bits: string, start: number, len: number): number {
    return parseInt(bits.substring(start, start + len), 2);
  }

  private normalizeMac(mac: string): string | null {
    if (!mac) return null;
    const normalized = mac.trim().toUpperCase();
    return /^[0-9A-F]{2}(:[0-9A-F]{2}){5}$/.test(normalized) ? normalized : null;
  }

  private showInitialStateDialogIfNeeded(): void {
    if (this.initialStateShown) return;
    this.initialStateShown = true;
    this.contextCallback?.showCubeStateDialog();
  }
}

class MoveEvent {
  moveCnt: number;
  move: number;
  deviceTs: number | null;
  receiveLocTime: number;
  constructor(moveCnt: number, move: number, deviceTs: number | null, receiveLocTime: number = -1) {
    this.moveCnt = moveCnt;
    this.move = move;
    this.deviceTs = deviceTs;
    this.receiveLocTime = receiveLocTime;
  }
}
