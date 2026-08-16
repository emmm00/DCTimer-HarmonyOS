import router from '@ohos.router';

@Entry
@Component
struct TestPage {
  @State testText: string = '测试页面';
  @State counter: number = 0;

  build() {
    Column({ space: 30 }) {
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

        Text(this.testText)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff');
      }
      .width('100%')
      .padding({ top: 20, left: 20, right: 20 })
      .justifyContent(FlexAlign.Start);

      Text('计数器: ' + this.counter)
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor('#00bcd4');

      Button('点击计数')
        .width('60%')
        .height(60)
        .backgroundColor('#00bcd4')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#ffffff')
        .borderRadius(30)
        .onClick(() => {
          this.counter++;
        });

      Button('重置')
        .width('60%')
        .height(50)
        .backgroundColor('#222222')
        .border({ width: 1, color: '#ffffff' })
        .fontSize(18)
        .fontColor('#ffffff')
        .borderRadius(25)
        .onClick(() => {
          this.counter = 0;
        });

      Text('项目结构测试')
        .fontSize(18)
        .fontColor('#999999');

      Text('✓ build-profile.json5')
        .fontSize(14)
        .fontColor('#4caf50');

      Text('✓ hvigorfile.ts')
        .fontSize(14)
        .fontColor('#4caf50');

      Text('✓ ohpm.json')
        .fontSize(14)
        .fontColor('#4caf50');

      Text('✓ module.json5')
        .fontSize(14)
        .fontColor('#4caf50');

      Text('✓ EntryAbility.ets')
        .fontSize(14)
        .fontColor('#4caf50');

      Text('✓ 所有页面文件')
        .fontSize(14)
        .fontColor('#4caf50');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center);
  }
}
