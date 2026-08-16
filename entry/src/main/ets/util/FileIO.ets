// HarmonyOS file IO helper for algorithm table caching (twophase.dat etc.)
import { fileIo as fs } from '@kit.CoreFileKit';

export class FileIO {
  static mkdir(path: string): void {
    try {
      fs.mkdirSync(path);
    } catch (e) {
      // ignore (already exists)
    }
  }

  static readWhole(path: string): Uint8Array | null {
    try {
      const file = fs.openSync(path, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(file.fd);
      const buf = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buf);
      fs.closeSync(file);
      return new Uint8Array(buf);
    } catch (e) {
      return null;
    }
  }

  static writeWhole(path: string, data: Uint8Array): boolean {
    try {
      const file = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      fs.writeSync(file.fd, data.buffer as ArrayBuffer);
      fs.closeSync(file);
      return true;
    } catch (e) {
      return false;
    }
  }
}
