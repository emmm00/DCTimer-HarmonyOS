import router from '@ohos.router';

@Entry
@Component
struct ResultPage {
  @State time: string = '0.00';
  @State penalty: number = 0;
  @State dnf: boolean = false;
  @State notes: string = '';

  build() {
    Column({ space: 30 }) {
      Button('返回')
        .width(60)
        .height(40)
        .backgroundColor('#222222')
        .fontSize(14)
        .fontColor('#999999')
        .borderRadius(20)
        .margin({ top: 20, left: 20 })
        .alignSelf(ItemAlign.Start)
        .onClick(() => {
          router.back();
        });

      Text('计时结果')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#ffffff')
        .margin({ top: 40 });

      Text(this.time)
        .fontSize(72)
        .fontWeight(FontWeight.Bold)
        .fontColor('#00bcd4');

      Row({ space: 20 }) {
        Button(this.penalty === 2 ? '+2 ✓' : '+2')
          .width(80)
          .height(45)
          .backgroundColor(this.penalty === 2 ? '#ff9800' : '#222222')
          .border({ width: 1, color: '#ff9800' })
          .fontSize(16)
          .fontColor('#ff9800')
          .borderRadius(22)
          .onClick(() => {
            this.penalty = this.penalty === 2 ? 0 : 2;
          });

        Button(this.dnf ? 'DNF ✓' : 'DNF')
          .width(80)
          .height(45)
          .backgroundColor(this.dnf ? '#f44336' : '#222222')
          .border({ width: 1, color: '#f44336' })
          .fontSize(16)
          .fontColor('#f44336')
          .borderRadius(22)
          .onClick(() => {
            this.dnf = !this.dnf;
          });
      }

      TextInput({ placeholder: '添加备注', text: this.notes })
        .width('80%')
        .height(50)
        .backgroundColor('#222222')
        .border({ width: 1, color: '#333333' })
        .borderRadius(8)
        .fontSize(16)
        .fontColor('#ffffff')
        .placeholderColor('#666666')
        .onChange((value: string) => {
          this.notes = value;
        });

      Button('保存')
        .width('80%')
        .height(55)
        .backgroundColor('#4caf50')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#ffffff')
        .borderRadius(27)
        .onClick(() => {
          this.saveResult();
          router.pushUrl({ url: 'pages/Index' });
        });

      Button('丢弃')
        .width('80%')
        .height(55)
        .backgroundColor('#222222')
        .border({ width: 1, color: '#ffffff' })
        .fontSize(20)
        .fontColor('#ffffff')
        .borderRadius(27)
        .onClick(() => {
          router.pushUrl({ url: 'pages/Index' });
        });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center);
  }

  saveResult(): void {
    console.info('保存结果: ' + this.time + ', 罚时: ' + this.penalty + ', DNF: ' + this.dnf);
  }

  aboutToAppear(): void {
    const params = router.getParams();
    if (params && (params as Record<string, string>).time) {
      this.time = (params as Record<string, string>).time;
    }
  }
}
