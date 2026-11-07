// Ported from com.dctimer.util.Stats.java (DCTimer-BLE -> HarmonyOS ArkTS)
// 时间单位：毫秒（与原版一致），+2 惩罚 = 2000ms。
import type { Result } from '../model/Result';
import { AppConfig } from '../model/AppConfig';
import { StringUtils } from './StringUtils';

const SORT_LATEST_FIRST: number = 7;
const MAX_VALUE: number = 2147483647;
const MIN_VALUE: number = -2147483648;

export class Stats {
  avg1: number[] = new Array<number>(24).fill(0);
  avg2: number[] = new Array<number>(24).fill(0);
  bestTimeRecord: boolean[] = new Array<boolean>(24).fill(false);
  bestAvgRecord: boolean[][] = [new Array<boolean>(24).fill(false), new Array<boolean>(24).fill(false)];
  bestAvg: number[] = [0, 0];
  bestAvgIdx: number[] = [-1, -1];
  mean: number = -1;
  sd: number = 0;
  minIdx: number = 0;
  maxIdx: number = 0;
  solved: number = 0;
  sortIdx: number[] = new Array<number>(24).fill(0);

  mpMin: number[] = [-1, -1, -1, -1, -1, -1];
  mpMax: number[] = [-1, -1, -1, -1, -1, -1];
  mpMean: number[] = new Array<number>(6).fill(0);

  private result: Result;

  constructor(result: Result) {
    this.result = result;
  }

  calcAvg(): void {
    const len: number = this.result.getLength();
    if (this.avg1.length <= len) {
      const size: number = Math.floor(len * 3 / 2);
      this.avg1 = new Array<number>(size).fill(0);
      this.avg2 = new Array<number>(size).fill(0);
      this.bestAvgRecord[0] = new Array<boolean>(size).fill(false);
      this.bestAvgRecord[1] = new Array<boolean>(size).fill(false);
    } else {
      this.bestAvgRecord[0].fill(false, 0, len);
      this.bestAvgRecord[1].fill(false, 0, len);
    }
    this.bestAvg[0] = this.bestAvg[1] = MAX_VALUE;
    this.bestAvgIdx[0] = this.bestAvgIdx[1] = -1;
    for (let i: number = 0; i < len; i++) {
      if (AppConfig.avg1Type === 0) {
        this.avg1[i] = this.averageOf(AppConfig.avg1Len, i, 0);
      } else {
        this.avg1[i] = this.meanOf(AppConfig.avg1Len, i, 0);
      }
      if (AppConfig.avg2Type === 0) {
        this.avg2[i] = this.averageOf(AppConfig.avg2Len, i, 1);
      } else {
        this.avg2[i] = this.meanOf(AppConfig.avg2Len, i, 1);
      }
    }
  }

  meanOf(n: number, i: number, midx: number): number {
    if (i < n - 1) {
      return -2;
    }
    let sum: number = 0;
    for (let j: number = i - n + 1; j <= i; j++) {
      if (this.result.isDnf(j)) {
        return -1;
      } else {
        let time: number = this.result.getTime(j);
        if (AppConfig.timerAccuracy === 0) {
          time = Math.floor(time / 10);
        }
        sum += time;
      }
    }
    let mean: number = Math.floor(sum / n + 0.5);
    if (AppConfig.timerAccuracy === 0) {
      mean *= 10;
    }
    if (midx >= 0 && mean < this.bestAvg[midx]) {
      this.bestAvgRecord[midx][i] = true;
    }
    if (midx >= 0 && mean <= this.bestAvg[midx]) {
      this.bestAvg[midx] = mean;
      this.bestAvgIdx[midx] = i;
    }
    return mean;
  }

