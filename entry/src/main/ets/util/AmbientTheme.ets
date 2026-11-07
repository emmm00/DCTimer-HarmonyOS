/**
 * 沉浸光感主题（HarmonyOS 7 / API 26 系统材质）。
 *
 * 为什么需要这一层：
 * 1. 材质模糊必须有「内容」做底才看得见。纯色背景下 systemMaterial 等价于一块
 *    半透明白/黑，视觉上等于没开。所以用户没设背景图时，用内置渐变打底。
 * 2. ImmersiveMaterial 会覆盖 backgroundColor / borderWidth / shadow，
 *    且属性顺序上 backgroundColor 若写在 systemMaterial 之后会盖掉材质，
 *    所以凡是套材质的组件都要走这里的 helper，不能各自写 backgroundColor。
 * 3. 设备能力、全局材质开关都要在运行时判断，不能假定支持。
 */
import { uiMaterial } from '@kit.ArkUI';

/** linearGradient 的 colors 要求元组数组，不能是二维数组 */
export type GradientStops = Array<[ResourceColor, number]>;

/** 内置渐变方案：光感需要层次，单色撑不起来 */
export interface GradientScheme {
  id: string;
  name: string;
  /** [颜色, 位置0~1] 元组数组，交给 linearGradient 用 */
  light: GradientStops;
  dark: GradientStops;
  angle: number;
}

/**
 * 内置渐变方案。
 *
 * 浅色不是纯白、而是带明显色相的粉彩：如果渐变本身接近 #FFFFFF，
 * 上面的半透明白色卡片（blockSurface）叠上去等于白加白，层次全无。
 * 这里保留足够色差，卡片才有「浮在彩色玻璃上」的观感。
 * 黑字压在这些色上对比度仍在 12:1 以上，可读性没问题。
 */
export const GRADIENT_SCHEMES: GradientScheme[] = [
  {
    id: 'aurora',
    name: '极光',
    angle: 135,
    light: [['#D6E4FF', 0.0], ['#C3DAFF', 0.35], ['#CFEBDD', 0.7], ['#E2DCFF', 1.0]],
    dark: [['#0E1A2B', 0.0], ['#122A3D', 0.35], ['#12302C', 0.7], ['#1A1830', 1.0]]
  },
  {
    id: 'sunset',
    name: '暮色',
    angle: 160,
    light: [['#FFE2CC', 0.0], ['#FFCDBB', 0.4], ['#EBD3FF', 0.75], ['#D6E0FF', 1.0]],
    dark: [['#2B1410', 0.0], ['#3A1A22', 0.4], ['#2A1830', 0.75], ['#141A2B', 1.0]]
  },
  {
    id: 'ocean',
    name: '深海',
    angle: 120,
    light: [['#C9ECFF', 0.0], ['#B8E0FC', 0.4], ['#C7D8FF', 0.75], ['#DDD3FF', 1.0]],
    dark: [['#08161F', 0.0], ['#0B2233', 0.4], ['#101E3A', 0.75], ['#1A1430', 1.0]]
  }
];

/** 取渐变方案，id 不匹配时回落第一个 */
export function findScheme(id: string): GradientScheme {
  for (let i = 0; i < GRADIENT_SCHEMES.length; i++) {
    if (GRADIENT_SCHEMES[i].id === id) {
      return GRADIENT_SCHEMES[i];
    }
  }
  return GRADIENT_SCHEMES[0];
}

/** 取当前主题下的渐变色段 */
export function schemeColors(scheme: GradientScheme, dark: boolean): GradientStops {
  return dark ? scheme.dark : scheme.light;
}

/**
 * 当前设备是否真的支持沉浸光感。
 * 必须在调用 systemMaterial 前后都考虑：不支持时退回普通不透明背景，
 * 否则会得到一块"没有内容却半透明"的怪东西，可读性反而变差。
 */
export function materialSupported(): boolean {
  try {
    return uiMaterial.isImmersiveMaterialSupported();
  } catch (e) {
    return false;
  }
}

/** 用户是否在设置里开启了光感效果（默认开） */
export function materialEnabled(cfgOn: boolean): boolean {
  return cfgOn && materialSupported();
}

/**
 * 顶栏材质。
 * 注意 applyShadow: false —— 顶栏紧贴内容区，系统投影会和分割线打架。
 */
