import { ResultEntry } from '../model/Result';
import { AppConfig } from '../model/AppConfig';
import { StringUtils } from '../util/StringUtils';

const CHART_PADDING_LEFT: number = 44;
const CHART_PADDING_RIGHT: number = 16;
const CHART_PADDING_TOP: number = 16;
const CHART_PADDING_BOTTOM: number = 32;

/**
 * 成绩趋势折线图 - 使用 Canvas 绘制（毫秒单位）
 */
@Component
export struct StatsChartView {
  @Prop results: ResultEntry[] = [];
  @Prop darkMode: boolean = false;
  // 沉浸光感开启时，Canvas 不填底色，让页面级渐变透出来（否则整块白底和光感割裂）
  @Prop transparentBg: boolean = false;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private canvasW: number = 300;
  private canvasH: number = 200;

  build() {
    Canvas(this.ctx)
      .width('100%')
      .height('100%')
      .onReady((): void => { this.drawChart(); })
      .onAreaChange((oldArea: Area, newArea: Area): void => {
        let w: number = 0;
        let h: number = 0;
        if (typeof newArea.width === 'number') {
          w = newArea.width;
        }
        if (typeof newArea.height === 'number') {
          h = newArea.height;
        }
        if (w > 0 && h > 0) {
          this.canvasW = w;
          this.canvasH = h;
          this.drawChart();
        }
      });
  }

  /** 忠实移植 Stats.averageOf（n<=20 或全量小样本路径）的简化版，仅用于平均线 */
  private sessionAverage(): number {
    const times: number[] = [];
    const penalties: number[] = [];
    for (let i: number = 0; i < this.results.length; i++) {
      times.push(this.results[i].time);
      penalties.push(this.results[i].penalty);
    }
    const n: number = this.results.length;
    const i: number = n - 1;
    if (i < n - 1 || n <= 0) {
      return -2;
    }
    const trim: number = Math.ceil(n / 20);
    let dnf: number = 0;
    let sum: number = 0;
    let min: number = 2147483647;
    let max: number = -2147483648;
    for (let j: number = i - n + 1; j <= i; j++) {
      if (penalties[j] >= 2) {
        dnf++;
        continue;
      }
      let v: number = times[j] + (penalties[j] === 1 ? 2000 : 0);
      sum += v;
      if (v < min) {
        min = v;
      }
      if (v > max) {
        max = v;
      }
    }
    if (dnf > trim || n < 3) {
      return -1;
    }
    if (n <= 20) {
      if (dnf == 0) {
        sum -= min + max;
      }
    } else {
      sum -= min + max;
    }
    const divisor: number = n - dnf - 2;
    if (divisor <= 0) {
      return -1;
    }
    let avg: number = sum / divisor;
    if (AppConfig.timerAccuracy == 0) {
      avg = Math.floor(avg / 10 + 0.5) * 10;
    }
    return Math.floor(avg);
  }

