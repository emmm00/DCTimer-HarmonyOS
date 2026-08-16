import router from '@ohos.router';

@Entry
@Component
struct SettingsPage {
  @State inspectionTime: number = 15;
  @State soundEnabled: boolean = true;
  @State vibrationEnabled: boolean = true;
  @State autoScramble: boolean = true;
  @State autoSave: boolean = false;

  build() {
    Column({ space: 0 }) {
      Row({ space: 20 }) {
        Button('返回')
          .width(60)
          .height(40)
          .backgroundColor('#222222')
          .fontSize(14)
          .fontColor('#999999')
          .borderRadius(20)
          .onClick(() => {
            router.back();
          });

        Text('设置')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff');
      }
      .width('100%')
      .padding({ top: 20, left: 20, right: 20 })
      .justifyContent(FlexAlign.Start);

      Column({ space: 1 }) {
        SettingItem({ title: '观察时间', subtitle: this.inspectionTime + '秒' });
        Slider({
          value: this.inspectionTime,
          min: 0,
          max: 30,
          step: 1,
          style: SliderStyle.OutSet
        })
          .width('80%')
          .blockColor('#00bcd4')
          .trackColor('#333333')
          .selectedColor('#00bcd4')
          .onChange((value: number) => {
            this.inspectionTime = value;
          });
      }
      .width('100%')
      .backgroundColor('#222222')
      .margin({ top: 20 })
      .padding({ left: 20, right: 20, top: 15, bottom: 15 });

      SettingSwitch({ title: '声音', subtitle: '计时提示音', value: this.soundEnabled, onChange: (value: boolean) => {
        this.soundEnabled = value;
      } })

      SettingSwitch({ title: '震动', subtitle: '计时震动反馈', value: this.vibrationEnabled, onChange: (value: boolean) => {
        this.vibrationEnabled = value;
      } })

      SettingSwitch({ title: '自动打乱', subtitle: '完成后自动生成新打乱', value: this.autoScramble, onChange: (value: boolean) => {
        this.autoScramble = value;
      } })

      SettingSwitch({ title: '自动保存', subtitle: '自动保存计时结果', value: this.autoSave, onChange: (value: boolean) => {
        this.autoSave = value;
      } })

      SettingItem({ title: '配色方案', subtitle: '自定义魔方配色' });

      SettingItem({ title: '字体大小', subtitle: '调整显示字体大小' });

      SettingItem({ title: '数据管理', subtitle: '导入/导出/备份数据' });

      SettingItem({ title: '关于', subtitle: 'DCTimer v1.0.0' });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000');
  }
}

@Component
struct SettingItem {
  title: string = '';
  subtitle: string = '';

  build() {
    Row({ space: 10 }) {
      Column({ space: 5 }) {
        Text(this.title)
          .fontSize(18)
          .fontColor('#ffffff');
        Text(this.subtitle)
          .fontSize(14)
          .fontColor('#999999');
      }
      .flexGrow(1);

      Text('>')
        .fontSize(18)
        .fontColor('#666666');
    }
    .width('100%')
    .height(60)
    .backgroundColor('#222222')
    .padding({ left: 20, right: 20 })
    .margin({ top: 1 });
  }
}

@Component
struct SettingSwitch {
  title: string = '';
  subtitle: string = '';
  value: boolean = false;
  onChange: (value: boolean) => void = () => { };

  build() {
    Row({ space: 10 }) {
      Column({ space: 5 }) {
        Text(this.title)
          .fontSize(18)
          .fontColor('#ffffff');
        Text(this.subtitle)
          .fontSize(14)
          .fontColor('#999999');
      }
      .flexGrow(1);

      Toggle({ type: ToggleType.Switch, isOn: this.value })
        .selectedColor('#00bcd4')
        .switchPointColor('#ffffff')
        .onChange((value: boolean) => {
          this.onChange(value);
        });
    }
    .width('100%')
    .height(60)
    .backgroundColor('#222222')
    .padding({ left: 20, right: 20 })
    .margin({ top: 1 });
  }
}