export function barMaterial(thin: boolean): uiMaterial.ImmersiveMaterial {
  return new uiMaterial.ImmersiveMaterial({
    style: thin ? uiMaterial.ImmersiveStyle.THIN : uiMaterial.ImmersiveStyle.REGULAR,
    applyShadow: false
  });
}

/** 弹窗/卡片材质：要投影，要交互反馈 */
export function panelMaterial(): uiMaterial.ImmersiveMaterial {
  return new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.REGULAR,
    applyShadow: true,
    interactive: true
  });
}

/** 底部栏材质：比顶栏厚一点，避免手势条区域透得太杂 */
export function bottomBarMaterial(): uiMaterial.ImmersiveMaterial {
  return new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.REGULAR,
    applyShadow: false
  });
}

/**
 * 通用毛玻璃档位（backgroundBlurStyle 用）。
 *
 * 留作备用：当前弹窗用的是 backdropBlur + 自定底色（见 dialogSurface），
 * 因为 backgroundBlurStyle 的 COMPONENT_* 档位自带浅色材质，深色模式下会把
 * 弹窗渲染成浅灰、不跟主题走。若将来需要「系统自适应材质」（宁可牺牲跟随主题
 * 也要系统统一观感），改回这个档位即可。
 */
export function panelBlurStyle(): BlurStyle {
  return BlurStyle.COMPONENT_THICK;
}

/** 顶栏/底部栏的毛玻璃档位：比弹窗薄，内容能从底下透出来（同上，备用） */
export function barBlurStyle(): BlurStyle {
  return BlurStyle.COMPONENT_THIN;
}

/**
 * 弹窗底板色（@CustomDialog 的根容器用）。
 *
 * 为什么不直接用 systemMaterial：ImmersiveMaterial 与 backgroundColor 互斥，
 * @CustomDialog 的根容器必须自带底色（customStyle: true 时系统不提供背景），
 * 两者一撞材质就被盖掉、弹窗变全透视，背后内容直接跟弹窗文字重叠（实测）。
 * 所以弹窗走「backdropBlur 模糊背后 + 自己给半透明底色」这条路，
 * 底色跟着深浅色主题走，观感同样是系统级毛玻璃。
 *
 * 0.82 的依据：再低（0.72）时深色下弹窗和背后的计时数字糊成一片，
 * 再高（0.92）又基本看不出背后内容，0.82 是「知道自己浮在内容上」和「读得清」的交点。
 */
export function dialogSurface(dark: boolean, ambientOn: boolean): string {
  if (!ambientOn) {
    return dark ? '#1e1e1e' : '#ffffff';
  }
  return dark ? 'rgba(26,26,30,0.82)' : 'rgba(255,255,255,0.82)';
}

/** 弹窗背后的模糊半径；光感关闭时为 0（不模糊） */
export function dialogBlurRadius(ambientOn: boolean): number {
  return ambientOn ? 28 : 0;
}

/**
 * 内容区表面色。
 *
 * 为什么光感开启时是全透明：系统材质靠模糊「背后的内容」出效果，而内置渐变本身
 * 就是粉彩（浅色 #E8F0FF 级、深色 #0E1A2B 级），黑字/浅字压上去对比度都在 15:1
 * 以上，完全够读。若在这里再盖一层 90% 白，渐变透出量只剩 10%，通道差被压到
 * 2~3，肉眼等于看不见——实测过，等于白做。
 *
 * 层次靠 blockSurface 的卡片来做，不靠压暗整页。
 */
export function pageSurface(dark: boolean, ambientOn: boolean): string {
  if (!ambientOn) {
    return dark ? '#1e1e1e' : '#ffffff';
  }
  return 'rgba(0,0,0,0)';
}

/**
 * 内容区里的次级块（卡片/行/工具条）。
 *
 * alpha 是「能看见渐变」和「文字有依托」的折中：0.58 在浅色渐变上几乎回变成纯白，
 * 看不到光感；0.45 能透出底色又不至于让文字糊掉。深色侧同理取 0.52。
 */
export function blockSurface(dark: boolean, ambientOn: boolean): string {
  if (!ambientOn) {
    return dark ? '#262626' : '#f5f5f5';
  }
  return dark ? 'rgba(38,38,38,0.52)' : 'rgba(255,255,255,0.45)';
}

