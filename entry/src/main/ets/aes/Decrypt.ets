// BLE 旧链路兼容 - AES 解密工具
export class Decrypt {
  static toHexValue(value: number[]): number[] {
    if (!value) return [];
    const result: number[] = new Array<number>(value.length * 2);
    for (let i = 0; i < value.length; i++) {
      const b = value[i] & 0xff;
      result[i * 2] = (b >> 4) & 0x0f;
      result[i * 2 + 1] = b & 0x0f;
    }
    return result;
  }

  static getKey(version: number, value: number[]): number[] | null {
    if (!value || value.length === 0) return null;
    const key: number[] = new Array<number>(16);
    const len = Math.min(value.length, key.length);
    for (let i = 0; i < len; i++) {
      key[i] = value[i];
    }
    return key;
  }

  static initAES(key: number[]): void {
    // Temporary compatibility shim for legacy Bluetooth code.
  }

  static decode(value: number[]): number[] {
    if (!value) return [];
    return value.slice(); // Arrays.copyOf
  }
}
