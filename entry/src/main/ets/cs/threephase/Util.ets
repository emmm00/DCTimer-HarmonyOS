// Ported from cs/threephase/Util.java (DCTimer-BLE -> HarmonyOS ArkTS)
// Android imports (android.os.Handler, android.util.Log, com.dctimer.APP) removed:
//   - Util.init(Handler) is now synchronous Util.init() (no progress callback);
//   - APP.dataPath replaced by the static field Util.dataPath.
import { Center1 } from './Center1';
import { Center2 } from './Center2';
import { Center3 } from './Center3';
import { Edge3 } from './Edge3';
import { FileIO } from '../../util/FileIO';

export class Util {
  static colorMap4to3: string[] = ['U', 'D', 'F', 'B', 'R', 'L'];
  private static ini = false;
  static dataPath: string = '';

  public static init(): void {
    if (Util.ini) {
      return;
    }
    try {
      const buf = FileIO.readWhole(Util.dataPath + 'center.dat');
      if (buf == null) {
        throw new Error('no cache file');
      }
      let pos = 0;
      Center1.initSym();
      pos = Util.readIntArrBE(Center1.sym2raw, buf, pos);
      pos = Util.readIntArr2D(Center1.ctsmv, buf, pos);
      Center1.createPrun();
      Center2.initRl();
      pos = Util.readCharArr2D(Center2.ctrot, buf, pos);
      pos = Util.readCharArr2D(Center2.ctmv, buf, pos);
      pos = Util.readBytes(Center2.ctprun, buf, pos);
      Util.readCharArr2D(Center3.ctmove, buf, pos);
      Center3.createPrun();
    } catch (e) {
      Center1.initSym();
      Center1.init();
      Center1.createPrun();
      Center2.initRl();
      Center2.initCt();
      Center3.createMove();
      Center3.createPrun();
      try {
        Util.writeCenterTables();
      } catch (e2) {
        // ignore
      }
    }
    Edge3.initMvrot();
    Edge3.initRaw2Sym();
    Edge3.eprun = new Array<number>(Math.floor(Edge3.N_EPRUN / 16)).fill(0);
    try {
      const buf = FileIO.readWhole(Util.dataPath + 'edge.dat');
      if (buf == null) {
        throw new Error('no cache file');
      }
      Util.readIntArrBE(Edge3.eprun as number[], buf, 0);
    } catch (e) {
      Edge3.createPrun();
      try {
        Util.writeEdgeTable();
      } catch (e2) {
        // ignore
      }
    }
    Util.ini = true;
  }

  static temp = 0;
  public static swap(arr: number[], a: number, b: number, c: number, d: number, key: number): void {
    switch (key) {
      case 0:
        Util.temp = arr[d];
        arr[d] = arr[c];
        arr[c] = arr[b];
        arr[b] = arr[a];
        arr[a] = Util.temp;
        return;
      case 1:
        Util.temp = arr[a];
        arr[a] = arr[c];
        arr[c] = Util.temp;
        Util.temp = arr[b];
        arr[b] = arr[d];
        arr[d] = Util.temp;
        return;
      case 2:
        Util.temp = arr[a];
        arr[a] = arr[b];
        arr[b] = arr[c];
        arr[c] = arr[d];
        arr[d] = Util.temp;
        return;
    }
  }

  static parity(arr: number[]): number {
    let parity = 0;
    for (let i = 0, len = arr.length; i < len; i++) {
      for (let j = i; j < len; j++) {
        if (arr[i] > arr[j]) {
          parity ^= 1;
        }
      }
    }
    return parity;
  }

  static binarySearch(arr: number[], key: number): number {
    let lo = 0;
    let hi = arr.length - 1;
    while (lo <= hi) {
      const mid = (lo + hi) >> 1;
      const midVal = arr[mid];
      if (midVal < key) {
        lo = mid + 1;
      } else if (midVal > key) {
        hi = mid - 1;
      } else {
        return mid;
      }
    }
    return -(lo + 1);
  }

  // ================= data storage (big-endian int, little-endian char/int2d) =================
  static readIntArrBE(arr: number[], buf: Uint8Array, pos: number): number {
    for (let i = 0; i < arr.length; i++) {
      arr[i] = ((buf[pos + i * 4] << 24) & 0xff000000) | ((buf[pos + i * 4 + 1] << 16) & 0xff0000) |
        ((buf[pos + i * 4 + 2] << 8) & 0xff00) | (buf[pos + i * 4 + 3] & 0xff);
    }
    return pos + arr.length * 4;
  }

