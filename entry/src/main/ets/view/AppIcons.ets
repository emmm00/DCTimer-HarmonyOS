/**
 * AppIcons — 自绘矢量图标（Canvas，圆帽描边风格）
 * 用于替换界面中的 emoji 占位图标，颜色通过 color 传入以适配深色模式。
 *
 * 逻辑坐标统一为 64x64 空间，绘制时按 size/64 缩放。
 */
@Component
export struct AppIcon {
  @Prop @Watch('onRedraw') iconId: string = 'cube';
  @Prop @Watch('onRedraw') color: string = '#000000';
  @Prop @Watch('onRedraw') iconSize: number = 24;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  private onRedraw(): void {
    this.draw();
  }

  build() {
    Canvas(this.ctx)
      .width(this.iconSize)
      .height(this.iconSize)
      .onReady((): void => {
        this.draw();
      });
  }

  private draw(): void {
    const ctx: CanvasRenderingContext2D = this.ctx;
    const s: number = this.iconSize / 64;
    ctx.clearRect(0, 0, this.iconSize, this.iconSize);
    ctx.save();
    ctx.scale(s, s);
    ctx.strokeStyle = this.color;
    ctx.fillStyle = this.color;
    ctx.lineWidth = 5.5;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.beginPath();
    if (this.iconId === 'cube') {
      this.buildCube(ctx);
    } else if (this.iconId === 'link') {
      this.buildLink(ctx);
    } else if (this.iconId === 'ble') {
      this.buildBle(ctx);
    } else if (this.iconId === 'wrench') {
      this.buildWrench(ctx);
    } else if (this.iconId === 'chart') {
      this.buildChart(ctx);
    } else if (this.iconId === 'note') {
      this.buildNote(ctx);
    } else if (this.iconId === 'stopwatch') {
      this.buildStopwatch(ctx);
    } else if (this.iconId === 'list') {
      this.buildList(ctx);
    } else if (this.iconId === 'gear') {
      this.buildGear(ctx);
    } else if (this.iconId === 'train') {
      this.buildTrain(ctx);
    }
    ctx.stroke();
    ctx.restore();
  }

  // 秒表（计时器页）：表盘 + 顶部表冠 + 斜向指针 + 右上侧钮
  private buildStopwatch(ctx: CanvasRenderingContext2D): void {
    ctx.arc(32, 38, 20, 0, Math.PI * 2);
    ctx.moveTo(32, 18);
    ctx.lineTo(32, 9);
    ctx.moveTo(26, 9);
    ctx.lineTo(38, 9);
    ctx.moveTo(32, 38);
    ctx.lineTo(43, 27);
    ctx.moveTo(54, 24);
    ctx.lineTo(58, 20);
  }

  // 列表（成绩页）：三个圆点 + 三条横线
  private buildList(ctx: CanvasRenderingContext2D): void {
    ctx.moveTo(24, 16);
    ctx.lineTo(52, 16);
    ctx.moveTo(24, 32);
    ctx.lineTo(52, 32);
    ctx.moveTo(24, 48);
    ctx.lineTo(52, 48);
    ctx.moveTo(17, 16);
    ctx.arc(14, 16, 3, 0, Math.PI * 2);
    ctx.moveTo(17, 32);
    ctx.arc(14, 32, 3, 0, Math.PI * 2);
    ctx.moveTo(17, 48);
    ctx.arc(14, 48, 3, 0, Math.PI * 2);
  }

  // 齿轮（设置页）：外圈 + 8 齿 + 中孔
  private buildGear(ctx: CanvasRenderingContext2D): void {
    ctx.arc(32, 32, 19, 0, Math.PI * 2);
    ctx.moveTo(40, 32);
    ctx.arc(32, 32, 8, 0, Math.PI * 2);
    const rad: number = Math.PI / 180;
    for (let k: number = 0; k < 8; k++) {
      const a: number = k * 45 * rad;
      const c: number = Math.cos(a);
      const sn: number = Math.sin(a);
      ctx.moveTo(32 + c * 21, 32 + sn * 21);
      ctx.lineTo(32 + c * 28, 32 + sn * 28);
    }
  }

