/**
 * 数据库帮助类 - 对应 Android DBHelper.java
 *
 * 映射：
 * - SQLiteOpenHelper → @ohos.data.relationalStore (RdbStore)
 * - ContentValues → ValuesBucket
 * - Cursor → ResultSet
 */

import { relationalStore } from '@kit.ArkData';
import { Session } from '../model/Session';
import { ResultDB } from '../model/Result';

export class DBHelper implements ResultDB {
  static readonly DB_NAME: string = 'spdcube.db';
  static readonly TBL_NAME: string[] = [
    'resulttb', 'result2', 'result3', 'result4', 'result5', 'result6',
    'result7', 'result8', 'result9', 'result10', 'result11', 'result12',
    'result13', 'result14', 'result15', 'resultstb'
  ];
  static readonly TBS_NAME: string = 'sessiontb';

  private rdbStore: relationalStore.RdbStore | null = null;
  public lastId: number = 0;
  public sessionId: number = 0;

  /**
   * 初始化数据库
   * @param context 鸿蒙 Context
   */
  async initialize(context: object): Promise<void> {
    const STORE_CONFIG: relationalStore.StoreConfig = {
      name: DBHelper.DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };

    this.rdbStore = await relationalStore.getRdbStore(context as Context, STORE_CONFIG);

    // 检查是否需要创建表（如果 sessiontb 不存在则创建所有表）
    const checkSql = "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='" + DBHelper.TBS_NAME + "'";
    let resultSet = await this.rdbStore.querySql(checkSql);
    let tableExists = false;
    if (resultSet.goToFirstRow()) {
      tableExists = resultSet.getLong(0) > 0;
    }
    resultSet.close();

    if (!tableExists) {
      await this.onCreate();
    } else {
      await this.onUpgrade();
    }
  }

  /** 列结构迁移：为成绩表补上 puzzle 列（记录成绩所属设备/项目，详情打乱图不随当前项目漂移） */
  private async ensureColumn(tableName: string, columnName: string, type: string): Promise<void> {
    if (!this.rdbStore) return;
    const infoSql = 'PRAGMA table_info(' + tableName + ')';
    const rs = await this.rdbStore.querySql(infoSql);
    let has = false;
    if (rs.rowCount > 0) {
      while (rs.goToNextRow()) {
        if (rs.getString(1) === columnName) {
          has = true;
          break;
        }
      }
    }
    rs.close();
    if (!has) {
      await this.rdbStore.executeSql('ALTER TABLE ' + tableName + ' ADD COLUMN ' + columnName + ' ' + type);
    }
  }

  private async onUpgrade(): Promise<void> {
    if (!this.rdbStore) return;
    // 前 15 个成绩表
    for (let i = 0; i < 15; i++) {
      await this.ensureColumn(DBHelper.TBL_NAME[i], 'puzzle', 'INTEGER');
    }
    // 自定义会话成绩表
    await this.ensureColumn(DBHelper.TBL_NAME[15], 'puzzle', 'INTEGER');
  }

  private async onCreate(): Promise<void> {
    if (!this.rdbStore) return;

    // 创建前 15 个成绩表
    for (let i = 0; i < 15; i++) {
      const sql = `CREATE TABLE ${DBHelper.TBL_NAME[i]} (
        id INTEGER NOT NULL,
        rest INTEGER NOT NULL, resp INTEGER NOT NULL, resd INTEGER NOT NULL,
        scr TEXT NOT NULL, time TEXT, note TEXT,
        p1 INTEGER, p2 INTEGER, p3 INTEGER, p4 INTEGER, p5 INTEGER, p6 INTEGER,
        moves TEXT, solve_meta TEXT, puzzle INTEGER)`;
      await this.rdbStore.executeSql(sql);
    }

    // 创建会话表
    await this.rdbStore.executeSql(
      `CREATE TABLE ${DBHelper.TBS_NAME} (
        id INTEGER NOT NULL, name TEXT, type INTEGER, mulp INTEGER, ra INTEGER, sorting INTEGER)`
    );

    // 创建自定义会话成绩表
    await this.rdbStore.executeSql(
      `CREATE TABLE ${DBHelper.TBL_NAME[15]} (
        id INTEGER NOT NULL, sid INTEGER NOT NULL,
        rest INTEGER NOT NULL, resp INTEGER NOT NULL, resd INTEGER NOT NULL,
        scr TEXT, time TEXT, note TEXT,
        p1 INTEGER, p2 INTEGER, p3 INTEGER, p4 INTEGER, p5 INTEGER, p6 INTEGER,
        moves TEXT, solve_meta TEXT, puzzle INTEGER)`
    );
  }

  getRdbStore(): relationalStore.RdbStore | null {
    return this.rdbStore;
  }

