import { ResultEntry } from '../model/Result';
import { StringUtils } from './StringUtils';

interface CsvImportResult {
  success: boolean;
  results: ResultEntry[];
  error: string;
}

/**
 * 导出工具 - CSV / csTimer 格式（毫秒单位）
 */
export class ExportUtil {
  /**
   * 生成 CSV 内容
   * 列: #, Time, Penalty, Scramble, Date, Note
   */
  static toCsv(results: ResultEntry[], sessionName: string): string {
    let csv: string = 'No,Time,Penalty,Scramble,Date,Note\n';
    for (let i: number = 0; i < results.length; i++) {
      const r: ResultEntry = results[i];
      const time: string = ExportUtil.formatTimeForCsv(r.time);
      const penalty: string = r.penalty === 0 ? '' : (r.penalty === 1 ? '+2' : 'DNF');
      const scramble: string = ExportUtil.escapeCsv(r.scramble);
      const date: string = r.getDateString();
      const note: string = ExportUtil.escapeCsv(r.note);
      csv += `${i + 1},${time},${penalty},${scramble},${date},${note}\n`;
    }
    return csv;
  }

  /**
   * 生成 csTimer 兼容的纯文本格式
   * 每行: 时间 打乱
   */
  static toCsTimer(results: ResultEntry[]): string {
    let text: string = '';
    for (let i: number = 0; i < results.length; i++) {
      const r: ResultEntry = results[i];
      if (r.isDnf()) {
        text += 'DNF: ' + r.scramble + '\n';
        continue;
      }
      const time: string = StringUtils.timeToString(r.time + (r.penalty === 1 ? 2000 : 0));
      text += `${time}: ${r.scramble}\n`;
    }
    return text;
  }

  /**
   * 格式化时间用于 CSV (秒, 保留2位)
   */
  private static formatTimeForCsv(timeMs: number): string {
    const sec: number = timeMs / 1000;
    return sec.toFixed(2);
  }

  private static escapeCsv(text: string): string {
    if (text.includes(',') || text.includes('"') || text.includes('\n')) {
      return '"' + text.replace(/"/g, '""') + '"';
    }
    return text;
  }

  /**
   * 从 CSV 导入
   * 返回 { success: boolean, results: ResultEntry[], error: string }
   */
  static fromCsv(csvContent: string): CsvImportResult {
    const lines: string[] = csvContent.split('\n').filter((l: string) => l.trim().length > 0);
    if (lines.length < 2) {
      return { success: false, results: [], error: 'CSV格式无效' };
    }
    // 跳过表头
    let results: ResultEntry[] = [];
    for (let i: number = 1; i < lines.length; i++) {
      const cols: string[] = ExportUtil.parseCsvLine(lines[i]);
      if (cols.length < 2) {
        continue;
      }
      try {
        let timeSec: number = parseFloat(cols[1]);
        if (isNaN(timeSec) || timeSec < 0) {
          continue;
        }
        let timeMs: number = Math.round(timeSec * 1000);
        let penalty: number = 0;
        if (cols.length >= 3) {
          const pStr: string = cols[2].trim().toUpperCase();
          if (pStr === '+2') {
            penalty = 1;
          } else if (pStr === 'DNF') {
            penalty = 2;
          }
        }
        const scramble: string = cols.length >= 4 ? cols[3] : '';
        const note: string = cols.length >= 6 ? cols[5] : '';

        let result: ResultEntry = new ResultEntry();
        result.time = timeMs;
        result.penalty = penalty;
        result.scramble = scramble;
        result.note = note;
        result.date = Date.now();
        results.push(result);
      } catch (e) {
        continue;
      }
    }
    return { success: true, results: results, error: '' };
  }

  private static parseCsvLine(line: string): string[] {
    let result: string[] = [];
    let current: string = '';
    let inQuotes: boolean = false;
    for (let i: number = 0; i < line.length; i++) {
      const ch: string = line[i];
      if (inQuotes) {
        if (ch === '"') {
          if (i + 1 < line.length && line[i + 1] === '"') {
            current += '"';
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          current += ch;
        }
      } else {
        if (ch === '"') {
          inQuotes = true;
        } else if (ch === ',') {
          result.push(current);
          current = '';
        } else {
          current += ch;
        }
      }
    }
    result.push(current);
    return result;
  }
}
