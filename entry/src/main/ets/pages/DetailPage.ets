import router from '@ohos.router';

interface Result {
  id: number;
  time: string;
  penalty: number;
  dnf: boolean;
  scramble: string;
  date: string;
}

@Entry
@Component
struct DetailPage {
  @State sessionName: string = '';
  @State results: Result[] = [];
  @State best: string = '--';
  @State avg: string = '--';
  @State ao5: string = '--';

  build() {
    Column({ space: 10 }) {
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

        Text(this.sessionName)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff');
      }
      .width('100%')
      .padding({ top: 20, left: 20, right: 20 })
      .justifyContent(FlexAlign.Start);

      Row({ space: 15 }) {
        StatBadge({ title: 'Best', value: this.best, color: '#4caf50' });
        StatBadge({ title: 'Avg', value: this.avg, color: '#ff9800' });
        StatBadge({ title: 'AO5', value: this.ao5, color: '#00bcd4' });
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .margin({ top: 10 });

      List({ space: 10 }) {
        ForEach(this.results, (result: Result, index: number) => {
          ListItem() {
            ResultCard({ result: result, index: index })
              .onClick(() => {
                this.showResultDetail(result);
              });
          }
        });

        if (this.results.length === 0) {
          ListItem() {
            Column({ space: 10 }) {
              Text('暂无记录')
                .fontSize(16)
                .fontColor('#666666');
            }
            .width('100%')
            .height(120)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center);
          }
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .margin({ top: 10 });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000');
  }

  showResultDetail(result: Result): void {
    console.info('查看详情: ' + result.time);
  }

  aboutToAppear(): void {
    const params = router.getParams();
    if (params && (params as Record<string, number>).id) {
      this.loadSession((params as Record<string, number>).id);
    }
  }

  loadSession(id: number): void {
    this.sessionName = '日常训练';
    this.results = [
      { id: 1, time: '6.23', penalty: 0, dnf: false, scramble: 'U R2 F B R B2 R U2 L B2 U R\' D2 F R\' B R', date: '10:30' },
      { id: 2, time: '7.85', penalty: 0, dnf: false, scramble: 'R U2 F B R B2 R U2 L B2 U R\' D2 F', date: '10:32' },
      { id: 3, time: '5.82', penalty: 0, dnf: false, scramble: 'U R F B R B2 R U2 L B2 U R\' D2 F', date: '10:35' },
      { id: 4, time: '8.12', penalty: 2, dnf: false, scramble: 'R2 F B R B2 R U2 L B2 U R\' D2 F R\'', date: '10:37' },
      { id: 5, time: '6.95', penalty: 0, dnf: false, scramble: 'U R2 F B R B2 R U2 L B2 U R\' D2', date: '10:40' },
      { id: 6, time: 'DNF', penalty: 0, dnf: true, scramble: 'R U2 F B R B2 R U2 L B2', date: '10:42' }
    ];
    this.best = '5.82';
    this.avg = '7.00';
    this.ao5 = '6.74';
  }
}

@Component
struct StatBadge {
  title: string = '';
  value: string = '';
  color: string = '#00bcd4';

  build() {
    Column({ space: 5 }) {
      Text(this.title)
        .fontSize(12)
        .fontColor('#999999');
      Text(this.value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.color);
    }
    .width(80)
    .height(50)
    .backgroundColor('#222222')
    .borderRadius(8)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }
}

@Component
struct ResultCard {
  result: Result = { id: 0, time: '', penalty: 0, dnf: false, scramble: '', date: '' };
  index: number = 0;

  build() {
    Row({ space: 15 }) {
      Text((this.index + 1).toString())
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#666666')
        .width(30);

      Text(this.result.dnf ? 'DNF' : this.result.time)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.result.dnf ? '#f44336' : '#ffffff');

      if (this.result.penalty > 0) {
        Text('+' + this.result.penalty)
          .fontSize(14)
          .fontColor('#ff9800');
      }

      Text(this.result.date)
        .fontSize(14)
        .fontColor('#666666')
        .flexGrow(1)
        .textAlign(TextAlign.End);
    }
    .width('100%')
    .height(45)
    .backgroundColor('#1a1a1a')
    .borderRadius(8)
    .padding({ left: 15, right: 15 })
    .alignItems(VerticalAlign.Center);
  }
}
