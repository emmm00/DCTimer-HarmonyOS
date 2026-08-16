/**
 * LcdText - 7段数码管风格文本（还原 DCTimer 计时器字体效果）
 * 仅支持字符 0-9、'.'、':'，其余内容请由调用方降级为普通 Text。
 *
 * 实现要点：
 * 1. Canvas 填满父容器 (width('100%').height('100%'))
 * 2. 通过 onAreaChange 获取布局尺寸(vp)，并正确处理 Length 联合类型
 * 3. 直接用 vp 值绘制（不转 px）——ArkUI Canvas 内部缓冲区与布局 vp 尺寸一致
 * 4. onReady 中立即画一次作为兜底
 */
@Component
export struct LcdText {
  @Prop @Watch('onChanged') text: string = '0.00';
  @Prop @Watch('onChanged') color: string = '#000000';

  /** 能否用数码管绘制（含其它字符时返回 false，调用方应降级普通文本） */
  static canRender(text: string): boolean {
    for (let i: number = 0; i < text.length; i++) {
      const c: string = text.charAt(i);
      const ok: boolean = (c >= '0' && c <= '9') || c === '.' || c === ':';
      if (!ok) {
        return false;
      }
    }
    return text.length > 0;
  }

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private ready: boolean = false;
  private areaW: number = 0; // vp 布局宽度
  private areaH: number = 0; // vp 布局高度

  // 段定义: a,b,c,d,e,f,g
  private static readonly SEGMENTS: boolean[][] = [
    [true,  true,  true,  true,  true,  true,  false], // 0
    [false, true,  true,  false, false, false, false], // 1
    [true,  true,  false, true,  true,  false, true ], // 2
    [true,  true,  true,  true,  false, false, true ], // 3
    [false, true,  true,  false, false, true,  true ], // 4
    [true,  false, true,  true,  false, true,  true ], // 5
    [true,  false, true,  true,  true,  true,  true ], // 6
    [true,  true,  true,  false, false, false, false], // 7
    [true,  true,  true,  true,  true,  true,  true ], // 8
    [true,  true,  true,  true,  false, true,  true ]  // 9
  ];

  onChanged(): void {
    if (this.ready && this.areaW > 0 && this.areaH > 0) {
      this.draw();
    }
  }

  /** 将 ArkUI 的 Length 联合类型 (number|string|Resource) 安全转为 vp 数字 */
  private parseLen(v: number | string | Resource): number {
    if (typeof v === 'number') {
      return v;
    }
    if (typeof v === 'string') {
      const s: string = v;
      // 去掉可能的单位后缀 "vp"/"px"/"fp"
      const n: number = parseFloat(s);
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
    if (!LcdText.canRender(this.text)) {
      return;
    }

    // 直接用 vp 绘制——ArkUI Canvas 内部坐标系与 .width/.height(vp) 一致
    const h: number = H * 0.88;    // 数字高度
    const w: number = h * 0.6;     // 数字宽度
    const t: number = h * 0.13;    // 段粗细
    const gap: number = w * 0.25;  // 字符间距
    const dotW: number = t * 1.2;  // 小数点/冒号宽度
    const y0: number = (H - h) / 2;

    let totalW: number = 0;
    for (let i: number = 0; i < this.text.length; i++) {
      const c: string = this.text.charAt(i);
      totalW += (c === '.' || c === ':') ? dotW + gap : w + gap;
    }
    totalW -= gap;

    let x: number = (W - totalW) / 2;
    ctx.fillStyle = this.color;

    for (let i: number = 0; i < this.text.length; i++) {
      const c: string = this.text.charAt(i);
      if (c === '.') {
        ctx.beginPath();
        ctx.arc(x + dotW / 2, y0 + h - dotW / 2, dotW / 2, 0, Math.PI * 2);
        ctx.fill();
        x += dotW + gap;
      } else if (c === ':') {
        const cx: number = x + dotW / 2;
        ctx.beginPath();
        ctx.arc(cx, y0 + h * 0.3, dotW / 2, 0, Math.PI * 2);
        ctx.fill();
        ctx.beginPath();
        ctx.arc(cx, y0 + h * 0.7, dotW / 2, 0, Math.PI * 2);
        ctx.fill();
        x += dotW + gap;
      } else {
        const digit: number = c.charCodeAt(0) - 48;
        const seg: boolean[] = LcdText.SEGMENTS[digit];
        if (seg[0]) { this.hSeg(x, y0, w, t); }
        if (seg[1]) { this.vSeg(x + w - t, y0, h / 2, t); }
        if (seg[2]) { this.vSeg(x + w - t, y0 + h / 2, h / 2, t); }
        if (seg[3]) { this.hSeg(x, y0 + h - t, w, t); }
        if (seg[4]) { this.vSeg(x, y0 + h / 2, h / 2, t); }
        if (seg[5]) { this.vSeg(x, y0, h / 2, t); }
        if (seg[6]) { this.hSeg(x, y0 + h / 2 - t / 2, w, t); }
        x += w + gap;
      }
    }
  }

  private hSeg(x: number, y: number, w: number, t: number): void {
    const ctx: CanvasRenderingContext2D = this.context;
    const half: number = t / 2;
    ctx.beginPath();
    ctx.moveTo(x + half, y);
    ctx.lineTo(x + w - half, y);
    ctx.lineTo(x + w, y + half);
    ctx.lineTo(x + w - half, y + t);
    ctx.lineTo(x + half, y + t);
    ctx.lineTo(x, y + half);
    ctx.closePath();
    ctx.fill();
  }

  private vSeg(x: number, y: number, len: number, t: number): void {
    const ctx: CanvasRenderingContext2D = this.context;
    const half: number = t / 2;
    ctx.beginPath();
    ctx.moveTo(x + half, y);
    ctx.lineTo(x + t, y + half);
    ctx.lineTo(x + t, y + len - half);
    ctx.lineTo(x + half, y + len);
    ctx.lineTo(x, y + len - half);
    ctx.lineTo(x, y + half);
    ctx.closePath();
    ctx.fill();
  }

  build() {
    Canvas(this.context)
      .width('100%')
      .height('100%')
      .onReady((): void => {
        this.ready = true;
        // 兜底：如果 onAreaChange 没触发，用默认尺寸
        if (this.areaW <= 0 || this.areaH <= 0) {
          this.areaW = 360;
          this.areaH = 100;
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