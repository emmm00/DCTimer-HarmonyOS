/**
 * 智能魔方 BLE 扫描与连接对话框
 */

import {
  BleManager, BleCallbacks, bleManager
} from '../util/BleManager';
import {
  CubeDeviceInfo, CubeConnectionState, CubeType, CubeMove
} from '../util/SmartCubeProtocol';
import { AppConfig } from '../model/AppConfig';
import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const CUBE_TYPE_NAMES: string[] = ['未知', 'Giiker', 'GAN', '魔域32', '奇艺'];

@CustomDialog
export struct BleScanDialog {
  controller: CustomDialogController;
  @State devices: CubeDeviceInfo[] = [];
  @State isScanning: boolean = false;
  @State connectionState: CubeConnectionState = CubeConnectionState.DISCONNECTED;
  @State statusText: string = '点击扫描搜索智能魔方';
  @State connectedName: string = '';
  onConnected: (address: string, name: string) => void = (): void => {};
  onCubeMove: (move: CubeMove) => void = (): void => {};

  private bleCallbacks: BleCallbacks = {
    onDeviceFound: (devices: CubeDeviceInfo[]): void => {
      this.devices = devices;
    },
    onConnectionStateChange: (state: CubeConnectionState, deviceName: string): void => {
      this.connectionState = state;
      switch (state) {
        case CubeConnectionState.SCANNING:
          this.statusText = '正在扫描...';
          this.isScanning = true;
          break;
        case CubeConnectionState.CONNECTING:
          this.statusText = '正在连接 ' + deviceName + '...';
          break;
        case CubeConnectionState.CONNECTED:
          this.statusText = '已连接 ' + deviceName + '，正在发现服务...';
          break;
        case CubeConnectionState.READY:
          this.statusText = '已就绪: ' + deviceName;
          this.connectedName = deviceName;
          this.isScanning = false;
          break;
        case CubeConnectionState.DISCONNECTED:
          this.statusText = '已断开连接';
          this.connectedName = '';
          break;
      }
    },
    onCubeMove: (move: CubeMove): void => {
      // 连接期间实时转发转动事件给上层，用于驱动 3D 魔方同步
      this.onCubeMove(move);
    },
    onBatteryChange: (level: number): void => {
      // battery update
    },
    onError: (message: string): void => {
      this.statusText = '错误: ' + message;
      this.isScanning = false;
    }
  };

  aboutToAppear(): void {
    this.devices = [];
    this.isScanning = false;
    this.connectionState = bleManager.getConnectionState();
    if (bleManager.getConnectedDeviceAddress().length > 0) {
      this.connectedName = bleManager.getConnectedDeviceName();
      this.statusText = '已连接: ' + this.connectedName;
    }
  }

  aboutToDisappear(): void {
    bleManager.stopScan();
  }

  startScan(): void {
    this.devices = [];
    this.requestPermissionBeforeScan();
  }

  /** BLE 扫描需定位权限，先动态申请再启动扫描，避免首次扫描失败 */
  async requestPermissionBeforeScan(): Promise<void> {
    try {
      const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const result = await atManager.requestPermissionsFromUser(context,
        ['ohos.permission.APPROXIMATELY_LOCATION']);
      const granted: boolean = result.authResults.every(
        (r: number): boolean => r === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED);
      if (granted) {
        bleManager.startScan(this.bleCallbacks);
      } else {
        this.statusText = '需要位置权限才能扫描魔方';
        this.isScanning = false;
      }
    } catch (err) {
      // 权限请求被取消或异常，尝试直接扫描
      bleManager.startScan(this.bleCallbacks);
    }
  }

  connectToDevice(device: CubeDeviceInfo): void {
    bleManager.connect(device);
  }

  disconnectDevice(): void {
    bleManager.disconnect();
    this.connectionState = CubeConnectionState.DISCONNECTED;
    this.statusText = '已断开连接';
    this.connectedName = '';
  }

