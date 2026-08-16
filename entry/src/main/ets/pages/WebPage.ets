import router from '@ohos.router';
import web_webview from '@ohos.web.webview';

@Entry
@Component
struct WebPage {
  controller: web_webview.WebviewController = new web_webview.WebviewController();

  build() {
    Column() {
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

        Text('网页')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff');
      }
      .width('100%')
      .padding({ top: 20, left: 20, right: 20 })
      .justifyContent(FlexAlign.Start);

      Web({ src: 'https://www.dctimer.net', controller: this.controller })
        .width('100%')
        .height('100%');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000');
  }
}
