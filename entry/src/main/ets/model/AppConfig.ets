export class AppConfig {
  // 计时器设置
  static wcaInspection: boolean = true;
  static inspectionAlert: boolean = true;
  static timerAccuracy: number = 0; // 0=厘秒, 1=毫秒
  static enterTime: number = 0; // 0=触屏, 1=手动, 2=Stackmat, 3=智能魔方
  static freezeTime: number = 0; // 冻结延迟（单位50ms）
  static multiPhase: number = 0; // 分段数（0=不分段）
  static showStats: boolean = true;

  // 打乱设置
  static scrambleIdx: number = 2; // 2=3x3
  static showScrambleImage: boolean = true;
  static scrambleFontSize: number = 16; // 打乱公式字号 sp

  // 统计设置
  static avg1Type: number = 0; // 0=average, 1=mean
  static avg1Len: number = 5;
  static avg2Type: number = 0;
  static avg2Len: number = 12;

  // 界面设置
  static timerFont: number = 0; // 0=LCD数码管, 1=系统字体
  static fontSize: number = 72; // 计时器字号
  static colors: number[] = [0xffffffff, 0xff000000, 0xffff00ff, 0xffee3333, 0xff009900, 0xff1e1e1e, 0xffe8e8e8];
  // 主题模式：0=浅色, 1=深色, 2=跟随系统
  static themeMode: number = 0;
  // 当前生效的明暗（主题函数读此项）
  static darkMode: boolean = false;
  // 当前系统是否为深色（跟随系统模式时使用）
  static systemDark: boolean = true;

  // 手势设置
  static swipeType: number[] = [1, 2, 3, 5]; // 左/右/上/下

  // 硬件设置
  static keepScreenOn: boolean = true;
  static vibrateType: number = 1; // 0=关, 1=开始, 2=停止, 3=都开
  static vibrateDuration: number = 50;

  // 蓝牙/智能魔方设置
  static bleDeviceAddress: string = '';
  static bleDeviceName: string = '';
  static bleAutoReconnect: boolean = false;

  // 背景主题设置
  static bgImageUri: string = '';
  static bgOpacity: number = 80; // 0-100, 0=完全透明, 100=完全不透明

  // 隐私政策
  static privacyAgreed: boolean = false;

  // 智能计算器/求解器设置
  static solverType: number = 1; // 0=无, 1=cross, 2=xcross, 3=eoline, 4=roux, 5=petrus, 6=eofc
  static solverCrossSide: number[] = [0]; // 十字底面选择(位掩码)
  static solverPetrusSide: number = 0;
  static solverRouxSide: number = 0;
  static defaultCrossBottom: number = 1; // 0=白 1=黄 2=橙 3=红 4=绿 5=蓝

  // 当前状态
  static sessionIdx: number = 0;
  static sortType: number = 7; // 最新优先

  static getBackgroundColor(): number {
    return AppConfig.darkMode ? AppConfig.colors[5] : AppConfig.colors[0];
  }

  static getTextColor(): number {
    return AppConfig.darkMode ? AppConfig.colors[6] : AppConfig.colors[1];
  }

  static colorToHex(color: number): string {
    const r: number = (color >> 16) & 0xff;
    const g: number = (color >> 8) & 0xff;
    const b: number = color & 0xff;
    return '#' + r.toString(16).padStart(2, '0') + g.toString(16).padStart(2, '0') + b.toString(16).padStart(2, '0');
  }
}
