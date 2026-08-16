// ArkUI Canvas adapter implementing ScrambleCanvas (ported Android Canvas/Paint -> CanvasRenderingContext2D)
import { PaintState, ScrambleCanvas } from '../scrambler/Scrambler';

function colorToString(cl: number): string {
  const a: number = (cl >>> 24) & 0xff;
  const r: number = (cl >>> 16) & 0xff;
  const g: number = (cl >>> 8) & 0xff;
  const b: number = cl & 0xff;
  const hx = (v: number): string => {
    const s = v.toString(16);
    return s.length < 2 ? '0' + s : s;
  };
  if (a < 255) {
    return '#' + hx(a) + hx(r) + hx(g) + hx(b);
  }
  return '#' + hx(r) + hx(g) + hx(b);
}

const FILL: number = 0;
const STROKE: number = 1;
const FILL_AND_STROKE: number = 2;

export class ScrambleCanvasAdapter implements ScrambleCanvas {
  private ctx: CanvasRenderingContext2D;

  constructor(ctx: CanvasRenderingContext2D) {
    this.ctx = ctx;
  }

  private applyStyle(p: PaintState): void {
    this.ctx.fillStyle = colorToString(p.color);
    this.ctx.strokeStyle = colorToString(p.color);
    this.ctx.lineWidth = 1;
  }

  drawRect(l: number, t: number, r: number, b: number, p: PaintState): void {
    const ctx: CanvasRenderingContext2D = this.ctx;
    this.applyStyle(p);
    if (p.style == FILL || p.style == FILL_AND_STROKE) {
      ctx.fillRect(l, t, r - l, b - t);
    }
    if (p.style == STROKE || p.style == FILL_AND_STROKE) {
      ctx.strokeRect(l, t, r - l, b - t);
    }
  }

  drawCircle(cx: number, cy: number, rad: number, p: PaintState): void {
    const ctx: CanvasRenderingContext2D = this.ctx;
    this.applyStyle(p);
    ctx.beginPath();
    ctx.arc(cx, cy, rad, 0, 2 * Math.PI);
    if (p.style == FILL || p.style == FILL_AND_STROKE) {
      ctx.fill();
    }
    if (p.style == STROKE || p.style == FILL_AND_STROKE) {
      ctx.stroke();
    }
  }

  drawPath(pts: number[][], p: PaintState): void {
    const ctx: CanvasRenderingContext2D = this.ctx;
    if (pts.length < 2) {
      return;
    }
    this.applyStyle(p);
    ctx.beginPath();
    ctx.moveTo(pts[0][0], pts[0][1]);
    for (let i: number = 1; i < pts.length; i++) {
      ctx.lineTo(pts[i][0], pts[i][1]);
    }
    ctx.closePath();
    if (p.style == FILL || p.style == FILL_AND_STROKE) {
      ctx.fill();
    }
    if (p.style == STROKE || p.style == FILL_AND_STROKE) {
      ctx.stroke();
    }
  }

  drawArc(l: number, t: number, r: number, b: number, startAngle: number, sweepAngle: number, p: PaintState): void {
    const ctx: CanvasRenderingContext2D = this.ctx;
    this.applyStyle(p);
    const cx: number = (l + r) / 2;
    const cy: number = (t + b) / 2;
    const rx: number = (r - l) / 2;
    const ry: number = (b - t) / 2;
    const rad: number = Math.max(rx, ry);
    const start: number = startAngle * Math.PI / 180;
    const sweep: number = sweepAngle * Math.PI / 180;
    if (Math.abs(rx - ry) > 0.001) {
      ctx.save();
      ctx.translate(cx, cy);
      ctx.scale(rx / rad, ry / rad);
      ctx.beginPath();
      ctx.arc(0, 0, rad, start, start + sweep, sweep < 0);
      ctx.closePath();
      if (p.style == FILL || p.style == FILL_AND_STROKE) {
        ctx.fill();
      }
      if (p.style == STROKE || p.style == FILL_AND_STROKE) {
        ctx.stroke();
      }
      ctx.restore();
      return;
    }
    ctx.beginPath();
    ctx.arc(cx, cy, rad, start, start + sweep, sweep < 0);
    ctx.closePath();
    if (p.style == FILL || p.style == FILL_AND_STROKE) {
      ctx.fill();
    }
    if (p.style == STROKE || p.style == FILL_AND_STROKE) {
      ctx.stroke();
    }
  }

  drawText(txt: string, x: number, y: number, p: PaintState): void {
    const ctx: CanvasRenderingContext2D = this.ctx;
    ctx.fillStyle = colorToString(p.color);
    ctx.font = p.textSize + 'px sans-serif';
    if (p.textAlign == 0) {
      ctx.textAlign = 'left';
    } else if (p.textAlign == 1) {
      ctx.textAlign = 'center';
    } else {
      ctx.textAlign = 'right';
    }
    ctx.fillText(txt, x, y);
  }

  save(): void {
    this.ctx.save();
  }

  restore(): void {
    this.ctx.restore();
  }

  rotate(deg: number, cx: number, cy: number): void {
    const ctx: CanvasRenderingContext2D = this.ctx;
    ctx.translate(cx, cy);
    ctx.rotate(deg * Math.PI / 180);
    ctx.translate(-cx, -cy);
  }
}