  averageOf(n: number, i: number, midx: number): number {
    if (i < n - 1) {
      return -2;
    }
    let nDnf: number = 0;
    let avg: number = 0;
    const trim: number = Math.ceil(n / 20.0);
    let sum: number = 0;

    if (n <= 20) {
      let max: number = MIN_VALUE;
      let min: number = MAX_VALUE;
      for (let j: number = i - n + 1; j <= i; j++) {
        if (this.result.isDnf(j)) {
          nDnf++;
          if (nDnf > trim) {
            return -1;
          }
        } else {
          let time: number = this.result.getTime(j);
          if (time > max) {
            max = time;
          }
          if (time < min) {
            min = time;
          }
          if (AppConfig.timerAccuracy === 0) {
            time = Math.floor(time / 10);
          }
          sum += time;
        }
      }
      if (nDnf !== 0) {
        max = 0;
      }
      if (AppConfig.timerAccuracy === 0) {
        min = Math.floor(min / 10);
        max = Math.floor(max / 10);
      }
      sum -= min + max;
      avg = Math.floor(sum / (n - 2) + 0.5);
    } else {
      const maxArr: number[] = new Array<number>(trim).fill(0);
      const minArr: number[] = new Array<number>(trim).fill(0);
      let size: number = 0;
      for (let j: number = i - n + 1; j <= i; j++) {
        if (this.result.isDnf(j)) {
          nDnf++;
          if (nDnf > trim) {
            return -1;
          }
          if (size < trim) {
            Stats.addMinQueue(minArr, MAX_VALUE, size);
            Stats.addMaxQueue(maxArr, MAX_VALUE, size++);
          } else if (maxArr[0] < MAX_VALUE) {
            Stats.pollMax(maxArr, trim);
            Stats.addMaxQueue(maxArr, MAX_VALUE, trim - 1);
          }
        } else {
          let time: number = this.result.getTime(j);
          if (AppConfig.timerAccuracy === 0) {
            time = Math.floor(time / 10);
          }
          sum += time;
          if (size < trim) {
            Stats.addMinQueue(minArr, time, size);
            Stats.addMaxQueue(maxArr, time, size++);
          } else {
            if (time < minArr[0]) {
              Stats.pollMin(minArr, trim);
              Stats.addMinQueue(minArr, time, trim - 1);
            }
            if (time > maxArr[0]) {
              Stats.pollMax(maxArr, trim);
              Stats.addMaxQueue(maxArr, time, trim - 1);
            }
          }
        }
      }
      for (let j: number = 0; j < trim; j++) {
        sum -= minArr[j];
        if (maxArr[j] !== MAX_VALUE) {
          sum -= maxArr[j];
        }
      }
      avg = Math.floor(sum / (n - 2 * trim) + 0.5);
    }
    if (AppConfig.timerAccuracy === 0) {
      avg *= 10;
    }
    if (midx >= 0 && avg < this.bestAvg[midx]) {
      this.bestAvgRecord[midx][i] = true;
    }
    if (midx >= 0 && avg <= this.bestAvg[midx]) {
      this.bestAvg[midx] = avg;
      this.bestAvgIdx[midx] = i;
    }
    return avg;
  }

  sessionMean(): string {
    let sum: number = 0;
    let sum2: number = 0;
    this.maxIdx = this.minIdx = this.mean = -1;
    this.solved = this.result.getLength();
    if (this.solved === 0) {
      return '(0/0): N/A (N/A)';
    }
    if (this.bestTimeRecord.length <= this.result.getLength()) {
      this.bestTimeRecord = new Array<boolean>(Math.floor(this.result.getLength() * 3 / 2)).fill(false);
    } else {
      this.bestTimeRecord.fill(false, 0, this.result.getLength());
    }
    let bestTime: number = MAX_VALUE;
    for (let i: number = 0; i < this.result.getLength(); i++) {
      if (this.result.isDnf(i)) {
        this.solved--;
      } else {
        let time: number = this.result.getTime(i);
        if (time < bestTime) {
          bestTime = time;
          this.bestTimeRecord[i] = true;
        }
        if (this.maxIdx === -1) {
          this.maxIdx = i;
        } else if (time > this.result.getTime(this.maxIdx)) {
          this.maxIdx = i;
        }
        if (this.minIdx === -1) {
          this.minIdx = i;
        } else if (time <= this.result.getTime(this.minIdx)) {
          this.minIdx = i;
        }
        if (AppConfig.timerAccuracy === 0) {
          time = Math.floor(time / 10);
        }
        sum += time;
        sum2 += time * time;
      }
    }
    if (this.solved === 0) {
      return '(0/' + this.result.getLength() + '): N/A (N/A)';
    }
    this.mean = Math.floor(sum / this.solved + 0.5);
    if (AppConfig.timerAccuracy === 0) {
      this.mean *= 10;
    }
    this.sd = Math.floor(Math.sqrt((sum2 - sum * sum / this.solved) / this.solved) + 0.5);
    return '(' + this.solved + '/' + this.result.getLength() + '): ' +
      StringUtils.timeToString(this.mean) + ' (' + this.getSD(this.sd) + ')';
  }

