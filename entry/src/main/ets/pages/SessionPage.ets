import router from '@ohos.router';

interface Session {
  id: number;
  name: string;
  cubeType: string;
  count: number;
  best: string;
  avg: string;
  date: string;
}

@Entry
@Component
struct SessionPage {
  @State sessions: Session[] = [];

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

        Text('训练记录')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff');

        Button('新建')
          .width(60)
          .height(40)
          .backgroundColor('#00bcd4')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')
          .borderRadius(20)
          .onClick(() => {
            this.createSession();
          });
      }
      .width('100%')
      .padding({ top: 20, left: 20, right: 20 })
      .justifyContent(FlexAlign.SpaceBetween);

      List({ space: 10 }) {
        ForEach(this.sessions, (session: Session) => {
          ListItem() {
            SessionCard({ session: session })
              .onClick(() => {
                router.pushUrl({ url: 'pages/DetailPage', params: { id: session.id } });
              });
          }
        });

        if (this.sessions.length === 0) {
          ListItem() {
            Column({ space: 10 }) {
              Text('暂无训练记录')
                .fontSize(16)
                .fontColor('#666666');
              Text('点击右上角新建训练')
                .fontSize(14)
                .fontColor('#444444');
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

  createSession(): void {
    const newSession: Session = {
      id: Date.now(),
      name: '训练 ' + (this.sessions.length + 1),
      cubeType: '三阶魔方',
      count: 0,
      best: '--',
      avg: '--',
      date: new Date().toLocaleDateString()
    };
    this.sessions.unshift(newSession);
  }

  aboutToAppear(): void {
    this.loadSessions();
  }

  loadSessions(): void {
    this.sessions = [
      { id: 1, name: '日常训练', cubeType: '三阶魔方', count: 42, best: '5.82', avg: '7.34', date: '2026-07-24' },
      { id: 2, name: '速拧练习', cubeType: '三阶魔方', count: 25, best: '6.15', avg: '7.89', date: '2026-07-23' },
      { id: 3, name: '单手练习', cubeType: '三阶魔方', count: 15, best: '15.32', avg: '18.45', date: '2026-07-22' }
    ];
  }
}

@Component
struct SessionCard {
  session: Session = { id: 0, name: '', cubeType: '', count: 0, best: '', avg: '', date: '' };

  build() {
    Row({ space: 15 }) {
      Column({ space: 5 }) {
        Text(this.session.name)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff');
        Text(this.session.cubeType + ' · ' + this.session.count + '次')
          .fontSize(14)
          .fontColor('#999999');
      }
      .flexGrow(1)
      .alignSelf(ItemAlign.Center);

      Column({ space: 5 }) {
        Text('Best ' + this.session.best)
          .fontSize(14)
          .fontColor('#4caf50');
        Text('Avg ' + this.session.avg)
          .fontSize(14)
          .fontColor('#ff9800');
      }
      .alignSelf(ItemAlign.Center);
    }
    .width('100%')
    .height(80)
    .backgroundColor('#222222')
    .borderRadius(12)
    .padding({ left: 20, right: 20 })
    .justifyContent(FlexAlign.SpaceBetween);
  }
}