  // 训练（训练页）：靶心 —— 外环 + 中心点
  // 注意：不要用多个同心细环。图标在 24vp 下渲染时线宽只有约 2px，
  // 半径 18/14/10/6 的四个环间距仅 1.5px，会糊成一个实心黑点（已踩过）。
  private buildTrain(ctx: CanvasRenderingContext2D): void {
    ctx.arc(32, 32, 19, 0, Math.PI * 2);
    ctx.moveTo(35.5, 32);
    ctx.arc(32, 32, 3.5, 0, Math.PI * 2);
  }

  // 三阶魔方：俯视菱形 + 前/右两面，均含 3x3 分格线
  private buildCube(ctx: CanvasRenderingContext2D): void {
    ctx.moveTo(32, 6);
    ctx.lineTo(56, 18);
    ctx.lineTo(32, 30);
    ctx.lineTo(8, 18);
    ctx.lineTo(32, 6);
    ctx.moveTo(32, 18);
    ctx.lineTo(44, 12);
    ctx.moveTo(32, 18);
    ctx.lineTo(44, 24);
    ctx.moveTo(32, 18);
    ctx.lineTo(20, 24);
    ctx.moveTo(32, 18);
    ctx.lineTo(20, 12);
    ctx.moveTo(8, 18);
    ctx.lineTo(8, 42);
    ctx.lineTo(32, 54);
    ctx.lineTo(32, 30);
    ctx.moveTo(8, 26);
    ctx.lineTo(32, 38);
    ctx.moveTo(8, 34);
    ctx.lineTo(32, 46);
    ctx.moveTo(56, 18);
    ctx.lineTo(56, 42);
    ctx.lineTo(32, 54);
    ctx.moveTo(32, 38);
    ctx.lineTo(56, 26);
    ctx.moveTo(32, 46);
    ctx.lineTo(56, 34);
  }

  // 链接：两圆环 + 上下横杠
  private buildLink(ctx: CanvasRenderingContext2D): void {
    ctx.arc(19, 26, 10, 0, Math.PI * 2);
    ctx.arc(45, 26, 10, 0, Math.PI * 2);
    ctx.moveTo(29, 17);
    ctx.lineTo(35, 17);
    ctx.moveTo(29, 35);
    ctx.lineTo(35, 35);
  }

  // 信号/连接：底部圆点 + 向上展开的三段弧
  private buildBle(ctx: CanvasRenderingContext2D): void {
    ctx.arc(32, 52, 25, Math.PI, Math.PI * 2);
    ctx.arc(32, 52, 16, Math.PI, Math.PI * 2);
    ctx.arc(32, 52, 7, Math.PI, Math.PI * 2);
    ctx.arc(32, 52, 3, 0, Math.PI * 2);
  }

  // 扳手：开口圆帽 + 竖直手柄
  private buildWrench(ctx: CanvasRenderingContext2D): void {
    const deg: number = Math.PI / 180;
    ctx.arc(32, 16, 13, 120 * deg, 420 * deg, false);
    ctx.arc(32, 16, 5, 120 * deg, 420 * deg, false);
    ctx.moveTo(32, 29);
    ctx.lineTo(32, 56);
  }

  // 走势图：基线 + 上升折线
  private buildChart(ctx: CanvasRenderingContext2D): void {
    ctx.moveTo(10, 50);
    ctx.lineTo(54, 50);
    ctx.moveTo(12, 46);
    ctx.lineTo(24, 36);
    ctx.lineTo(34, 40);
    ctx.lineTo(50, 16);
  }

  // 备注/文档：折角页 + 三条横线
  private buildNote(ctx: CanvasRenderingContext2D): void {
    ctx.moveTo(18, 10);
    ctx.lineTo(44, 10);
    ctx.lineTo(54, 20);
    ctx.lineTo(54, 56);
    ctx.lineTo(18, 56);
    ctx.lineTo(18, 10);
    ctx.moveTo(44, 10);
    ctx.lineTo(44, 20);
    ctx.lineTo(54, 20);
    ctx.moveTo(24, 28);
    ctx.lineTo(48, 28);
    ctx.moveTo(24, 38);
    ctx.lineTo(48, 38);
    ctx.moveTo(24, 48);
    ctx.lineTo(40, 48);
  }
}