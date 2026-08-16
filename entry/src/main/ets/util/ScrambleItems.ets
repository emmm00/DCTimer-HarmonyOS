// 忠实移植 MainActivity.onCreate 的 scrambleItems/scrambleSubitems 初始化
// （对应 Android res/values/arrays.xml 的 item_scr 与各子项数组）
import { StringUtils } from './StringUtils';

const SCRAMBLE_GROUP_NAMES: string[] = [
  'WCA', '2x2', '3x3', '4x4', '5x5', '6x6', '7x7', 'Megaminx', 'Pyraminx',
  'Square-1', 'Clock', 'Skewb', 'LxMxN', 'Cmetrick', 'Gear Cube', 'Siamese Cube',
  '15 puzzle', 'Other', '3x3 subsets', 'Bandaged Cube', 'Megaminx subsets',
  'Relay', '3x3 CFOP', '3x3 Roux'
];

const SCRAMBLE_SUB_NAMES: string[][] = [
  // 组 0: WCA
  ['3x3x3', '4x4x4', '5x5x5', '2x2x2', '3x3 BLD', '3x3 OH', '3x3 FM', 'Megaminx',
    'Pyraminx', 'Square-1', 'Clock', 'Skewb', '6x6x6', '7x7x7', '4x4 BLD', '5x5 BLD',
    '3x3 MBLD', 'FTO'],
  // 组 1: 2x2
  ['random state', '3-gen', '6-gen', 'CLL training', 'EG1 training', 'EG2 training',
    'PBL training', 'EG training', 'TCLL+ training', 'TCLL- training', 'No bar'],
  // 组 2: 3x3
  ['old style', 'random state', 'cross solved', 'last layer', 'PLL', 'edges only',
    'corners only', 'last slot+last layer', 'ZBLL', 'ELL', 'CLL', 'last six edges',
    'CMLL + LSE', 'edges permutation', 'edges orientation', 'corners permutation',
    'corners orientation', 'permutation only', 'orientation only', 'easy cross',
    '2GLL', 'ZBLS', 'ZZLL', '3-cycle edges', '3-cycle corners', '3x3 for noobs'],
  // 组 3: 4x4
  ['old style', 'SiGN', 'YJ', 'edges', 'R,r,U,u'],
  // 组 4: 5x5
  ['prefix', 'SiGN', 'edges'],
  // 组 5/6: 6x6/7x7（Java 端 7x7 复用 item_666）
  ['prefix', 'SiGN', 'suffix', 'edges'],
  ['prefix', 'SiGN', 'suffix', 'edges'],
  // 组 7: Megaminx
  ['Pochmann', 'old style'],
  // 组 8: Pyraminx
  ['random state', 'random moves', 'L4E'],
  // 组 9: Square-1
  ['face turn metric', 'twist metric', 'random state', 'cube shape', 'PBL'],
  // 组 10: Clock
  ['WCA', 'Jaap order', 'concise', 'efficient pin order'],
  // 组 11: Skewb
  ['random state', 'U L R B', 'L2L'],
  // 组 12: LxMxN
  ['1x3x3', 'Super 1x3x3', '2x3x3', '2x2x3', '2x2x4', '3x3x4', '3x3x5', '3x3x6',
    '3x3x7', '4x4x6', '8x8x8', '9x9x9', '10x10x10', '11x11x11'],
  // 组 13: Cmetrick
  ['normal', 'mini'],
  // 组 14: Gear Cube
  ['random state', '3-gen'],
  // 组 15: Siamese Cube
  ['1x1x3 block', '1x2x3 block', '2x2x2 block'],
  // 组 16: 15 puzzle
  ['piece moves', 'blank moves'],
  // 组 17: Other
  ['Latch Cube', 'Helicopter', 'Square-2', 'Super SQ1', 'UFO', 'FTO', 'Redi cube',
    'Master pyraminx', '8 puzzle', 'CTO', 'Ivy Cube'],
  // 组 18: 3x3 subsets
  ['2-gen R,U', '2-gen L,U', 'Roux-gen M,U', '3-gen F,R,U', '3-gen R,U,L', '3-gen R,r,U',
    'half turns only', 'LSLL(old)'],
  // 组 19: Bandaged Cube
  ['Bicube', 'SQ1 /,(1,0)'],
  // 组 20: Megaminx subsets
  ['2-gen R,U', 'LSLL'],
  // 组 21: Relay
  ['lots of 3x3s', '234 relay', '2345 relay', '23456 relay', '234567 relay',
    'Guildford challenge', 'Mini Guildford challenge'],
  // 组 22: 3x3 CFOP
  ['OLL', 'PLL', 'Last layer', 'F2L', 'ZBLL', 'ZZLL', '2GLL', 'ELL', 'ZBLS', 'COLL',
    'OLLCP', 'EOCP', 'CLL'],
  // 组 23: 3x3 Roux
  ['CMLL', 'LSE', 'L10P']
];

/** 初始化 StringUtils.scrambleItems / scrambleSubitems（对应 MainActivity.onCreate） */
export function initScrambleItems(): void {
  StringUtils.scrambleItems = SCRAMBLE_GROUP_NAMES.slice();
  StringUtils.scrambleSubitems = [];
  for (let i: number = 0; i < SCRAMBLE_SUB_NAMES.length; i++) {
    StringUtils.scrambleSubitems.push(SCRAMBLE_SUB_NAMES[i].slice());
  }
}
