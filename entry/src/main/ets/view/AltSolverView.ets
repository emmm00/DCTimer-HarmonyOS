/**
 * AltSolverView — 非三阶魔方的求解页签（二阶 / 金字塔 / SQ1 / EOLine / Petrus）。
 *
 * 背景（审核问题1）：应用原本只有三阶的十字/CFOP/桥式求解，二审反馈"使用场景
 * 有限"。solver/ 目录里早有 Cube2Face、Cube2Layer、PyraminxV、Sq1Shape 等求解器
 * （Scrambler.updateHint 里甚至已经预留了分发逻辑），只是 UI 从未接出来。本组件
 * 把这些能力按魔方类型暴露成页签。
 *
 * 设计约束：
 *  - 所有求解经 AltSolverRunner 走 taskpool，首屏不建查找表，避免主线程卡死。
 *  - 与 MethodSolverView 一致：外层唯一 Scroll 承载滚动，结果平铺不嵌套滚动区。
 *  - ArkTS 严格子集：不用 any/unknown，不用 as 断言官方 Options。
 */
import { FaceChipsRow } from './FaceChipsRow';
import {
  solveTwoByTwoFace, solveTwoByTwoLayer, solvePyraminx, solveSq1, solveEoline, solvePetrus
} from '../solver/AltSolverRunner';

/** 求解器种类 */
export enum AltSolverKind {
  CUBE2_WAY = 0,   // 二阶：面法 / 一层法
  PYRAMINX = 1,    // 金字塔
  SQ1 = 2,         // Square-1
  ZZ_EOLINE = 3,   // ZZ 法 EOLine
  PETRUS = 4       // Petrus 前两段
}

interface MaskChip {
  label: string;
  color: string;
  bit: number;
}

@Component
export struct AltSolverView {
  @Prop scramble: string;
  @Prop isDark: boolean;
  @Prop kind: number = AltSolverKind.CUBE2_WAY;
  @State subTab: number = 0;
  @State faceMask: number = 1;
  @State busy: boolean = false;
  @State result: string = '';
  @State errText: string = '';

  /** 二阶六面（与 FaceChipsRow 同序：白黄橙红绿蓝） */
  private static readonly CUBE_FACES: MaskChip[] = [
    { label: '白', color: '#eeeeee', bit: 1 },
    { label: '黄', color: '#ffd54f', bit: 2 },
    { label: '橙', color: '#ff9800', bit: 4 },
    { label: '红', color: '#f44336', bit: 8 },
    { label: '绿', color: '#4caf50', bit: 16 },
    { label: '蓝', color: '#2196f3', bit: 32 }
  ];

  /** 金字塔四面 */
  private static readonly PYR_FACES: MaskChip[] = [
    { label: 'D', color: '#4caf50', bit: 1 },
    { label: 'L', color: '#f44336', bit: 2 },
    { label: 'R', color: '#2196f3', bit: 4 },
    { label: 'F', color: '#ffd54f', bit: 8 }
  ];

  /**
   * Petrus 选的是「2x2x2 块」不是面：Petrus.solvePetrus 里 block 的 bit0~bit7
   * 对应 ULF/ULB/URF/URB/DLF/DLB/DRF/DRB 八个角块，bit8 才是"是否继续解 S2"。
   * 所以这里不能用面掩码的 UI。
   */
  private static readonly PETRUS_BLOCKS: MaskChip[] = [
    { label: 'ULF', color: '#eeeeee', bit: 1 },
    { label: 'ULB', color: '#ffd54f', bit: 2 },
    { label: 'URF', color: '#ff9800', bit: 4 },
    { label: 'URB', color: '#f44336', bit: 8 },
    { label: 'DLF', color: '#4caf50', bit: 16 },
    { label: 'DLB', color: '#2196f3', bit: 32 },
    { label: 'DRF', color: '#9c27b0', bit: 64 },
    { label: 'DRB', color: '#795548', bit: 128 }
  ];

