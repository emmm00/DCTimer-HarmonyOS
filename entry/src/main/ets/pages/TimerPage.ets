import router from '@ohos.router';

@Entry
@Component
struct TimerPage {
  @State time: string = '0.00';
  @State isRunning: boolean = false;
  @State isReady: boolean = false;
  @State scramble: string = '';
  @State inspectionTime: number = 0;
  @State isInspection: boolean = false;

  private startTime: number = 0;
  private timerInterval: number | null = null;

  build() {
    Column({ space: 20 }) {
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

      if (this.scramble) {
        Text(this.scramble)
          .fontSize(16)
          .fontColor('#999999')
          .maxLines(3)
          .textAlign(TextAlign.Center)
          .padding({ left: 20, right: 20 });
      }

      Stack() {
        Text(this.time)
          .fontSize(80)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .textAlign(TextAlign.Center);
        if (this.isInspection) {
          Text('观察中')
            .fontSize(24)
            .fontColor('#ff9800')
            .position({ bottom: -40 });
        }
      }
      .margin({ top: 80 });

      Row({ space: 30 }) {
        Button('观察')
          .width(100)
          .height(50)
          .backgroundColor('#222222')
          .border({ width: 1, color: '#ff9800' })
          .fontSize(16)
          .fontColor('#ff9800')
          .borderRadius(25)
          .onClick(() => {
            this.startInspection();
          });

        Button(this.isRunning ? '停止' : '开始')
          .width(120)
          .height(60)
          .backgroundColor(this.isRunning ? '#f44336' : '#4caf50')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .borderRadius(30)
          .onClick(() => {
            if (this.isRunning) {
              this.stopTimer();
            } else {
              this.startTimer();
            }
          });

        Button('重置')
          .width(100)
          .height(50)
          .backgroundColor('#222222')
          .border({ width: 1, color: '#ffffff' })
          .fontSize(16)
          .fontColor('#ffffff')
          .borderRadius(25)
          .onClick(() => {
            this.resetTimer();
          });
      }
      .margin({ top: 100 });

      Button('新打乱')
        .width('60%')
        .height(45)
        .backgroundColor('#222222')
        .fontSize(16)
        .fontColor('#999999')
        .borderRadius(22)
        .onClick(() => {
          this.generateScramble();
        });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center);
  }

  startTimer(): void {
    if (this.isRunning) return;
    this.isRunning = true;
    this.startTime = Date.now();
    this.timerInterval = setInterval(() => {
      const elapsed = (Date.now() - this.startTime) / 1000;
      this.time = elapsed.toFixed(2);
    }, 10);
  }

  stopTimer(): void {
    if (!this.isRunning) return;
    this.isRunning = false;
    if (this.timerInterval) {
      clearInterval(this.timerInterval);
      this.timerInterval = null;
    }
    router.pushUrl({ url: 'pages/ResultPage', params: { time: this.time } });
  }

  resetTimer(): void {
    this.isRunning = false;
    if (this.timerInterval) {
      clearInterval(this.timerInterval);
      this.timerInterval = null;
    }
    this.time = '0.00';
    this.isReady = false;
    this.isInspection = false;
    this.inspectionTime = 0;
  }

  startInspection(): void {
    this.isInspection = true;
    this.inspectionTime = 15;
    this.timerInterval = setInterval(() => {
      this.inspectionTime--;
      if (this.inspectionTime <= 0) {
        this.stopInspection();
      }
    }, 1000);
  }

  stopInspection(): void {
    this.isInspection = false;
    if (this.timerInterval) {
      clearInterval(this.timerInterval);
      this.timerInterval = null;
    }
    this.inspectionTime = 0;
  }

  generateScramble(): void {
    const moves = ['U', 'U\'', 'U2', 'D', 'D\'', 'D2', 'R', 'R\'', 'R2', 'L', 'L\'', 'L2', 'F', 'F\'', 'F2', 'B', 'B\'', 'B2'];
    let scramble = '';
    const length = 20;
    for (let i = 0; i < length; i++) {
      const move = moves[Math.floor(Math.random() * moves.length)];
      scramble += move + ' ';
    }
    this.scramble = scramble.trim();
  }

  aboutToAppear(): void {
    this.generateScramble();
  }

  aboutToDisappear(): void {
    if (this.timerInterval) {
      clearInterval(this.timerInterval);
      this.timerInterval = null;
    }
  }
}
