// 颜色调色板工具
export class ColorPalette {
  // Material Design 500 色调色
  static readonly MD_RED_500 = 0xfff44336;
  static readonly MD_PINK_500 = 0xffe91e63;
  static readonly MD_PURPLE_500 = 0xff9c27b0;
  static readonly MD_DEEP_PURPLE_500 = 0xff673ab7;
  static readonly MD_INDIGO_500 = 0xff3f51b5;
  static readonly MD_BLUE_500 = 0xff2196f3;
  static readonly MD_LIGHT_BLUE_500 = 0xff03a9f4;
  static readonly MD_CYAN_500 = 0xff00bcd4;
  static readonly MD_TEAL_500 = 0xff009688;
  static readonly MD_GREEN_500 = 0xff4caf50;
  static readonly MD_LIGHT_GREEN_500 = 0xff8bc34a;
  static readonly MD_LIME_500 = 0xffcddc39;
  static readonly MD_YELLOW_500 = 0xffffeb3b;
  static readonly MD_AMBER_500 = 0xffffc107;
  static readonly MD_ORANGE_500 = 0xffff9800;
  static readonly MD_DEEP_ORANGE_500 = 0xffff5722;
  static readonly MD_BROWN_500 = 0xff795548;
  static readonly MD_BLUE_GRAY_500 = 0xff607d8b;
  static readonly MD_GRAY_500 = 0xff9e9e9e;

  // 100-900 色阶
  static readonly MD_RED_100 = 0xffffcdd2;
  static readonly MD_RED_200 = 0xffef9a9a;
  static readonly MD_RED_300 = 0xffe57373;
  static readonly MD_RED_400 = 0xffef5350;
  static readonly MD_RED_600 = 0xffe53935;
  static readonly MD_RED_700 = 0xffd32f2f;
  static readonly MD_RED_800 = 0xffc62828;
  static readonly MD_RED_900 = 0xffb71c1c;

  static readonly MD_PINK_100 = 0xfff8bbd0;
  static readonly MD_PINK_200 = 0xfff48fb1;
  static readonly MD_PINK_300 = 0xfff06292;
  static readonly MD_PINK_400 = 0xffec407a;
  static readonly MD_PINK_600 = 0xffd81b60;
  static readonly MD_PINK_700 = 0xffc2185b;
  static readonly MD_PINK_800 = 0xffad1457;
  static readonly MD_PINK_900 = 0xff880e4f;

  static readonly MD_PURPLE_100 = 0xffe1bee7;
  static readonly MD_PURPLE_200 = 0xffce93d8;
  static readonly MD_PURPLE_300 = 0xffba68c8;
  static readonly MD_PURPLE_400 = 0xffab47bc;
  static readonly MD_PURPLE_600 = 0xff8e24aa;
  static readonly MD_PURPLE_700 = 0xff7b1fa2;
  static readonly MD_PURPLE_800 = 0xff6a1b9a;
  static readonly MD_PURPLE_900 = 0xff4a148c;

  static readonly MD_DEEP_PURPLE_100 = 0xffd1c4e9;
  static readonly MD_DEEP_PURPLE_200 = 0xffb39ddb;
  static readonly MD_DEEP_PURPLE_300 = 0xff9575cd;
  static readonly MD_DEEP_PURPLE_400 = 0xff7e57c2;
  static readonly MD_DEEP_PURPLE_600 = 0xff5e35b1;
  static readonly MD_DEEP_PURPLE_700 = 0xff512da8;
  static readonly MD_DEEP_PURPLE_800 = 0xff4527a0;
  static readonly MD_DEEP_PURPLE_900 = 0xff311b92;

  static readonly MD_INDIGO_100 = 0xffc5cae9;
  static readonly MD_INDIGO_200 = 0xff9fa8da;
  static readonly MD_INDIGO_300 = 0xff7986cb;
  static readonly MD_INDIGO_400 = 0xff5c6bc0;
  static readonly MD_INDIGO_600 = 0xff3949ab;
  static readonly MD_INDIGO_700 = 0xff303f9f;
  static readonly MD_INDIGO_800 = 0xff283593;
  static readonly MD_INDIGO_900 = 0xff1a237e;