  static readCharArr2D(arr: number[][], buf: Uint8Array, pos: number): number {
    const len = arr[0].length;
    for (let i = 0; i < arr.length; i++) {
      for (let j = 0; j < len; j++) {
        arr[i][j] = (buf[pos + j * 2] & 0xff) | ((buf[pos + j * 2 + 1] << 8) & 0xff00);
      }
      pos += len * 2;
    }
    return pos;
  }

  private static readIntArr2D(arr: number[][], buf: Uint8Array, pos: number): number {
    const len = arr[0].length;
    for (let i = 0; i < arr.length; i++) {
      for (let j = 0; j < len; j++) {
        arr[i][j] = (buf[pos + j * 4] & 0xff) | ((buf[pos + j * 4 + 1] << 8) & 0xff00) |
          ((buf[pos + j * 4 + 2] << 16) & 0xff0000) | ((buf[pos + j * 4 + 3] << 24) & 0xff000000);
      }
      pos += len * 4;
    }
    return pos;
  }

  private static readBytes(arr: number[], buf: Uint8Array, pos: number): number {
    for (let i = 0; i < arr.length; i++) {
      arr[i] = buf[pos + i];
    }
    return pos + arr.length;
  }

  // ================= center.dat cache writer =================
  private static writeCenterTables(): void {
    const parts: Uint8Array[] = [];
    parts.push(Util.packIntArrBE(Center1.sym2raw));
    parts.push(Util.packIntArr2D(Center1.ctsmv));
    parts.push(Util.packCharArr2D(Center2.ctrot));
    parts.push(Util.packCharArr2D(Center2.ctmv));
    parts.push(Util.packBytes(Center2.ctprun));
    parts.push(Util.packCharArr2D(Center3.ctmove));
    let total = 0;
    for (const p of parts) {
      total += p.length;
    }
    const out = new Uint8Array(total);
    let pos = 0;
    for (const p of parts) {
      out.set(p, pos);
      pos += p.length;
    }
    FileIO.writeWhole(Util.dataPath + 'center.dat', out);
  }

  // ================= edge.dat cache writer =================
  private static writeEdgeTable(): void {
    FileIO.writeWhole(Util.dataPath + 'edge.dat', Util.packIntArrBE(Edge3.eprun as number[]));
  }

  private static packIntArrBE(arr: number[]): Uint8Array {
    const out = new Uint8Array(arr.length * 4);
    let pos = 0;
    for (let i = 0; i < arr.length; i++) {
      out[pos++] = (arr[i] >>> 24) & 0xff;
      out[pos++] = (arr[i] >>> 16) & 0xff;
      out[pos++] = (arr[i] >>> 8) & 0xff;
      out[pos++] = arr[i] & 0xff;
    }
    return out;
  }

  private static packBytes(arr: number[]): Uint8Array {
    const out = new Uint8Array(arr.length);
    for (let i = 0; i < arr.length; i++) {
      out[i] = arr[i] & 0xff;
    }
    return out;
  }

  private static packCharArr2D(arr: number[][]): Uint8Array {
    const len = arr[0].length;
    const out = new Uint8Array(arr.length * len * 2);
    let pos = 0;
    for (let i = 0; i < arr.length; i++) {
      for (let j = 0; j < len; j++) {
        out[pos++] = arr[i][j] & 0xff;
        out[pos++] = (arr[i][j] >>> 8) & 0xff;
      }
    }
    return out;
  }

  private static packIntArr2D(arr: number[][]): Uint8Array {
    const len = arr[0].length;
    const out = new Uint8Array(arr.length * len * 4);
    let pos = 0;
    for (let i = 0; i < arr.length; i++) {
      for (let j = 0; j < len; j++) {
        out[pos++] = arr[i][j] & 0xff;
        out[pos++] = (arr[i][j] >>> 8) & 0xff;
        out[pos++] = (arr[i][j] >>> 16) & 0xff;
        out[pos++] = (arr[i][j] >>> 24) & 0xff;
      }
    }
    return out;
  }
}
