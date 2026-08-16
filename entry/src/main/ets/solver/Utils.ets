// Ported from solver/Utils.java (DCTimer-BLE -> HarmonyOS ArkTS)

export class Utils {
  static Cnk: number[][] = Utils.initCnk();
  static turn: string[] = ['U', 'D', 'L', 'R', 'F', 'B'];
  static suff: string[] = ['', '2', "'"];
  static suffInv: string[] = ["'", '2', ''];
  static fact: number[] = [1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880, 3628800, 39916800, 479001600];

  private static initCnk(): number[][] {
    const cnk: number[][] = [];
    for (let i = 0; i < 25; i++) {
      const row: number[] = new Array<number>(25).fill(0);
      row[0] = 1;
      row[i] = 1;
      for (let j = 1; j < i; j++) {
        row[j] = cnk[i - 1][j - 1] + cnk[i - 1][j];
      }
      cnk.push(row);
    }
    return cnk;
  }

  static getPruning(table: number[], index: number): number {
    return (table[index >> 3] >> ((index & 7) << 2)) & 15;
  }

  static setPruning(table: number[], index: number, value: number): void {
    table[index >> 3] ^= (15 ^ value) << ((index & 7) << 2);
  }

  static getBit(arr: number[], idx: number): number {
    return arr[idx >> 5] & (1 << (idx & 0x1f));
  }

  static setBit(arr: number[], idx: number): void {
    arr[idx >> 5] |= 1 << (idx & 0x1f);
  }

  static set8Perm(arr: number[], len: number, idx: number): void {
    let val = 0x76543210;
    for (let i = 0; i < len - 1; i++) {
      let p = Utils.fact[len - 1 - i];
      let v = Math.floor(idx / p);
      idx -= v * p;
      v <<= 2;
      arr[i] = (val >> v) & 0x7;
      const m = (1 << v) - 1;
      val = (val & m) + ((val >> 4) & ~m);
    }
    arr[len - 1] = val & 0x7;
  }

  static get8Perm(arr: number[], len: number): number {
    let idx = 0;
    let val = 0x76543210;
    for (let i = 0; i < len - 1; i++) {
      const v = arr[i] << 2;
      idx = (len - i) * idx + ((val >> v) & 0x7);
      val -= 0x11111110 << v;
    }
    return idx;
  }

  static set11Perm(arr: number[], idx: number, len: number): void {
    let val = 0xa9876543210n;
    for (let i = 0; i < len - 1; i++) {
      const p = Utils.fact[len - 1 - i];
      let v = Math.floor(idx / p);
      idx -= v * p;
      v <<= 2;
      arr[i] = Number((val >> BigInt(v)) & 0xfn);
      const m = (1n << BigInt(v)) - 1n;
      val = (val & m) + ((val >> 4n) & ~m);
    }
    arr[len - 1] = Number(val & 0xfn);
  }

  static get11Perm(arr: number[], len: number): number {
    let idx = 0;
    let val = 0xa9876543210n;
    for (let i = 0; i < len - 1; i++) {
      const v = arr[i] << 2;
      idx = Number(BigInt(len - i) * BigInt(idx) + ((val >> BigInt(v)) & 0xfn));
      val -= 0x11111111110n << BigInt(v);
    }
    return idx;
  }

  static circle(arr: number[], a: number, b: number, c: number, d: number): void {
    const temp = arr[a];
    arr[a] = arr[b];
    arr[b] = arr[c];
    arr[c] = arr[d];
    arr[d] = temp;
  }

  static circleOri(arr: number[], a: number, b: number, c: number, d: number, ori: number[]): void {
    const temp = arr[a];
    arr[a] = arr[b] + ori[0];
    arr[b] = arr[c] + ori[1];
    arr[c] = arr[d] + ori[2];
    arr[d] = temp + ori[3];
  }

