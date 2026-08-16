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
    // 金字塔按宽度等比绘制，高度约为宽度的 0.78 倍，画布高度不足时底部会被裁剪
    let dw: number = Math.floor(W);
    if (this.puzzleSize === -70 && H < Math.floor(dw * 0.78) + 6) {
      dw = Math.max(1, Math.floor((H - 6) / 0.78));
    }
    this.scrambler.drawScramble(dw, p, adapter);
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