  /**
   * 查询所有会话
   */
  async querySession(): Promise<relationalStore.ResultSet | null> {
    if (!this.rdbStore) return null;
    return await this.rdbStore.query(new relationalStore.RdbPredicates(DBHelper.TBS_NAME));
  }

  /**
   * 获取会话列表
   */
  async getSession(sessionList: Session[]): Promise<void> {
    if (!this.rdbStore) return;

    const predicates = new relationalStore.RdbPredicates(DBHelper.TBS_NAME);
    const resultSet = await this.rdbStore.query(predicates);
    const count = resultSet.rowCount;

    if (count === 0) {
      // 初始化默认 15 个会话
      for (let sessionId = 0; sessionId < 15; sessionId++) {
        const session = new Session(sessionId);
        session.name = '组 ' + (sessionId + 1);
        session.puzzle = 33;
        session.sorting = sessionId + 1;
        sessionList.push(session);

        const valueBucket: relationalStore.ValuesBucket = {
          'id': sessionId,
          'name': session.name,
          'type': 33,
          'sorting': sessionId + 1
        };
        await this.rdbStore.insert(DBHelper.TBS_NAME, valueBucket);
      }
    } else {
      while (resultSet.goToNextRow()) {
        let avg = resultSet.getLong(resultSet.getColumnIndex('ra'));
        if (avg === 0) avg = 8011;
        let sorting = resultSet.getLong(resultSet.getColumnIndex('sorting'));
        if (sorting === 0) sorting = sessionList.length + 1;

        const session = new Session();
        session.id = resultSet.getLong(resultSet.getColumnIndex('id'));
        session.name = resultSet.getString(resultSet.getColumnIndex('name'));
        session.puzzle = resultSet.getLong(resultSet.getColumnIndex('type'));
        session.multiPhase = resultSet.getLong(resultSet.getColumnIndex('mulp'));
        session.avg = avg;
        session.sorting = sorting;
        sessionList.push(session);
      }

      resultSet.goToLastRow();
      this.sessionId = resultSet.getLong(resultSet.getColumnIndex('id'));
      if (this.sessionId < 14) this.sessionId = 14;
    }
    resultSet.close();
  }

  /**
   * 获取会话成绩数量
   */
  async getSessionCount(id: number): Promise<number> {
    if (!this.rdbStore) return 0;

    let sql: string;
    if (id < 15) {
      sql = `SELECT count(*) FROM ${DBHelper.TBL_NAME[id]}`;
    } else {
      sql = `SELECT count(*) FROM ${DBHelper.TBL_NAME[15]} WHERE sid=${id}`;
    }

    const resultSet = await this.rdbStore.querySql(sql);
    let count = 0;
    if (resultSet.goToFirstRow()) {
      count = resultSet.getLong(0);
    }
    resultSet.close();
    return count;
  }

  /**
   * 添加新会话
   */
  async addSession(name: string): Promise<number> {
    if (!this.rdbStore) return -1;

    this.sessionId++;
    const valueBucket: relationalStore.ValuesBucket = {
      'id': this.sessionId,
      'name': name,
      'type': 33,
      'mulp': 0,
      'ra': 8011
    };
    await this.rdbStore.insert(DBHelper.TBS_NAME, valueBucket);
    return this.sessionId;
  }

  /**
   * 保存会话列表排序
   */
  async saveSession(sessionList: Session[]): Promise<void> {
    if (!this.rdbStore) return;

    for (const session of sessionList) {
      const sorting = session.sorting;
      const id = session.id;
      const sql = `UPDATE ${DBHelper.TBS_NAME} SET sorting=? WHERE id=?`;
      await this.rdbStore.executeSql(sql, [sorting, id]);
    }
  }

  /**
   * 更新会话
   */
  private async updateSession(id: number, values: relationalStore.ValuesBucket): Promise<void> {
    if (!this.rdbStore) return;

    const predicates = new relationalStore.RdbPredicates(DBHelper.TBS_NAME);
    predicates.equalTo('id', id);
    await this.rdbStore.update(values, predicates);
  }

  async updateName(id: number, name: string): Promise<void> {
    const cv: relationalStore.ValuesBucket = { 'name': name };
    await this.updateSession(id, cv);
  }

  async updatePuzzle(id: number, puzzle: number): Promise<void> {
    const cv: relationalStore.ValuesBucket = { 'type': puzzle };
    await this.updateSession(id, cv);
  }

  async updateMultiPhase(id: number, mp: number): Promise<void> {
    const cv: relationalStore.ValuesBucket = { 'mulp': mp };
    await this.updateSession(id, cv);
  }

  async updateAverage(id: number, avg: number): Promise<void> {
    const cv: relationalStore.ValuesBucket = { 'ra': avg };
    await this.updateSession(id, cv);
  }