  sessionAvg(): string {
    let n: number = this.result.getLength();
    if (n < 3) {
      return 'N/A';
    }
    const data: number[] = new Array<number>(n).fill(0);
    let count: number = 0;
    const trim: number = Math.ceil(n / 20.0);
    for (let i: number = 0; i < this.result.getLength(); i++) {
      if (this.result.isDnf(i)) {
        n--;
        if (n < this.result.getLength() - trim) {
          return 'DNF';
        }
      } else {
        data[count++] = this.result.getTime(i);
      }
    }
    let sum: number = 0;
    let sum2: number = 0;
    data.length = count;
    data.sort((a: number, b: number): number => a - b);
    for (let j: number = trim; j < this.result.getLength() - trim; j++) {
      let t: number = data[j];
      if (AppConfig.timerAccuracy === 0) {
        t = Math.floor(t / 10);
      }
      sum += t;
      sum2 += t * t;
    }
    const num: number = this.result.getLength() - 2 * trim;
    let savg: number = Math.floor(sum / num + 0.5);
    if (AppConfig.timerAccuracy === 0) {
      savg *= 10;
    }
    const ssd: number = Math.floor(Math.sqrt((sum2 - sum * sum / num) / num) + 0.5);
    return StringUtils.timeToString(savg) + ' (\u03c3 = ' + this.getSD(ssd) + ')';
  }

  getAvgDetail(nSolves: number, idx: number, ary: number[]): string[] {
    let avg: number = 0;
    let sd: number = -1;
    const trim: number = Math.ceil(nSolves / 20.0);
    let max: number = 0;
    let min: number = 0;
    const dnfIdx: number[] = [];
    for (let j: number = idx - nSolves + 1; j <= idx; j++) {
      if (this.result.isDnf(j)) {
        dnfIdx.push(j);
      }
    }
    const dnf: number = dnfIdx.length;
    const data: number[] = [];
    for (let j: number = idx - nSolves + 1; j <= idx; j++) {
      if (!this.result.isDnf(j)) {
        data.push(j);
      }
    }
    data.sort((a: number, b: number): number => {
      const ta: number = this.result.getTime(a);
      const tb: number = this.result.getTime(b);
      if (ta !== tb) {
        return ta - tb;
      }
      return a - b;
    });
    const len: number = data.length;
    if (nSolves - dnf >= trim) {
      for (let j: number = 0; j < trim; j++) {
        ary.push(data[j]);
      }
    } else {
      for (let j: number = 0; j < len; j++) {
        ary.push(data[j]);
      }
      for (let j: number = 0; j < trim - nSolves + dnf; j++) {
        ary.push(dnfIdx[j]);
      }
    }
    const m: boolean = dnf > trim;
    min = ary[0];
    if (m) {
      for (let j: number = dnf - trim; j < dnf; j++) {
        ary.push(dnfIdx[j]);
      }
    } else {
      for (let j: number = nSolves - trim; j < nSolves - dnf; j++) {
        ary.push(data[j]);
      }
      for (let j: number = 0; j < dnf; j++) {
        ary.push(dnfIdx[j]);
      }
      let sum: number = 0;
      let sum2: number = 0;
      for (let j: number = trim; j < nSolves - trim; j++) {
        let time: number = this.result.getTime(data[j]);
        if (AppConfig.timerAccuracy === 0) {
          time = Math.floor(time / 10);
        }
        sum += time;
        sum2 += time * time;
      }
      const num: number = nSolves - trim * 2;
      avg = Math.floor(sum / num + 0.5);
      sd = Math.floor(Math.sqrt((sum2 - sum * sum / num) / num) + 0.5);
      if (AppConfig.timerAccuracy === 0) {
        avg *= 10;
      }
    }
    max = ary[ary.length - 1];
    return [m ? 'DNF' : StringUtils.timeToString(avg), this.getSD(sd),
      this.result.getTimeAt(min, false), this.result.getTimeAt(max, false)];
  }

