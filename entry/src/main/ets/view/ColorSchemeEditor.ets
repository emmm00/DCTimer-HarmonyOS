// ColorSchemeEditor — 打乱图配色编辑器（NxNxN / 金字塔 / 斜转 / 五魔方）。
// UI 仿原版 Android DCTimer 配色页：
//   顶部当前类型各"面"的色块（点击选中正在编辑的面）
//   中部 HSV 选色板（方形 SV 渐变板 + 垂直色相彩虹条，可直接拖动）
//   当前颜色 hex 码 + 一行快捷色块
//   底部 恢复默认 / 取消 / 确定
// 确定后才生效：onConfirm 把编辑色表交回 Index 写入 Scrambler.schemeX 并持久化。
import { Scrambler } from '../scrambler/Scrambler';

// 配色类型定义（kind 与 Index 设置项 id 对应：81/82/83/84 -> 0/1/2/3）
interface SchemeKindInfo {
  name: string;
  labels: string[];
}

const SCHEME_KINDS: SchemeKindInfo[] = [
  { name: 'NxNxN 魔方', labels: ['U', 'R', 'F', 'D', 'L', 'B'] },
  { name: '金字塔', labels: ['1', '2', '3', '4'] },
  { name: '斜转', labels: ['U', 'R', 'F', 'D', 'L', 'B'] },
  { name: '五魔方', labels: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'] }
];

// 快捷色一行（白 黑 红 橙 黄 绿 蓝 紫）
const QUICK_COLORS: number[] = [0xffffffff, 0xff333333, 0xffff0000, 0xffff9900,
  0xffffff00, 0xff00cc00, 0xff0066ff, 0xff9900ff];

// HSV(0-360, 0-1, 0-1) -> ARGB
function hsvToArgb(h: number, s: number, v: number): number {
  const hh = ((h % 360) + 360) % 360;
  const c = v * s;
  const hp = hh / 60;
  const x = c * (1 - Math.abs(hp % 2 - 1));
  let r = 0;
  let g = 0;
  let b = 0;
  if (hp < 1) { r = c; g = x; }
  else if (hp < 2) { r = x; g = c; }
  else if (hp < 3) { g = c; b = x; }
  else if (hp < 4) { g = x; b = c; }
  else if (hp < 5) { r = x; b = c; }
  else { r = c; b = x; }
  const m = v - c;
  const ri = Math.round((r + m) * 255);
  const gi = Math.round((g + m) * 255);
  const bi = Math.round((b + m) * 255);
  return 0xff000000 | (ri << 16) | (gi << 8) | bi;
}

// ARGB -> [h(0-360), s(0-1), v(0-1)]
function argbToHsv(argb: number): number[] {
  const r = ((argb >> 16) & 0xff) / 255;
  const g = ((argb >> 8) & 0xff) / 255;
  const b = (argb & 0xff) / 255;
  const mx = Math.max(r, g, b);
  const mn = Math.min(r, g, b);
  const d = mx - mn;
  let h = 0;
  if (d > 0.00001) {
    if (mx === r) {
      h = 60 * (((g - b) / d) % 6);
    } else if (mx === g) {
      h = 60 * ((b - r) / d + 2);
    } else {
      h = 60 * ((r - g) / d + 4);
    }
  }
  if (h < 0) {
    h += 360;
  }
  return [h, mx <= 0 ? 0 : d / mx, mx];
}

function hex2(v: number): string {
  let h: string = v.toString(16).toUpperCase();
  if (h.length < 2) {
    h = '0' + h;
  }
  return h;
}

function argbToHex(argb: number): string {
  return '#' + hex2((argb >> 16) & 0xff) + hex2((argb >> 8) & 0xff) + hex2(argb & 0xff);
}

function numToColorStr(v: number): string {
  return '#' + (v & 0xffffff).toString(16).padStart(6, '0').toUpperCase();
}

@Component
export struct ColorSchemeEditor {
  @Prop kind: number = 0; // 0=NxNxN 1=金字塔 2=斜转 3=五魔方
  @Prop isDark: boolean = false;
  // 底部安全区高度（vp）：沉浸式布局下弹窗需自行避让手势条/导航栏
  @Prop bottomInset: number = 28;
  // 控制显隐（父组件 @State showColorScheme 的双向绑定）
  @Link editing: boolean;
  onConfirm: (kind: number, colors: number[]) => void = (kind: number, colors: number[]): void => {
  };

  @State colors: number[] = [];
  @State sel: number = 0; // 当前编辑的面索引
  // HSV 状态
  @State hue: number = 0;
  @State sat: number = 1;
  @State val: number = 1;
  @State svW: number = 0; // SV 板实际尺寸（onReady/布局后记录）
  @State svH: number = 0;
  @State hueH: number = 0;

  private svCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private hueCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private readonly SV_H: number = 190; // SV 板高度(vp)，宽自适应（约 260）

  aboutToAppear(): void {
    this.colors = this.loadCurrent().slice();
    this.sel = 0;
    this.syncHsvFromSel();
  }

  // 读当前生效配色（未持久化时即类内默认）
  private loadCurrent(): number[] {
    if (this.kind === 0) {
      return Scrambler.schemeN.slice();
    }
    if (this.kind === 1) {
      return Scrambler.schemeP.slice();
    }
    if (this.kind === 2) {
      return Scrambler.schemeW.slice();
    }
    return Scrambler.schemeM.slice();
  }

  private loadDefault(): number[] {
    if (this.kind === 0) {
      return Scrambler.defaultSchemeN();
    }
    if (this.kind === 1) {
      return Scrambler.defaultSchemeP();
    }
    if (this.kind === 2) {
      return Scrambler.defaultSchemeW();
    }
    return Scrambler.defaultSchemeM();
  }

  // ArkTS 禁止对 struct 字段直接下标访问（arkts-no-props-by-index），
  // 须经局部变量中转
  private colorsGet(i: number): number {
    const arr = this.colors;
    return arr[i];
  }

  private colorsSet(i: number, v: number): void {
    const arr = this.colors;
    arr[i] = v;
  }

  private syncHsvFromSel(): void {
    const hsv: number[] = argbToHsv(this.colorsGet(this.sel));
    this.hue = hsv[0];
    this.sat = hsv[1];
    this.val = hsv[2];
  }

  private currentColor(): number {
    return hsvToArgb(this.hue, this.sat, this.val);
  }

  private applyColorToSel(): void {
    this.colorsSet(this.sel, this.currentColor());
  }

  private pickFace(idx: number): void {
    this.sel = idx;
    this.syncHsvFromSel();
    this.drawSv(); // 切面后色相可能变化，SV 板底色需重绘
  }

  private drawSv(): void {
    const w = this.svW;
    const h = this.svH;
    if (w <= 0 || h <= 0) {
      return;
    }
    const ctx = this.svCtx;
    ctx.clearRect(0, 0, w, h);
    // 底层：当前色相的纯色
    ctx.fillStyle = numToColorStr(hsvToArgb(this.hue, 1, 1));
    ctx.fillRect(0, 0, w, h);
    // 横向：白 -> 透明（饱和度左高右低）
    const gW = ctx.createLinearGradient(0, 0, w, 0);
    gW.addColorStop(0, 'rgba(255,255,255,1)');
    gW.addColorStop(1, 'rgba(255,255,255,0)');
    ctx.fillStyle = gW;
    ctx.fillRect(0, 0, w, h);
    // 纵向：透明 -> 黑（明度上高下低）
    const gB = ctx.createLinearGradient(0, 0, 0, h);
    gB.addColorStop(0, 'rgba(0,0,0,0)');
    gB.addColorStop(1, 'rgba(0,0,0,1)');
    ctx.fillStyle = gB;
    ctx.fillRect(0, 0, w, h);
  }

  private drawHue(): void {
    const h = this.hueH;
    if (h <= 0) {
      return;
    }
    const ctx = this.hueCtx;
    ctx.clearRect(0, 0, 30, h);
    const g = ctx.createLinearGradient(0, 0, 0, h);
    g.addColorStop(0, numToColorStr(hsvToArgb(0, 1, 1)));
    g.addColorStop(1 / 6, numToColorStr(hsvToArgb(60, 1, 1)));
    g.addColorStop(2 / 6, numToColorStr(hsvToArgb(120, 1, 1)));
    g.addColorStop(3 / 6, numToColorStr(hsvToArgb(180, 1, 1)));
    g.addColorStop(4 / 6, numToColorStr(hsvToArgb(240, 1, 1)));
    g.addColorStop(5 / 6, numToColorStr(hsvToArgb(300, 1, 1)));
    g.addColorStop(1, numToColorStr(hsvToArgb(360, 1, 1)));
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, 30, h);
  }

  build() {
    Column() {
      // 遮罩：点击关闭（=取消）
      Column()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(this.isDark ? 0x66000000 : 0x44000000)
        .onClick((): void => {
          this.editing = false;
        });

      // 弹窗主体
      Column({ space: 12 }) {
        Text('选择颜色')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDark ? 0xffeeeeee : 0xff222222)

        Text(SCHEME_KINDS[this.kind].name + '（点击色块选择要修改的面）')
          .fontSize(12)
          .fontColor(this.isDark ? 0xff999999 : 0xff888888)

        // 面选择（当前各面色块）
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
          ForEach(SCHEME_KINDS[this.kind].labels, (label: string, idx: number) => {
            Column({ space: 3 }) {
              Text(label)
                .fontSize(10)
                .fontColor(this.sel === idx ? 0xff1e90ff : (this.isDark ? 0xffaaaaaa : 0xff666666))
              Column()
                .width(34)
                .height(24)
                .borderRadius(4)
                .backgroundColor(this.colors.length > idx ? this.colorsGet(idx) : 0xff888888)
                .border({
                  width: this.sel === idx ? 2.5 : 1,
                  color: this.sel === idx ? 0xff1e90ff : (this.isDark ? 0xff555555 : 0xffcccccc)
                })
            }
            .margin(4)
            .onClick((): void => {
              this.pickFace(idx);
            })
          }, (label: string, idx: number): string => 'f' + idx)
        }
        .width('100%')

        // HSV 选色板：SV 方板 + 色相条
        Row({ space: 12 }) {
          Stack({ alignContent: Alignment.TopStart }) {
            Canvas(this.svCtx)
              .onReady((): void => {
                this.svW = 260;
                this.svH = this.SV_H;
                this.drawSv();
              })
              .width(260)
              .height(this.SV_H)
              .borderRadius(6)
              .onTouch((e: TouchEvent): void => {
                if (e.type === TouchType.Down || e.type === TouchType.Move) {
                  const x = Math.max(0, Math.min(260, e.touches[0].x));
                  const y = Math.max(0, Math.min(this.SV_H, e.touches[0].y));
                  this.sat = x / 260;
                  this.val = 1 - y / this.SV_H;
                  this.applyColorToSel();
                }
              })
            // SV 选择器圆点
            Circle({ width: 20, height: 20 })
              .fillOpacity(0)
              .stroke(0xffffffff)
              .strokeWidth(2.5)
              .position({
                x: Math.max(0, Math.min(260, this.sat * 260)) - 10,
                y: Math.max(0, Math.min(this.SV_H, (1 - this.val) * this.SV_H)) - 10
              })
          }
          .width(260)
          .height(this.SV_H)

          Stack({ alignContent: Alignment.TopStart }) {
            Canvas(this.hueCtx)
              .onReady((): void => {
                this.hueH = this.SV_H;
                this.drawHue();
              })
              .width(30)
              .height(this.SV_H)
              .borderRadius(6)
              .onTouch((e: TouchEvent): void => {
                if (e.type === TouchType.Down || e.type === TouchType.Move) {
                  const y = Math.max(0, Math.min(this.SV_H, e.touches[0].y));
                  this.hue = y / this.SV_H * 360;
                  this.applyColorToSel();
                  this.drawSv(); // 色相变化需重绘 SV 板底色
                }
              })
            // 色相指示条
            Row()
              .width(38)
              .height(5)
              .borderRadius(2)
              .backgroundColor(0xffffffff)
              .border({ width: 1.5, color: 0xff000000 })
              .position({ x: -4, y: Math.max(0, Math.min(this.SV_H, this.hue / 360 * this.SV_H)) - 2.5 })
          }
          .width(30)
          .height(this.SV_H)
        }
        .alignItems(VerticalAlign.Top)

        // 当前颜色 + 快捷色
        Row({ space: 10 }) {
          Column()
            .width(40)
            .height(26)
            .borderRadius(4)
            .backgroundColor(this.currentColor())
            .border({ width: 1, color: this.isDark ? 0xff555555 : 0xffcccccc })
          Text(argbToHex(this.currentColor()))
            .fontSize(13)
            .fontColor(this.isDark ? 0xffdddddd : 0xff333333)
            .width(74)
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(QUICK_COLORS, (qc: number, idx: number) => {
              Column()
                .width(26)
                .height(26)
                .borderRadius(13)
                .backgroundColor(qc)
                .border({ width: 1, color: 0xff888888 })
                .margin(2)
                .onClick((): void => {
                  const hsv: number[] = argbToHsv(qc);
                  this.hue = hsv[0];
                  this.sat = hsv[1];
                  this.val = hsv[2];
                  this.applyColorToSel();
                  this.drawSv();
                })
            }, (qc: number, idx: number): string => 'q' + idx)
          }
          .layoutWeight(1)
        }
        .width('100%')

        Divider()
          .color(this.isDark ? 0xff444444 : 0xffdddddd)

        // 底部按钮：恢复默认 / 取消 / 确定
        Row({ space: 8 }) {
          Button('恢复默认')
            .fontSize(13)
            .fontColor(0xffe53935)
            .backgroundColor(Color.Transparent)
            .border({ width: 1, color: 0xffe53935 })
            .borderRadius(16)
            .height(32)
            .onClick((): void => {
              this.colors = this.loadDefault();
              this.sel = 0;
              this.syncHsvFromSel();
              this.drawSv();
            })
          Blank()
          Button('取消')
            .fontSize(13)
            .fontColor(this.isDark ? 0xff64b5f6 : 0xff1e88e5)
            .backgroundColor(Color.Transparent)
            .height(32)
            .onClick((): void => {
              this.editing = false;
            })
          Button('确定')
            .fontSize(13)
            .fontColor(0xffffffff)
            .backgroundColor(this.isDark ? 0xff1e88e5 : 0xff2196f3)
            .borderRadius(16)
            .height(32)
            .padding({ left: 14, right: 14 })
            .onClick((): void => {
              this.onConfirm(this.kind, this.colors.slice());
              this.editing = false;
            })
        }
        .width('100%')
      }
      .width('100%')
      // 底部垫高安全区，避免「恢复默认/取消/确定」按钮被手势条遮挡（审核问题2）
      .padding({ left: 16, right: 16, top: 16, bottom: 16 + this.bottomInset })
      .borderRadius({ topLeft: 16, topRight: 16 })
      .backgroundColor(this.isDark ? 0xff222222 : 0xffffffff)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.End)
  }
}