  static readonly MD_BLUE_100 = 0xffbbdefb;
  static readonly MD_BLUE_200 = 0xff90caf9;
  static readonly MD_BLUE_300 = 0xff64b5f6;
  static readonly MD_BLUE_400 = 0xff42a5f5;
  static readonly MD_BLUE_600 = 0xff1e88e5;
  static readonly MD_BLUE_700 = 0xff1976d2;
  static readonly MD_BLUE_800 = 0xff1565c0;
  static readonly MD_BLUE_900 = 0xff0d47a1;

  static readonly MD_LIGHT_BLUE_100 = 0xffb3e5fc;
  static readonly MD_LIGHT_BLUE_200 = 0xff81d4fa;
  static readonly MD_LIGHT_BLUE_300 = 0xff4fc3f7;
  static readonly MD_LIGHT_BLUE_400 = 0xff29b6f6;
  static readonly MD_LIGHT_BLUE_600 = 0xff039be5;
  static readonly MD_LIGHT_BLUE_700 = 0xff0288d1;
  static readonly MD_LIGHT_BLUE_800 = 0xff0277bd;
  static readonly MD_LIGHT_BLUE_900 = 0xff01579b;

  static readonly MD_CYAN_100 = 0xffb2ebf2;
  static readonly MD_CYAN_200 = 0xff80deea;
  static readonly MD_CYAN_300 = 0xff4dd0e1;
  static readonly MD_CYAN_400 = 0xff26c6da;
  static readonly MD_CYAN_600 = 0xff00acc1;
  static readonly MD_CYAN_700 = 0xff0097a7;
  static readonly MD_CYAN_800 = 0xff00838f;
  static readonly MD_CYAN_900 = 0xff006064;

  static readonly MD_TEAL_100 = 0xffb2dfdb;
  static readonly MD_TEAL_200 = 0xff80cbc4;
  static readonly MD_TEAL_300 = 0xff4db6ac;
  static readonly MD_TEAL_400 = 0xff26a69a;
  static readonly MD_TEAL_600 = 0xff00897b;
  static readonly MD_TEAL_700 = 0xff00796b;
  static readonly MD_TEAL_800 = 0xff00695c;
  static readonly MD_TEAL_900 = 0xff004d40;

  static readonly MD_GREEN_100 = 0xffc8e6c9;
  static readonly MD_GREEN_200 = 0xffa5d6a7;
  static readonly MD_GREEN_300 = 0xff81c784;
  static readonly MD_GREEN_400 = 0xff66bb6a;
  static readonly MD_GREEN_600 = 0xff43a047;
  static readonly MD_GREEN_700 = 0xff388e3c;
  static readonly MD_GREEN_800 = 0xff2e7d32;
  static readonly MD_GREEN_900 = 0xff1b5e20;

  static readonly MD_LIGHT_GREEN_100 = 0xffdcedc8;
  static readonly MD_LIGHT_GREEN_200 = 0xffc5e1a5;
  static readonly MD_LIGHT_GREEN_300 = 0xffaed581;
  static readonly MD_LIGHT_GREEN_400 = 0xff9ccc65;
  static readonly MD_LIGHT_GREEN_600 = 0xff7cb342;
  static readonly MD_LIGHT_GREEN_700 = 0xff689f38;
  static readonly MD_LIGHT_GREEN_800 = 0xff558b2f;
  static readonly MD_LIGHT_GREEN_900 = 0xff33691e;

  static readonly MD_LIME_100 = 0xfff0f4c3;
  static readonly MD_LIME_200 = 0xffe6ee9c;
  static readonly MD_LIME_300 = 0xffdce775;
  static readonly MD_LIME_400 = 0xffd4e157;
  static readonly MD_LIME_600 = 0xffc0ca33;
  static readonly MD_LIME_700 = 0xffafb42b;
  static readonly MD_LIME_800 = 0xff9e9d24;
  static readonly MD_LIME_900 = 0xff827717;

  static readonly MD_YELLOW_100 = 0xfffff9c4;
  static readonly MD_YELLOW_200 = 0xfffff59d;
  static readonly MD_YELLOW_300 = 0xfffff176;
  static readonly MD_YELLOW_400 = 0xffffee58;
  static readonly MD_YELLOW_600 = 0xfffdd835;
  static readonly MD_YELLOW_700 = 0xfffbc02d;
  static readonly MD_YELLOW_800 = 0xfff9a825;
  static readonly MD_YELLOW_900 = 0xfff57f17;