  getMeanDetail(n: number, i: number): string[] {
    let max: number = 0;
    let min: number = 0;
    let dnf: number = 0;
    let cavg: number = 0;
    let csdv: number = -1;
    let sum: number = 0;
    let sum2: number = 0;
    max = min = i - n + 1;
    let m: boolean = false;
    for (let j: number = i - n + 1; j <= i; j++) {
      if (!this.result.isDnf(j) && !m) {
        min = j;
        m = true;
      }
      if (this.result.isDnf(j)) {
        max = j;
        dnf++;
      }
    }
    m = dnf > 0;
    if (!m) {
      for (let j: number = i - n + 1; j <= i; j++) {
        let time: number = this.result.getTime(j);
        if (time > this.result.getTime(max)) {
          max = j;
        }
        if (time <= this.result.getTime(min)) {
          min = j;
        }
        if (AppConfig.timerAccuracy === 0) {
          time = Math.floor(time / 10);
        }
        sum += time;
        sum2 += time * time;
      }
      cavg = Math.floor(sum / n + 0.5);
      csdv = Math.floor(Math.sqrt((sum2 - sum * sum / n) / n) + 0.5);
    }
    if (AppConfig.timerAccuracy === 0) {
      cavg *= 10;
    }
    return [m ? 'DNF' : StringUtils.timeToString(cavg), this.getSD(csdv),
      this.result.getTimeAt(min, false), this.result.getTimeAt(max, false)];
  }

  calcMpMean(): void {
    for (let i: number = 0; i <= AppConfig.multiPhase; i++) {
      if (this.result.getLength() === 0) {
        this.mpMean[i] = 0;
      } else {
        this.mpMean[i] = this.mpMeanCalc(i);
      }
    }
  }

  private mpMeanCalc(p: number): number {
    let sum: number = 0; // Java long -> 整数除法
    let n: number = 0;
    let max: number = 0;
    let min: number = MAX_VALUE;
    this.mpMin[p] = this.mpMax[p] = -1;
    if (n === this.result.getLength()) {
      return 0;
    }
    for (let i: number = 0; i < this.result.getLength(); i++) {
      let time: number = this.result.getMulTime(p, i);
      if (time !== 0) {
        if (AppConfig.timerAccuracy === 0) {
          time = Math.floor(time / 10);
        }
        if (time > max) {
          max = time;
          this.mpMax[p] = i;
        }
        if (time <= min) {
          min = time;
          this.mpMin[p] = i;
        }
        sum += time;
        n++;
      }
    }
    if (n === 0) {
      return 0;
    }
    let m: number = Math.trunc(sum / n);
    if (AppConfig.timerAccuracy === 0) {
      m *= 10;
    }
    return m;
  }

  getSD(i: number): string {
    if (i < 0) {
      return 'N/A';
    }
    if (AppConfig.timerAccuracy === 1) {
      i = Math.trunc((i + 5) / 10);
    }
    return (i / 100).toFixed(2);
  }

  sortResult(): void {
    const len: number = this.result.getLength();
    if (this.sortIdx.length <= len) {
      this.sortIdx = new Array<number>(Math.floor(len * 3 / 2)).fill(0);
    }
    for (let i: number = 0; i < len; i++) {
      this.sortIdx[i] = i;
    }
    if (AppConfig.sortType === SORT_LATEST_FIRST) {
      for (let i: number = 0; i < len; i++) {
        this.sortIdx[i] = len - 1 - i;
      }
      return;
    }
    if (AppConfig.sortType < 0) {
      this.sortPbRecords(-AppConfig.sortType - 1, len);
      return;
    }
    const type: number = Math.trunc((AppConfig.sortType - 1) / 2);
    if (type === 0) {
      this.quickSort(this.result.getResult(), true, 0, len - 1);
    } else if (type === 1) {
      this.quickSort(this.avg1, false, 0, len - 1);
    } else if (type === 2) {
      this.quickSort(this.avg2, false, 0, len - 1);
    }
    if (AppConfig.sortType % 2 === 0) {
      const s: number[] = new Array<number>(this.sortIdx.length).fill(0);
      for (let i: number = 0; i < len; i++) {
        s[len - 1 - i] = this.sortIdx[i];
      }
      this.sortIdx = s;
    }
  }

