import { TrainingCase, TrainingSets } from '../model/TrainingData';
import { AppConfig } from '../model/AppConfig';
import { TrainingCaseImage } from './TrainingCaseImage';

function themeText(dark: boolean): string { return dark ? '#e8e8e8' : '#000000'; }
function themeSubText(dark: boolean): string { return dark ? '#9a9a9a' : '#888888'; }
function themeBg(dark: boolean): string { return dark ? '#2a2a2a' : '#f0f0f0'; }

/**
 * 训练视图 - OLL/PLL/F2L 训练打乱
 */
@Component
export struct TrainingView {
  @Prop darkMode: boolean = false;
  @State trainingType: string = 'OLL';
  @State cases: TrainingCase[] = [];
  @State searchText: string = '';
  @State filteredCases: TrainingCase[] = [];
  @State currentCase: TrainingCase | null = null;
  @State showSolution: boolean = false;
  onGenerateScramble?: (scramble: string, puzzle: string) => void;

  aboutToAppear(): void {
    this.loadCases();
  }

  loadCases(): void {
    if (this.trainingType === 'OLL') {
      this.cases = TrainingSets.OLL;
    } else if (this.trainingType === 'PLL') {
      this.cases = TrainingSets.PLL;
    } else {
      this.cases = TrainingSets.F2L;
    }
    this.filterCases();
  }

  filterCases(): void {
    if (this.searchText.trim().length === 0) {
      this.filteredCases = this.cases.slice();
    } else {
      const lower: string = this.searchText.toLowerCase().trim();
      this.filteredCases = this.cases.filter((c: TrainingCase): boolean => {
        return c.name.toLowerCase().includes(lower) ||
          c.setup.toLowerCase().includes(lower);
      });
    }
  }

  build() {
    Column() {
      // 训练类型选择
      Row() {
        ForEach(['OLL', 'PLL', 'F2L'], (type: string): void => {
          Text(type)
            .fontSize(14)
            .fontColor(this.trainingType === type ? '#ffffff' : themeSubText(this.darkMode))
            .fontWeight(this.trainingType === type ? FontWeight.Bold : FontWeight.Normal)
            .backgroundColor(this.trainingType === type ? '#448AFF' : themeBg(this.darkMode))
            .borderRadius(6)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .onClick((): void => {
              this.trainingType = type;
              this.currentCase = null;
              this.searchText = '';
              this.loadCases();
            });
        });
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ top: 8, bottom: 8 });

      // 搜索
      TextInput({ text: this.searchText, placeholder: '搜索 OLL/PLL...' })
        .width('100%')
        .height(36)
        .fontSize(13)
        .backgroundColor(themeBg(this.darkMode))
        .borderRadius(6)
        .margin({ bottom: 8, left: 16, right: 16 })
        .onChange((value: string): void => {
          this.searchText = value;
          this.filterCases();
        });

      if (this.currentCase) {
        // 训练详情
        this.TrainingDetail();
      }

      // 训练列表
      Scroll() {
        Column() {
          Text(`${this.trainingType} 训练 (共${this.filteredCases.length}个)`)
            .fontSize(13)
            .fontColor(themeSubText(this.darkMode))
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 8, bottom: 8 });

          ForEach(this.filteredCases, (item: TrainingCase): void => {
            Row() {
              TrainingCaseImage({ item: item, imageSize: 56 })
                .margin({ right: 10 });

              Column() {
                Text(item.name)
                  .fontSize(14)
                  .fontColor(themeText(this.darkMode))
                  .maxLines(1);

                Text(item.solution)
                  .fontSize(11)
                  .fontColor(themeSubText(this.darkMode))
                  .maxLines(1);
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1);
            }
            .width('100%')
            .height(68)
            .padding({ left: 10, right: 16 })
            .backgroundColor(themeBg(this.darkMode))
            .borderRadius(6)
            .onClick((): void => {
              this.currentCase = item;
              this.showSolution = false;
              if (this.onGenerateScramble) {
                this.onGenerateScramble(item.setup, '3x3');
              }
            });
          });
        }
        .width('100%');
      }
      .width('100%')
      .layoutWeight(1);
    }
    .width('100%');
  }

  @Builder TrainingDetail() {
    Column() {
      Text(this.currentCase!.name)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#448AFF')
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 8 });

      TrainingCaseImage({ item: this.currentCase!, imageSize: 140 })
        .margin({ top: 8, bottom: 8 });

      Text(`Setup: ${this.currentCase!.setup}`)
        .fontSize(13)
        .fontColor(themeText(this.darkMode))
        .width('100%')
        .textAlign(TextAlign.Center)
        .fontFamily('monospace')
        .padding({ top: 4, bottom: 4 });

      Row() {
        Button(this.showSolution ? '隐藏解法' : '显示解法')
          .fontSize(13)
          .fontColor('#ffffff')
          .backgroundColor('#448AFF')
          .height(32)
          .borderRadius(6)
          .onClick((): void => {
            this.showSolution = !this.showSolution;
          });

        Button('下一个')
          .fontSize(13)
          .fontColor('#ffffff')
          .backgroundColor('#448AFF')
          .height(32)
          .borderRadius(6)
          .onClick((): void => {
            let currentIdx: number = this.cases.indexOf(this.currentCase!);
            let nextIdx: number = (currentIdx + 1) % this.cases.length;
            this.currentCase = this.cases[nextIdx];
            this.showSolution = false;
            if (this.onGenerateScramble) {
              this.onGenerateScramble(this.currentCase.setup, '3x3');
            }
          });

        Button('随机')
          .fontSize(13)
          .fontColor('#ffffff')
          .backgroundColor('#448AFF')
          .height(32)
          .borderRadius(6)
          .onClick((): void => {
            let rIdx: number = Math.floor(Math.random() * this.cases.length);
            this.currentCase = this.cases[rIdx];
            this.showSolution = false;
            if (this.onGenerateScramble) {
              this.onGenerateScramble(this.currentCase.setup, '3x3');
            }
          });
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .padding({ top: 4, bottom: 4 });

      if (this.showSolution) {
        Text(`解法: ${this.currentCase!.solution}`)
          .fontSize(14)
          .fontColor('#00cc00')
          .width('100%')
          .textAlign(TextAlign.Center)
          .fontFamily('monospace')
          .padding({ top: 8, bottom: 8 });
      }
    }
    .width('100%')
    .backgroundColor(themeBg(this.darkMode))
    .borderRadius(8)
    .margin({ bottom: 8 });
  }
}
