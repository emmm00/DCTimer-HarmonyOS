// Ported from com.dctimer.model.Result.java (DCTimer-BLE -> HarmonyOS ArkTS)
// 时间单位：毫秒（与原版一致），+2 惩罚 = 2000ms。
import { relationalStore } from '@kit.ArkData';
import { Stats } from '../util/Stats';
import { StringUtils } from '../util/StringUtils';
import { AppConfig } from './AppConfig';

/**
 * 数据库访问接口（对应 DBHelper 中被 Result 使用的方法）。
 * ArkTS 端 RDB 为异步 API，原版 Cursor 的按需读取改为内存镜像
 * （id/scr/time/note/moves/solve_meta 在 init 时一次性载入）。
 */
export interface ResultDB {
  getResult(id: number): Promise<relationalStore.ResultSet | null>;
  addResult(sid: number, values: relationalStore.ValuesBucket): Promise<void>;
  updateResult(sid: number, id: number, resp: number, resd: number): Promise<void>;
  updateResultNote(sid: number, id: number, note: string): Promise<void>;
  updateResultMoves(sid: number, id: number, moves: string): Promise<void>;
  deleteResult(sid: number, id: number): Promise<void>;
  clearSession(id: number): Promise<void>;
  getLastId(): Promise<void>;
  getTableName(sessionId: number): string;
  lastId: number;
}

export class Result {
  static multemp: number[] = [0, 0, 0, 0, 0, 0, 0];
  private db: ResultDB;
  private sessionId: number = 0;
  private resultArr: number[] = [];
  private penaltyArr: number[] = [];
  private multiPhase: number[][] = [];
  private length: number = 0;
  private mp: boolean = false;
  private offset: number = 0;
  private mod: boolean = false;
  // 字符串列内存镜像（原版由 Cursor 按需读取）
  private ids: number[] = [];
  private scrArr: string[] = [];
  private dates: string[] = [];
  private notes: string[] = [];
  private movesArr: string[] = [];
  private solveMetaArr: string[] = [];
  private puzzleArr: number[] = [];
  stats: Stats;

  constructor(db: ResultDB) {
    this.db = db;
    this.stats = new Stats(this);
  }

  getLength(): number {
    return this.length;
  }

  async init(mp: boolean, sid: number): Promise<void> {
    this.sessionId = sid;
    this.mp = mp;
    if (sid >= 15) {
      this.offset = 1;
    } else {
      this.offset = 0;
    }
    const cursor: relationalStore.ResultSet | null = await this.db.getResult(sid);
    this.mod = false;
    this.ids = [];
    this.scrArr = [];
    this.dates = [];
    this.notes = [];
    this.movesArr = [];
    this.solveMetaArr = [];
    this.puzzleArr = [];
    this.length = 0;
    if (cursor === null || cursor.rowCount === 0) {
      this.initArrays(24);
      if (cursor !== null) {
        cursor.close();
      }
      this.db.lastId = 0;
      this.stats = new Stats(this);
      return;
    }
    const length: number = cursor.rowCount;
    if (length < 500) {
      this.initArrays(length * 2);
    } else {
      this.initArrays(Math.floor(length * 3 / 2));
    }
    let i: number = 0;
    let puzzleCol: number = -1;
    if (cursor.getColumnIndex('puzzle') > -1) {
      puzzleCol = cursor.getColumnIndex('puzzle');
    }
    if (cursor.goToFirstRow()) {
      do {
        this.resultArr[i] = cursor.getLong(1 + this.offset);
        this.penaltyArr[i] = cursor.getLong(2 + this.offset);
        const d: number = cursor.getLong(3 + this.offset);
        if (d === 0) {
          this.penaltyArr[i] = 2;
        }
        if (mp) {
          for (let j: number = 0; j < 6; j++) {
            this.multiPhase[j][i] = cursor.getLong(7 + j + this.offset);
          }
        }
        this.ids[i] = cursor.getLong(0);
        this.scrArr[i] = cursor.getString(4 + this.offset);
        this.dates[i] = cursor.getString(5 + this.offset);
        this.notes[i] = cursor.getString(6 + this.offset);
        this.movesArr[i] = cursor.getString(13 + this.offset);
        this.solveMetaArr[i] = cursor.getString(14 + this.offset);
        this.puzzleArr.push(puzzleCol > -1 ? cursor.getLong(puzzleCol) : 0);
        i++;
      } while (cursor.goToNextRow());
    }
    this.length = i;
    cursor.close();
    if (sid < 15) {
      this.db.lastId = this.ids[this.length - 1];
    } else {
      await this.db.getLastId();
    }
    this.stats = new Stats(this);
  }

