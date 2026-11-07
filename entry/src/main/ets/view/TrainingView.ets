/**
 * TrainingView — 公式专项训练
 *
 * 闭环：选集合 → 随机出题 → 计时 → 揭晓参考解法 → 记录成绩 → 下一题
 * 练习数据按「集合 + 题名」存进 preferences 的 trainRecords 键，退出应用不丢。
 */

import dataPreferences from '@ohos.data.preferences';
import { TRAIN_SETS, TrainSet, TrainCase, setupOf } from '../model/TrainingData';

const ACCENT: string = '#448AFF';
const GOOD: string = '#00cc00';
const WARN: string = '#ff9800';

/** 单题训练记录 */
export interface TrainRecord {
  setKey: string;
  caseName: string;
  attempts: number;
  bestMs: number;
  sumMs: number;
  lastMs: number;
  lastAt: number;
}

function tText(dark: boolean): string { return dark ? '#e8e8e8' : '#000000'; }
function tSub(dark: boolean): string { return dark ? '#9a9a9a' : '#666666'; }
function tDiv(dark: boolean): string { return dark ? '#3a3a3a' : '#dddddd'; }
function tCard(dark: boolean): string { return dark ? '#1a1a2e' : '#f0f4ff'; }

/** 毫秒转「12.34」或「1:02.34」 */
function fmtMs(ms: number): string {
  if (ms <= 0) {
    return '--';
  }
  const sec: number = ms / 1000;
  if (sec < 60) {
    return sec.toFixed(2);
  }
  const m: number = Math.floor(sec / 60);
  const s: number = sec - m * 60;
  return m + ':' + (s < 10 ? '0' : '') + s.toFixed(2);
}

@Component
export struct TrainingView {
  @Prop isDark: boolean = false;
  /** 0 未开始 / 1 计时中 / 2 已完成 */
  @State phase: number = 0;
  @State setIdx: number = 0;
  @State caseIdx: number = 0;
  @State elapsed: number = 0;
  @State lastMs: number = 0;
  @State records: TrainRecord[] = [];
  @State loaded: boolean = false;

  private startAt: number = 0;
  private timerId: number = -1;
  private prefs: dataPreferences.Preferences | null = null;

  aboutToAppear(): void {
    this.openPrefs();
    this.pickNext(false);
  }

  aboutToDisappear(): void {
    this.stopTicker();
  }

  private openPrefs(): void {
    try {
      this.prefs = dataPreferences.getPreferencesSync(getContext(this), { name: 'dctimer_data' });
      this.loadRecords();
    } catch (err) {
      this.loaded = true;
    }
  }

  private loadRecords(): void {
    if (this.prefs === null) {
      this.loaded = true;
      return;
    }
    try {
      const raw: string = this.prefs.getSync('trainRecords', '[]') as string;
      const arr: TrainRecord[] = JSON.parse(raw) as TrainRecord[];
      if (arr !== null && arr !== undefined) {
        this.records = arr;
      }
    } catch (err) {
      this.records = [];
    }
    this.loaded = true;
  }

  private saveRecords(): void {
    if (this.prefs === null) {
      return;
    }
    try {
      this.prefs.putSync('trainRecords', JSON.stringify(this.records));
      this.prefs.flush();
    } catch (err) {
      // 存不进去就算了，不影响练习
    }
  }

  private currentSet(): TrainSet {
    return TRAIN_SETS[this.setIdx];
  }

  private currentCase(): TrainCase {
    const set: TrainSet = this.currentSet();
    const idx: number = Math.min(Math.max(this.caseIdx, 0), set.cases.length - 1);
    return set.cases[idx];
  }

  private pickNext(avoidSame: boolean): void {
    const set: TrainSet = this.currentSet();
    const n: number = set.cases.length;
    if (n <= 1) {
      this.caseIdx = 0;
      return;
    }
    let next: number = this.caseIdx;
    let guard: number = 0;
    while (guard < 32 && (next === this.caseIdx || (avoidSame && next === this.caseIdx))) {
      next = Math.floor(Math.random() * n);
      guard++;
    }
    this.caseIdx = next;
  }

  private onSetChange(i: number): void {
    if (this.phase === 1) {
      return;
    }
    this.setIdx = i;
    this.caseIdx = 0;
    this.phase = 0;
    this.elapsed = 0;
    this.lastMs = 0;
    this.pickNext(false);
  }

  private start(): void {
    this.stopTicker();
    this.phase = 1;
    this.elapsed = 0;
    this.startAt = Date.now();
    this.timerId = setInterval((): void => {
      this.elapsed = Date.now() - this.startAt;
    }, 50);
  }