  static readonly MD_AMBER_100 = 0xffffecb3;
  static readonly MD_AMBER_200 = 0xffffe082;
  static readonly MD_AMBER_300 = 0xffffd54f;
  static readonly MD_AMBER_400 = 0xffffca28;
  static readonly MD_AMBER_600 = 0xffffb300;
  static readonly MD_AMBER_700 = 0xffffa000;
  static readonly MD_AMBER_800 = 0xffff8f00;
  static readonly MD_AMBER_900 = 0xffff6f00;

  static readonly MD_ORANGE_100 = 0xffffe0b2;
  static readonly MD_ORANGE_200 = 0xffffcc80;
  static readonly MD_ORANGE_300 = 0xffffb74d;
  static readonly MD_ORANGE_400 = 0xffffa726;
  static readonly MD_ORANGE_600 = 0xfffb8c00;
  static readonly MD_ORANGE_700 = 0xfff57c00;
  static readonly MD_ORANGE_800 = 0xffef6c00;
  static readonly MD_ORANGE_900 = 0xffe65100;

  static readonly MD_DEEP_ORANGE_100 = 0xffffccbc;
  static readonly MD_DEEP_ORANGE_200 = 0xffffab91;
  static readonly MD_DEEP_ORANGE_300 = 0xffff8a65;
  static readonly MD_DEEP_ORANGE_400 = 0xffff7043;
  static readonly MD_DEEP_ORANGE_600 = 0xfff4511e;
  static readonly MD_DEEP_ORANGE_700 = 0xffe64a19;
  static readonly MD_DEEP_ORANGE_800 = 0xffd84315;
  static readonly MD_DEEP_ORANGE_900 = 0xffbf360c;

  static readonly MD_BROWN_100 = 0xffd7ccc8;
  static readonly MD_BROWN_200 = 0xffbcaaa4;
  static readonly MD_BROWN_300 = 0xffa1887f;
  static readonly MD_BROWN_400 = 0xff8d6e63;
  static readonly MD_BROWN_600 = 0xff6d4c41;
  static readonly MD_BROWN_700 = 0xff5d4037;
  static readonly MD_BROWN_800 = 0xff4e342e;
  static readonly MD_BROWN_900 = 0xff3e2723;

  static readonly MD_GRAY_100 = 0xfff5f5f5;
  static readonly MD_GRAY_200 = 0xffeeeeee;
  static readonly MD_GRAY_300 = 0xffe0e0e0;
  static readonly MD_GRAY_400 = 0xffbdbdbd;
  static readonly MD_GRAY_600 = 0xff757575;
  static readonly MD_GRAY_700 = 0xff616161;
  static readonly MD_GRAY_800 = 0xff424242;
  static readonly MD_GRAY_900 = 0xff212121;

  static readonly MD_BLUE_GRAY_100 = 0xffcfd8dc;
  static readonly MD_BLUE_GRAY_200 = 0xffb0bec5;
  static readonly MD_BLUE_GRAY_300 = 0xff90a4ae;
  static readonly MD_BLUE_GRAY_400 = 0xff78909c;
  static readonly MD_BLUE_GRAY_600 = 0xff546e7a;
  static readonly MD_BLUE_GRAY_700 = 0xff455a64;
  static readonly MD_BLUE_GRAY_800 = 0xff37474f;
  static readonly MD_BLUE_GRAY_900 = 0xff263238;

  static readonly WHITE = 0xffffffff;
  static readonly BLACK = 0xff000000;

  static getAccentColors(): number[] {
    return [
      ColorPalette.MD_RED_500,
      ColorPalette.MD_PURPLE_500,
      ColorPalette.MD_DEEP_PURPLE_500,
      ColorPalette.MD_BLUE_500,
      ColorPalette.MD_LIGHT_BLUE_500,
      ColorPalette.MD_CYAN_500,
      ColorPalette.MD_TEAL_500,
      ColorPalette.MD_GREEN_500,
      ColorPalette.MD_YELLOW_500,
      ColorPalette.MD_ORANGE_500,
      ColorPalette.MD_DEEP_ORANGE_500,
      ColorPalette.MD_BROWN_500,
      ColorPalette.MD_BLUE_GRAY_500
    ];
  }