  private initArrays(capacity: number): void {
    this.resultArr = new Array<number>(capacity).fill(0);
    this.penaltyArr = new Array<number>(capacity).fill(0);
    if (this.mp) {
      this.multiPhase = [];
      for (let i: number = 0; i < 6; i++) {
        this.multiPhase.push(new Array<number>(capacity).fill(0));
      }
    }
  }

  setMod(mod: boolean): void {
    this.mod = mod;
  }

  private expand(): void {
    if (this.length < 1000) {
      const pen: number[] = new Array<number>(this.penaltyArr.length * 2).fill(0);
      const res: number[] = new Array<number>(this.resultArr.length * 2).fill(0);
      for (let i: number = 0; i < this.length; i++) {
        pen[i] = this.penaltyArr[i];
        res[i] = this.resultArr[i];
      }
      this.penaltyArr = pen;
      this.resultArr = res;
    } else {
      const pen: number[] = new Array<number>(Math.floor(this.penaltyArr.length * 3 / 2)).fill(0);
      const res: number[] = new Array<number>(Math.floor(this.resultArr.length * 3 / 2)).fill(0);
      for (let i: number = 0; i < this.length; i++) {
        pen[i] = this.penaltyArr[i];
        res[i] = this.resultArr[i];
      }
      this.penaltyArr = pen;
      this.resultArr = res;
    }
    if (this.mp) {
      const mul: number[][] = [];
      for (let i: number = 0; i < 6; i++) {
        mul.push(new Array<number>(this.resultArr.length).fill(0));
      }
      for (let i: number = 0; i < this.length; i++) {
        for (let j: number = 0; j < 6; j++) {
          mul[j][i] = this.multiPhase[j][i];
        }
      }
      this.multiPhase = mul;
    }
  }

  private expandNum(num: number): void {
    const pen2: number[] = new Array<number>(this.penaltyArr.length + num).fill(0);
    const res2: number[] = new Array<number>(this.resultArr.length + num).fill(0);
    for (let i: number = 0; i < this.length; i++) {
      pen2[i] = this.penaltyArr[i];
      res2[i] = this.resultArr[i];
    }
    this.penaltyArr = pen2;
    this.resultArr = res2;
    if (this.mp) {
      const mul: number[][] = [];
      for (let i: number = 0; i < 6; i++) {
        mul.push(new Array<number>(this.resultArr.length).fill(0));
      }
      for (let i: number = 0; i < this.length; i++) {
        for (let j: number = 0; j < 6; j++) {
          mul[j][i] = this.multiPhase[j][i];
        }
      }
      this.multiPhase = mul;
    }
  }

  getPenalty(i: number): number {
    if (i < 0 || i >= this.length) {
      return 0;
    }
    return this.penaltyArr[i];
  }

  isDnf(i: number): boolean {
    if (i < 0 || i >= this.length) {
      return false;
    }
    return this.penaltyArr[i] === 2;
  }

  getResult(): number[] {
    return this.resultArr;
  }

  getResultAt(i: number): number {
    if (i < 0 || i >= this.length) {
      return 0;
    }
    return this.resultArr[i];
  }

  getTime(i: number): number {
    return this.resultArr[i] + this.penaltyArr[i] * 2000;
  }

  getMulTime(p: number, i: number): number {
    return this.multiPhase[p][i];
  }

  initMulTime(): void {
    const mul: number[][] = [];
    for (let i: number = 0; i < 6; i++) {
      mul.push(new Array<number>(this.resultArr.length).fill(0));
    }
    this.multiPhase = mul;
  }