  /** Petrus 的 bit8：求完 2x2x2 后是否接着解 2x2x3 */
  @State petrusS2: boolean = true;

  faces(): MaskChip[] {
    if (this.kind === AltSolverKind.PYRAMINX) {
      return AltSolverView.PYR_FACES;
    }
    if (this.kind === AltSolverKind.PETRUS) {
      return AltSolverView.PETRUS_BLOCKS;
    }
    return AltSolverView.CUBE_FACES;
  }

  /** 切换子页签时清掉上一次结果，避免旧解法串到新算法下 */
  resetResult(): void {
    this.result = '';
    this.errText = '';
  }

  toggleBit(bit: number): void {
    this.faceMask = this.faceMask ^ bit;
    this.resetResult();
  }

  async run(): Promise<void> {
    if (this.faceMask === 0) {
      this.errText = this.kind === AltSolverKind.PETRUS ? '请至少选一个角块' : '请至少选择一个面';
      return;
    }
    if (this.scramble.length === 0) {
      this.errText = '当前没有打乱，先回计时页生成一个';
      return;
    }
    this.busy = true;
    this.errText = '';
    this.result = '';
    try {
      let out: string = '';
      if (this.kind === AltSolverKind.CUBE2_WAY) {
        out = this.subTab === 0
          ? await solveTwoByTwoFace(this.scramble, this.faceMask)
          : await solveTwoByTwoLayer(this.scramble, this.faceMask);
      } else if (this.kind === AltSolverKind.PYRAMINX) {
        out = await solvePyraminx(this.scramble, this.faceMask);
      } else if (this.kind === AltSolverKind.SQ1) {
        out = await solveSq1(this.scramble, this.subTab === 0 ? 1 : 2);
      } else if (this.kind === AltSolverKind.ZZ_EOLINE) {
        out = await solveEoline(this.scramble, this.faceMask);
      } else {
        // Petrus：bit8 控制是否顺带解 S2（2x2x3）
        const blockMask: number = this.petrusS2 ? (this.faceMask | 256) : this.faceMask;
        out = await solvePetrus(this.scramble, blockMask);
      }
      const trimmed: string = out.trim();
      if (trimmed.length === 0 || trimmed.indexOf('error') >= 0) {
        this.errText = '这一组选项没解出来，换个面再试';
      } else {
        this.result = trimmed;
      }
    } catch (e) {
      this.errText = '求解失败，可换个面重试';
    } finally {
      this.busy = false;
    }
  }

