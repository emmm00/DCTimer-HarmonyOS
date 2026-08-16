import { AppConfig } from '../model/AppConfig';

/**
 * 背景图片和透明度管理工具
 * 负责持久化背景图片 URI 和透明度设置
 */
export class BackgroundManager {

  /** 获取当前背景图片 URI */
  static getImageUri(): string {
    return AppConfig.bgImageUri;
  }

  /** 设置背景图片 URI */
  static setImageUri(uri: string): void {
    AppConfig.bgImageUri = uri;
  }

  /** 清除背景图片 */
  static clearImage(): void {
    AppConfig.bgImageUri = '';
  }

  /** 获取当前透明度 (0-100) */
  static getOpacity(): number {
    return AppConfig.bgOpacity;
  }

  /** 设置透明度 (0-100) */
  static setOpacity(opacity: number): void {
    AppConfig.bgOpacity = Math.max(0, Math.min(100, Math.round(opacity)));
  }

  /** 获取透明度作为 opacity 值 (0.0-1.0) */
  static getOpacityFactor(): number {
    return AppConfig.bgOpacity / 100;
  }

  /** 是否有背景图片 */
  static hasBackground(): boolean {
    return AppConfig.bgImageUri.length > 0;
  }

  /** 获取预设背景列表 */
  static getPresets(): string[] {
    return [];
  }
}
