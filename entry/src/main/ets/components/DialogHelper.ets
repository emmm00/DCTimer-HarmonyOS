/**
 * DialogHelper 组件 - 通用弹窗集合
 * 对应 Android 的各 Dialog（KeypadDialog, ColorSchemeDialog, ResultDialog, ImportExportDialog, ScrambleDetailDialog 等）
 *
 * 提供：
 * - ColorPickerDialog: 颜色选择弹窗
 * - DeviceSelectDialog: 蓝牙设备选择弹窗
 * - NumberKeypadDialog: 数字键盘输入弹窗
 * - ResultDetailDialog: 成绩详情弹窗
 * - ImportExportDialog: 导入导出弹窗
 * - ConfirmDialog: 通用确认弹窗
 * - InputTextDialog: 文本输入弹窗
 */

/** 通用确认弹窗 */
@CustomDialog
export struct ConfirmDialog {
  controller: CustomDialogController
  title: string = '确认'
  message: string = ''
  confirmText: string = '确定'
  cancelText: string = '取消'
  onConfirm?: () => void
  onCancel?: () => void

  build() {
    Column() {
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 12 })

      Text(this.message)
        .fontSize(14)
        .fontColor('#888888')
        .margin({ bottom: 20 })
        .padding({ left: 20, right: 20 })
        .textAlign(TextAlign.Center)

      Divider().strokeWidth(0.5)

      Row() {
        Button(this.cancelText)
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#007AFF')
          .layoutWeight(1)
          .onClick(() => {
            this.onCancel?.()
            this.controller.close()
          })
        Divider().strokeWidth(0.5).vertical(true).height(44)
        Button(this.confirmText)
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#007AFF')
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .onClick(() => {
            this.onConfirm?.()
            this.controller.close()
          })
      }
      .height(44)
    }
    .width('80%')
    .backgroundColor('#2C2C2E')
    .borderRadius(14)
  }
}

/** 颜色选择弹窗 - 对应 Android ColorSchemeDialog / ColorPickerDialog */
@CustomDialog
export struct ColorPickerDialog {
  controller: CustomDialogController
  title: string = '选择颜色'
  /** 预置颜色列表 */
  presetColors: string[] = [
    '#FF0000', '#FF4500', '#FF8C00', '#FFD700', '#FFFF00',
    '#ADFF2F', '#00FF00', '#00FA9A', '#00CED1', '#00BFFF',
    '#1E90FF', '#0000FF', '#8A2BE2', '#9400D3', '#FF00FF',
    '#FF1493', '#FFFFFF', '#808080', '#000000', '#A52A2A'
  ]
  selectedColor: string = '#FFFFFF'
  onColorSelected?: (color: string) => void

  build() {
    Column() {
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })

      // 预置颜色网格
      Grid() {
        ForEach(this.presetColors, (color: string, index: number) => {
          GridItem() {
            Column() {
              Row()
                .width(36)
                .height(36)
                .backgroundColor(color)
                .borderRadius(18)
                .border({
                  width: this.selectedColor === color ? 3 : 0,
                  color: '#FFFFFF'
                })
            }
            .onClick(() => {
              this.onColorSelected?.(color)
              this.controller.close()
            })
            .padding(4)
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr 1fr')
      .width('100%')
      .padding({ left: 16, right: 16 })
      .height(180)

      Divider().strokeWidth(0.5).margin({ top: 16, bottom: 0 })

      Button('取消')
        .fontSize(16)
        .backgroundColor(Color.Transparent)
        .fontColor('#007AFF')
        .width('100%')
        .height(44)
        .onClick(() => this.controller.close())
    }
    .width('85%')
    .backgroundColor('#2C2C2E')
    .borderRadius(14)
  }
}

/** 蓝牙设备选择弹窗 - 对应 Android BLE 设备扫描结果 */
@CustomDialog
export struct DeviceSelectDialog {
  controller: CustomDialogController
  title: string = '选择设备'
  devices: BLEDeviceInfo[] = []
  isLoading: boolean = false
  onDeviceSelected?: (device: BLEDeviceInfo) => void
  onRefresh?: () => void

  build() {
    Column() {
      Row() {
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)

        Blank()

        Button() {
          Image($r('sys.media.ohos_ic_public_refresh'))
            .width(20)
            .height(20)
            .fillColor('#007AFF')
        }
        .width(32)
        .height(32)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.onRefresh?.())
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 12 })

      if (this.isLoading) {
        LoadingProgress()
          .width(36)
          .height(36)
          .margin({ top: 20, bottom: 20 })
      } else if (this.devices.length === 0) {
        Text('未发现设备')
          .fontSize(14)
          .fontColor('#888888')
          .margin({ top: 20, bottom: 20 })
      } else {
        List() {
          ForEach(this.devices, (device: BLEDeviceInfo) => {
            ListItem() {
              Row() {
                Column() {
                  Text(device.name)
                    .fontSize(15)
                    .fontColor('#FFFFFF')
                  Text(device.address)
                    .fontSize(12)
                    .fontColor('#888888')
                    .margin({ top: 2 })
                }

                Blank()

                Image($r('sys.media.ohos_ic_public_arrow_right'))
                  .width(16)
                  .height(16)
                  .fillColor('#888888')
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 12, bottom: 12 })
            }
            .onClick(() => {
              this.onDeviceSelected?.(device)
              this.controller.close()
            })
          })
        }
        .height(240)
        .width('100%')
      }