  static getBaseColors(): number[] {
    return [
      ColorPalette.MD_RED_500,
      ColorPalette.MD_PINK_500,
      ColorPalette.MD_PURPLE_500,
      ColorPalette.MD_DEEP_PURPLE_500,
      ColorPalette.MD_INDIGO_500,
      ColorPalette.MD_BLUE_500,
      ColorPalette.MD_LIGHT_BLUE_500,
      ColorPalette.MD_CYAN_500,
      ColorPalette.MD_TEAL_500,
      ColorPalette.MD_GREEN_500,
      ColorPalette.MD_LIGHT_GREEN_500,
      ColorPalette.MD_LIME_500,
      ColorPalette.MD_YELLOW_500,
      ColorPalette.MD_AMBER_500,
      ColorPalette.MD_ORANGE_500,
      ColorPalette.MD_DEEP_ORANGE_500,
      ColorPalette.MD_BROWN_500,
      ColorPalette.MD_BLUE_GRAY_500,
      ColorPalette.MD_GRAY_500
    ];
  }

  static getObscuredColor(c: number): number {
    const r = (c >> 16) & 0xff;
    const g = (c >> 8) & 0xff;
    const b = c & 0xff;
    const hsv = ColorPalette.rgbToHsv(r, g, b);
    hsv[2] *= 0.85;
    return ColorPalette.hsvToColor(hsv[0], hsv[1], hsv[2]);
  }

  static getTransparentColor(color: number, alpha: number): number {
    const a = Math.max(0, Math.min(255, alpha));
    return (color & 0x00ffffff) | (a << 24);
  }

  static getTransparencyShadows(color: number): number[] {
    const shadows: number[] = new Array<number>(10);
    for (let i = 0; i < 10; i++)
      shadows[i] = ColorPalette.getTransparentColor(color, Math.floor(((100 - i * 10) * 255) / 100));
    return shadows;
  }