  @Builder FaceChips() {
    // Petrus 有 8 个角块，单行放不下，用 Flex 自动换行
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
      ForEach(this.faces(), (f: MaskChip) => {
        Column() {
          Circle({ width: 26, height: 26 })
            .fill(f.color)
            .stroke((this.faceMask & f.bit) !== 0 ? '#FFFFFF' :
              (this.isDark ? '#555555' : '#cccccc'))
            .strokeWidth((this.faceMask & f.bit) !== 0 ? 3 : 1)
            .margin({ bottom: 2 });
          Text(f.label)
            .fontSize(11)
            .fontColor((this.faceMask & f.bit) !== 0 ? (this.isDark ? '#e8e8e8' : '#000000') :
              (this.isDark ? '#9a9a9a' : '#999999'))
            .fontWeight((this.faceMask & f.bit) !== 0 ? FontWeight.Bold : FontWeight.Normal);
        }
        .padding(4)
        .borderRadius(6)
        .backgroundColor((this.faceMask & f.bit) !== 0 ?
          (this.isDark ? '#2a2a3a' : '#eef3ff') : Color.Transparent)
        .margin({ right: 4, bottom: 4 })
        .onClick((): void => { this.toggleBit(f.bit); });
      }, (f: MaskChip) => f.label);
    }
    .width('100%');
  }

  @Builder SubTabs(labels: string[]) {
    Row() {
      ForEach(labels, (name: string, idx: number) => {
        Text(name)
          .fontSize(13)
          .fontWeight(this.subTab === idx ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.subTab === idx ? '#448AFF' : (this.isDark ? '#9a9a9a' : '#666666'))
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .padding({ top: 6, bottom: 6 })
          .onClick((): void => {
            this.subTab = idx;
            this.resetResult();
          });
      }, (name: string) => name);
    }
    .width('100%')
    .border({ width: { bottom: 1 }, color: this.isDark ? '#333333' : '#e5e5e5' })
    .margin({ bottom: 10 });
  }

  hintText(): string {
    if (this.kind === AltSolverKind.CUBE2_WAY) {
      return this.subTab === 0
        ? '把一个面整层还原（面法），勾选要算的面'
        : '还原第一层（含侧面颜色），勾选要算的底面';
    } else if (this.kind === AltSolverKind.PYRAMINX) {
      return '把金字塔底面/侧面的三角还原，勾选朝向';
    } else if (this.kind === AltSolverKind.SQ1) {
      return this.subTab === 0 ? 'FTM：按面转 30° 计数' : 'TTM：把扭转也算一步';
    } else if (this.kind === AltSolverKind.ZZ_EOLINE) {
      return '棱定向 + 底棱（ZZ 法第一步），勾选底面';
    }
    return '先搭 2x2x2 块，可再扩到 2x2x3（Petrus 前两段），勾选目标角块';
  }

  build() {
    Column() {
      if (this.kind === AltSolverKind.CUBE2_WAY) {
        this.SubTabs(['面法', '一层法']);
      } else if (this.kind === AltSolverKind.SQ1) {
        this.SubTabs(['FTM', 'TTM']);
      }

      Text(this.hintText())
        .fontSize(11)
        .fontColor(this.isDark ? '#9a9a9a' : '#999999')
        .width('100%')
        .margin({ bottom: 8 });

      // SQ1 不按面枚举，隐藏面选择
      if (this.kind !== AltSolverKind.SQ1) {
        this.FaceChips();
      }

      // Petrus 可选是否顺带解 S2（bit8）
      if (this.kind === AltSolverKind.PETRUS) {
        Row() {
          Text('同时解 S2（2x2x3）')
            .fontSize(12)
            .fontColor(this.isDark ? '#cccccc' : '#444444')
            .layoutWeight(1);
          Toggle({ type: ToggleType.Switch, isOn: this.petrusS2 })
            .selectedColor('#448AFF')
            .onChange((on: boolean): void => {
              this.petrusS2 = on;
              this.resetResult();
            });
        }
        .width('100%')
        .margin({ top: 4 })
        .padding({ left: 6, right: 6 });
      }

      Button(this.busy ? '计算中…' : '求解')
        .fontSize(14)
        .fontColor('#ffffff')
        .backgroundColor(this.busy ? '#90CAF9' : '#448AFF')
        .borderRadius(8)
        .padding({ left: 24, right: 24, top: 8, bottom: 8 })
        .enabled(!this.busy)
        .margin({ top: 4 })
        .onClick((): void => { this.run(); });

      if (this.errText.length > 0) {
        Text(this.errText)
          .fontSize(13)
          .fontColor('#e57373')
          .margin({ top: 12 });
      }

      if (this.result.length > 0) {
        Column() {
          Text('解法（按当前持握正序执行）')
            .fontSize(12)
            .fontColor(this.isDark ? '#9a9a9a' : '#666666')
            .margin({ bottom: 6 });
          Text(this.result)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isDark ? '#e8e8e8' : '#000000')
            .width('100%')
            .lineHeight(24);
        }
        .width('100%')
        .padding(14)
        .backgroundColor(this.isDark ? '#1a1a2e' : '#f0f4ff')
        .borderRadius(8)
        .margin({ top: 12 });
      }
    }
    .width('100%')
    .padding(4);
  }
}
