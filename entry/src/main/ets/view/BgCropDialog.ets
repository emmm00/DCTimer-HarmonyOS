import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { display } from '@kit.ArkUI';
import promptAction from '@ohos.promptAction';

/** 背景图裁剪对话框：拖动调整位置、双指缩放，确认后按屏幕比例裁剪导出 JPEG */
@Component
export struct BgCropDialog {
  srcUri: string = '';
  isDark: boolean = false;
  onConfirm: (path: string) => void = (path: string): void => {};
  onCancel: () => void = (): void => {};

  // 裁剪预览窗口尺寸（vp，宽高比与屏幕一致）
  @State winW: number = 0;
  @State winH: number = 0;
  // 手势状态
  @State zoomScale: number = 1;
  @State offX: number = 0;
  @State offY: number = 0;
  @State loading: boolean = true;
  @State loadError: boolean = false;
  @State exporting: boolean = false;
  // 原图尺寸（px）与铺满窗口的基础缩放
  private imgW0: number = 0;
  private imgH0: number = 0;
  private coverScale: number = 1;
  private pinchStartScale: number = 1;
  private panStartX: number = 0;
  private panStartY: number = 0;

  aboutToAppear(): void {
    this.setupWindow();
    this.loadImageSize();
  }

  /** 预览窗口：屏幕宽高比，宽度留边，高度不超过屏幕高的 2/3 */
  setupWindow(): void {
    try {
      const d: display.Display = display.getDefaultDisplaySync();
      const screenWVp: number = d.width / d.densityPixels;
      const screenHVp: number = d.height / d.densityPixels;
      let w: number = screenWVp - 24;
      let h: number = w * d.height / d.width;
      const maxH: number = screenHVp * 2 / 3;
      if (h > maxH) {
        h = maxH;
        w = h * d.width / d.height;
      }
      this.winW = Math.floor(w);
      this.winH = Math.floor(h);
    } catch (err) {
      this.winW = 336;
      this.winH = 480;
    }
  }

  async loadImageSize(): Promise<void> {
    try {
      const srcFile: fileIo.File = fileIo.openSync(this.srcUri, fileIo.OpenMode.READ_ONLY);
      const source: image.ImageSource = image.createImageSource(srcFile.fd);
      const info: image.ImageInfo = await source.getImageInfo();
      this.imgW0 = info.size.width;
      this.imgH0 = info.size.height;
      this.coverScale = Math.max(this.winW / this.imgW0, this.winH / this.imgH0);
      await source.release();
      fileIo.closeSync(srcFile);
      this.loading = false;
    } catch (err) {
      this.loadError = true;
    }
  }

  /** 当前图片显示尺寸（vp） */
  dispW(): number {
    return this.imgW0 * this.coverScale * this.zoomScale;
  }

  dispH(): number {
    return this.imgH0 * this.coverScale * this.zoomScale;
  }

  /** 限制平移范围：图片始终铺满窗口（cover 效果，不出白边） */
  clampOffsets(): void {
    const maxX: number = Math.max(0, (this.dispW() - this.winW) / 2);
    this.offX = Math.max(-maxX, Math.min(this.offX, maxX));
    const maxY: number = Math.max(0, (this.dispH() - this.winH) / 2);
    this.offY = Math.max(-maxY, Math.min(this.offY, maxY));
  }

