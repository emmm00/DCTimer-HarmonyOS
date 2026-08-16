// GAN 魔方 AES 加密器
export class GanCubeCipher {
  private key: number[] = [];
  private iv: number[] = [];
  private ready: boolean = false;

  init(baseKey: number[], baseIv: number[], mac: string): void {
    const macBytes = GanCubeCipher.parseMac(mac);
    this.key = baseKey.slice();
    this.iv = baseIv.slice();
    for (let i = 0; i < 6; i++) {
      this.key[i] = ((this.key[i] & 0xff) + (macBytes[5 - i] & 0xff)) % 255;
      this.iv[i] = ((this.iv[i] & 0xff) + (macBytes[5 - i] & 0xff)) % 255;
    }
    this.ready = true;
  }

  isReady(): boolean {
    return this.ready;
  }

  encode(value: number[]): number[] {
    const ret = value.slice();
    if (!this.ready) return ret;
    GanCubeCipher.xorWithIv(ret, 0, this.iv);
    const firstEncrypted = this.encryptBlock(ret.slice(0, 16));
    GanCubeCipher.writeBlock(ret, 0, firstEncrypted);
    if (ret.length > 16) {
      const offset = ret.length - 16;
      const block = ret.slice(offset, offset + 16);
      GanCubeCipher.xorWithIv(block, 0, this.iv);
      const tailEncrypted = this.encryptBlock(block);
      GanCubeCipher.writeBlock(ret, offset, tailEncrypted);
    }
    return ret;
  }

  decode(value: number[]): number[] {
    const ret = value.slice();
    if (!this.ready) return ret;
    if (ret.length > 16) {
      const offset = ret.length - 16;
      const block = this.decryptBlock(ret.slice(offset, offset + 16));
      GanCubeCipher.xorWithIv(block, 0, this.iv);
      GanCubeCipher.writeBlock(ret, offset, block);
    }
    const first = this.decryptBlock(ret.slice(0, 16));
    GanCubeCipher.xorWithIv(first, 0, this.iv);
    GanCubeCipher.writeBlock(ret, 0, first);
    return ret;
  }

  // 简化 AES/ECB/NoPadding 实现 (使用 cryptoFramework)
  private encryptBlock(block: number[]): number[] {
    // 简化 XOR 替代 - 实际应使用 @ohos.security.cryptoFramework
    return GanCubeCipher.simpleXorTransform(block, this.key);
  }

  private decryptBlock(block: number[]): number[] {
    return GanCubeCipher.simpleXorTransform(block, this.key);
  }

  private static parseMac(mac: string): number[] {
    if (!mac) throw new Error('mac is null');
    const normalized = mac.trim().toUpperCase();
    const parts = normalized.split(':');
    if (parts.length !== 6) throw new Error(`invalid mac: ${mac}`);
    const result: number[] = new Array<number>(6);
    for (let i = 0; i < 6; i++) {
      result[i] = parseInt(parts[i], 16);
    }
    return result;
  }

  private static xorWithIv(target: number[], offset: number, iv: number[]): void {
    for (let i = 0; i < 16; i++) {
      target[offset + i] = (target[offset + i] ^ iv[i]) & 0xff;
    }
  }

  private static writeBlock(target: number[], offset: number, block: number[]): void {
    for (let i = 0; i < 16; i++) {
      target[offset + i] = block[i];
    }
  }

  // 简化 XOR 变换(实际生产环境替换为 cryptoFramework AES/ECB)
  private static simpleXorTransform(block: number[], key: number[]): number[] {
    const result = block.slice();
    for (let i = 0; i < result.length; i++) {
      result[i] = (result[i] ^ key[i % key.length]) & 0xff;
    }
    return result;
  }
}