  clearMulTime(): void {
    this.multiPhase = [];
  }

  private addResult(time: number, p: number, mp: boolean): void {
    if (this.length >= this.resultArr.length) {
      this.expand();
    }
    this.penaltyArr[this.length] = p;
    this.resultArr[this.length] = time;
    if (mp) {
      let tag: boolean = true;
      for (let i: number = 0; i < AppConfig.multiPhase + 1; i++) {
        if (tag) {
          this.multiPhase[i][this.length] = Result.multemp[i + 1] - Result.multemp[i];
        } else {
          this.multiPhase[i][this.length] = 0;
        }
        if (this.multiPhase[i][this.length] < 0 || this.multiPhase[i][this.length] > this.resultArr[this.length]) {
          this.multiPhase[i][this.length] = 0;
          tag = false;
        }
      }
    }
    this.length++;
  }

  checkExpand(num: number): void {
    if (this.length + num >= this.resultArr.length) {
      this.expandNum(num);
    }
  }

  async reloadMulTime(): Promise<void> {
    const cursor: relationalStore.ResultSet | null = await this.db.getResult(this.sessionId);
    if (cursor === null) {
      return;
    }
    let i: number = 0;
    if (cursor.goToFirstRow()) {
      do {
        for (let j: number = 0; j < 6; j++) {
          this.multiPhase[j][i] = cursor.getLong(7 + j);
        }
        i++;
      } while (cursor.goToNextRow());
    }
    cursor.close();
  }

  getString(i: number, column: number): string {
    if (i < 0 || i >= this.length) {
      return '';
    }
    switch (column) {
      case 4:
        return this.scrArr[i];
      case 5:
        return this.dates[i];
      case 6:
        return this.notes[i];
      case 13:
        return this.movesArr[i];
      case 14:
        return this.solveMetaArr[i];
      default:
        return '';
    }
  }

  getId(i: number): number {
    if (i < 0 || i >= this.length) {
      return 0;
    }
    return this.ids[i];
  }

  getPuzzle(i: number): number {
    if (i < 0 || i >= this.length) {
      return 0;
    }
    return this.puzzleArr[i];
  }

  async insert(time: number, penalty: number, scramble: string, mp: boolean,
    moves: string | null, solveMeta: string | null, puzzle: number): Promise<void> {
    this.addResult(time, penalty, mp);
    let d: number = 1;
    if (penalty === 2) {
      penalty = 0;
      d = 0;
    }
    const dateStr: string = StringUtils.getDate();
    const cv: relationalStore.ValuesBucket = {
      'rest': time,
      'resp': penalty,
      'resd': d,
      'scr': scramble,
      'time': dateStr,
      'puzzle': puzzle
    };
    if (moves !== null && moves.length > 0) {
      cv['moves'] = moves;
    }
    if (solveMeta !== null && solveMeta.length > 0) {
      cv['solve_meta'] = solveMeta;
    }
    if (mp && this.multiPhase !== null) {
      for (let i: number = 0; i < 6; i++) {
        cv['p' + (i + 1)] = this.multiPhase[i][this.length - 1];
      }
    }
    await this.db.addResult(this.sessionId, cv);
    this.ids.push(this.db.lastId);
    this.scrArr.push(scramble);
    this.dates.push(dateStr);
    this.notes.push('');
    this.movesArr.push(moves !== null ? moves : '');
    this.solveMetaArr.push(solveMeta !== null ? solveMeta : '');
    this.puzzleArr.push(puzzle);
    this.mod = true;
  }

  async insertBulk(num: number, u: number, v: number, scr: string): Promise<void> {
    this.checkExpand(num);
    for (let i: number = 0; i < num; i++) {
      const time: number = Math.floor(Math.sqrt(v) * Result.gaussian() + u);
      const dateStr: string = StringUtils.getDate();
      this.resultArr[this.length] = time;
      this.penaltyArr[this.length] = 0;
      const cv: relationalStore.ValuesBucket = {
        'rest': time,
        'resp': 0,
        'resd': 1,
        'scr': scr,
        'time': dateStr,
        'note': '',
        'p1': 0, 'p2': 0, 'p3': 0, 'p4': 0, 'p5': 0, 'p6': 0,
        'moves': ''
      };
      await this.db.addResult(this.sessionId, cv);
      this.ids.push(this.db.lastId);
      this.scrArr.push(scr);
      this.dates.push(dateStr);
      this.notes.push('');
      this.movesArr.push('');
      this.solveMetaArr.push('');
      this.puzzleArr.push(0);
      this.length++;
    }
    this.mod = true;
  }