  static swap(arr: number[], a: number, b: number, c: number, d: number): void {
    let temp = arr[a];
    arr[a] = arr[b];
    arr[b] = temp;
    temp = arr[c];
    arr[c] = arr[d];
    arr[d] = temp;
  }

  static swap2(arr: number[], a: number, b: number): void {
    const temp = arr[a];
    arr[a] = arr[b];
    arr[b] = temp;
  }

  static circle3(arr: number[], a: number, b: number, c: number): void {
    const temp = arr[a];
    arr[a] = arr[b];
    arr[b] = arr[c];
    arr[c] = temp;
  }

  static permToIdx(permutation: number[], length: number, even: boolean): number {
    let index = 0;
    const end = even ? length - 2 : length - 1;
    for (let i = 0; i < end; i++) {
      index *= length - i;
      for (let j = i + 1; j < length; j++) {
        if (permutation[i] > permutation[j]) {
          index++;
        }
      }
    }
    return index;
  }

  static idxToPerm(permutation: number[], index: number, length: number, even: boolean): void {
    let sum = 0;
    if (even) {
      permutation[length - 1] = 1;
      permutation[length - 2] = 0;
    } else {
      permutation[length - 1] = 0;
    }
    const start = even ? length - 3 : length - 2;
    for (let i = start; i >= 0; i--) {
      permutation[i] = index % (length - i);
      sum += permutation[i];
      index = Math.floor(index / (length - i));
      for (let j = i + 1; j < length; j++) {
        if (permutation[j] >= permutation[i]) {
          permutation[j]++;
        }
      }
    }
    if (even && sum % 2 != 0) {
      Utils.swap2(permutation, length - 1, length - 2);
    }
  }

  static flipToIdx(flip: number[], length: number, zeroSum: boolean): number {
    let idx = 0;
    if (zeroSum) {
      length--;
    }
    for (let i = 0; i < length; i++) {
      idx = (idx << 1) | flip[i];
    }
    return idx;
  }

  static idxToFlip(flip: number[], index: number, length: number, zeroSum: boolean): void {
    let sum = 0;
    if (zeroSum) {
      length--;
    }
    for (let i = length - 1; i >= 0; i--) {
      flip[i] = index & 1;
      sum ^= flip[i];
      index >>= 1;
    }
    if (zeroSum) {
      flip[length] = sum;
    }
  }

  static oriToIdx(orientation: number[], length: number, zeroSum: boolean): number {
    let index = 0;
    if (zeroSum) {
      length--;
    }
    for (let i = 0; i < length; i++) {
      index = 3 * index + (orientation[i] % 3);
    }
    return index;
  }

  static idxToOri(orientation: number[], index: number, length: number, zeroSum: boolean): void {
    let sum = 0;
    const start = zeroSum ? length - 2 : length - 1;
    for (let i = start; i >= 0; i--) {
      orientation[i] = index % 3;
      index = Math.floor(index / 3);
      sum += orientation[i];
    }
    if (zeroSum) {
      orientation[length - 1] = 3 - (sum % 3);
    }
  }

  static combToIdx(comb: number[], k: number, n: number): number {
    let idx = 0;
    for (let i = n - 1; i >= 0; i--) {
      if (comb[i] != 0) {
        idx += Utils.Cnk[i][k--];
      }
    }
    return idx;
  }

  static idxToComb(comb: number[], index: number, k: number, n: number): void {
    for (let i = n - 1; i >= 0; i--) {
      if (index >= Utils.Cnk[i][k]) {
        index -= Utils.Cnk[i][k--];
        comb[i] = 1;
      } else {
        comb[i] = 0;
      }
    }
  }

  static permutationSign(permutation: number[]): boolean {
    let nInversions = 0;
    for (let i = 0; i < permutation.length; i++) {
      for (let j = i + 1; j < permutation.length; j++) {
        if (permutation[i] > permutation[j]) {
          nInversions++;
        }
      }
    }
    return nInversions % 2 == 0;
  }

