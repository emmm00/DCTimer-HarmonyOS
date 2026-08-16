import router from '@ohos.router';

@Entry
@Component
struct GanRobotPage {
  @State connected: boolean = false;
  @State deviceName: string = '';
  @State battery: number = 0;

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

        Text('GAN 机器人')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff');
      }
      .width('100%')
      .padding({ top: 20, left: 20, right: 20 })
      .justifyContent(FlexAlign.Start);

      if (!this.connected) {
        Column({ space: 20 }) {
          Text('未连接设备')
            .fontSize(18)
            .fontColor('#999999');
          Button('扫描设备')
            .width('60%')
            .height(55)
            .backgroundColor('#00bcd4')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#ffffff')
            .borderRadius(27)
            .onClick(() => {
              this.scanDevices();
            });
        }
        .width('100%')
        .height(200)
        .backgroundColor('#222222')
        .borderRadius(12)
        .padding(20)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);
      } else {
        Column({ space: 15 }) {
          Text('已连接: ' + this.deviceName)
            .fontSize(18)
            .fontColor('#4caf50');
          Text('电量: ' + this.battery + '%')
            .fontSize(16)
            .fontColor('#ffffff');

          Button('断开连接')
            .width('60%')
            .height(50)
            .backgroundColor('#f44336')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#ffffff')
            .borderRadius(25)
            .onClick(() => {
              this.disconnect();
            });
        }
        .width('100%')
        .height(200)
        .backgroundColor('#222222')
        .borderRadius(12)
        .padding(20)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center);

        TextInput({ placeholder: '输入打乱序列' })
          .width('80%')
          .height(50)
          .backgroundColor('#222222')
          .border({ width: 1, color: '#333333' })
          .borderRadius(8)
          .fontSize(16)
          .fontColor('#ffffff')
          .placeholderColor('#666666');

        Button('执行打乱')
          .width('80%')
          .height(55)
          .backgroundColor('#4caf50')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .borderRadius(27)
          .onClick(() => {
            this.executeScramble();
          });
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center);
  }

  scanDevices(): void {
    this.connected = true;
    this.deviceName = 'GAN Robot Pro';
    this.battery = 85;
  }

  disconnect(): void {
    this.connected = false;
    this.deviceName = '';
    this.battery = 0;
  }

  executeScramble(): void {
    console.info('执行打乱');
  }
}
