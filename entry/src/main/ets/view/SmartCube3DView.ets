/**
 * SmartCube3DView — 智能魔方实时 3D 预览（Canvas 手绘渲染）
 *
 * 参考 DCTimer-BLE 的 SmartCube3DView / SmartCubeImageView：
 * - 54 个贴面(sticker)，每个由中心坐标 + 法线 + 面内切向定义
 * - painter 算法按深度排序、透视投影绘制
 * - 支持触摸拖动旋转视角(YAW/PITCH)
 * - 提供 setGyroQuaternion 接口，可将智能魔方姿态（四元数）映射为视角，
 *   实现"打乱图跟随现实魔方转动"
 *
 * 说明：真实设备上的魔方姿态数据需在 BleManager 订阅 GATT notify 后解析
 * 协议获得（Giiker/GAN/QiYi/Moyu 各不相同），本组件提供姿态输入口，
 * 数据通路需在真机上验证。
 */

export const CUBE_FACE_COLORS: string[] = ['#ffffff', '#ff4444', '#44ff44', '#ffdd00', '#ff8800', '#0055ff'];

interface Sticker3 {
  cx: number; cy: number; cz: number; // 面中心坐标
  nx: number; ny: number; nz: number; // 面法线（已归一化）
  tx: number; ty: number; tz: number; // 面内切向 u（row 方向）
  ux: number; uy: number; uz: number; // 面内切向 v（col 方向）
  colorIndex: number;
}

interface ProjectedSticker {
  z: number;
  poly: number[][]; // 投影后四边形（4 个 [x,y]）
  colorIndex: number;
}

const STICKER_HALF: number = 0.40;
const CAM_DIST: number = 6.2;

/** 每面固定切向（法线方向决定唯一）：
 *  U(+Y): u=-Z(前), v=+X(右)  使 facelet 顺序与求解器一致
 *  R(+X): u=-Z,      v=+Y
 *  F(+Z): u=+X,      v=+Y
 *  D(-Y): u=+Z,      v=+X
 *  L(-X): u=+Z,      v=+Y
 *  B(-Z): u=-X,      v=+Y
 *  贴面在面平面内由 中心 ± u*half ± v*half 构成。
 */
function faceTangents(f: number): number[][] {
  switch (f) {
    case 0: return [[0, 0, -1], [1, 0, 0]];
    case 1: return [[0, 0, -1], [0, 1, 0]];
    case 2: return [[1, 0, 0], [0, 1, 0]];
    case 3: return [[0, 0, 1], [1, 0, 0]];
    case 4: return [[0, 0, 1], [0, 1, 0]];
    default: return [[-1, 0, 0], [0, 1, 0]];
  }
}

const FACE_VECTORS: number[][] = [
  [0, 1, 0], [1, 0, 0], [0, 0, 1], [0, -1, 0], [-1, 0, 0], [0, 0, -1]
];

function buildStickers(): Sticker3[] {
  const stickers: Sticker3[] = [];
  for (let f = 0; f < 6; f++) {
    const n = FACE_VECTORS[f];
    const t = faceTangents(f);
    const u = t[0];
    const v = t[1];
    // 九宫格：col 沿 u(-1..1)，row 沿 v
    for (let col = -1; col <= 1; col++) {
      for (let row = -1; row <= 1; row++) {
        stickers.push({
          cx: n[0] + u[0] * col + v[0] * row,
          cy: n[1] + u[1] * col + v[1] * row,
          cz: n[2] + u[2] * col + v[2] * row,
          nx: n[0], ny: n[1], nz: n[2],
          tx: u[0], ty: u[1], tz: u[2],
          ux: v[0], uy: v[1], uz: v[2],
          colorIndex: f
        });
      }
    }
  }
  return stickers;
}

@Component
export struct SmartCube3DView {
  // 可选：当前贴面状态（54 字符，各面顺序 U R F D L B）。为空时用已解配色。
  @Prop @Watch('onChanged') facelets: string = '';
  @Prop @Watch('onChanged') puzzleCode: number = 33;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private ready: boolean = false;
  private W: number = 0;
  private H: number = 0;

  // 视角欧拉角（度）
  private yawDeg: number = 32;
  private pitchDeg: number = -10;
  private gx: number = 0;
  private gy: number = 0;
  private dragging: boolean = false;

  private stickers: Sticker3[] = buildStickers();

  onChanged(): void {
    if (this.ready && this.W > 0 && this.H > 0) {
      this.render();
    }
  }

  /** 姿态跟随：传入魔方四元数 (x,y,z,w)，映射为视角。linkageOn 时生效。 */
  setGyroQuaternion(qx: number, qy: number, qz: number, qw: number, linkageOn: boolean): void {
    if (!linkageOn) {
      return;
    }
    const sqw = qw * qw, sqx = qx * qx, sqy = qy * qy, sqz = qz * qz;
    const yaw = Math.atan2(2 * (qy * qw - qx * qz), sqw - sqx - sqy + sqz) * 180 / Math.PI;
    const pitch = clamp(Math.asin(clamp(2 * (qx * qy + qz * qw), -1, 1)), -85, 85) * 180 / Math.PI;
    this.yawDeg = yaw;
    this.pitchDeg = -pitch;
    if (this.ready) {
      this.render();
    }
  }

  setView(yawDeg: number, pitchDeg: number): void {
    this.yawDeg = yawDeg;
    this.pitchDeg = pitchDeg;
    if (this.ready) {
      this.render();
    }
  }