      Divider().strokeWidth(0.5)

      Button('取消')
        .fontSize(16)
        .backgroundColor(Color.Transparent)
        .fontColor('#007AFF')
        .width('100%')
        .height(44)
        .onClick(() => this.controller.close())
    }
    .width('85%')
    .backgroundColor('#2C2C2E')
    .borderRadius(14)
  }
}

/** 蓝牙设备信息 */
export interface BLEDeviceInfo {
  name: string
  address: string
  rssi: number
}

/** 数字键盘输入弹窗 - 对应 Android KeypadDialog */
@CustomDialog
export struct NumberKeypadDialog {
  controller: CustomDialogController
  title: string = '输入时间'
  value: string = ''
  hintText: string = '格式: 分:秒.毫秒'
  onConfirm?: (value: string) => void

  build() {
    Column() {
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })

      // 输入显示区
      Text(this.value || this.hintText)
        .fontSize(28)
        .fontColor(this.value ? '#FFFFFF' : '#666666')
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })
        .fontFamily('monospace')

      // 数字键盘
      Grid() {
        ForEach(['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '⌫'], (key: string) => {
          GridItem() {
            Button(key)
              .fontSize(22)
              .width(60)
              .height(48)
              .backgroundColor(key === '⌫' ? '#444444' : '#3A3A3C')
              .fontColor('#FFFFFF')
              .borderRadius(8)
              .onClick(() => {
                if (key === '⌫') {
                  this.value = this.value.slice(0, -1)
                } else {
                  this.value += key
                }
              })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr 1fr')
      .width('100%')
      .padding({ left: 32, right: 32 })
      .height(220)

      Divider().strokeWidth(0.5).margin({ top: 12, bottom: 0 })

      Row() {
        Button('取消')
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#007AFF')
          .layoutWeight(1)
          .height(44)
          .onClick(() => this.controller.close())

        Divider().strokeWidth(0.5).vertical(true).height(44)

        Button('确定')
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#007AFF')
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .height(44)
          .onClick(() => {
            this.onConfirm?.(this.value)
            this.controller.close()
          })
      }
    }
    .width('85%')
    .backgroundColor('#2C2C2E')
    .borderRadius(14)
  }
}

/** 成绩详情弹窗 - 对应 Android ResultDialog */
@CustomDialog
export struct ResultDetailDialog {
  controller: CustomDialogController
  solveIndex: number = 0
  solveTime: string = '12.345'
  scramble: string = 'R U R\' U\' F\' U F'
  date: string = '2024-01-01 12:00'
  memo: string = ''
  penalty: PenaltyType = PenaltyType.NONE
  ao5: string = '12.34'
  ao12: string = '13.45'
  onPenaltyChange?: (penalty: PenaltyType) => void
  onDelete?: () => void
  onDismiss?: () => void

  build() {
    Column() {
      Text(`成绩 #${this.solveIndex + 1}`)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })

      // 时间显示
      Text(this.getDisplayTime())
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getPenaltyColor())
        .fontFamily('monospace')
        .margin({ bottom: 8 })

      // 统计
      Row() {
        this.statItem('AO5', this.ao5)
        this.statItem('AO12', this.ao12)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ bottom: 12 })

      // 打乱
      Row() {
        Text('打乱: ')
          .fontSize(13)
          .fontColor('#888888')
        Text(this.scramble)
          .fontSize(13)
          .fontColor('#FFFFFF')
          .maxLines(2)
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .margin({ bottom: 8 })

      // 日期
      Row() {
        Text('日期: ')
          .fontSize(13)
          .fontColor('#888888')
        Text(this.date)
          .fontSize(13)
          .fontColor('#FFFFFF')
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .margin({ bottom: 16 })

      Divider().strokeWidth(0.5)

      // 罚时按钮
      Row() {
        this.penaltyButton('无', PenaltyType.NONE)
        this.penaltyButton('+2', PenaltyType.PLUS_TWO)
        this.penaltyButton('DNF', PenaltyType.DNF)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .padding({ left: 20, right: 20, top: 8, bottom: 8 })

      Divider().strokeWidth(0.5)

      Row() {
        Button('删除')
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#FF3B30')
          .layoutWeight(1)
          .height(44)
          .onClick(() => {
            this.onDelete?.()
            this.controller.close()
          })

        Divider().strokeWidth(0.5).vertical(true).height(44)

        Button('关闭')
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#007AFF')
          .layoutWeight(1)
          .height(44)
          .onClick(() => {
            this.onDismiss?.()
            this.controller.close()
          })
      }
    }
    .width('85%')
    .backgroundColor('#2C2C2E')
    .borderRadius(14)
  }

  @Builder statItem(label: string, value: string) {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor('#888888')
        .margin({ bottom: 4 })
      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .fontFamily('monospace')
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder penaltyButton(label: string, type: PenaltyType) {
    Button(label)
      .fontSize(14)
      .backgroundColor(this.penalty === type ? '#007AFF' : '#3A3A3C')
      .fontColor(this.penalty === type ? '#FFFFFF' : '#CCCCCC')
      .borderRadius(8)
      .width(60)
      .height(32)
      .onClick(() => {
        this.onPenaltyChange?.(type)
      })
  }

  getDisplayTime(): string {
    switch (this.penalty) {
      case PenaltyType.PLUS_TWO: return this.solveTime + ' +2'
      case PenaltyType.DNF: return 'DNF'
      default: return this.solveTime
    }
  }

  getPenaltyColor(): ResourceColor {
    switch (this.penalty) {
      case PenaltyType.DNF: return '#FF3B30'
      case PenaltyType.PLUS_TWO: return '#FF9500'
      default: return '#FFFFFF'
    }
  }
}

export enum PenaltyType {
  NONE = 'none',
  PLUS_TWO = '+2',
  DNF = 'DNF'
}

/** 导入导出弹窗 - 对应 Android ImportExportDialog */
@CustomDialog
export struct ImportExportDialog {
  controller: CustomDialogController
  title: string = '导入/导出'

  build() {
    Column() {
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })

      Column() {
        this.menuItem('导入成绩 (CSV)', '#34C759')
        this.menuItem('导出成绩 (CSV)', '#007AFF')
        this.menuItem('导入打乱', '#FF9500')
        this.menuItem('导出打乱', '#FF9500')
        this.menuItem('导出数据库', '#AF52DE')
      }
      .width('100%')

      Divider().strokeWidth(0.5).margin({ top: 8 })

      Button('取消')
        .fontSize(16)
        .backgroundColor(Color.Transparent)
        .fontColor('#007AFF')
        .width('100%')
        .height(44)
        .onClick(() => this.controller.close())
    }
    .width('85%')
    .backgroundColor('#2C2C2E')
    .borderRadius(14)
  }

  @Builder menuItem(label: string, color: string) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor(color)
        .padding({ left: 20, right: 20 })
      Blank()
    }
    .width('100%')
    .height(44)
    .onClick(() => {
      this.controller.close()
    })
  }
}

/** 文本输入弹窗 */
@CustomDialog
export struct InputTextDialog {
  controller: CustomDialogController
  title: string = '输入'
  value: string = ''
  placeholder: string = ''
  onConfirm?: (value: string) => void

  build() {
    Column() {
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })

      TextInput({ text: this.value, placeholder: this.placeholder })
        .width('100%')
        .height(40)
        .backgroundColor('#1C1C1E')
        .borderRadius(8)
        .fontSize(14)
        .margin({ left: 20, right: 20, bottom: 16 })
        .onChange((value: string) => {
          this.value = value
        })

      Divider().strokeWidth(0.5)

      Row() {
        Button('取消')
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#007AFF')
          .layoutWeight(1)
          .height(44)
          .onClick(() => this.controller.close())

        Divider().strokeWidth(0.5).vertical(true).height(44)

        Button('确定')
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#007AFF')
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .height(44)
          .onClick(() => {
            this.onConfirm?.(this.value)
            this.controller.close()
          })
      }
    }
    .width('85%')
    .backgroundColor('#2C2C2E')
    .borderRadius(14)
  }
}