  private sortPbRecords(type: number, len: number): void {
    const idx: number[] = new Array<number>(len).fill(0);
    for (let i: number = 0; i < len; i++) {
      idx[i] = i;
    }
    const that: Stats = this;
    idx.sort((left: number, right: number): number => {
      const leftPb: boolean = that.isPbRecord(type, left);
      const rightPb: boolean = that.isPbRecord(type, right);
      if (leftPb !== rightPb) {
        return leftPb ? -1 : 1;
      }
      if (leftPb) {
        const diff: number = that.getSortValue(type, left) - that.getSortValue(type, right);
        if (diff !== 0) {
          return diff;
        }
      }
      return left - right;
    });
    for (let i: number = 0; i < len; i++) {
      this.sortIdx[i] = idx[i];
    }
  }

  private isPbRecord(type: number, idx: number): boolean {
    if (type === 0) {
      return idx < this.bestTimeRecord.length && this.bestTimeRecord[idx];
    }
    const avgType: number = type - 1;
    return avgType >= 0 && avgType < this.bestAvgRecord.length &&
      idx < this.bestAvgRecord[avgType].length && this.bestAvgRecord[avgType][idx];
  }

  private getSortValue(type: number, idx: number): number {
    if (type === 0) {
      return this.result.getTime(idx);
    }
    if (type === 1) {
      return this.avg1[idx];
    }
    return this.avg2[idx];
  }

  private quickSort(arr: number[], penalty: boolean, low: number, high: number): void {
    let start: number = low;
    let end: number = high;
    const key: number = this.getData(arr, this.sortIdx[low], penalty);
    while (end > start) {
      while (end > start && this.getData(arr, this.sortIdx[end], penalty) >= key) {
        end--;
      }
      if (this.getData(arr, this.sortIdx[end], penalty) <= key) {
        const temp: number = this.sortIdx[end];
        this.sortIdx[end] = this.sortIdx[start];
        this.sortIdx[start] = temp;
      }
      while (end > start && this.getData(arr, this.sortIdx[start], penalty) <= key) {
        start++;
      }
      if (this.getData(arr, this.sortIdx[start], penalty) >= key) {
        const temp: number = this.sortIdx[start];
        this.sortIdx[start] = this.sortIdx[end];
        this.sortIdx[end] = temp;
      }
    }
    if (start > low) {
      this.quickSort(arr, penalty, low, start - 1);
    }
    if (end < high) {
      this.quickSort(arr, penalty, end + 1, high);
    }
  }

  private getData(arr: number[], pos: number, penalty: boolean): number {
    if (!penalty) {
      if (arr[pos] === -1) {
        return MAX_VALUE;
      }
      return arr[pos];
    }
    if (this.result.isDnf(pos)) {
      return MAX_VALUE;
    }
    return arr[pos] + (this.result.getPenalty(pos) === 1 ? 2000 : 0);
  }

  // ===== 优先队列（移植自 com.dctimer.util.Utils.java）=====
  private static addMaxQueue(data: number[], x: number, size: number): void {
    if (size === 0) {
      data[0] = x;
    } else {
      let k: number = size;
      while (k > 0) {
        const parent: number = (k - 1) >>> 1;
        const e: number = data[parent];
        if (x >= e) {
          break;
        }
        data[k] = e;
        k = parent;
      }
      data[k] = x;
    }
  }

  private static pollMax(data: number[], size: number): void {
    let s: number = --size;
    const x: number = data[s];
    const half: number = s >>> 1;
    let k: number = 0;
    while (half > k) {
      let child: number = (k << 1) + 1;
      let c: number = data[child];
      const right: number = child + 1;
      if (right < s && c > data[right]) {
        c = data[child = right];
      }
      if (x <= c) {
        break;
      }
      data[k] = c;
      k = child;
    }
    data[k] = x;
  }

  private static addMinQueue(data: number[], x: number, size: number): void {
    if (size === 0) {
      data[0] = x;
    } else {
      let k: number = size;
      while (k > 0) {
        const parent: number = (k - 1) >>> 1;
        const e: number = data[parent];
        if (x <= e) {
          break;
        }
        data[k] = e;
        k = parent;
      }
      data[k] = x;
    }
  }

  private static pollMin(data: number[], size: number): void {
    let s: number = --size;
    const x: number = data[s];
    const half: number = s >>> 1;
    let k: number = 0;
    while (half > k) {
      let child: number = (k << 1) + 1;
      let c: number = data[child];
      const right: number = child + 1;
      if (right < s && c < data[right]) {
        c = data[child = right];
      }
      if (x >= c) {
        break;
      }
      data[k] = c;
      k = child;
    }
    data[k] = x;
  }
}