  static getColors(c: number): number[] {
    if (c === ColorPalette.MD_RED_500) {
      return [ColorPalette.MD_RED_100, ColorPalette.MD_RED_200, ColorPalette.MD_RED_300,
              ColorPalette.MD_RED_400, ColorPalette.MD_RED_500, ColorPalette.MD_RED_600,
              ColorPalette.MD_RED_700, ColorPalette.MD_RED_800, ColorPalette.MD_RED_900];
    } else if (c === ColorPalette.MD_PINK_500) {
      return [ColorPalette.MD_PINK_100, ColorPalette.MD_PINK_200, ColorPalette.MD_PINK_300,
              ColorPalette.MD_PINK_400, ColorPalette.MD_PINK_500, ColorPalette.MD_PINK_600,
              ColorPalette.MD_PINK_700, ColorPalette.MD_PINK_800, ColorPalette.MD_PINK_900];
    } else if (c === ColorPalette.MD_PURPLE_500) {
      return [ColorPalette.MD_PURPLE_100, ColorPalette.MD_PURPLE_200, ColorPalette.MD_PURPLE_300,
              ColorPalette.MD_PURPLE_400, ColorPalette.MD_PURPLE_500, ColorPalette.MD_PURPLE_600,
              ColorPalette.MD_PURPLE_700, ColorPalette.MD_PURPLE_800, ColorPalette.MD_PURPLE_900];
    } else if (c === ColorPalette.MD_DEEP_PURPLE_500) {
      return [ColorPalette.MD_DEEP_PURPLE_100, ColorPalette.MD_DEEP_PURPLE_200, ColorPalette.MD_DEEP_PURPLE_300,
              ColorPalette.MD_DEEP_PURPLE_400, ColorPalette.MD_DEEP_PURPLE_500, ColorPalette.MD_DEEP_PURPLE_600,
              ColorPalette.MD_DEEP_PURPLE_700, ColorPalette.MD_DEEP_PURPLE_800, ColorPalette.MD_DEEP_PURPLE_900];
    } else if (c === ColorPalette.MD_INDIGO_500) {
      return [ColorPalette.MD_INDIGO_100, ColorPalette.MD_INDIGO_200, ColorPalette.MD_INDIGO_300,
              ColorPalette.MD_INDIGO_400, ColorPalette.MD_INDIGO_500, ColorPalette.MD_INDIGO_600,
              ColorPalette.MD_INDIGO_700, ColorPalette.MD_INDIGO_800, ColorPalette.MD_INDIGO_900];
    } else if (c === ColorPalette.MD_BLUE_500) {
      return [ColorPalette.MD_BLUE_100, ColorPalette.MD_BLUE_200, ColorPalette.MD_BLUE_300,
              ColorPalette.MD_BLUE_400, ColorPalette.MD_BLUE_500, ColorPalette.MD_BLUE_600,
              ColorPalette.MD_BLUE_700, ColorPalette.MD_BLUE_800, ColorPalette.MD_BLUE_900];
    } else if (c === ColorPalette.MD_LIGHT_BLUE_500) {
      return [ColorPalette.MD_LIGHT_BLUE_100, ColorPalette.MD_LIGHT_BLUE_200, ColorPalette.MD_LIGHT_BLUE_300,
              ColorPalette.MD_LIGHT_BLUE_400, ColorPalette.MD_LIGHT_BLUE_500, ColorPalette.MD_LIGHT_BLUE_600,
              ColorPalette.MD_LIGHT_BLUE_700, ColorPalette.MD_LIGHT_BLUE_800, ColorPalette.MD_LIGHT_BLUE_900];
    } else if (c === ColorPalette.MD_CYAN_500) {
      return [ColorPalette.MD_CYAN_100, ColorPalette.MD_CYAN_200, ColorPalette.MD_CYAN_300,
              ColorPalette.MD_CYAN_400, ColorPalette.MD_CYAN_500, ColorPalette.MD_CYAN_600,
              ColorPalette.MD_CYAN_700, ColorPalette.MD_CYAN_800, ColorPalette.MD_CYAN_900];
    } else if (c === ColorPalette.MD_TEAL_500) {
      return [ColorPalette.MD_TEAL_100, ColorPalette.MD_TEAL_200, ColorPalette.MD_TEAL_300,
              ColorPalette.MD_TEAL_400, ColorPalette.MD_TEAL_500, ColorPalette.MD_TEAL_600,
              ColorPalette.MD_TEAL_700, ColorPalette.MD_TEAL_800, ColorPalette.MD_TEAL_900];
    } else if (c === ColorPalette.MD_GREEN_500) {
      return [ColorPalette.MD_GREEN_100, ColorPalette.MD_GREEN_200, ColorPalette.MD_GREEN_300,
              ColorPalette.MD_GREEN_400, ColorPalette.MD_GREEN_500, ColorPalette.MD_GREEN_600,
              ColorPalette.MD_GREEN_700, ColorPalette.MD_GREEN_800, ColorPalette.MD_GREEN_900];
    } else if (c === ColorPalette.MD_LIGHT_GREEN_500) {
      return [ColorPalette.MD_LIGHT_GREEN_100, ColorPalette.MD_LIGHT_GREEN_200, ColorPalette.MD_LIGHT_GREEN_300,
              ColorPalette.MD_LIGHT_GREEN_400, ColorPalette.MD_LIGHT_GREEN_500, ColorPalette.MD_LIGHT_GREEN_600,
              ColorPalette.MD_LIGHT_GREEN_700, ColorPalette.MD_LIGHT_GREEN_800, ColorPalette.MD_LIGHT_GREEN_900];
    } else if (c === ColorPalette.MD_LIME_500) {
      return [ColorPalette.MD_LIME_100, ColorPalette.MD_LIME_200, ColorPalette.MD_LIME_300,
              ColorPalette.MD_LIME_400, ColorPalette.MD_LIME_500, ColorPalette.MD_LIME_600,
              ColorPalette.MD_LIME_700, ColorPalette.MD_LIME_800, ColorPalette.MD_LIME_900];
    } else if (c === ColorPalette.MD_YELLOW_500) {
      return [ColorPalette.MD_YELLOW_100, ColorPalette.MD_YELLOW_200, ColorPalette.MD_YELLOW_300,
              ColorPalette.MD_YELLOW_400, ColorPalette.MD_YELLOW_500, ColorPalette.MD_YELLOW_600,
              ColorPalette.MD_YELLOW_700, ColorPalette.MD_YELLOW_800, ColorPalette.MD_YELLOW_900];
    } else if (c === ColorPalette.MD_AMBER_500) {
      return [ColorPalette.MD_AMBER_100, ColorPalette.MD_AMBER_200, ColorPalette.MD_AMBER_300,
              ColorPalette.MD_AMBER_400, ColorPalette.MD_AMBER_500, ColorPalette.MD_AMBER_600,
              ColorPalette.MD_AMBER_700, ColorPalette.MD_AMBER_800, ColorPalette.MD_AMBER_900];
    } else if (c === ColorPalette.MD_ORANGE_500) {
      return [ColorPalette.MD_ORANGE_100, ColorPalette.MD_ORANGE_200, ColorPalette.MD_ORANGE_300,
              ColorPalette.MD_ORANGE_400, ColorPalette.MD_ORANGE_500, ColorPalette.MD_ORANGE_600,
              ColorPalette.MD_ORANGE_700, ColorPalette.MD_ORANGE_800, ColorPalette.MD_ORANGE_900];
    } else if (c === ColorPalette.MD_DEEP_ORANGE_500) {
      return [ColorPalette.MD_DEEP_ORANGE_100, ColorPalette.MD_DEEP_ORANGE_200, ColorPalette.MD_DEEP_ORANGE_300,
              ColorPalette.MD_DEEP_ORANGE_400, ColorPalette.MD_DEEP_ORANGE_500, ColorPalette.MD_DEEP_ORANGE_600,
              ColorPalette.MD_DEEP_ORANGE_700, ColorPalette.MD_DEEP_ORANGE_800, ColorPalette.MD_DEEP_ORANGE_900];
    } else if (c === ColorPalette.MD_BROWN_500) {
      return [ColorPalette.MD_BROWN_100, ColorPalette.MD_BROWN_200, ColorPalette.MD_BROWN_300,
              ColorPalette.MD_BROWN_400, ColorPalette.MD_BROWN_500, ColorPalette.MD_BROWN_600,
              ColorPalette.MD_BROWN_700, ColorPalette.MD_BROWN_800, ColorPalette.MD_BROWN_900];
    } else if (c === ColorPalette.MD_GRAY_500) {
      return [ColorPalette.WHITE, ColorPalette.MD_GRAY_100, ColorPalette.MD_GRAY_200,
              ColorPalette.MD_GRAY_300, ColorPalette.MD_GRAY_400, ColorPalette.MD_GRAY_500,
              ColorPalette.MD_GRAY_600, ColorPalette.MD_GRAY_700, ColorPalette.MD_GRAY_800,
              ColorPalette.MD_GRAY_900, ColorPalette.BLACK];
    } else {
      return [ColorPalette.MD_BLUE_GRAY_100, ColorPalette.MD_BLUE_GRAY_200, ColorPalette.MD_BLUE_GRAY_300,
              ColorPalette.MD_BLUE_GRAY_400, ColorPalette.MD_BLUE_GRAY_500, ColorPalette.MD_BLUE_GRAY_600,
              ColorPalette.MD_BLUE_GRAY_700, ColorPalette.MD_BLUE_GRAY_800, ColorPalette.MD_BLUE_GRAY_900];
    }
  }

