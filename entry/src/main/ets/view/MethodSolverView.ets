/**
 * MethodSolverView — 求解器弹窗容器。
 *
 * 页签按当前魔方类型动态生成（审核问题1：丰富使用场景）：
 *   三阶（33/31/32/34/35）→ 十字 / CFOP / 桥式 / ZZ / Petrus
 *   二阶（22）           → 面法 / 一层法
 *   金字塔（70）          → 金字塔
 *   SQ1（40）            → FTM / TTM
 * 三阶页签沿用 CrossSolverView + min2phase 语义求解器；其余走 AltSolverView，
 * 底层由 AltSolverRunner 在 taskpool 里建表求解，主线程不阻塞。
 */
import { CROSS_FACE_VALUES } from '../util/CrossSolver';
import { AppConfig } from '../model/AppConfig';
import { CrossSolverView } from './CrossSolverView';
import { FaceChipsRow } from './FaceChipsRow';
import { AltSolverView, AltSolverKind } from './AltSolverView';
import { isAltSolver, is222Solver, isPyraminxSolver, solverTabLabels } from '../util/SolverRouting';
import { solveCFOP } from '../solver/CfopSolver';
import { solveRoux } from '../solver/RouxSolver';
import {
  SolveOutput, simplifyMoves, movesToStr, F2lAlternative
} from '../solver/SolverCore';

interface ResultStep {
  name: string;
  count: number;
  alg: string;
}

@Component
export struct MethodSolverView {
  @Prop scramble: string;
  @Prop isDark: boolean;
  /** 当前魔方编码（Index.ets 里的 flatPuzzleCode），决定显示哪些页签 */
  @Prop puzzleCode: number = 33;
  @State tab: number = 0;
  @State cfopBottom: number = MethodSolverView.defaultBottomFace();
  @State cfopFront: number = MethodSolverView.adjFace(MethodSolverView.defaultBottomFace(), 4);
  @State rouxBottom: number = MethodSolverView.defaultBottomFace();
  @State rouxLeft: number = MethodSolverView.adjFace(MethodSolverView.defaultBottomFace(), 2);
  @State cfopResult: SolveOutput | null = null;
  @State rouxResult: SolveOutput | null = null;
  @State cfopMsg: string = '选择底色与前面色后点击"求解"';
  @State rouxMsg: string = '选择底面与左侧后点击"求解"';
  @State cfopCands: F2lAlternative[] = [];
  @State cfopSel: number = 0;

  /**
   * 按魔方类型产出页签。三阶保留原三页 + ZZ/Petrus 两页；其余魔方用
   * AltSolverView 承接，页签名直接反映算法。规则在 util/SolverRouting.ets。
   */
  tabLabels(): string[] {
    return solverTabLabels(this.puzzleCode);
  }

  /** 非三阶魔方整体交给 AltSolverView */
  isAltPuzzle(): boolean {
    return isAltSolver(this.puzzleCode);
  }

  altKind(): number {
    if (is222Solver(this.puzzleCode)) {
      return AltSolverKind.CUBE2_WAY;
    }
    if (isPyraminxSolver(this.puzzleCode)) {
      return AltSolverKind.PYRAMINX;
    }
    return AltSolverKind.SQ1;
  }

  static defaultBottomFace(): number {
    const bottom: number = Math.max(0, Math.min(5, AppConfig.defaultCrossBottom));
    for (let i: number = 0; i < CROSS_FACE_VALUES.length; i++) {
      if (CROSS_FACE_VALUES[i] === bottom) {
        return i;
      }
    }
    return 1;
  }

  // 相对面：UD(0,1) / LR(2,3) / FB(4,5)
  static oppositeFace(f: number): number {
    return f % 2 === 0 ? f + 1 : f - 1;
  }

  // 前面/左侧面必须与底面相邻：既不能相同，也不能相对
  static isAdjFace(bottom: number, cand: number): boolean {
    return cand !== bottom && cand !== MethodSolverView.oppositeFace(bottom);
  }

  // 返回与 bottom 相邻的面，优先取 pref，不合法则回落到固定默认表
  static adjFace(bottom: number, pref: number): number {
    const b: number = Math.max(0, Math.min(5, bottom));
    const p: number = Math.max(0, Math.min(5, pref));
    if (MethodSolverView.isAdjFace(b, p)) {
      return p;
    }
    const tab: number[] = [4, 4, 4, 4, 1, 1]; // 对每个底面都相邻的默认面
    return tab[b];
  }

