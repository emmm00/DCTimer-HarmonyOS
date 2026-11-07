/**
 * FaceChipsRow — 六面色块选择器（圆形色块 + 单字标签）
 * 自定义组件 + @Prop：父组件状态变化时自动刷新选中态。
 * （注意：不能用带参 @Builder 实现 —— ArkUI 中 @Builder 按值传参
 * 时状态变化不会刷新内部 UI，会出现"点不动/锁死"现象。）
 */

export interface FaceOption {
  label: string;
  color: string;
}

const FACE_OPTIONS: FaceOption[] = [
  { label: '白', color: '#eeeeee' },
  { label: '黄', color: '#ffd54f' },
  { label: '橙', color: '#ff9800' },
  { label: '红', color: '#f44336' },
  { label: '绿', color: '#4caf50' },
  { label: '蓝', color: '#2196f3' }
];

@Component
export struct FaceChipsRow {
  @Prop selected: number;
  @Prop isDark: boolean;
  onPick: (idx: number) => void = (idx: number): void => {};

  build() {
    Row() {
      ForEach(FACE_OPTIONS, (opt: FaceOption, idx: number) => {
        Column() {
          Circle({ width: 26, height: 26 })
            .fill(opt.color)
            .stroke(this.selected === idx ? '#FFFFFF' : (this.isDark ? '#555555' : '#cccccc'))
            .strokeWidth(this.selected === idx ? 3 : 1)
            .margin({ bottom: 2 });
          Text(opt.label)
            .fontSize(11)
            .fontColor(this.selected === idx ? (this.isDark ? '#e8e8e8' : '#000000') :
              (this.isDark ? '#9a9a9a' : '#999999'))
            .fontWeight(this.selected === idx ? FontWeight.Bold : FontWeight.Normal);
        }
        .padding(4)
        .borderRadius(6)
        .backgroundColor(this.selected === idx ? (this.isDark ? '#2a2a3a' : '#eef3ff') : Color.Transparent)
        .margin({ right: 4 })
        .onClick((): void => { this.onPick(idx); });
      });
    }
    .width('100%')
    .justifyContent(FlexAlign.Center);
  }
}