  static createPrun(prunTable: number[], depth: number, moveTable: number[][], times: number): void {
    const total = prunTable.length;
    const moves = moveTable[0].length;
    for (let d = 0; d < depth; d++) {
      for (let i = 0; i < total; i++) {
        if (prunTable[i] == d) {
          for (let j = 0; j < moves; j++) {
            let next = i;
            for (let k = 0; k < times; k++) {
              next = moveTable[next][j];
              if (prunTable[next] < 0) {
                prunTable[next] = d + 1;
              }
            }
          }
        }
      }
    }
  }

  static createPrun2(prunTable: number[], depth: number, moveTable1: number[][], moveTable2: number[][],
    times: number): void {
    const moves1 = moveTable1.length;
    const moves2 = moveTable2.length;
    const moves = moveTable1[0].length;
    for (let d = 0; d < depth; d++) {
      for (let i = 0; i < moves1; i++) {
        for (let j = 0; j < moves2; j++) {
          if (prunTable[i * moves2 + j] == d) {
            for (let k = 0; k < moves; k++) {
              let x = i;
              let y = j;
              for (let l = 0; l < times; l++) {
                x = moveTable1[x][k];
                y = moveTable2[y][k];
                if (prunTable[x * moves2 + y] < 0) {
                  prunTable[x * moves2 + y] = d + 1;
                }
              }
            }
          }
        }
      }
    }
  }

  static createPrun3(prunTable: number[], depth: number, moveTable: number[][], times: number): void {
    const total = prunTable.length;
    const moves = moveTable[0].length;
    for (let d = 0; d < depth; d++) {
      for (let i = 0; i < total; i++) {
        if (prunTable[i] == d) {
          for (let j = 0; j < moves; j++) {
            let next = i;
            for (let k = 0; k < times; k++) {
              next = moveTable[next][j];
              if (prunTable[next] < 0) {
                prunTable[next] = d + 1;
              }
            }
          }
        }
      }
    }
  }

  static fillFacelet(facelet: number[][], f: number[], perm: number[], ori: number[], ts: number[], pcs: number): void {
    for (let c = 0; c < facelet.length; c++) {
      const o = facelet[c].length;
      for (let n = 0; n < o; n++) {
        f[facelet[c][(n + ori[c]) % o]] = ts[Math.floor(facelet[perm[c]][n] / pcs)];
      }
    }
  }

  // ================= data storage (byte helpers, little-endian int/char) =================
  static readCharArr(arr: number[], buf: Uint8Array, pos: number): number {
    for (let i = 0; i < arr.length; i++) {
      arr[i] = (buf[pos + i * 2] & 0xff) | ((buf[pos + i * 2 + 1] << 8) & 0xff00);
    }
    return pos + arr.length * 2;
  }

  static readIntArr(arr: number[], buf: Uint8Array, pos: number): number {
    for (let i = 0; i < arr.length; i++) {
      arr[i] = (buf[pos + i * 4] & 0xff) | ((buf[pos + i * 4 + 1] << 8) & 0xff00) |
        ((buf[pos + i * 4 + 2] << 16) & 0xff0000) | ((buf[pos + i * 4 + 3] << 24) & 0xff000000);
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

  static writeCharArr(arr: number[], out: number[], pos: number): number {
    for (let i = 0; i < arr.length; i++) {
      out[pos++] = arr[i] & 0xff;
      out[pos++] = (arr[i] >>> 8) & 0xff;
    }
    return pos;
  }

  static writeIntArr(arr: number[], out: number[], pos: number): number {
    for (let i = 0; i < arr.length; i++) {
      out[pos++] = arr[i] & 0xff;
      out[pos++] = (arr[i] >>> 8) & 0xff;
      out[pos++] = (arr[i] >>> 16) & 0xff;
      out[pos++] = (arr[i] >>> 24) & 0xff;
    }
    return pos;
  }
}