  private static rgbToHsv(r: number, g: number, b: number): number[] {
    const rf = r / 255, gf = g / 255, bf = b / 255;
    const max = Math.max(rf, gf, bf);
    const min = Math.min(rf, gf, bf);
    let h = 0;
    const delta = max - min;
    if (delta !== 0) {
      if (max === rf) h = 60 * (((gf - bf) / delta) % 6);
      else if (max === gf) h = 60 * ((bf - rf) / delta + 2);
      else h = 60 * ((rf - gf) / delta + 4);
    }
    if (h < 0) h += 360;
    const s = max === 0 ? 0 : delta / max;
    return [h, s, max];
  }

  private static hsvToColor(h: number, s: number, v: number): number {
    const c = v * s;
    const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
    const m = v - c;
    let rp = 0, gp = 0, bp = 0;
    if (h < 60) { rp = c; gp = x; }
    else if (h < 120) { rp = x; gp = c; }
    else if (h < 180) { gp = c; bp = x; }
    else if (h < 240) { gp = x; bp = c; }
    else if (h < 300) { rp = x; bp = c; }
    else { rp = c; bp = x; }
    const r = Math.round((rp + m) * 255);
    const g = Math.round((gp + m) * 255);
    const b = Math.round((bp + m) * 255);
    return 0xff000000 | (r << 16) | (g << 8) | b;
  }
}