  private finish(): void {
    this.stopTicker();
    this.elapsed = Date.now() - this.startAt;
    this.lastMs = this.elapsed;
    this.phase = 2;
    this.commitRecord(this.lastMs);
  }

  private stopTicker(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private commitRecord(ms: number): void {
    const c: TrainCase = this.currentCase();
    const key: string = this.currentSet().title + '|' + c.name;
    const next: TrainRecord[] = [];
    let found: boolean = false;
    for (let i: number = 0; i < this.records.length; i++) {
      const r: TrainRecord = this.records[i];
      if (r.setKey + '|' + r.caseName === key) {
        found = true;
        const best: number = r.bestMs > 0 ? Math.min(r.bestMs, ms) : ms;
        next.push({
          setKey: r.setKey, caseName: r.caseName, attempts: r.attempts + 1,
          bestMs: best, sumMs: r.sumMs + ms, lastMs: ms, lastAt: Date.now()
        } as TrainRecord);
      } else {
        next.push(r);
      }
    }
    if (!found) {
      next.push({
        setKey: this.currentSet().title, caseName: c.name, attempts: 1,
        bestMs: ms, sumMs: ms, lastMs: ms, lastAt: Date.now()
      } as TrainRecord);
    }
    this.records = next;
    this.saveRecords();
  }

  private nextCase(): void {
    this.phase = 0;
    this.elapsed = 0;
    this.lastMs = 0;
    this.pickNext(true);
  }

  /** 当前集合的汇总统计 */
  private setStats(): TrainRecord {
    const title: string = this.currentSet().title;
    let attempts: number = 0;
    let sum: number = 0;
    let best: number = 0;
    for (let i: number = 0; i < this.records.length; i++) {
      const r: TrainRecord = this.records[i];
      if (r.setKey === title) {
        attempts += r.attempts;
        sum += r.sumMs;
        if (r.bestMs > 0 && (best === 0 || r.bestMs < best)) {
          best = r.bestMs;
        }
      }
    }
    return {
      setKey: title, caseName: '', attempts: attempts, bestMs: best,
      sumMs: sum, lastMs: 0, lastAt: 0
    } as TrainRecord;
  }

  /** 单题历史（用于揭晓区显示「第几次练 / 最好成绩」） */
  private caseRecord(): TrainRecord | null {
    const key: string = this.currentSet().title + '|' + this.currentCase().name;
    for (let i: number = 0; i < this.records.length; i++) {
      const r: TrainRecord = this.records[i];
      if (r.setKey + '|' + r.caseName === key) {
        return r;
      }
    }
    return null;
  }

  @Builder
  SetChips() {
    Row({ space: 8 }) {
      ForEach(TRAIN_SETS, (s: TrainSet, i: number) => {
        Column() {
          Text(s.title)
            .fontSize(15)
            .fontWeight(this.setIdx === i ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.setIdx === i ? '#ffffff' : tText(this.isDark));
          Text(s.cases.length + ' 条')
            .fontSize(10)
            .fontColor(this.setIdx === i ? '#e8f0ff' : tSub(this.isDark))
            .margin({ top: 2 });
        }
        .layoutWeight(1)
        .padding({ top: 8, bottom: 8 })
        .borderRadius(10)
        .backgroundColor(this.setIdx === i ? ACCENT : (this.isDark ? '#262626' : '#f0f0f0'))
        .onClick((): void => { this.onSetChange(i); });
      }, (s: TrainSet) => s.title);
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .margin({ top: 12 });
  }

  @Builder
  ScrambleCard() {
    Column() {
      Row() {
        Text('打乱')
          .fontSize(12)
          .fontColor(tSub(this.isDark));
        Blank();
        Text(this.currentSet().title + ' · ' + this.currentCase().name)
          .fontSize(12)
          .fontColor(tSub(this.isDark));
      }
      .width('100%')
      .margin({ bottom: 6 });

      Text(setupOf(this.currentCase()))
        .fontSize(17)
        .fontColor(tText(this.isDark))
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .textAlign(TextAlign.Start);
    }
    .width('100%')
    .padding(14)
    .backgroundColor(tCard(this.isDark))
    .borderRadius(12)
    .margin({ top: 12 });
  }

  @Builder
  TimerArea() {
    Column() {
      Text(this.phase === 0 ? '准备' : fmtMs(this.elapsed))
        .fontSize(this.phase === 0 ? 34 : 60)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.phase === 1 ? ACCENT : tText(this.isDark));
      Text(this.phase === 0 ? '点下面「开始」计时' :
        (this.phase === 1 ? '做完点「完成」' : '本次用时（秒）'))
        .fontSize(12)
        .fontColor(tSub(this.isDark))
        .margin({ top: 4 });
    }
    .width('100%')
    .padding({ top: 26, bottom: 26 })
    .justifyContent(FlexAlign.Center);
  }

  @Builder
  Controls() {
    Row({ space: 12 }) {
      if (this.phase === 1) {
        Button('完成')
          .layoutWeight(1)
          .height(46)
          .fontSize(16)
          .fontColor('#ffffff')
          .backgroundColor(GOOD)
          .borderRadius(10)
          .onClick((): void => { this.finish(); });
      } else if (this.phase === 2) {
        Button('下一题')
          .layoutWeight(1)
          .height(46)
          .fontSize(16)
          .fontColor('#ffffff')
          .backgroundColor(ACCENT)
          .borderRadius(10)
          .onClick((): void => { this.nextCase(); });
      } else {
        Button('开始')
          .layoutWeight(1)
          .height(46)
          .fontSize(16)
          .fontColor('#ffffff')
          .backgroundColor(ACCENT)
          .borderRadius(10)
          .onClick((): void => { this.start(); });
        Button('换一题')
          .layoutWeight(1)
          .height(46)
          .fontSize(16)
          .fontColor(tText(this.isDark))
          .backgroundColor(this.isDark ? '#262626' : '#eeeeee')
          .borderRadius(10)
          .onClick((): void => { this.pickNext(true); this.elapsed = 0; });
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16 });
  }

  @Builder
  RevealCard() {
    Column() {
      Row() {
        Text('参考解法')
          .fontSize(12)
          .fontColor(tSub(this.isDark));
        Blank();
        if (this.lastMs > 0) {
          Text('本次 ' + fmtMs(this.lastMs) + 's')
            .fontSize(12)
            .fontColor(WARN);
        }
      }
      .width('100%')
      .margin({ bottom: 6 });

      Text(this.currentCase().alg)
        .fontSize(17)
        .fontColor(tText(this.isDark))
        .fontWeight(FontWeight.Bold)
        .width('100%');

      Divider()
        .color(tDiv(this.isDark))
        .margin({ top: 10, bottom: 8 });

      Row() {
        Text(this.caseRecordText())
          .fontSize(11)
          .fontColor(tSub(this.isDark));
      }
      .width('100%');
    }
    .width('100%')
    .padding(14)
    .backgroundColor(tCard(this.isDark))
    .borderRadius(12)
    .margin({ top: 12 });
  }

  private caseRecordText(): string {
    const r: TrainRecord | null = this.caseRecord();
    if (r === null) {
      return '这一条还没练过';
    }
    const avg: number = r.attempts > 0 ? r.sumMs / r.attempts : 0;
    return '这条已练 ' + r.attempts + ' 次 · 最好 ' + fmtMs(r.bestMs) + 's · 平均 ' + fmtMs(avg) + 's';
  }

  @Builder
  StatsRow() {
    Row() {
      Column() {
        Text('' + this.setStats().attempts)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(tText(this.isDark));
        Text('已练次数')
          .fontSize(11)
          .fontColor(tSub(this.isDark))
          .margin({ top: 2 });
      }
      .layoutWeight(1);

      Divider()
        .vertical(true)
        .height(28)
        .color(tDiv(this.isDark));

      Column() {
        Text(fmtMs(this.setStats().bestMs))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(tText(this.isDark));
        Text('本集合最好')
          .fontSize(11)
          .fontColor(tSub(this.isDark))
          .margin({ top: 2 });
      }
      .layoutWeight(1);

      Divider()
        .vertical(true)
        .height(28)
        .color(tDiv(this.isDark));

      Column() {
        Text(this.setAvgText())
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(tText(this.isDark));
        Text('平均')
          .fontSize(11)
          .fontColor(tSub(this.isDark))
          .margin({ top: 2 });
      }
      .layoutWeight(1);
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .margin({ top: 12 })
    .backgroundColor(this.isDark ? '#262626' : '#fafafa')
    .borderRadius(12);
  }

  private setAvgText(): string {
    const s: TrainRecord = this.setStats();
    if (s.attempts <= 0) {
      return '--';
    }
    return fmtMs(s.sumMs / s.attempts);
  }

  build() {
    Scroll() {
      Column() {
        this.SetChips();
        this.ScrambleCard();
        this.TimerArea();
        this.Controls();
        if (this.phase === 2) {
          this.RevealCard();
        }
        this.StatsRow();
        // 底部留白，避免最后一块贴着手势条
        Row().height(24);
      }
      .width('100%')
      .padding({ bottom: 8 });
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .align(Alignment.Top);
  }
}