  private static gaussian(): number {
    let u: number = 0;
    let v: number = 0;
    let s: number = 0;
    do {
      u = Math.random() * 2 - 1;
      v = Math.random() * 2 - 1;
      s = u * u + v * v;
    } while (s >= 1 || s === 0);
    return u * Math.sqrt(-2 * Math.log(s) / s);
  }

  async updatePenalty(i: number, p: number): Promise<boolean> {
    if (i < 0 || i >= this.penaltyArr.length) {
      return false;
    }
    if (this.penaltyArr[i] === p) {
      return false;
    }
    this.penaltyArr[i] = p;
    let d: number = 1;
    if (p === 2) {
      p = 0;
      d = 0;
    }
    await this.db.updateResult(this.sessionId, this.ids[i], p, d);
    this.mod = true;
    return true;
  }

  async updateNote(i: number, text: string): Promise<void> {
    this.notes[i] = text;
    await this.db.updateResultNote(this.sessionId, this.ids[i], text);
    this.mod = true;
  }

  async updateMoves(i: number, moves: string): Promise<void> {
    this.movesArr[i] = moves;
    await this.db.updateResultMoves(this.sessionId, this.ids[i], moves);
    this.mod = true;
  }

  async delete(idx: number): Promise<number> {
    if (idx >= this.length) {
      return -1;
    }
    const id: number = this.ids[idx];
    if (idx !== this.length - 1) {
      for (let i: number = idx; i < this.length - 1; i++) {
        this.resultArr[i] = this.resultArr[i + 1];
        this.penaltyArr[i] = this.penaltyArr[i + 1];
        if (AppConfig.multiPhase > 0) {
          for (let j: number = 0; j <= AppConfig.multiPhase; j++) {
            this.multiPhase[j][i] = this.multiPhase[j][i + 1];
          }
        }
        this.ids[i] = this.ids[i + 1];
        this.scrArr[i] = this.scrArr[i + 1];
        this.dates[i] = this.dates[i + 1];
        this.notes[i] = this.notes[i + 1];
        this.movesArr[i] = this.movesArr[i + 1];
        this.solveMetaArr[i] = this.solveMetaArr[i + 1];
      }
    }
    this.length--;
    await this.db.deleteResult(this.sessionId, id);
    this.mod = true;
    return 0;
  }

  async clear(): Promise<void> {
    await this.db.clearSession(this.sessionId);
    this.length = 0;
    this.resultArr = new Array<number>(24).fill(0);
    this.penaltyArr = new Array<number>(24).fill(0);
    if (this.mp) {
      this.multiPhase = [];
      for (let i: number = 0; i < 6; i++) {
        this.multiPhase.push(new Array<number>(24).fill(0));
      }
    }
    this.ids = [];
    this.scrArr = [];
    this.dates = [];
    this.notes = [];
    this.movesArr = [];
    this.solveMetaArr = [];
    this.mod = true;
    this.stats.maxIdx = this.stats.minIdx = -1;
    this.stats.bestTimeRecord = new Array<boolean>(24).fill(false);
    this.stats.bestAvgRecord = [new Array<boolean>(24).fill(false), new Array<boolean>(24).fill(false)];
    this.stats.mpMean = new Array<number>(6).fill(0);
  }

  getDates(): string[] {
    return this.dates.slice(0, this.length);
  }

