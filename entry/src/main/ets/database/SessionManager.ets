/**
 * 会话管理器 - 对应 Android SessionManager.java
 */

import { DBHelper } from './DBHelper';
import { Session } from '../model/Session';

export class SessionManager {
  private db: DBHelper;
  private sessionList: Session[];
  private currentSession: number = 0;

  constructor(db: DBHelper) {
    this.db = db;
    this.sessionList = [];
  }

  /**
   * 初始化会话列表（需要异步调用）
   */
  async init(): Promise<void> {
    await this.db.getSession(this.sessionList);
    this.sessionList.sort((a, b) => a.getSorting() - b.getSorting());
  }

  getSessionLength(): number {
    return this.sessionList.length;
  }

  getCurrentSession(): number {
    return this.currentSession;
  }

  setCurrentSession(currentSession: number): void {
    this.currentSession = currentSession;
  }

  getSessionName(i: number): string {
    let name = this.sessionList[i].getName();
    if (!name || name.length === 0) {
      if (i === 0) {
        name = 'Default Session'; // 默认值，对应 R.string.default_session
      } else {
        name = 'Session' + (i + 1); // 对应 R.string.session
      }
    }
    return name;
  }

  async setSessionName(i: number, name: string): Promise<void> {
    const session = this.sessionList[i];
    session.setName(name);
    await this.db.updateName(session.getId(), name);
  }

  getSessionNames(): string[] {
    const list: string[] = new Array<string>(this.sessionList.length);
    for (let i = 0; i < this.sessionList.length; i++) {
      list[i] = this.getSessionName(i);
    }
    return list;
  }

  async updateSessionCount(): Promise<void> {
    for (const session of this.sessionList) {
      const id = session.getId();
      const count = await this.db.getSessionCount(id);
      session.setCount(count);
    }
  }

  getPuzzle(i: number): number {
    const session = this.sessionList[i];
    return session.getPuzzle();
  }

  async setPuzzle(i: number, puzzle: number): Promise<void> {
    const session = this.sessionList[i];
    if (session.getPuzzle() !== puzzle) {
      session.setPuzzle(puzzle);
      await this.db.updatePuzzle(session.getId(), puzzle);
    }
  }

  getMultiPhase(i: number): number {
    const session = this.sessionList[i];
    return session.getMultiPhase();
  }

  async setMultiPhase(i: number, mp: number): Promise<void> {
    const session = this.sessionList[i];
    if (session.getMultiPhase() !== mp) {
      session.setMultiPhase(mp);
      await this.db.updateMultiPhase(session.getId(), mp);
    }
  }

  getAverage(i: number): number {
    const session = this.sessionList[i];
    return session.getAvg();
  }

  async setAverage(i: number, avg: number): Promise<void> {
    const session = this.sessionList[i];
    if (session.getAvg() !== avg) {
      session.setAvg(avg);
      await this.db.updateAverage(session.getId(), avg);
    }
  }

  async addSession(name: string): Promise<void> {
    const id = await this.db.addSession(name);
    const session = new Session(id, name, 33, 0, 8011, this.sessionList.length + 1);
    this.sessionList.push(session);
  }

  getSession(i: number): Session {
    return this.sessionList[i];
  }

  async removeSession(i: number): Promise<void> {
    const session = this.sessionList[i];
    const id = session.getId();
    await this.db.deleteSession(id);
    this.sessionList.splice(i, 1);
  }

  move(from: number, to: number): void {
    const session = this.sessionList.splice(from, 1)[0];
    this.sessionList.splice(to, 0, session);
  }

  async save(): Promise<void> {
    for (let i = 0; i < this.sessionList.length; i++) {
      this.sessionList[i].setSorting(i + 1);
    }
    await this.db.saveSession(this.sessionList);
  }
}
