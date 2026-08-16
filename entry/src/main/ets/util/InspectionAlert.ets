// 观察语音提醒
import { media } from '@kit.MediaKit';

export class InspectionAlertPlayer {
  private static readonly TAG = 'InspectionAlert';
  private currentPlayer: media.AVPlayer | null = null;
  private playing: boolean = false;

  play(textResId: number): void {
    // 使用 TTS 或音频文件播放观察提醒
    // 在鸿蒙中使用 @ohos.multimedia.audio 或 TextToSpeech API
    try {
      this.speakFallback(textResId);
    } catch (e) {
      console.error(InspectionAlertPlayer.TAG + ' 播放失败: ' + e);
    }
  }

  release(): void {
    if (this.currentPlayer) {
      this.currentPlayer.release();
      this.currentPlayer = null;
    }
    this.playing = false;
  }

  private speakFallback(textResId: number): void {
    // TTS 回退: 使用 @ohos.ai.textToSpeech
    // 简化实现: 不做实际播放，仅保持接口
    console.info(InspectionAlertPlayer.TAG + ' speakFallback: ' + textResId);
  }
}
