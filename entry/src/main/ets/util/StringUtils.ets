// Ported from com.dctimer.util.StringUtils.java (pure logic subset, DCTimer-BLE -> HarmonyOS ArkTS)
import { Scrambler } from '../scrambler/Scrambler';
import { AppGlobals } from '../model/AppGlobals';

export class StringUtils {
  static scrambleItems: string[] = [];
  static scrambleSubitems: string[][] = [];

  static getDate(): string {
    const d: Date = new Date();
    const pad = (n: number): string => n.toString().padStart(2, '0');
    return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate()) + ' ' +
      pad(d.getHours()) + ':' + pad(d.getMinutes()) + ':' + pad(d.getSeconds());
  }

  static timeToString(t: number): string {
    return StringUtils.timeToString1(t, true);
  }

  static timeToString1(t: number, showMsec: boolean): string {
    if (t == -2) {
      return 'N/A';
    }
    if (t == -1) {
      return 'DNF';
    }
    if (t < 0) {
      return '-';
    }
    let msec = t % 1000;
    if (AppGlobals.timerAccuracy == 0) {
      msec = Math.floor(msec / 10);
    }
    let sec = Math.floor(t / 1000);
    let min = 0;
    let hour = 0;
    if (AppGlobals.timeFormat < 2) {
      min = Math.floor(sec / 60);
      sec %= 60;
      if (AppGlobals.timeFormat < 1) {
        hour = Math.floor(min / 60);
        min %= 60;
      }
    }
    let sb = '';
    if (hour > 0) {
      sb += hour + ':';
    }
    if (min > 0) {
      if (hour > 0 && min < 10) {
        sb += '0';
      }
      sb += min + ':';
    }
    if (sec < 10 && (hour > 0 || min > 0)) {
      sb += '0';
    }
    sb += sec;
    if (showMsec) {
      if (AppGlobals.decimalMark == 0) {
        sb += '.';
      } else {
        sb += ',';
      }
      if (AppGlobals.timerAccuracy == 1) {
        if (msec < 10) {
          sb += '00';
        } else if (msec < 100) {
          sb += '0';
        }
        sb += msec;
      } else {
        if (msec < 10) {
          sb += '0';
        }
        sb += msec;
      }
    }
    return sb;
  }

  static parseTime(s: string): number {
    if (s == null || s.length == 0) {
      return -1;
    }
    const arr = s.split(':');
    if (arr.length > 3) {
      return -1;
    }
    let hour = 0;
    let min = 0;
    let sec = 0;
    try {
      if (arr.length > 2) {
        hour = parseInt(arr[0]);
        min = parseInt(arr[1]);
        sec = parseFloat(arr[2]);
      } else if (arr.length > 1) {
        min = parseInt(arr[0]);
        sec = parseFloat(arr[1]);
      } else {
        sec = parseFloat(arr[0]);
      }
      if (isNaN(hour) || isNaN(min) || isNaN(sec) || sec < 0 || min < 0 || hour < 0) {
        return -1;
      }
      const numRe: RegExp = /^\d+(\.\d+)?$/;
      if (arr.length > 2 && (!numRe.test(arr[0]) || !numRe.test(arr[1]) || !numRe.test(arr[2]))) {
        return -1;
      }
      if (arr.length === 2 && (!numRe.test(arr[0]) || !numRe.test(arr[1]))) {
        return -1;
      }
      if (arr.length === 1 && !numRe.test(arr[0])) {
        return -1;
      }
      return Math.floor((hour * 3600 + min * 60 + sec) * 1000 + 0.5);
    } catch (e) {
      return -1;
    }
  }

  static parseManualInputTime(s: string): number {
    if (s == null) {
      return -1;
    }
    const time = s.trim();
    if (time.length == 0) {
      return -1;
    }
    if (time.match(/^\d+$/) != null) {
      try {
        const input = parseInt(time);
        const divisor = AppGlobals.timerAccuracy == 1 ? 1000 : 100;
        const whole = Math.floor(input / divisor);
        const fraction = input % divisor;
        const seconds = whole < 100 ? whole : Math.floor(whole / 100) * 60 + whole % 100;
        const value = seconds * 1000 + fraction * (1000 / divisor);
        return value > 2147483647 ? -1 : value;
      } catch (e) {
        return -1;
      }
    }
    return StringUtils.parseTime(time);
  }

  static getImageType(scramble: string): number {
    if (scramble.match(/([URF][2']?\s*)+/) != null) {
      return 2;
    }
    if (scramble.match(/([URLB]'?\s*)+/) != null) {
      return Scrambler.TYPE_SKW;
    }
    if (scramble.match(/([URLBurlb]'?\s*)+/) != null) {
      return Scrambler.TYPE_PYR;
    }
    if (scramble.match(/([xyzURFDLBMurfdlb][2']?\s*)+/) != null) {
      return 3;
    }
    if (scramble.match(/(([xyzURFDLBurf]|[URF]w)[2']?\s*)+/) != null) {
      return 4;
    }
    if (scramble.match(/(([URFDLBurfdlb]|[URFDLB]w)[2']?\s*)+/) != null) {
      return 5;
    }
    if (scramble.match(/((2?[URFDLB]w?|[urfdlb]|3[URF]w?|3[urf])[2']?\s*)+/) != null) {
      return 6;
    }
    if (scramble.match(/(([23]?[URFDLB]w?|3?[urfdlb])[2']?\s*)+/) != null) {
      return 7;
    }
    return 0;
  }

  static getImageType1(scramble: string, type: number): number {
    switch (type) {
      case 1: // 二阶
        return scramble.match(/([URFDLB][2']?\s*)+/) != null ? 2 : 0;
      case 2: // 三阶
        return scramble.match(/([xyzURFDLBMurfdlb]w?[2']?\s*)+/) != null ? 3 : 0;
      case 3: // 四阶
        return scramble.match(/(([xyzURFDLBurf]|[URF]w)[2']?\s*)+/) != null ? 4 : 0;
      case 4: // 五阶
        return scramble.match(/(([URFDLBurfdlb]|[URFDLB]w)[2']?\s*)+/) != null ? 5 : 0;
      case 5: // 六阶
        return scramble.match(/((2?[URFDLB]w?|[urfdlb]|3[URF]w?|3[urf])[2']?\s*)+/) != null ? 6 : 0;
      case 6: // 七阶
        return scramble.match(/(([23]?[URFDLB]w?|3?[urfdlb])[2']?\s*)+/) != null ? 7 : 0;
      case 7: // 金字塔
        return scramble.match(/([URLBulrb]'?\s*)+/) != null ? Scrambler.TYPE_PYR : 0;
      case 8: // 斜转
        return scramble.match(/([URLB]'?\s*)+/) != null ? Scrambler.TYPE_SKW : 0;
      case 9: // SQ1
        return scramble.match(/((\/|\(-?\d+,-?\d+\))\s*)+/) != null ? Scrambler.TYPE_SQ1 : 0;
      case 10: // 五魔
        return scramble.match(/((R\+\+|R--|D\+\+|D--|U'?)\s*)+/) != null ? Scrambler.TYPE_MEGA : 0;
      case 11: // 魔表
        if (scramble.match(/((UR|DR|DL|UL|U|R|D|L|ALL|y2)(\d[+-])?\s*)+/) != null) {
          return Scrambler.TYPE_CLK;
        }
        return 0;
      default:
        return 0;
    }
  }

  static getScrambleName(idx: number, sub: number): string {
    const subitems = StringUtils.scrambleSubitems[idx + 1];
    let subIdx = sub;
    if (subIdx >= subitems.length) {
      subIdx = 0;
    }
    return StringUtils.scrambleItems[idx + 1] + ' - ' + subitems[subIdx];
  }
}
