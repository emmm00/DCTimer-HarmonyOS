export class Session {
  id: number = 0;
  name: string = '';
  puzzle: number = 33; // 魔方类型编码，33=3x3
  count: number = 0;
  multiPhase: number = 0;
  avg: number = 8011; // 编码的平均配置 (ra1 + ra2*1000)
  sorting: number = 0;

  constructor(id?: number) {
    if (id !== undefined) {
      this.id = id;
    }
  }

  getRa1(): number {
    return this.avg % 1000 + 1;
  }

  getRa2(): number {
    return Math.floor(this.avg / 1000) % 1000 + 1;
  }

  getAvg1Len(): number {
    return this.getRa1();
  }

  getAvg2Len(): number {
    return this.getRa2();
  }

  toJSON(): Record<string, Object> {
    return {
      'id': this.id,
      'name': this.name,
      'puzzle': this.puzzle
    } as Record<string, Object>;
  }

  static fromJSON(obj: Record<string, Object>): Session {
    const s: Session = new Session();
    s.id = (obj['id'] as number) ?? 0;
    s.name = (obj['name'] as string) ?? '';
    s.puzzle = (obj['puzzle'] as number) ?? 33;
    return s;
  }
}