  search(key: string): number[] {
    let i: number = 0;
    while (i < key.length && key.charAt(i) === '0') {
      i++;
    }
    if (i > 0) {
      key = key.substring(i);
    }
    const list: number[] = [];
    for (i = 0; i < this.length; i++) {
      const pos: number = AppConfig.sortType === 0 ? i : this.stats.sortIdx[i];
      let tag: boolean = false;
      if (this.penaltyArr[pos] !== 2) {
        const time: string = StringUtils.timeToString(this.getTime(pos));
        if (time.startsWith(key)) {
          list.push(i);
          tag = true;
        }
      } else if ('dnf'.startsWith(key)) {
        list.push(i);
        tag = true;
      }
      const comment: string = this.getString(pos, 6);
      if (comment.length > 0 && comment.includes(key) && !tag) {
        list.push(i);
      }
    }
    return list;
  }

  getTimeAt(idx: number, showTime: boolean): string {
    if (idx < 0 || idx >= this.length) {
      return 'error';
    }
    const i: number = this.resultArr[idx];
    const penalty: number = this.getPenalty(idx);
    if (penalty === 2) {
      if (showTime) {
        return 'DNF (' + StringUtils.timeToString(i) + ')';
      } else {
        return 'DNF';
      }
    } else if (penalty === 1) {
      return StringUtils.timeToString(i + 2000) + '+';
    } else {
      return StringUtils.timeToString(i);
    }
  }

  getSolved(): number {
    return this.stats.solved;
  }

  getMinIdx(): number {
    return this.stats.minIdx;
  }

  getBestTime(): string {
    if (this.getMaxIdx() < 0) {
      return '-';
    }
    return this.getTimeAt(this.getMinIdx(), false);
  }

  isSessionBest(): boolean {
    if (this.length < 2) {
      return false;
    }
    return this.isSessionBestRecord(this.length - 1);
  }

  isSessionBestRecord(i: number): boolean {
    return i >= 0 && i < this.length && i < this.stats.bestTimeRecord.length && this.stats.bestTimeRecord[i];
  }

  getMaxIdx(): number {
    return this.stats.maxIdx;
  }

  getWorstTime(): string {
    if (this.getMaxIdx() < 0) {
      return '-';
    }
    return this.getTimeAt(this.getMaxIdx(), false);
  }

  sessionMean(): number {
    return this.stats.mean;
  }

  getSessionMean(): string {
    return this.stats.sessionMean();
  }

  getSessionAvg(): string {
    return this.stats.sessionAvg();
  }

  getSessionSD(): string {
    return this.stats.getSD(this.stats.sd);
  }

  calcAvg(): void {
    this.stats.calcAvg();
  }

  getAvg1(idx: number): number {
    return this.stats.avg1[idx];
  }

  getAvg2(idx: number): number {
    return this.stats.avg2[idx];
  }

  getRollingAvg1(i: number): string {
    if (i < 0 || i >= this.length) {
      return '-';
    }
    return StringUtils.timeToString(this.stats.avg1[i]);
  }

  getRollingAvg2(i: number): string {
    if (i < 0 || i >= this.length) {
      return '-';
    }
    return StringUtils.timeToString(this.stats.avg2[i]);
  }

  getAvgDetail(n: number, i: number, trim: number[]): string[] {
    return this.stats.getAvgDetail(n, i, trim);
  }

  getMeanDetail(n: number, i: number): string[] {
    return this.stats.getMeanDetail(n, i);
  }

  getBestAvgIdx(i: number): number {
    return this.stats.bestAvgIdx[i];
  }

  getBestAvg1(): string {
    if (this.stats.bestAvgIdx[0] === -1) {
      return 'N/A';
    }
    return StringUtils.timeToString(this.stats.bestAvg[0]);
  }

  getBestAvg2(): string {
    if (this.stats.bestAvgIdx[1] === -1) {
      return 'N/A';
    }
    return StringUtils.timeToString(this.stats.bestAvg[1]);
  }

  isAvgBest(i: number): boolean {
    if (this.length === 0) {
      return false;
    }
    return this.isAvgBestRecord(i, this.length - 1);
  }

  isAvgBestRecord(type: number, i: number): boolean {
    return type >= 0 && type < this.stats.bestAvgRecord.length &&
      i >= 0 && i < this.length && i < this.stats.bestAvgRecord[type].length &&
      this.stats.bestAvgRecord[type][i];
  }

