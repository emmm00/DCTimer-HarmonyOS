import { Scrambler as DctScrambler } from '../scrambler/Scrambler';
import { PaintState } from '../scrambler/Scrambler';
import { ScrambleCanvasAdapter } from './ScrambleCanvasAdapter';

// puzzleCode -> DCTimer category (same mapping as pages/Index.ets toDctimerCategory)
function toDctimerCategory(code: number): number {
  switch (code) {
    case 33: return -32; // 三阶速拧
    case 22: return -29; // 二阶速拧
    case 44: return -31; // 四阶速拧
    case 55: return -30; // 五阶速拧
    case 66: return -19; // 六阶速拧
    case 77: return -18; // 七阶速拧
    case 31: return -27; // 单拧
    case 32: return -28; // 盲拧
    case 42: return -17; // 四阶盲拧
    case 52: return -16; // 五阶盲拧
    case 34: return -15; // 三阶多盲
    case 35: return -26; // 最少步
    case 70: return -23; // Pyraminx
    case 50: return -24; // Megaminx
    case 40: return -22; // Square-1
    case 80: return -21; // Clock
    case 16: return -20; // Skewb
    case 82: return 517; // FTO
    default:
      if (code >= 900) return code - 900;
      return code >= 100 ? code : -32;
  }
}

@Component
export struct ScrambleImageView {
  @Prop @Watch('onChanged') scramble: string = '';
  @Prop @Watch('onChanged') puzzleSize: number = 3;
  @Prop @Watch('onChanged') puzzleCode: number = 33;
  // 配色变更版本号：配色是 Scrambler 静态表，scramble/puzzleCode 不变时
  // 靠 bump 此值触发重绘（Index.onSchemeConfirm）
  @Prop @Watch('onChanged') schemeVersion: number = 0;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private ready: boolean = false;
  private areaW: number = 0;
  private areaH: number = 0;
  private scrambler: DctScrambler = new DctScrambler();

  onChanged(): void {
    if (this.ready && this.areaW > 0 && this.areaH > 0) {
      this.draw();
    }
  }

  private parseLen(v: number | string | Resource): number {
    if (typeof v === 'number') {
      return v;
    }
    if (typeof v === 'string') {
      const n: number = parseFloat(v);
      return isNaN(n) ? 0 : n;
    }
    return 0;
  }

  draw(): void {
    if (this.areaW <= 0 || this.areaH <= 0) {
      return;
    }
    const W: number = this.areaW;
    const H: number = this.areaH;
    const ctx: CanvasRenderingContext2D = this.context;
    ctx.clearRect(0, 0, W, H);

    if (this.scramble.length == 0) {
      return;
    }
    this.scrambler.parseScramble(toDctimerCategory(this.puzzleCode), this.scramble);
    const adapter: ScrambleCanvasAdapter = new ScrambleCanvasAdapter(ctx);
    const p: PaintState = new PaintState();
    // 大屏适配：打乱图按宽等比绘制，高度约为宽度的 fitRatio 倍。当画布高度不足
    // （大屏宽度巨大时高度 220 固定，比例绘制会超高被底部裁切）时，收缩绘制宽
    // 度让其完整落入画布，并横向居中。
    const fitRatio: number = 0.85; // 覆盖 NxN(≈0.75)、金字塔 等常见类型的高宽比上界
    let dw: number = Math.floor(W);
    if (H < Math.floor(dw * fitRatio)) {
      dw = Math.max(1, Math.floor(H / fitRatio));
    }
    ctx.save();
    if (dw < W) {
      ctx.translate(Math.floor((W - dw) / 2), 0);
    }
    this.scrambler.drawScramble(dw, p, adapter);
    ctx.restore();
  }

  build() {
    Canvas(this.context)
      .width('100%')
      .height('100%')
      .onReady((): void => {
        this.ready = true;
        if (this.areaW <= 0 || this.areaH <= 0) {
          this.areaW = 152;
          this.areaH = 114;
        }
        this.draw();
      })
      .onAreaChange((_oldValue: Area, newValue: Area): void => {
        this.areaW = this.parseLen(newValue.width);
        this.areaH = this.parseLen(newValue.height);
        if (this.ready) {
          this.draw();
        }
      });
  }
}
