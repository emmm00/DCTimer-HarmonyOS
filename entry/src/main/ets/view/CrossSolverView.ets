/**
 * 十字求解器 UI 组件
 * 显示在当前打乱条件下指定底面的十字最优解
 */

import { solveCross, CROSS_FACE_OPTIONS, CROSS_FACE_VALUES } from '../util/CrossSolver';
import { AppConfig } from '../model/AppConfig';
import { FaceChipsRow } from './FaceChipsRow';

@Component
export struct CrossSolverView {
  @Prop scramble: string;
  @Prop isDark: boolean;
  @State selectedFaceIdx: number = CrossSolverView.defaultBottomIndex();
  @State title: string = '黄底（绿朝前）';
  @State solution: string = '点击"求解"开始计算';

  static defaultBottomIndex(): number {
    const bottom: number = Math.max(0, Math.min(5, AppConfig.defaultCrossBottom));
    for (let i: number = 0; i < CROSS_FACE_VALUES.length; i++) {
      if (CROSS_FACE_VALUES[i] === bottom) {
        return i;
      }
    }
    return 1;
  }

  aboutToAppear(): void {
    this.autoSolve();
  }

  onScrambleChange(): void {
    this.autoSolve();
  }

  autoSolve(): void {
    const bottomFace: number = CROSS_FACE_VALUES[this.selectedFaceIdx];
    const result = solveCross(this.scramble, bottomFace);
    if (result) {
      this.title = result.title;
      this.solution = result.solution;
    } else {
      this.title = CROSS_FACE_OPTIONS[this.selectedFaceIdx];
      this.solution = '未找到解 (超过 9 步)';
    }
  }

  build() {
    Column() {
      // 底面选择（与 CFOP/桥式页签同款色块选择器）
      Row() {
        Text('底面:')
          .fontSize(14)
          .fontColor(this.isDark ? '#9a9a9a' : '#666666')
          .width(50);
        FaceChipsRow({
          selected: this.selectedFaceIdx,
          isDark: this.isDark,
          onPick: (idx: number): void => {
            this.selectedFaceIdx = idx;
            this.autoSolve();
          }
        });
      }
      .width('100%')
      .margin({ bottom: 12 });

      // 求解按钮
      Button('求解')
        .fontSize(14)
        .fontColor('#ffffff')
        .backgroundColor('#448AFF')
        .borderRadius(8)
        .padding({ left: 24, right: 24, top: 8, bottom: 8 })
        .onClick((): void => { this.autoSolve(); });

      // 结果展示
      Column() {
        Text(this.title)
          .fontSize(14)
          .fontColor(this.isDark ? '#9a9a9a' : '#666666')
          .margin({ bottom: 6 });
        Text('按下方持握魔方后，正序执行：')
          .fontSize(12)
          .fontColor(this.isDark ? '#9a9a9a' : '#666666')
          .margin({ bottom: 6 });
        Text(this.solution)
          .fontSize(18)
          .fontColor(this.isDark ? '#e8e8e8' : '#000000')
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .width('100%');
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.isDark ? '#1a1a2e' : '#f0f4ff')
      .borderRadius(8)
      .margin({ top: 12 });
    }
    .width('100%')
    .padding(16);
  }
}
