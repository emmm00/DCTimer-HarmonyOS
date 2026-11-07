import { AbilityConstant, Configuration, ConfigurationConstant, EnvironmentCallback, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0000;

// 系统深色状态的全局存储键，供界面驱动“跟随系统”
export const SYSTEM_DARK_KEY: string = 'dcSystemDark';
// 底部安全区高度（vp）：沉浸式布局下由页面自行避让，供 Index 读取
export const BOTTOM_INSET_KEY: string = 'dcBottomInset';
// 顶部安全区高度（vp）：状态栏高度，沉浸式下同样需要页面避让
export const TOP_INSET_KEY: string = 'dcTopInset';
// 底部最小避让（vp）：审核要求底部控件距屏幕底边不小于 28vp
export const MIN_BOTTOM_INSET_VP: number = 28;

export default class EntryAbility extends UIAbility {
  private envCallbackId: number = -1;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      // 注意：不能调用 setColorMode(COLOR_MODE_NOT_SET)——那会让
      // context.config.colorMode 返回 -1（NOT_SET）而非系统真实值，
      // 导致跟随系统的初始判断和兜底读取全部失效（曾表现为明暗颠倒）。
      AppStorage.setOrCreate(SYSTEM_DARK_KEY,
        this.context.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
      // 应用级实时配置回调：前台时系统切深色/浅色也会立刻收到，
      // UIAbility.onConfigurationUpdate 在真机上可能只在后台/恢复时触发，
      // 这就是"跟随系统不即时响应、需重启才生效"的根因。
      const envCb: EnvironmentCallback = {
        onConfigurationUpdated: (config: Configuration): void => {
          AppStorage.setOrCreate(SYSTEM_DARK_KEY,
            config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
        },
        onMemoryLevel: (): void => {
        }
      };
      this.envCallbackId = this.context.getApplicationContext().on('environment', envCb);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  /** 系统配置（含深色模式）变化时同步到全局存储（后台/恢复场景的兜底） */
  onConfigurationUpdate(newConfig: Configuration): void {
    super.onConfigurationUpdate(newConfig);
    try {
      AppStorage.setOrCreate(SYSTEM_DARK_KEY,
        newConfig.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to sync colorMode. Cause: %{public}s', JSON.stringify(err));
    }
  }

  onDestroy(): void {
    if (this.envCallbackId >= 0) {
      try {
        this.context.getApplicationContext().off('environment', this.envCallbackId);
      } catch (err) {
        hilog.error(DOMAIN, 'testTag', 'Failed to off environment cb. Cause: %{public}s', JSON.stringify(err));
      }
      this.envCallbackId = -1;
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 沉浸式布局：让背景/内容可以铺到状态栏与底部手势条下方，
    // 再由页面按真实安全区高度自行避让（审核问题2 的整改方式）。
    // 注意：开启全屏后组件不再自动避让，所有底部控件必须自行抬高，故这里
    // 同时把安全区高度写入 AppStorage，供 Index 读取并监听变化。
    try {
      const win: window.Window = windowStage.getMainWindowSync();
      win.setWindowLayoutFullScreen(true).catch((err: Error): void => {
        hilog.error(DOMAIN, 'testTag', 'Failed to set layout full screen. Cause: %{public}s',
          JSON.stringify(err));
      });
      this.syncSafeArea(win);
      win.on('avoidAreaChange', (data: window.AvoidAreaOptions): void => {
        this.syncSafeArea(win);
        hilog.info(DOMAIN, 'testTag', 'avoidAreaChange type: %{public}d', data.type);
      });
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to setup immersive layout. Cause: %{public}s',
        JSON.stringify(err));
    }

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  /** 读取顶部/底部安全区并写入全局存储（vp）。
   *  底部同时取 TYPE_NAVIGATION_INDICATOR 与 TYPE_SYSTEM 的较大值，
   *  并按审核要求兜底到 28vp（手势条换算后可能不足 28vp）。 */
  private syncSafeArea(win: window.Window): void {
    try {
      const indicator: window.AvoidArea =
        win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      const sysBar: window.AvoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const bottomPx: number = Math.max(indicator.bottomRect.height, sysBar.bottomRect.height);
      const topPx: number = Math.max(indicator.topRect.height, sysBar.topRect.height);
      const bottomVp: number = Math.max(px2vp(bottomPx), MIN_BOTTOM_INSET_VP);
      const topVp: number = px2vp(topPx);
      AppStorage.setOrCreate(BOTTOM_INSET_KEY, bottomVp);
      AppStorage.setOrCreate(TOP_INSET_KEY, topVp);
    } catch (err) {
      AppStorage.setOrCreate(BOTTOM_INSET_KEY, MIN_BOTTOM_INSET_VP);
      AppStorage.setOrCreate(TOP_INSET_KEY, 0);
      hilog.error(DOMAIN, 'testTag', 'Failed to read avoid area. Cause: %{public}s', JSON.stringify(err));
    }
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}