  confirmConnection(): void {
    const addr: string = bleManager.getConnectedDeviceAddress();
    const name: string = bleManager.getConnectedDeviceName();
    if (addr.length > 0) {
      AppConfig.bleDeviceAddress = addr;
      AppConfig.bleDeviceName = name;
      this.onConnected(addr, name);
    }
    this.controller.close();
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('连接智能魔方')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppConfig.darkMode ? '#e8e8e8' : '#000000')
          .layoutWeight(1);
        Button('×')
          .fontSize(22)
          .fontColor(AppConfig.darkMode ? '#9a9a9a' : '#666666')
          .backgroundColor(Color.Transparent)
          .onClick((): void => { this.controller.close(); });
      }
      .width('100%')
      .margin({ bottom: 12 });

      // 状态文字
      Text(this.statusText)
        .fontSize(13)
        .fontColor(AppConfig.darkMode ? '#9a9a9a' : '#666666')
        .width('100%')
        .margin({ bottom: 12 });

      // 扫描/断开按钮
      if (this.connectionState === CubeConnectionState.READY) {
        Row() {
          Button('断开')
            .fontSize(14)
            .fontColor('#ffffff')
            .backgroundColor('#ee3333')
            .borderRadius(6)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .onClick((): void => { this.disconnectDevice(); });
          Button('确认使用')
            .fontSize(14)
            .fontColor('#ffffff')
            .backgroundColor('#448AFF')
            .borderRadius(6)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .margin({ left: 12 })
            .onClick((): void => { this.confirmConnection(); });
        }
        .margin({ bottom: 12 });
      } else if (this.connectionState === CubeConnectionState.DISCONNECTED) {
        Button(this.isScanning ? '扫描中...' : '开始扫描')
          .fontSize(14)
          .fontColor('#ffffff')
          .backgroundColor('#448AFF')
          .borderRadius(6)
          .padding({ left: 20, right: 20, top: 8, bottom: 8 })
          .enabled(!this.isScanning)
          .onClick((): void => { this.startScan(); });
      } else {
        LoadingProgress()
          .width(32)
          .height(32)
          .color('#448AFF');
      }

      // 设备列表
      if (this.devices.length > 0) {
        Text('发现的设备 (' + this.devices.length + ')')
          .fontSize(12)
          .fontColor(AppConfig.darkMode ? '#7a7a7a' : '#999999')
          .width('100%')
          .margin({ top: 8, bottom: 8 });

        List({ space: 8 }) {
          ForEach(this.devices, (device: CubeDeviceInfo) => {
            ListItem() {
              Row() {
                // 设备类型色点指示
                Circle({ width: 14, height: 14 })
                  .fill(this.getTypeColor(device.type))
                  .stroke('#cccccc')
                  .strokeWidth(1)
                  .margin({ right: 10 });

                Column() {
                  Text(device.name || '未知设备')
                    .fontSize(14)
                    .fontColor(AppConfig.darkMode ? '#e8e8e8' : '#000000')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis });
                  Text(CUBE_TYPE_NAMES[device.type] + ' · ' +
                    device.address.substring(0, 17) + ' · ' + device.rssi + 'dBm')
                    .fontSize(11)
                    .fontColor(AppConfig.darkMode ? '#7a7a7a' : '#999999');
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1);

                Button('连接')
                  .fontSize(12)
                  .fontColor('#ffffff')
                  .backgroundColor('#448AFF')
                  .borderRadius(4)
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .onClick((): void => { this.connectToDevice(device); });
              }
              .width('100%')
              .padding(10)
              .backgroundColor(AppConfig.darkMode ? '#2a2a2a' : '#f5f5f5')
              .borderRadius(8);
            }
          });
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 0 });
      }
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor(AppConfig.darkMode ? '#1e1e1e' : '#ffffff')
    .borderRadius(12);
  }

  getTypeColor(type: CubeType): string {
    switch (type) {
      case CubeType.GAN: return '#4caf50';
      case CubeType.GIIKER: return '#2196f3';
      case CubeType.MOYU32: return '#ff9800';
      case CubeType.QIYI: return '#9c27b0';
      default: return '#ffffff';
    }
  }
}
