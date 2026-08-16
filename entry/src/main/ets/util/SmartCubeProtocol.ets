/**
 * 智能魔方协议定义与数据解析
 *
 * 支持品牌:
 * - Giiker (计客) — 最简单的协议，通知数据直接包含转动信息
 * - GAN (淦源) — AES 加密协议，需先获取密钥
 * - Moyu (魔域) — 32面协议
 * - QiYi (奇艺) — 奇艺魔方协议
 *
 * 参考: DCTimer-BLE Android 源码
 *   BluetoothTools.java, GanCubeProtocol.java, SmartCubeProtocol.java
 */

export enum CubeType {
  UNKNOWN = 0,
  GIIKER = 1,
  GAN = 2,
  MOYU32 = 3,
  QIYI = 4
}

export enum CubeConnectionState {
  DISCONNECTED = 0,
  SCANNING = 1,
  CONNECTING = 2,
  CONNECTED = 3,
  READY = 4
}

export interface CubeMove {
  face: number;   // 0=U,1=R,2=F,3=D,4=L,5=B
  direction: number; // 0=clockwise, 1=double, 2=counter-clockwise
  timestamp: number;
}

export interface CubeDeviceInfo {
  address: string;
  name: string;
  type: CubeType;
  rssi: number;
}

/**
 * 根据设备名称推测智能魔方类型
 */
export function guessCubeType(deviceName: string | null): CubeType {
  if (!deviceName) {
    return CubeType.UNKNOWN;
  }
  const name: string = deviceName.toUpperCase();
  // Giiker cubes
  if (name.startsWith('GIIKER') || name.startsWith('SUPERCUBE') || name.startsWith('ICUBE')) {
    return CubeType.GIIKER;
  }
  // 魔域32面
  if (name.startsWith('WCU_MY3')) {
    return CubeType.MOYU32;
  }
  // 奇艺
  if (name.startsWith('QY-') || name.startsWith('XMD-')) {
    return CubeType.QIYI;
  }
  // GAN
  if (name.startsWith('GAN') || name.startsWith('GANCUBE') || name.startsWith('GAN356') ||
    name.startsWith('GAN11') || name.startsWith('GAN12') || name.startsWith('GAN13') ||
    name.startsWith('GAN14') || name.startsWith('GAN15') || name.startsWith('ICARRY') ||
    name.startsWith('MONSTER')) {
    return CubeType.GAN;
  }
  // GoCube
  if (name.startsWith('GOCUBE') || name.startsWith('RUBIKS')) {
    return CubeType.GIIKER; // shares similar protocol
  }
  return CubeType.UNKNOWN;
}

// --- Giiker 协议解析 ---

/**
 * Giiker (计客) 转动数据解析
 * 原始协议中，数据被编码为 hex 值数组
 * byte[32] = face index (1-6), byte[33] = rotation amount
 * move = moveIdx[face-1] * 3 + (rotation - 1) % 7
 */
const GIIKER_MOVE_IDX: number[] = [5, 3, 4, 0, 1, 2]; // face 1-6 mapping

export function parseGiikerMove(data: Uint8Array): CubeMove | null {
  if (data.length < 34) {
    return null;
  }
  const faceRaw: number = data[32] - 1; // 1-6 → 0-5
  const rotRaw: number = (data[33] - 1) % 7;
  if (faceRaw < 0 || faceRaw >= 6 || rotRaw < 0 || rotRaw >= 3) {
    return null;
  }
  const face: number = GIIKER_MOVE_IDX[faceRaw];
  const direction: number = rotRaw;
  return {
    face: face,
    direction: direction,
    timestamp: Date.now()
  };
}

// --- 服务 UUID 接口定义（ArkTS 要求显式类型） ---

interface GanServiceUUIDs {
  SERVICE_UUID_V1: string;
  SERVICE_UUID_V2: string;
  SERVICE_UUID_V3: string;
  CHARACTER_F2: string;
  CHARACTER_F3: string;
  CHARACTER_F5: string;
  CHARACTER_F6: string;
  CHARACTER_F7: string;
  CHARACTER_READ_V2: string;
  CHARACTER_WRITE_V2: string;
}

interface GiikerServiceUUIDs {
  SERVICE_UUID: string;
  CHARACTER_DATA: string;
  CHARACTER_READ: string;
  CHARACTER_WRITE: string;
}

// --- GAN 协议 UUID ---
export const GAN_SERVICES: GanServiceUUIDs = {
  SERVICE_UUID_V1: '0000fff0-0000-1000-8000-00805f9b34fb',
  SERVICE_UUID_V2: '6e400001-b5a3-f393-e0a9-e50e24dc4179',
  SERVICE_UUID_V3: '8653000a-43e6-47b7-9cb0-5fc21d4ae340',
  CHARACTER_F2: '0000fff2-0000-1000-8000-00805f9b34fb',
  CHARACTER_F3: '0000fff3-0000-1000-8000-00805f9b34fb',
  CHARACTER_F5: '0000fff5-0000-1000-8000-00805f9b34fb',
  CHARACTER_F6: '0000fff6-0000-1000-8000-00805f9b34fb',
  CHARACTER_F7: '0000fff7-0000-1000-8000-00805f9b34fb',
  CHARACTER_READ_V2: '28be4a4a-cd67-11e9-a32f-2a2ae2dbcce4',
  CHARACTER_WRITE_V2: '28be4cb6-cd67-11e9-a32f-2a2ae2dbcce4'
};

// --- Giiker 协议 UUID ---
export const GIIKER_SERVICES: GiikerServiceUUIDs = {
  SERVICE_UUID: '0000aadb-0000-1000-8000-00805f9b34fb',
  CHARACTER_DATA: '0000aadc-0000-1000-8000-00805f9b34fb',
  CHARACTER_READ: '0000aaab-0000-1000-8000-00805f9b34fb',
  CHARACTER_WRITE: '0000aaac-0000-1000-8000-00805f9b34fb'
};