  /** 世界坐标 -> 相机（先绕Y再绕X）。命名为 rot3 以避免与基类 CustomComponent.rotate 冲突。 */
  private rot3(v: number[]): number[] {
    const yaw = this.yawDeg * Math.PI / 180;
    const pitch = this.pitchDeg * Math.PI / 180;
    const cy = Math.cos(yaw), sy = Math.sin(yaw);
    const cp = Math.cos(pitch), sp = Math.sin(pitch);
    const x1 = v[0] * cy + v[2] * sy;
    const z1 = -v[0] * sy + v[2] * cy;
    const y2 = v[1] * cp - z1 * sp;
    const z2 = v[1] * sp + z1 * cp;
    return [x1, y2, z2];
  }

  private project(s: Sticker3): ProjectedSticker | null {
    const center = this.rot3([s.cx, s.cy, s.cz]);
    const zc = center[2];
    // 背面剔除：中心朝向相机(+Z 近端)才绘制
    if (zc <= 0) {
      return null;
    }
    const scale = CAM_DIST / (CAM_DIST - zc);
    const h = STICKER_HALF;
    // 纯 center 无法代表朝向，需旋转面内角点。用中心作为旋转基准，直接旋转四个角点。
    const cornerWorld: number[][] = [
      [s.cx + s.tx * h + s.ux * h, s.cy + s.ty * h + s.uy * h, s.cz + s.tz * h + s.uz * h],
      [s.cx + s.tx * h - s.ux * h, s.cy + s.ty * h - s.uy * h, s.cz + s.tz * h - s.uz * h],
      [s.cx - s.tx * h - s.ux * h, s.cy - s.ty * h - s.uy * h, s.cz - s.tz * h - s.uz * h],
      [s.cx - s.tx * h + s.ux * h, s.cy - s.ty * h + s.uy * h, s.cz - s.tz * h + s.uz * h]
    ];
    const poly: number[][] = [];
    for (const cw of cornerWorld) {
      const r = this.rot3(cw);
      const scl = CAM_DIST / (CAM_DIST - r[2]);
      poly.push([this.scaleX(r[0], scl), this.scaleY(r[1], scl)]);
    }
    return { z: zc, poly: poly, colorIndex: s.colorIndex };
  }

  private scaleX(wx: number, s: number): number {
    return this.W / 2 + wx * s * this.W / CAM_DIST;
  }
  private scaleY(wy: number, s: number): number {
    return this.H / 2 - wy * s * this.W / CAM_DIST;
  }

  private render(): void {
    if (this.W <= 0 || this.H <= 0) {
      return;
    }
    const ctx = this.ctx;
    ctx.clearRect(0, 0, this.W, this.H);

    const list: ProjectedSticker[] = [];
    for (const s of this.stickers) {
      const pr = this.project(s);
      if (pr != null) {
        list.push(pr);
      }
    }
    list.sort((a: ProjectedSticker, b: ProjectedSticker): number => b.z - a.z);

    for (const pr of list) {
      const colorIdx = this.resolveColor(pr.colorIndex);
      ctx.beginPath();
      ctx.moveTo(pr.poly[0][0], pr.poly[0][1]);
      ctx.lineTo(pr.poly[1][0], pr.poly[1][1]);
      ctx.lineTo(pr.poly[2][0], pr.poly[2][1]);
      ctx.lineTo(pr.poly[3][0], pr.poly[3][1]);
      ctx.closePath();
      ctx.fillStyle = CUBE_FACE_COLORS[colorIdx];
      ctx.fill();
      ctx.strokeStyle = 'rgba(0,0,0,0.35)';
      ctx.lineWidth = 1;
      ctx.stroke();
    }
  }

  private resolveColor(face: number): number {
    if (this.facelets.length >= 54) {
      const ch = this.facelets.charAt(face * 9);
      switch (ch) {
        case 'U': return 0;
        case 'R': return 1;
        case 'F': return 2;
        case 'D': return 3;
        case 'L': return 4;
        case 'B': return 5;
      }
    }
    return face;
  }

  private lenToNum(v: Length): number {
    if (typeof v === 'number') {
      return v;
    }
    if (typeof v === 'string') {
      const n: number = parseFloat(v);
      return isNaN(n) ? 0 : n;
    }
    return 0;
  }

  build() {
    Column() {
      Canvas(this.ctx)
        .width('100%')
        .height('100%')
        .onReady((): void => {
          this.ready = true;
          if (this.W <= 0 || this.H <= 0) {
            this.W = 152;
            this.H = 114;
          }
          this.render();
        })
        .onAreaChange((_o: Area, n: Area): void => {
          const nw = this.lenToNum(n.width);
          const nh = this.lenToNum(n.height);
          if (nw > 0) {
            this.W = nw;
          }
          if (nh > 0) {
            this.H = nh;
          }
          if (this.ready) {
            this.render();
          }
        })
        .onTouch((event: TouchEvent): void => {
          if (event.type === TouchType.Down) {
            this.dragging = true;
            this.gx = event.touches[0].x;
            this.gy = event.touches[0].y;
          } else if (event.type === TouchType.Move && this.dragging && event.touches.length > 0) {
            const dx = event.touches[0].x - this.gx;
            const dy = event.touches[0].y - this.gy;
            this.gx = event.touches[0].x;
            this.gy = event.touches[0].y;
            this.yawDeg += dx * 0.7;
            this.pitchDeg = clamp(this.pitchDeg - dy * 0.7, -85, 85);
            this.render();
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.dragging = false;
          }
        });
    }
    .width('100%')
    .height('100%');
  }
}

function clamp(v: number, lo: number, hi: number): number {
  return v < lo ? lo : (v > hi ? hi : v);
}