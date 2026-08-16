/**
 * TimerDisplay 组件 - 计时器显示
 * 对应 Android 的 tvTimer (MainActivity)
 * 大字体时间显示，颜色变化：绿色就绪、红色观察、正常计时
 */
@Component
export struct TimerDisplay {
  /** 计时器显示文本，如 "0.00" 或 "12.345" */
  @Prop timerText: string = '0.00'
  /** 计时器状态：'ready' | 'running' | 'inspecting' | 'stopped' */
  @Prop timerState: TimerState = TimerState.STOPPED
  /** 计时器字体大小(px) */
  @Prop fontSize: number = 72
  /** 是否使用等宽字体 */
  @Prop monoFont: boolean = true
  /** 是否显示毫秒 */
  @Prop showMillis: boolean = true
  /** 自定义文本颜色（覆盖状态颜色） */
  @Prop customColor: ResourceColor | null = null

  build() {
    Column() {
      Text(this.timerText)
        .fontSize(this.fontSize)
        .fontFamily(this.monoFont ? 'monospace' : 'sans-serif')
        .fontWeight(FontWeight.Bold)
        .fontColor(this.customColor ?? this.getStateColor())
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        .animation({ duration: 200, curve: Curve.EaseInOut })
        .layoutWeight(1)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  getStateColor(): ResourceColor {
    switch (this.timerState) {
      case TimerState.READY:
        return '#00FF00' // 绿色：就绪
      case TimerState.RUNNING:
        return '#FFFFFF' // 白色：正常计时
      case TimerState.INSPECTING:
        return '#FF4444' // 红色：观察阶段
      case TimerState.STOPPED:
      default:
        return '#CCCCCC' // 灰色：停止
    }
  }
}

/** 计时器状态枚举 */
export enum TimerState {
  STOPPED = 'stopped',
  READY = 'ready',
  RUNNING = 'running',
  INSPECTING = 'inspecting'
}
