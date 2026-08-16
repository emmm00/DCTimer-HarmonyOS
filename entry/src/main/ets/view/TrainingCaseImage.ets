/**
 * 训练公式配图组件
 * 根据 setup 公式模拟魔方状态并绘制 OLL/PLL/F2L 示意图
 */

import { Cube3x3, FACE_COLORS } from '../util/Cube3x3';
import { TrainingCase } from '../model/TrainingData';

const STICKER_OUTLINE: string = '#333333';
const OLL_UP_COLOR: string = '#FFD700';
const OLL_OTHER_COLOR: string = '#F5F5F5';

@Component
export struct TrainingCaseImage {
  @Prop item: TrainingCase;
  @Prop imageSize: number = 120;
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));

  build() {
    Canvas(this.context)
      .width(this.imageSize)
      .height(this.imageSize)
      .backgroundColor('#e8e8e8')
      .borderRadius(8)
      .onReady((): void => {
        this.draw();
      });
  }

  private draw(): void {
    this.context.clearRect(0, 0, this.imageSize, this.imageSize);

    const cube: Cube3x3 = new Cube3x3();
    try {
      cube.applyAlgorithm(this.item.setup);
    } catch (e) {
      // 公式解析异常时保持还原状态
    }

    if (this.item.category === 'oll') {
      this.drawOllNet(this.context, cube);
    } else if (this.item.category === 'pll') {
      this.drawPllFace(this.context, cube);
    } else {
      this.drawF2L(this.context, cube);
    }
  }

  /** OLL：绘制 U 面 + 四周侧面顶层条（十字展开图），避免只看顶面无法区分 case */
  private drawOllNet(ctx: CanvasRenderingContext2D, cube: Cube3x3): void {
    const pad: number = this.imageSize * 0.04;
    const side: number = (this.imageSize - pad * 2) / 5; // 5x5 网格：边条1格 + 中心3格 + 边条1格
    const cornerRadius: number = side * 0.12;
    const left: number = pad + side; // U 面左上角
    const top: number = pad + side;

    const uFace: number[][] = cube.getFace(0);
    const fFace: number[][] = cube.getFace(4);
    const rFace: number[][] = cube.getFace(3);
    const bFace: number[][] = cube.getFace(5);
    const lFace: number[][] = cube.getFace(2);

    // 中心 U 面 3x3：OLL 关注的是哪些顶面贴纸最终朝上（黄色/D 面颜色），因此用黄色高亮 D 面颜色
    for (let r: number = 0; r < 3; r++) {
      for (let c: number = 0; c < 3; c++) {
        const colorIdx: number = uFace[r][c];
        const color: string = colorIdx === 1 ? OLL_UP_COLOR : OLL_OTHER_COLOR;
        this.drawSticker(ctx, left + c * side, top + r * side, side - 2, side - 2, cornerRadius, color);
      }
    }

    // 下方 F 面顶层（侧面黄色也要高亮，避免只看顶面无法区分 case）
    for (let c: number = 0; c < 3; c++) {
      const colorIdx: number = fFace[0][c];
      const color: string = colorIdx === 1 ? OLL_UP_COLOR : FACE_COLORS[colorIdx];
      this.drawSticker(ctx, left + c * side, top + 3 * side, side - 2, side - 2, cornerRadius, color);
    }

    // 上方 B 面顶层（从背面看，需要左右翻转）
    for (let c: number = 0; c < 3; c++) {
      const colorIdx: number = bFace[0][2 - c];
      const color: string = colorIdx === 1 ? OLL_UP_COLOR : FACE_COLORS[colorIdx];
      this.drawSticker(ctx, left + c * side, top - side, side - 2, side - 2, cornerRadius, color);
    }

    // 左方 L 面顶层
    for (let r: number = 0; r < 3; r++) {
      const colorIdx: number = lFace[0][r];
      const color: string = colorIdx === 1 ? OLL_UP_COLOR : FACE_COLORS[colorIdx];
      this.drawSticker(ctx, left - side, top + r * side, side - 2, side - 2, cornerRadius, color);
    }

    // 右方 R 面顶层
    for (let r: number = 0; r < 3; r++) {
      const colorIdx: number = rFace[0][r];
      const color: string = colorIdx === 1 ? OLL_UP_COLOR : FACE_COLORS[colorIdx];
      this.drawSticker(ctx, left + 3 * side, top + r * side, side - 2, side - 2, cornerRadius, color);
    }

    // 四个角落补一小块背景色，避免空白
    const corners: number[][] = [[0, 0], [4, 0], [0, 4], [4, 4]];
    for (const corner of corners) {
      const x: number = pad + corner[0] * side;
      const y: number = pad + corner[1] * side;
      ctx.fillStyle = '#e8e8e8';
      ctx.fillRect(x, y, side, side);
    }
  }

  /** PLL：顶面真实颜色 + 角块/棱块身份标记 + 块循环箭头 */
  private drawPllFace(ctx: CanvasRenderingContext2D, cube: Cube3x3): void {
    const pad: number = this.imageSize * 0.1;
    const board: number = this.imageSize - pad * 2;
    const stickerSize: number = board / 3;
    const cornerRadius: number = stickerSize * 0.15;
    const left: number = pad;
    const top: number = pad;

    const face: number[][] = cube.getFace(0);
    for (let r: number = 0; r < 3; r++) {
      for (let c: number = 0; c < 3; c++) {
        const colorIdx: number = face[r][c];
        this.drawSticker(ctx, left + c * stickerSize, top + r * stickerSize, stickerSize - 2, stickerSize - 2,
          cornerRadius, FACE_COLORS[colorIdx]);
      }
    }

    // 根据 case 名画 PLL 循环箭头
    this.drawPllArrows(ctx, left, top, stickerSize);
  }

  /** 根据 PLL 类型画循环箭头（带数字标记，与 CFOP 公式表风格一致） */
  private drawPllArrows(ctx: CanvasRenderingContext2D, left: number, top: number, sz: number): void {
    const name: string = this.item.name.toLowerCase();
    const cx: number = left + sz * 1.5;
    const cy: number = top + sz * 1.5;
    ctx.lineWidth = 2.5;
    ctx.strokeStyle = '#000000';
    ctx.fillStyle = '#000000';

    // 角块循环 / 棱块循环 用不同颜色区分，并带数字
    if (name.includes('t perm')) {
      this.drawCornerSwapArrow(ctx, cx, cy, sz, 'top-right', 'bottom-right', '#E53935');
      this.drawEdgeSwapArrow(ctx, cx, cy, sz, 'top', 'right', '#1E88E5');
    } else if (name.includes('y perm')) {
      this.drawCornerCycleArrow(ctx, cx, cy, sz, ['top-left', 'top-right', 'bottom-right'], '#E53935');
      this.drawEdgeSwapArrow(ctx, cx, cy, sz, 'top', 'right', '#1E88E5');
    } else if (name.includes('f perm')) {
      this.drawCornerCycleArrow(ctx, cx, cy, sz, ['top-left', 'top-right', 'bottom-right'], '#E53935');
      this.drawEdgeCycleArrow(ctx, cx, cy, sz, ['top', 'right', 'left'], '#1E88E5');
    } else if (name.includes('j')) {
      // Ja / Jb：两个角块交换 + 两个棱块交换
      this.drawCornerSwapArrow(ctx, cx, cy, sz, 'top-left', 'top-right', '#E53935');
      this.drawEdgeSwapArrow(ctx, cx, cy, sz, 'top', 'right', '#1E88E5');
    } else if (name.includes('r')) {
      // Ra / Rb
      this.drawCornerSwapArrow(ctx, cx, cy, sz, 'top-left', 'bottom-right', '#E53935');
      this.drawEdgeSwapArrow(ctx, cx, cy, sz, 'top', 'right', '#1E88E5');
    } else if (name.includes('v perm')) {
      this.drawCornerCycleArrow(ctx, cx, cy, sz, ['top-left', 'top-right', 'bottom-right'], '#E53935');
      this.drawEdgeSwapArrow(ctx, cx, cy, sz, 'top', 'right', '#1E88E5');
    } else if (name.includes('n')) {
      // Na / Nb：对角块交换 + 对棱块交换
      this.drawCornerSwapArrow(ctx, cx, cy, sz, 'top-left', 'bottom-right', '#E53935');
      this.drawEdgeSwapArrow(ctx, cx, cy, sz, 'top', 'bottom', '#1E88E5');
    } else if (name.includes('g')) {
      // G perms：四个角块循环
      this.drawCornerCycleArrow(ctx, cx, cy, sz, ['top-left', 'top-right', 'bottom-right', 'bottom-left'], '#E53935');
    } else if (name.includes('u')) {
      // Ua / Ub：三个棱块循环
      this.drawEdgeCycleArrow(ctx, cx, cy, sz, ['top', 'right', 'left'], '#1E88E5');
    } else if (name.includes('h perm')) {
      // H：两对棱块交换
      this.drawEdgeSwapArrow(ctx, cx, cy, sz, 'top', 'bottom', '#1E88E5');
      this.drawEdgeSwapArrow(ctx, cx, cy, sz, 'left', 'right', '#1E88E5');
    } else if (name.includes('z perm')) {
      // Z：四个棱块循环
      this.drawEdgeCycleArrow(ctx, cx, cy, sz, ['top', 'right', 'bottom', 'left'], '#1E88E5');
    } else if (name.includes('e perm')) {
      // E：四个角块对角循环
      this.drawCornerCycleArrow(ctx, cx, cy, sz, ['top-left', 'top-right', 'bottom-right', 'bottom-left'], '#E53935');
    } else if (name.includes('a')) {
      // Aa / Ab：三个角块循环
      this.drawCornerCycleArrow(ctx, cx, cy, sz, ['top-left', 'top-right', 'bottom-right'], '#E53935');
    }
  }

  private positionToPoint(pos: string, cx: number, cy: number, sz: number): number[] {
    // 将箭头/数字放在贴纸外侧，避免盖住贴纸
    const offset: number = sz * 0.7;
    switch (pos) {
      case 'top-left': return [cx - offset, cy - offset];
      case 'top': return [cx, cy - offset];
      case 'top-right': return [cx + offset, cy - offset];
      case 'right': return [cx + offset, cy];
      case 'bottom-right': return [cx + offset, cy + offset];
      case 'bottom': return [cx, cy + offset];
      case 'bottom-left': return [cx - offset, cy + offset];
      case 'left': return [cx - offset, cy];
      default: return [cx, cy];
    }
  }

  private drawCornerSwapArrow(ctx: CanvasRenderingContext2D, cx: number, cy: number, sz: number,
    pos1: string, pos2: string, color: string): void {
    const p1: number[] = this.positionToPoint(pos1, cx, cy, sz);
    const p2: number[] = this.positionToPoint(pos2, cx, cy, sz);
    this.drawDoubleArrow(ctx, p1[0], p1[1], p2[0], p2[1], color, 10);
  }

  private drawEdgeSwapArrow(ctx: CanvasRenderingContext2D, cx: number, cy: number, sz: number,
    pos1: string, pos2: string, color: string): void {
    const p1: number[] = this.positionToPoint(pos1, cx, cy, sz);
    const p2: number[] = this.positionToPoint(pos2, cx, cy, sz);
    this.drawDoubleArrow(ctx, p1[0], p1[1], p2[0], p2[1], color, 8);
  }

  private drawCornerCycleArrow(ctx: CanvasRenderingContext2D, cx: number, cy: number, sz: number,
    positions: string[], color: string): void {
    const points: number[][] = positions.map((p: string): number[] => this.positionToPoint(p, cx, cy, sz));
    this.drawCycleArrow(ctx, points, color, 10);
  }

  private drawEdgeCycleArrow(ctx: CanvasRenderingContext2D, cx: number, cy: number, sz: number,
    positions: string[], color: string): void {
    const points: number[][] = positions.map((p: string): number[] => this.positionToPoint(p, cx, cy, sz));
    this.drawCycleArrow(ctx, points, color, 8);
  }

  private drawDoubleArrow(ctx: CanvasRenderingContext2D, x1: number, y1: number, x2: number, y2: number,
    color: string, headSize: number): void {
    ctx.strokeStyle = color;
    ctx.fillStyle = color;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(x1, y1);
    ctx.lineTo(x2, y2);
    ctx.stroke();
    this.drawArrowHead(ctx, x1, y1, x2, y2, headSize);
    this.drawArrowHead(ctx, x2, y2, x1, y1, headSize);
    this.drawNumber(ctx, x1, y1, '1', color);
    this.drawNumber(ctx, x2, y2, '2', color);
  }

  private drawCycleArrow(ctx: CanvasRenderingContext2D, points: number[][], color: string, headSize: number): void {
    if (points.length < 3) {
      return;
    }
    ctx.strokeStyle = color;
    ctx.fillStyle = color;
    ctx.lineWidth = 2;
    ctx.beginPath();
    const start: number[] = points[0];
    ctx.moveTo(start[0], start[1]);
    for (let i: number = 1; i < points.length; i++) {
      ctx.lineTo(points[i][0], points[i][1]);
    }
    ctx.closePath();
    ctx.stroke();
    const last: number[] = points[points.length - 1];
    this.drawArrowHead(ctx, last[0], last[1], start[0], start[1], headSize);
    for (let i: number = 0; i < points.length; i++) {
      this.drawNumber(ctx, points[i][0], points[i][1], (i + 1).toString(), color);
    }
  }

  private drawNumber(ctx: CanvasRenderingContext2D, x: number, y: number, text: string, color: string): void {
    const size: number = 10;
    ctx.font = `${size}px sans-serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillStyle = '#FFFFFF';
    ctx.beginPath();
    ctx.arc(x, y, size * 0.6, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = color;
    ctx.fillText(text, x, y + 1);
  }

  private drawArrowHead(ctx: CanvasRenderingContext2D, fromX: number, fromY: number, toX: number, toY: number,
    size: number): void {
    const angle: number = Math.atan2(toY - fromY, toX - fromX);
    ctx.beginPath();
    ctx.moveTo(toX, toY);
    ctx.lineTo(toX - size * Math.cos(angle - Math.PI / 6), toY - size * Math.sin(angle - Math.PI / 6));
    ctx.lineTo(toX - size * Math.cos(angle + Math.PI / 6), toY - size * Math.sin(angle + Math.PI / 6));
    ctx.closePath();
    ctx.fill();
  }

  /** 绘制 F2L 前两层简化侧视图（F 面 + 左右面 + U 面底行） */
  private drawF2L(ctx: CanvasRenderingContext2D, cube: Cube3x3): void {
    const pad: number = this.imageSize * 0.08;
    const cw: number = (this.imageSize - pad * 2) / 4;
    const ch: number = cw;
    const left: number = pad;
    const top: number = pad;
    const cornerRadius: number = cw * 0.12;

    // 绘制 U 面底部一行（F 面相邻的三个 U 贴纸）
    const uFace: number[][] = cube.getFace(0);
    for (let c: number = 0; c < 3; c++) {
      const x: number = left + cw + c * cw;
      const y: number = top;
      this.drawSticker(ctx, x, y, cw - 2, ch - 2, cornerRadius, FACE_COLORS[uFace[2][c]]);
    }

    // 绘制 F 面 3x3
    const fFace: number[][] = cube.getFace(4);
    for (let r: number = 0; r < 3; r++) {
      for (let c: number = 0; c < 3; c++) {
        const x: number = left + cw + c * cw;
        const y: number = top + ch + r * ch;
        this.drawSticker(ctx, x, y, cw - 2, ch - 2, cornerRadius, FACE_COLORS[fFace[r][c]]);
      }
    }

    // 绘制 L 面右侧条
    const lFace: number[][] = cube.getFace(2);
    for (let r: number = 0; r < 3; r++) {
      const x: number = left;
      const y: number = top + ch + r * ch;
      this.drawSticker(ctx, x, y, cw - 2, ch - 2, cornerRadius, FACE_COLORS[lFace[r][2]]);
    }

    // 绘制 R 面左侧条
    const rFace: number[][] = cube.getFace(3);
    for (let r: number = 0; r < 3; r++) {
      const x: number = left + cw * 4;
      const y: number = top + ch + r * ch;
      this.drawSticker(ctx, x, y, cw - 2, ch - 2, cornerRadius, FACE_COLORS[rFace[r][0]]);
    }
  }

  private drawSticker(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number,
    r: number, color: string): void {
    this.roundRect(ctx, x, y, w, h, r);
    ctx.fillStyle = color;
    ctx.fill();
    ctx.lineWidth = 1.2;
    ctx.strokeStyle = STICKER_OUTLINE;
    ctx.stroke();
  }

  private roundRect(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number): void {
    const radius: number = Math.min(r, w / 2, h / 2);
    ctx.beginPath();
    ctx.moveTo(x + radius, y);
    ctx.arcTo(x + w, y, x + w, y + h, radius);
    ctx.arcTo(x + w, y + h, x, y + h, radius);
    ctx.arcTo(x, y + h, x, y, radius);
    ctx.arcTo(x, y, x + w, y, radius);
    ctx.closePath();
  }
}
