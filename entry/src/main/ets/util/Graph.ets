// 图表绘制工具 - 绘制成绩分布直方图和趋势图
import { StringUtils } from './StringUtils';

export class Graph {
  private static getDivision(dv: number): number {
    const ds = [100, 200, 500, 1000, 2000, 5000, 10000, 20000, 30000, 60000, 90000, 120000, 300000, 600000, 1200000, 1800000, 3600000];
    if (dv < ds[0]) return 100;
    for (let i = 1; i < ds.length; i++)
      if (dv < ds[i]) return ds[i];
    return Math.floor(dv / 1000 + 1) * 1000;
  }

  // 计算直方图数据
  static calcHistogramData(results: number[], dnfFlags: boolean[]): HistogramData {
    const len = results.length;
    if (len === 0 || dnfFlags.every(f => f)) {
      return { bins: new Array<number>(14).fill(0), start: 11000, end: 25000, divi: 1000, maxValue: 0 };
    }
    let maxTime = 0, minTime = Number.MAX_SAFE_INTEGER;
    for (let i = 0; i < len; i++) {
      if (!dnfFlags[i]) {
        const t = results[i];
        if (t > maxTime) maxTime = t;
        if (t < minTime) minTime = t;
      }
    }
    if (maxTime === minTime) maxTime = minTime + 4000;
    const divi = Graph.getDivision(Math.floor((maxTime - minTime) / 14));
    let mean = Math.floor((minTime + maxTime) / 2);
    mean = Math.floor((mean + divi / 2) / divi) * divi;
    const start = mean - divi * 7;
    const end = mean + divi * 7;
    const bins: number[] = new Array<number>(14).fill(0);
    for (let i = 0; i < len; i++) {
      if (!dnfFlags[i]) {
        const time = results[i];
        if (time >= start && time < end) {
          const bin = Math.floor(bins.length * (time - start) / (end - start));
          bins[bin]++;
        } else if (time === end) {
          bins[13]++;
        }
      }
    }
    const maxValue = Math.max(...bins);
    return { bins, start, end, divi, maxValue };
  }

  // 计算趋势图数据
  static calcGraphData(results: number[], dnfFlags: boolean[], avg1: number[], avg2: number[], avg1len: number, avg2len: number): GraphData {
    const len = results.length;
    if (len === 0) {
      return { up: 20000, down: 16000, mean: 16000, divi: 1000, points: [], avg1Points: [], avg2Points: [] };
    }
    let maxTime = 0, minTime = Number.MAX_SAFE_INTEGER;
    for (let i = 0; i < len; i++) {
      if (!dnfFlags[i]) {
        const t = results[i];
        if (t > maxTime) maxTime = t;
        if (t < minTime) minTime = t;
      }
    }
    if (maxTime === minTime) maxTime = minTime + 8000;
    const divi = Graph.getDivision(Math.floor((maxTime - minTime) / 8));
    let mean = Math.floor((minTime + maxTime) / 2);
    mean = Math.floor((mean + divi / 2) / divi) * divi;
    let up = mean, down = mean;
    while (up < maxTime) up += divi;
    while (down > minTime) down -= divi;
    const points: DataPoint[] = [];
    const avg1Points: DataPoint[] = [];
    const avg2Points: DataPoint[] = [];
    for (let i = 0; i < len; i++) {
      if (!dnfFlags[i]) points.push({ index: i, value: results[i] });
    }
    for (let i = avg1len - 1; i < len; i++) {
      if (avg1[i] > 0) avg1Points.push({ index: i, value: avg1[i] });
    }
    for (let i = avg2len - 1; i < len; i++) {
      if (avg2[i] > 0) avg2Points.push({ index: i, value: avg2[i] });
    }
    let sessionMean = 0;
    let count = 0;
    for (let i = 0; i < len; i++) {
      if (!dnfFlags[i]) { sessionMean += results[i]; count++; }
    }
    if (count > 0) sessionMean = Math.floor(sessionMean / count);
    return { up, down, mean: sessionMean, divi, points, avg1Points, avg2Points };
  }
}

export interface HistogramData {
  bins: number[];
  start: number;
  end: number;
  divi: number;
  maxValue: number;
}

export interface GraphData {
  up: number;
  down: number;
  mean: number;
  divi: number;
  points: DataPoint[];
  avg1Points: DataPoint[];
  avg2Points: DataPoint[];
}

export interface DataPoint {
  index: number;
  value: number;
}