  async runCfop(forcedOrder?: number[]): Promise<void> {
    this.cfopMsg = '计算中…（正在比较多种 F2L 插入顺序，稍候）';
    try {
      const front: number = MethodSolverView.adjFace(this.cfopBottom, this.cfopFront);
      this.cfopFront = front;
      const out: SolveOutput = await solveCFOP(this.scramble,
        CROSS_FACE_VALUES[this.cfopBottom], CROSS_FACE_VALUES[front], forcedOrder);
      this.cfopResult = out;
      if (out.f2lAlternatives != null && out.f2lAlternatives.length > 0) {
        this.cfopCands = out.f2lAlternatives;
        this.cfopSel = 0;
      }
      if (out.ok) {
        this.cfopMsg = '已求出解法';
      } else {
        this.cfopMsg = out.error;
      }
    } catch (e) {
      this.cfopMsg = 'CFOP 求解失败，请重试';
    }
  }

  pickF2l(idx: number): void {
    if (idx < 0 || idx >= this.cfopCands.length || idx === this.cfopSel) {
      return;
    }
    this.cfopSel = idx;
    this.runCfop(this.cfopCands[idx].order);
  }

  async runRoux(): Promise<void> {
    this.rouxMsg = '计算中…（首次需构建桥式剪枝表，已生成后永久缓存）';
    try {
      const left: number = MethodSolverView.adjFace(this.rouxBottom, this.rouxLeft);
      this.rouxLeft = left;
      const out: SolveOutput = await solveRoux(this.scramble,
        CROSS_FACE_VALUES[this.rouxBottom], CROSS_FACE_VALUES[left]);
      this.rouxResult = out;
      if (out.ok) {
        this.rouxMsg = '已求出解法';
      } else {
        this.rouxMsg = out.error;
      }
    } catch (e) {
      this.rouxMsg = '桥式求解失败，请重试';
    }
  }

  buildSteps(out: SolveOutput): ResultStep[] {
    const steps: ResultStep[] = [];
    for (let i: number = 0; i < out.stages.length; i++) {
      // stages[i].moves 已是握姿坐标系（求解器帧），直接 simplify 展示
      const simp: number[] = simplifyMoves(out.stages[i].moves);
      steps.push({ name: out.stages[i].name, count: simp.length, alg: movesToStr(simp) });
    }
    return steps;
  }

  @Builder StageCard(step: ResultStep) {
    Row() {
      Text(step.name)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isDark ? '#e8e8e8' : '#000000')
        .width(86);
      // 不再限制行数/省略：长公式完整换行显示（外层有滚动容器兜底）
      Text(step.alg.length > 0 ? step.alg : '（无需转动）')
        .fontSize(13)
        .fontColor(this.isDark ? '#cccccc' : '#444444')
        .layoutWeight(1);
      Text(step.count + ' 步')
        .fontSize(12)
        .fontColor('#448AFF')
        .width(48)
        .textAlign(TextAlign.End);
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor(this.isDark ? '#22222d' : '#f6f8fc')
    .borderRadius(8)
    .margin({ bottom: 8 });
  }

  // 多种 F2L 插入顺序 → 用户自选。选中后重新求解（force 该顺序）并刷新各阶段。
  @Builder F2lChooser() {
    Column() {
      Text('F2L 插入顺序（点击切换）')
        .fontSize(12)
        .fontColor(this.isDark ? '#9a9a9a' : '#888888')
        .width('100%')
        .margin({ bottom: 6 });
      // 直接铺在外层 Scroll 里，避免嵌套滚动吞掉手势导致底部完整解法划不到
      ForEach(this.cfopCands, (cand: F2lAlternative, idx: number) => {
        Row() {
          Text(cand.orderName)
            .fontSize(11)
            .fontWeight(this.cfopSel === idx ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.cfopSel === idx ? '#448AFF' : (this.isDark ? '#cccccc' : '#555555'))
            .width(112)
            .textAlign(TextAlign.Center);
          Text(cand.f2lSteps + ' 步')
            .fontSize(11)
            .fontColor('#448AFF')
            .width(40)
            .textAlign(TextAlign.End);
          // F2L 公式同样完整显示，不截断
          Text(cand.f2lAlg)
            .fontSize(12)
            .fontColor(this.isDark ? '#9a9a9a' : '#777777')
            .layoutWeight(1);
        }
        .width('100%')
        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
        .borderRadius(6)
        .backgroundColor(this.cfopSel === idx ? (this.isDark ? '#223048' : '#e3edff') :
          (this.isDark ? '#22222d' : '#f6f8fc'))
        .margin({ bottom: 4 })
        .onClick((): void => { this.pickF2l(idx); });
      });
    }
    .width('100%');
  }

