// GAN 机器人协议和编解码器
import { BLEGattHandle, BLEServiceHandle, BLECharacteristicHandle, BLEDescriptorHandle } from './SmartCubeProtocol';

export class GanRobotProtocol {
  static readonly SERVICE_UUID = '0000fff0-0000-1000-8000-00805f9b34fb';
  static readonly CHARACTER_UUID_BUTTON = '0000fff4-0000-1000-8000-00805f9b34fb';
  static readonly CHARACTER_UUID_STATUS = '0000fff2-0000-1000-8000-00805f9b34fb';
  static readonly CHARACTER_UUID_MOVE = '0000fff3-0000-1000-8000-00805f9b34fb';
  static readonly CCCD_UUID = '00002902-0000-1000-8000-00805f9b34fb';

  static isCandidate(deviceName: string): boolean {
    if (!deviceName) return false;
    const normalized = deviceName.trim().toUpperCase();
    return normalized.startsWith('GANBOT-');
  }

  static isButtonPressEvent(rawValue: number[]): boolean {
    return rawValue !== null && rawValue.length > 0 && (rawValue[0] & 0xff) === 0x02;
  }

  static enableNotifications(gatt: BLEGattHandle, service: BLEServiceHandle): void {
    if (!gatt || !service) return;
    // 启用所有通知特征
    const characteristics = [service.getCharacteristic(GanRobotProtocol.CHARACTER_UUID_BUTTON),
                             service.getCharacteristic(GanRobotProtocol.CHARACTER_UUID_STATUS),
                             service.getCharacteristic(GanRobotProtocol.CHARACTER_UUID_MOVE)];
    for (const ch of characteristics) {
      if (!ch) continue;
      gatt.setCharacteristicNotification(ch, true);
      const desc = ch.getDescriptor(GanRobotProtocol.CCCD_UUID);
      if (desc) {
        desc.setValue([0x01, 0x00]);
      }
    }
  }
}

// GAN 机器人指令编码器
export class GanRobotCodec {
  private static readonly MAX_NIBBLES_PER_WRITE = 36;
  private static readonly MOVE_MAP: Map<string, number> = new Map([
    ['R', 0], ['R2', 1], ['R\'', 2],
    ['F', 3], ['F2', 4], ['F\'', 5],
    ['D', 6], ['D2', 7], ['D\'', 8],
    ['L', 9], ['L2', 10], ['L\'', 11],
    ['B', 12], ['B2', 13], ['B\'', 14]
  ]);

  static encodeScramble(scramble: string): number[][] {
    const moves = GanRobotCodec.parseMoves(scramble);
    const nibbles = GanRobotCodec.movesToNibbles(moves);
    if (nibbles.length === 0) return [];
    const packets: number[][] = [];
    for (let offset = 0; offset < nibbles.length; offset += GanRobotCodec.MAX_NIBBLES_PER_WRITE) {
      const end = Math.min(offset + GanRobotCodec.MAX_NIBBLES_PER_WRITE, nibbles.length);
      packets.push(GanRobotCodec.packNibbles(nibbles.slice(offset, end)));
    }
    return packets;
  }

  static estimateRobotCost(algorithm: string): number {
    return GanRobotCodec.parseMoves(algorithm).length;
  }

  static parseMoves(scramble: string): string[] {
    if (!scramble) throw new Error('scramble is empty');
    const normalized = scramble.replace(/['\u2019\uFF07]/g, '\'').trim().replace(/\s+/g, ' ');
    if (normalized.length === 0) throw new Error('scramble is empty');
    const rawTokens = normalized.split(' ');
    const tokens: string[] = [];
    for (const rawToken of rawTokens) {
      tokens.push(GanRobotCodec.normalizeToken(rawToken));
    }
    const expanded: string[] = [];
    for (let i = 0; i < tokens.length; i++) {
      const token = tokens[i];
      if (token.charAt(0) === 'U') {
        let totalQuarterTurns = 0;
        let j = i;
        while (j < tokens.length && tokens[j].charAt(0) === 'U') {
          totalQuarterTurns = (totalQuarterTurns + GanRobotCodec.toQuarterTurns(tokens[j])) % 4;
          j++;
        }
        if (totalQuarterTurns !== 0) {
          expanded.push('F', 'B', 'R2', 'L2', 'B\'', 'F\'');
          expanded.push('D' + GanRobotCodec.toSuffix(totalQuarterTurns));
          expanded.push('F', 'B', 'L2', 'R2', 'B\'', 'F\'');
        }
        i = j - 1;
      } else {
        expanded.push(token);
      }
    }
    return GanRobotCodec.simplifyAdjacentFaceTurns(expanded);
  }

  static movesToNibbles(moves: string[]): number[] {
    const nibbles: number[] = [];
    for (const move of moves) {
      const nibble = GanRobotCodec.MOVE_MAP.get(move);
      if (nibble === undefined) throw new Error('Unsupported move: ' + move);
      nibbles.push(nibble);
    }
    return nibbles;
  }

  private static normalizeToken(token: string): string {
    if (!token) throw new Error('Invalid move: ' + token);
    let normalized = token.trim().toUpperCase();
    if (normalized.length === 0) throw new Error('Invalid move: ' + token);
    if (normalized.endsWith('2\'')) normalized = normalized.substring(0, normalized.length - 1);
    if (!/^[RUFBLD](2|')?$/.test(normalized)) throw new Error('Invalid move: ' + token);
    return normalized;
  }

  private static toQuarterTurns(move: string): number {
    if (move.endsWith('2')) return 2;
    if (move.endsWith('\'')) return 3;
    return 1;
  }

  private static toSuffix(quarterTurns: number): string {
    if (quarterTurns === 2) return '2';
    if (quarterTurns === 3) return '\'';
    return '';
  }

  private static simplifyAdjacentFaceTurns(moves: string[]): string[] {
    const simplified: string[] = [];
    for (const move of moves) {
      if (simplified.length === 0) { simplified.push(move); continue; }
      const lastIdx = simplified.length - 1;
      const lastMove = simplified[lastIdx];
      if (lastMove.charAt(0) !== move.charAt(0)) { simplified.push(move); continue; }
      const combined = (GanRobotCodec.toQuarterTurns(lastMove) + GanRobotCodec.toQuarterTurns(move)) % 4;
      if (combined === 0) {
        simplified.splice(lastIdx, 1);
      } else {
        simplified[lastIdx] = lastMove.charAt(0) + GanRobotCodec.toSuffix(combined);
      }
    }
    return simplified;
  }

  private static packNibbles(nibbles: number[]): number[] {
    const bytes: number[] = new Array<number>(18).fill(0xff);
    for (let i = 0; i < nibbles.length; i++) {
      const value = nibbles[i] & 0x0f;
      const idx = Math.floor(i / 2);
      if (i % 2 === 0) {
        bytes[idx] = value << 4;
      } else {
        bytes[idx] = (bytes[idx] & 0xf0) | value;
      }
    }
    if (nibbles.length % 2 === 1) {
      const idx = Math.floor(nibbles.length / 2);
      bytes[idx] = (bytes[idx] & 0xf0) | 0x0f;
    }
    return bytes;
  }
}