  getMpMinIdx(idx: number): number {
    return this.stats.mpMin[idx];
  }

  getMpMaxIdx(idx: number): number {
    return this.stats.mpMax[idx];
  }

  getMpMean(idx: number): string {
    return StringUtils.timeToString(this.stats.mpMean[idx]);
  }

  calcMpMean(): void {
    this.stats.calcMpMean();
  }

  sortResult(): void {
    this.stats.sortResult();
  }

  getSortIdx(i: number): number {
    return this.stats.sortIdx[i];
  }

  close(): void {
  }
}

/**
 * 成绩条目（UI 展示模型）。时间单位：毫秒（1000 = 1秒），+2 惩罚 = 2000。
 */
export class ResultEntry {
  id: number = 0;
  time: number = 0; // 毫秒
  penalty: number = 0; // 0=无, 1=+2, 2=DNF
  scramble: string = '';
  date: number = 0;
  note: string = '';
  puzzle: number = 0; // 成绩所属项目（flatPuzzleCode 索引/DB 项目码），0=未知
  phases: number[] = []; // 分段成绩（毫秒），非分段计时时为空

  getTime(): number {
    if (this.penalty === 2) {
      return -1; // DNF
    }
    return this.time + (this.penalty === 1 ? 2000 : 0);
  }

  isDnf(): boolean {
    return this.penalty === 2;
  }

  getDisplayTime(accuracy: number): string {
    if (this.penalty === 2) {
      return 'DNF';
    }
    return ResultEntry.formatMs(this.time + (this.penalty === 1 ? 2000 : 0), accuracy);
  }

  static formatMs(total: number, accuracy: number): string {
    if (total < 0) {
      return 'DNF';
    }
    const sec: number = Math.floor(total / 1000);
    const ms: number = Math.floor(total % 1000);
    if (accuracy === 0) {
      // 厘秒精度
      const cs: number = Math.floor(ms / 10);
      if (sec >= 60) {
        const min: number = Math.floor(sec / 60);
        return min + ':' + (sec % 60).toString().padStart(2, '0') + '.' + cs.toString().padStart(2, '0');
      }
      return sec + '.' + cs.toString().padStart(2, '0');
    } else {
      // 毫秒精度
      if (sec >= 60) {
        const min: number = Math.floor(sec / 60);
        return min + ':' + (sec % 60).toString().padStart(2, '0') + '.' + ms.toString().padStart(3, '0');
      }
      return sec + '.' + ms.toString().padStart(3, '0');
    }
  }

  getDateString(): string {
    const d: Date = new Date(this.date);
    return (d.getMonth() + 1) + '/' + d.getDate() + ' ' +
      d.getHours().toString().padStart(2, '0') + ':' + d.getMinutes().toString().padStart(2, '0');
  }

  /** 解析数据库日期字符串（yyyy-MM-dd HH:mm:ss）为毫秒时间戳 */
  static parseDate(dateStr: string): number {
    if (dateStr.length === 0) {
      return 0;
    }
    const t: number = Date.parse(dateStr.replace(' ', 'T'));
    return isNaN(t) ? 0 : t;
  }

  /** 序列化为 JSON 对象（Preferences 旧数据迁移用） */
  toJSON(): Record<string, Object> {
    return {
      'time': this.time,
      'penalty': this.penalty,
      'scramble': this.scramble,
      'date': this.date,
      'phases': this.phases.join(',')
    } as Record<string, Object>;
  }

  static fromJSON(obj: Record<string, Object>): ResultEntry {
    const r: ResultEntry = new ResultEntry();
    r.time = (obj['time'] as number) ?? 0;
    r.penalty = (obj['penalty'] as number) ?? 0;
    r.scramble = (obj['scramble'] as string) ?? '';
    r.date = (obj['date'] as number) ?? 0;
    const ph: string = (obj['phases'] as string) ?? '';
    if (ph.length > 0) {
      const parts: string[] = ph.split(',');
      for (let i: number = 0; i < parts.length; i++) {
        const v: number = parseInt(parts[i]);
        if (!isNaN(v)) {
          r.phases.push(v);
        }
      }
    }
    return r;
  }
}
