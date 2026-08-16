import router from '@ohos.router';

@Entry
@Component
struct GraphPage {
  @State chartData: number[] = [6.2, 5.8, 7.1, 6.5, 5.9, 6.8, 7.2, 6.1, 5.7, 6.3];

  build() {
    Column({ space: 20 }) {
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

        Text('成绩图表')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff');
      }
      .width('100%')
      .padding({ top: 20, left: 20, right: 20 })
      .justifyContent(FlexAlign.Start);

      Column({ space: 10 }) {
        ForEach(this.chartData, (value: number, index: number) => {
          ChartBar({ value: value, maxValue: 8 });
        });
      }
      .width('80%')
      .height(300)
      .backgroundColor('#222222')
      .borderRadius(12)
      .padding(20);

      Text('最近10次成绩趋势')
        .fontSize(16)
        .fontColor('#999999');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center);
  }
}

@Component
struct ChartBar {
  value: number = 0;
  maxValue: number = 10;

  build() {
    Column({ space: 5 }) {
      Stack() {
        Column()
          .width('100%')
          .height(this.maxValue * 30)
          .backgroundColor('#1a1a1a');
        Column()
          .width('100%')
          .height((this.value / this.maxValue) * this.maxValue * 30)
          .backgroundColor('#00bcd4')
          .alignSelf(ItemAlign.End);
      }
      .width(30);
      Text(this.value.toFixed(1))
        .fontSize(12)
        .fontColor('#999999');
    }
    .height(280)
    .alignItems(HorizontalAlign.Center);
  }
}