  /** 按窗口比例裁剪原图并导出 JPEG 到应用沙箱，返回文件绝对路径 */
  async exportCrop(): Promise<void> {
    this.exporting = true;
    try {
      const dispScale: number = this.coverScale * this.zoomScale;
      let cropW: number = Math.min(Math.round(this.winW / dispScale), this.imgW0);
      let cropH: number = Math.min(Math.round(this.winH / dispScale), this.imgH0);
      let cropX: number = Math.round((this.dispW() / 2 - this.winW / 2 - this.offX) / dispScale);
      let cropY: number = Math.round((this.dispH() / 2 - this.winH / 2 - this.offY) / dispScale);
      cropX = Math.max(0, Math.min(cropX, this.imgW0 - cropW));
      cropY = Math.max(0, Math.min(cropY, this.imgH0 - cropH));

      const srcFile: fileIo.File = fileIo.openSync(this.srcUri, fileIo.OpenMode.READ_ONLY);
      const source: image.ImageSource = image.createImageSource(srcFile.fd);
      const region: image.Region = { size: { width: cropW, height: cropH }, x: cropX, y: cropY };
      const opts: image.DecodingOptions = { desiredRegion: region };
      const pm: image.PixelMap = await source.createPixelMap(opts);
      const packer: image.ImagePacker = image.createImagePacker();
      const packOpt: image.PackingOption = { format: 'image/jpeg', quality: 90 };
      const buf: ArrayBuffer = await packer.packing(pm, packOpt);
      await packer.release();
      await source.release();
      fileIo.closeSync(srcFile);
      pm.release();

      const destPath: string = getContext(this).filesDir + '/bg_image_' + Date.now() + '.jpg';
      const dstFile: fileIo.File = fileIo.openSync(destPath,
        fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      fileIo.writeSync(dstFile.fd, buf);
      fileIo.closeSync(dstFile);
      this.onConfirm(destPath);
    } catch (err) {
      this.exporting = false;
      promptAction.showToast({ message: '背景图片处理失败', duration: 2000 });
    }
  }

  build() {
    Column({ space: 16 }) {
      // 顶栏
      Row() {
        Button('取消')
          .fontSize(15)
          .fontColor(this.isDark ? '#e8e8e8' : '#333333')
          .backgroundColor(Color.Transparent)
          .onClick((): void => { this.onCancel(); });

        Text('调整背景')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDark ? '#f0f0f0' : '#111111')
          .layoutWeight(1)
          .textAlign(TextAlign.Center);

        Button(this.exporting ? '处理中' : '应用')
          .fontSize(15)
          .fontColor('#ffffff')
          .backgroundColor(this.exporting ? '#999999' : '#ff6f00')
          .enabled(!this.exporting && !this.loading)
          .onClick((): void => { this.exportCrop(); });
      }
      .width('100%');

      // 裁剪预览窗口
      Stack() {
        if (this.loading) {
          LoadingProgress()
            .width(36)
            .height(36)
            .color('#ff6f00');
        } else if (this.loadError) {
          Text('图片读取失败')
            .fontSize(14)
            .fontColor('#ffffff');
        } else {
          Image(this.srcUri)
            .width(this.dispW())
            .height(this.dispH())
            .objectFit(ImageFit.Fill)
            .translate({ x: this.offX, y: this.offY });
        }
      }
      .width(this.winW)
      .height(this.winH)
      .backgroundColor('#000000')
      .clip(true)
      .borderRadius(8)
      .gesture(
        GestureGroup(GestureMode.Exclusive,
          PinchGesture({ fingers: 2 })
            .onActionStart((): void => { this.pinchStartScale = this.zoomScale; })
            .onActionUpdate((e: GestureEvent): void => {
              this.zoomScale = Math.max(1, Math.min(this.pinchStartScale * e.scale, 8));
              this.clampOffsets();
            }),
          PanGesture({ fingers: 1 })
            .onActionStart((): void => {
              this.panStartX = this.offX;
              this.panStartY = this.offY;
            })
            .onActionUpdate((e: GestureEvent): void => {
              this.offX = this.panStartX + e.offsetX;
              this.offY = this.panStartY + e.offsetY;
              this.clampOffsets();
            })
        )
      );

      Text('拖动调整位置 · 双指缩放')
        .fontSize(13)
        .fontColor(this.isDark ? '#aaaaaa' : '#666666');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.85)')
    .justifyContent(FlexAlign.Center)
    .padding({ left: 12, right: 12 });
  }
}