  /**
   * 删除会话
   */
  async deleteSession(id: number): Promise<void> {
    if (!this.rdbStore) return;

    const predicates = new relationalStore.RdbPredicates(DBHelper.TBS_NAME);
    predicates.equalTo('id', id);
    await this.rdbStore.delete(predicates);

    if (id < 15) {
      const delPredicates = new relationalStore.RdbPredicates(DBHelper.TBL_NAME[id]);
      await this.rdbStore.delete(delPredicates);
    } else {
      const delPredicates = new relationalStore.RdbPredicates(DBHelper.TBL_NAME[15]);
      delPredicates.equalTo('sid', id);
      await this.rdbStore.delete(delPredicates);
    }
  }

  /**
   * 添加成绩
   */
  async addResult(sid: number, values: relationalStore.ValuesBucket): Promise<void> {
    if (!this.rdbStore) return;

    let tableIdx = sid;
    if (sid >= 15) {
      values['sid'] = sid;
      tableIdx = 15;
    }
    values['id'] = ++this.lastId;
    await this.rdbStore.insert(DBHelper.TBL_NAME[tableIdx], values);
  }

  /**
   * 查询成绩
   */
  async getResult(id: number): Promise<relationalStore.ResultSet | null> {
    if (!this.rdbStore) return null;

    if (id < 15) {
      const predicates = new relationalStore.RdbPredicates(DBHelper.TBL_NAME[id]);
      return await this.rdbStore.query(predicates);
    }
    const predicates = new relationalStore.RdbPredicates(DBHelper.TBL_NAME[15]);
    predicates.equalTo('sid', id);
    return await this.rdbStore.query(predicates);
  }

  /**
   * 获取最大 ID
   */
  async getLastId(): Promise<void> {
    if (!this.rdbStore) return;

    const resultSet = await this.rdbStore.querySql('SELECT id FROM ' + DBHelper.TBL_NAME[15]);

    this.lastId = 1;
    if (resultSet.rowCount !== 0) {
      while (resultSet.goToNextRow()) {
        const id = resultSet.getLong(0);
        if (id > this.lastId) this.lastId = id;
      }
    }
    resultSet.close();
  }

  /**
   * 获取表名
   */
  getTableName(sessionId: number): string {
    if (sessionId >= 15) return DBHelper.TBL_NAME[15];
    return DBHelper.TBL_NAME[sessionId];
  }

  /**
   * 删除成绩
   */
  async deleteResult(sid: number, id: number): Promise<void> {
    if (!this.rdbStore) return;

    let tableIdx = sid;
    if (sid >= 15) tableIdx = 15;

    const predicates = new relationalStore.RdbPredicates(DBHelper.TBL_NAME[tableIdx]);
    predicates.equalTo('id', id);
    await this.rdbStore.delete(predicates);
  }

  /**
   * 清空会话成绩
   */
  async clearSession(id: number): Promise<void> {
    if (!this.rdbStore) return;

    if (id < 15) {
      const predicates = new relationalStore.RdbPredicates(DBHelper.TBL_NAME[id]);
      await this.rdbStore.delete(predicates);
    } else {
      const predicates = new relationalStore.RdbPredicates(DBHelper.TBL_NAME[15]);
      predicates.equalTo('sid', id);
      await this.rdbStore.delete(predicates);
    }
  }

  /**
   * 更新成绩惩罚标记
   */
  async updateResult(sid: number, id: number, resp: number, resd: number): Promise<void> {
    if (!this.rdbStore) return;

    let tableIdx = sid;
    if (sid >= 15) tableIdx = 15;

    const values: relationalStore.ValuesBucket = {
      'resp': resp,
      'resd': resd
    };
    const predicates = new relationalStore.RdbPredicates(DBHelper.TBL_NAME[tableIdx]);
    predicates.equalTo('id', id);
    await this.rdbStore.update(values, predicates);
  }

  /**
   * 更新成绩备注
   */
  async updateResultNote(sid: number, id: number, note: string): Promise<void> {
    if (!this.rdbStore) return;

    let tableIdx = sid;
    if (sid >= 15) tableIdx = 15;

    const values: relationalStore.ValuesBucket = { 'note': note };
    const predicates = new relationalStore.RdbPredicates(DBHelper.TBL_NAME[tableIdx]);
    predicates.equalTo('id', id);
    await this.rdbStore.update(values, predicates);
  }

  /**
   * 更新成绩解法步数
   */
  async updateResultMoves(sid: number, id: number, moves: string): Promise<void> {
    if (!this.rdbStore) return;

    let tableIdx = sid;
    if (sid >= 15) tableIdx = 15;

    const values: relationalStore.ValuesBucket = { 'moves': moves };
    const predicates = new relationalStore.RdbPredicates(DBHelper.TBL_NAME[tableIdx]);
    predicates.equalTo('id', id);
    await this.rdbStore.update(values, predicates);
  }

  /**
   * 关闭数据库
   */
  async close(): Promise<void> {
    if (this.rdbStore) {
      await this.rdbStore.close();
      this.rdbStore = null;
    }
  }
}