  drawChart(): void {
    if (this.canvasW <= 0 || this.canvasH <= 0) {
      return;
    }

    const bgColor: string = this.darkMode ? '#1e1e1e' : '#ffffff';
    const textColor: string = this.darkMode ? '#9a9a9a' : '#666666';
    const lineColor: string = '#448AFF';
    const bestColor: string = '#00cc00';
    const worstColor: string = '#ff4444';
    const dnfColor: string = '#ff0000';
    const avgColor: string = '#ff6600';
    const gridColor: string = this.darkMode ? '#333333' : '#dddddd';

    const ctx: CanvasRenderingContext2D = this.ctx;
    const w: number = this.canvasW;
    const h: number = this.canvasH;

    // 清屏：光感模式下清成透明，露出页面渐变；否则填主题底色
    if (this.transparentBg) {
      ctx.clearRect(0, 0, w, h);
    } else {
      ctx.fillStyle = bgColor;
      ctx.fillRect(0, 0, w, h);
    }

    const validResults: number[] = [];
    const validIndices: number[] = [];
    for (let i: number = 0; i < this.results.length; i++) {
      const r: ResultEntry = this.results[i];
      const t: number = r.time;
      if (!r.isDnf()) {
        validResults.push(t + (r.penalty === 1 ? 2000 : 0));
        validIndices.push(i);
      }
    }

    if (validResults.length < 1) {
      ctx.fillStyle = textColor;
      ctx.font = '14px sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText('暂无有效成绩', w / 2, h / 2);
      return;
    }

    // 计算范围
    let minTime: number = validResults[0];
    let maxTime: number = validResults[0];
    for (let i: number = 1; i < validResults.length; i++) {
      if (validResults[i] < minTime) {
        minTime = validResults[i];
      }
      if (validResults[i] > maxTime) {
        maxTime = validResults[i];
      }
    }
    const range: number = maxTime - minTime;
    const paddedMin: number = minTime - range * 0.1;
    const paddedMax: number = maxTime + range * 0.1;
    const totalRange: number = paddedMax - paddedMin;

    const plotW: number = w - CHART_PADDING_LEFT - CHART_PADDING_RIGHT;
    const plotH: number = h - CHART_PADDING_TOP - CHART_PADDING_BOTTOM;
    const count: number = validResults.length;

    // Y轴标签
    ctx.fillStyle = textColor;
    ctx.font = '10px sans-serif';
    ctx.textAlign = 'right';
    const yLabels: number = 4;
    for (let i: number = 0; i <= yLabels; i++) {
      const val: number = paddedMin + (totalRange * i) / yLabels;
      const y: number = CHART_PADDING_TOP + plotH - (plotH * i) / yLabels;
      const secs: number = val / 1000;
      ctx.fillText(secs.toFixed(2), CHART_PADDING_LEFT - 4, y + 3);
      // 网格线
      ctx.strokeStyle = gridColor;
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(CHART_PADDING_LEFT, y);
      ctx.lineTo(w - CHART_PADDING_RIGHT, y);
      ctx.stroke();
    }

    // X轴
    ctx.strokeStyle = textColor;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(CHART_PADDING_LEFT, CHART_PADDING_TOP);
    ctx.lineTo(CHART_PADDING_LEFT, CHART_PADDING_TOP + plotH);
    ctx.lineTo(w - CHART_PADDING_RIGHT, CHART_PADDING_TOP + plotH);
    ctx.stroke();

    // 平均线
    if (this.results.length >= 3) {
      const avg: number = this.sessionAverage();
      if (avg > 0) {
        const avgY: number = CHART_PADDING_TOP + plotH - ((avg - paddedMin) / totalRange) * plotH;
        ctx.strokeStyle = avgColor;
        ctx.lineWidth = 1;
        ctx.setLineDash([4, 4]);
        ctx.beginPath();
        ctx.moveTo(CHART_PADDING_LEFT, avgY);
        ctx.lineTo(w - CHART_PADDING_RIGHT, avgY);
        ctx.stroke();
        ctx.setLineDash([]);
        ctx.fillStyle = avgColor;
        ctx.textAlign = 'left';
        ctx.fillText('ao' + this.results.length, w - CHART_PADDING_RIGHT + 4, avgY + 3);
      }
    }

    // 折线
    ctx.strokeStyle = lineColor;
    ctx.lineWidth = 2;
    ctx.lineJoin = 'round';
    ctx.beginPath();
    let firstPoint: boolean = true;
    const pointRadius: number = 3;

    for (let i: number = 0; i < count; i++) {
      const idx: number = validIndices[i];
      const t: number = validResults[i];
      const x: number = CHART_PADDING_LEFT + (plotW * i) / Math.max(count - 1, 1);
      const y: number = CHART_PADDING_TOP + plotH - ((t - paddedMin) / totalRange) * plotH;

      if (firstPoint) {
        ctx.moveTo(x, y);
        firstPoint = false;
      } else {
        ctx.lineTo(x, y);
      }
    }
    ctx.stroke();

    // 数据点
    for (let i: number = 0; i < count; i++) {
      const idx: number = validIndices[i];
      const t: number = validResults[i];
      const x: number = CHART_PADDING_LEFT + (plotW * i) / Math.max(count - 1, 1);
      const y: number = CHART_PADDING_TOP + plotH - ((t - paddedMin) / totalRange) * plotH;

      // 判断最佳/最差
      let dotColor: string = lineColor;
      if (validResults.length >= 3 && i >= validResults.length - AppConfig.avg1Len) {
        // 在 ao5/ao12 统计窗口中
        const windowStart: number = Math.max(0, validResults.length - AppConfig.avg1Len);
        if (t === minTime) {
          dotColor = bestColor;
        } else if (t === maxTime) {
          dotColor = worstColor;
        }
      }

      ctx.fillStyle = dotColor;
      ctx.beginPath();
      ctx.arc(x, y, pointRadius, 0, Math.PI * 2);
      ctx.fill();
    }

    // X轴标签
    ctx.fillStyle = textColor;
    ctx.font = '10px sans-serif';
    ctx.textAlign = 'center';
    const xStep: number = Math.max(1, Math.floor(count / 8));
    for (let i: number = 0; i < count; i += xStep) {
      const x: number = CHART_PADDING_LEFT + (plotW * i) / Math.max(count - 1, 1);
      const idx: number = validIndices[i];
      ctx.fillText((idx + 1).toString(), x, CHART_PADDING_TOP + plotH + 16);
    }
  }
}