  // ===== CFOP 页签 =====
  @Builder CfopTab() {
    Column() {
      Row() {
        Text('底面:')
          .fontSize(14)
          .fontColor(this.isDark ? '#9a9a9a' : '#666666')
          .width(50);
        FaceChipsRow({
          selected: this.cfopBottom,
          isDark: this.isDark,
          onPick: (idx: number): void => {
            this.cfopBottom = idx;
            this.cfopFront = MethodSolverView.adjFace(idx, this.cfopFront);
          }
        });
      }
      .width('100%')
      .margin({ bottom: 10 });

      Row() {
        Text('前面:')
          .fontSize(14)
          .fontColor(this.isDark ? '#9a9a9a' : '#666666')
          .width(50);
        FaceChipsRow({
          selected: this.cfopFront,
          isDark: this.isDark,
          onPick: (idx: number): void => {
            if (!MethodSolverView.isAdjFace(this.cfopBottom, idx)) {
              return;
            }
            this.cfopFront = idx;
          }
        });
      }
      .width('100%')
      .margin({ bottom: 12 });

      Button('求解')
        .fontSize(14)
        .fontColor('#ffffff')
        .backgroundColor('#448AFF')
        .borderRadius(8)
        .padding({ left: 24, right: 24, top: 8, bottom: 8 })
        .onClick((): void => { this.runCfop(); });

      if (this.cfopResult != null && this.cfopResult!.ok) {
        Column() {
          Row() {
            Text('总步数 ' + this.cfopResult!.totalSteps)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isDark ? '#e8e8e8' : '#000000')
              .layoutWeight(1);
            Text('✓ 验证通过')
              .fontSize(13)
              .fontColor('#00b487');
          }
          .width('100%')
          .margin({ bottom: 4 });
          Text('解法按所选握姿应用：底面朝下、前面朝自己（HTM 口径，U2 计 1 步）')
            .fontSize(11)
            .fontColor(this.isDark ? '#9a9a9a' : '#999999')
            .width('100%')
            .margin({ bottom: 10 });

          // 阶段卡片与 F2L 选择器直接铺排（不内嵌滚动容器，避免嵌套垂直
          // Scroll 互相吞手势）；整个结果卡片由组件最外层唯一滚动区承载，
          // 内容超高时滚动即可划到底部完整解法。
          Column() {
            ForEach(this.buildSteps(this.cfopResult!), (step: ResultStep) => {
              this.StageCard(step);
            });
          }
          .width('100%');

          if (this.cfopCands.length > 1) {
            this.F2lChooser();
          }

          Divider().color(this.isDark ? '#333333' : '#eeeeee').margin({ top: 6, bottom: 8 });
          Text(this.cfopResult!.userAlg)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isDark ? '#e8e8e8' : '#000000')
            .textAlign(TextAlign.Center)
            .width('100%')
            .lineHeight(24);
        }
        .width('100%')
        .padding(14)
        .backgroundColor(this.isDark ? '#1a1a2e' : '#f0f4ff')
        .borderRadius(8)
        .margin({ top: 12 });
      } else {
        Text(this.cfopMsg)
          .fontSize(14)
          .fontColor(this.isDark ? '#9a9a9a' : '#666666')
          .margin({ top: 20 });
      }
    }
    .width('100%')
    .padding(4);
  }

  // ===== Roux 页签 =====
  @Builder RouxTab() {
    Column() {
      Row() {
        Text('底面:')
          .fontSize(14)
          .fontColor(this.isDark ? '#9a9a9a' : '#666666')
          .width(50);
        FaceChipsRow({
          selected: this.rouxBottom,
          isDark: this.isDark,
          onPick: (idx: number): void => {
            this.rouxBottom = idx;
            this.rouxLeft = MethodSolverView.adjFace(idx, this.rouxLeft);
          }
        });
      }
      .width('100%')
      .margin({ bottom: 10 });

      Row() {
        Text('左侧:')
          .fontSize(14)
          .fontColor(this.isDark ? '#9a9a9a' : '#666666')
          .width(50);
        FaceChipsRow({
          selected: this.rouxLeft,
          isDark: this.isDark,
          onPick: (idx: number): void => {
            if (!MethodSolverView.isAdjFace(this.rouxBottom, idx)) {
              return;
            }
            this.rouxLeft = idx;
          }
        });
      }
      .width('100%')
      .margin({ bottom: 12 });

      Button('求解')
        .fontSize(14)
        .fontColor('#ffffff')
        .backgroundColor('#448AFF')
        .borderRadius(8)
        .padding({ left: 24, right: 24, top: 8, bottom: 8 })
        .onClick((): void => { this.runRoux(); });

      if (this.rouxResult != null && this.rouxResult!.ok) {
        Column() {
          Row() {
            Text('总步数 ' + this.rouxResult!.totalSteps)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isDark ? '#e8e8e8' : '#000000')
              .layoutWeight(1);
            Text('✓ 验证通过')
              .fontSize(13)
              .fontColor('#00b487');
          }
          .width('100%')
          .margin({ bottom: 4 });
          Text('解法按所选握姿应用：底面朝下、左侧朝自己（HTM 口径，M/U2 计 1 步）')
            .fontSize(11)
            .fontColor(this.isDark ? '#9a9a9a' : '#999999')
            .width('100%')
            .margin({ bottom: 10 });

          // 阶段卡片直接平铺（与 CFOP 一致，避免嵌套滚动），由组件最外层
          // 唯一滚动区承载；长公式自动换行完整显示。
          Column() {
            ForEach(this.buildSteps(this.rouxResult!), (step: ResultStep) => {
              this.StageCard(step);
            });
          }
          .width('100%');

          Divider().color(this.isDark ? '#333333' : '#eeeeee').margin({ top: 6, bottom: 8 });
          Text(this.rouxResult!.userAlg)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isDark ? '#e8e8e8' : '#000000')
            .textAlign(TextAlign.Center)
            .width('100%')
            .lineHeight(24);
        }
        .width('100%')
        .padding(14)
        .backgroundColor(this.isDark ? '#1a1a2e' : '#f0f4ff')
        .borderRadius(8)
        .margin({ top: 12 });
      } else {
        Text(this.rouxMsg)
          .fontSize(14)
          .fontColor(this.isDark ? '#9a9a9a' : '#666666')
          .margin({ top: 20 });
      }
    }
    .width('100%')
    .padding(4);
  }

  @Builder TabBar() {
    Row() {
      // 页签数量随魔方类型变化（三阶 5 个、二阶 2 个…），宽度按数量均分，
      // 固定 33.3% 在 5 页签时会溢出到屏幕外。
      ForEach(this.tabLabels(), (name: string, idx: number) => {
        Text(name)
          .fontSize(this.tabLabels().length > 3 ? 13 : 15)
          .fontWeight(this.tab === idx ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.tab === idx ? '#448AFF' : (this.isDark ? '#9a9a9a' : '#666666'))
          .width((100 / this.tabLabels().length).toFixed(2) + '%')
          .textAlign(TextAlign.Center)
          .padding({ top: 8, bottom: 8 })
          .onClick((): void => { this.tab = idx; });
      }, (name: string) => name);
    }
    .width('100%')
    .border({ width: { bottom: 1 }, color: this.isDark ? '#333333' : '#e5e5e5' });
  }

  /** 页签点击后按索引决定渲染内容（三阶专用，非三阶整体走 AltSolverView） */
  @Builder TabContent() {
    if (this.tab === 0) {
      CrossSolverView({
        scramble: this.scramble,
        isDark: this.isDark
      });
    } else if (this.tab === 1) {
      this.CfopTab();
    } else if (this.tab === 2) {
      this.RouxTab();
    } else if (this.tab === 3) {
      // ZZ 法：棱定向 + 底棱
      AltSolverView({
        scramble: this.scramble,
        isDark: this.isDark,
        kind: AltSolverKind.ZZ_EOLINE
      });
    } else {
      // Petrus 法：2x2x2 → 2x2x3
      AltSolverView({
        scramble: this.scramble,
        isDark: this.isDark,
        kind: AltSolverKind.PETRUS
      });
    }
  }

  build() {
    // 外层限高 + 自适应滚动：弹窗整体被限在半屏内，内容（尤其是带长公式的
    // 求解结果）超高时在这里滚动而不是溢出屏幕底部被裁掉（此前"底部的完整
    // 公式显示不全"的根因之一）。
    Scroll() {
      Column() {
        if (this.isAltPuzzle()) {
          // 二阶 / 金字塔 / SQ1：页签与内容都由 AltSolverView 自己管，
          // 外层不再画 TabBar，否则同一组页签会出现两遍。
          AltSolverView({
            scramble: this.scramble,
            isDark: this.isDark,
            kind: this.altKind()
          });
        } else {
          this.TabBar();
          Divider().color(this.isDark ? '#333333' : '#eeeeee');
          this.TabContent();
        }
      }
      .width('100%');
    }
    .width('100%')
    .scrollBar(BarState.Off)
    .constraintSize({ maxHeight: '100%' });
  }
}