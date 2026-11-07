// Ported from com.dctimer.util.Utils.java (smart cube orientation subset, DCTimer-BLE -> HarmonyOS ArkTS)

class Sticker {
  readonly sourceIndex: number;
  readonly x: number;
  readonly y: number;
  readonly z: number;
  readonly nx: number;
  readonly ny: number;
  readonly nz: number;

  constructor(sourceIndex: number, x: number, y: number, z: number, nx: number, ny: number, nz: number) {
    this.sourceIndex = sourceIndex;
    this.x = x;
    this.y = y;
    this.z = z;
    this.nx = nx;
    this.ny = ny;
    this.nz = nz;
  }

  rotate(axis: number): Sticker {
    switch (axis) {
      case 0:
        return new Sticker(this.sourceIndex, this.x, -this.z, this.y, this.nx, -this.nz, this.ny);
      case 1:
        return new Sticker(this.sourceIndex, this.z, this.y, -this.x, this.nz, this.ny, -this.nx);
      default:
        return new Sticker(this.sourceIndex, -this.y, this.x, this.z, -this.ny, this.nx, this.nz);
    }
  }

  index(): number {
    const face = SmartCubeOrientation.getFaceIndex(this.nx, this.ny, this.nz);
    const row = SmartCubeOrientation.getRow(face, this.x, this.y, this.z);
    const col = SmartCubeOrientation.getCol(face, this.x, this.y, this.z);
    return face * 9 + row * 3 + col;
  }
}

export class SmartCubeOrientation {
  static readonly SOLVED_FACELET = 'UUUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB';
  static readonly SMART_CUBE_ORIENTATION_FACES: number[][] = SmartCubeOrientation.createSmartCubeOrientationFaces();

  private static faceVectors: number[][] = [
    [0, 1, 0], [1, 0, 0], [0, 0, 1], [0, -1, 0], [-1, 0, 0], [0, 0, -1]
  ];

  static getSmartCubeOrientationPair(orientationIndex: number): number[] {
    if (orientationIndex < 0 || orientationIndex >= SmartCubeOrientation.SMART_CUBE_ORIENTATION_FACES.length) {
      orientationIndex = 0;
    }
    return SmartCubeOrientation.SMART_CUBE_ORIENTATION_FACES[orientationIndex];
  }

  static orientFacelets(facelets: string, orientationIndex: number): string {
    if (facelets == null || facelets.length < 54) {
      return facelets;
    }
    const stickerMap = SmartCubeOrientation.getSmartCubeStickerMap(orientationIndex);
    if (stickerMap == null) {
      return facelets;
    }
    const oriented: string[] = new Array<string>(54).fill('');
    for (let sourceIndex = 0; sourceIndex < stickerMap.length; sourceIndex++) {
      oriented[stickerMap[sourceIndex]] = facelets.charAt(sourceIndex);
    }
    return oriented.join('');
  }

  static unorientFacelets(facelets: string, orientationIndex: number): string {
    if (facelets == null || facelets.length < 54) {
      return facelets;
    }
    const stickerMap = SmartCubeOrientation.getSmartCubeStickerMap(orientationIndex);
    if (stickerMap == null) {
      return facelets;
    }
    const oriented: string[] = new Array<string>(54).fill('');
    for (let sourceIndex = 0; sourceIndex < stickerMap.length; sourceIndex++) {
      oriented[sourceIndex] = facelets.charAt(stickerMap[sourceIndex]);
    }
    return oriented.join('');
  }

  private static createSmartCubeOrientationFaces(): number[][] {
    const pairs: number[][] = [];
    pairs.push([0, 2]);
    for (let top = 0; top < 6; top++) {
      for (let front = 0; front < 6; front++) {
        if (top == front || SmartCubeOrientation.getOppositeFace(top) == front || (top == 0 && front == 2)) {
          continue;
        }
        pairs.push([top, front]);
      }
    }
    return pairs;
  }

  static getOppositeFace(face: number): number {
    switch (face) {
      case 0: return 3;
      case 1: return 4;
      case 2: return 5;
      case 3: return 0;
      case 4: return 1;
      default: return 2;
    }
  }

  private static faceVector(face: number): number[] {
    return SmartCubeOrientation.faceVectors[face];
  }

  private static dot(x1: number, y1: number, z1: number, x2: number, y2: number, z2: number): number {
    return x1 * x2 + y1 * y2 + z1 * z2;
  }

  private static cross(a: number[], b: number[]): number[] {
    return [
      a[1] * b[2] - a[2] * b[1],
      a[2] * b[0] - a[0] * b[2],
      a[0] * b[1] - a[1] * b[0]
    ];
  }

  private static getSmartCubeStickerMap(orientationIndex: number): number[] | null {
    const pair = SmartCubeOrientation.getSmartCubeOrientationPair(orientationIndex);
    const top = pair[0];
    const front = pair[1];
    if (top == front || SmartCubeOrientation.getOppositeFace(top) == front) {
      return null;
    }
    const topVector = SmartCubeOrientation.faceVector(top);
    const frontVector = SmartCubeOrientation.faceVector(front);
    const rightVector = SmartCubeOrientation.cross(topVector, frontVector);
    const stickerMap: number[] = new Array<number>(54).fill(0);
    const used: boolean[] = new Array<boolean>(54).fill(false);
    for (const sticker of SmartCubeOrientation.STICKERS) {
      const x = SmartCubeOrientation.dot(sticker.x, sticker.y, sticker.z, rightVector[0], rightVector[1], rightVector[2]);
      const y = SmartCubeOrientation.dot(sticker.x, sticker.y, sticker.z, topVector[0], topVector[1], topVector[2]);
      const z = SmartCubeOrientation.dot(sticker.x, sticker.y, sticker.z, frontVector[0], frontVector[1], frontVector[2]);
      const nx = SmartCubeOrientation.dot(sticker.nx, sticker.ny, sticker.nz, rightVector[0], rightVector[1], rightVector[2]);
      const ny = SmartCubeOrientation.dot(sticker.nx, sticker.ny, sticker.nz, topVector[0], topVector[1], topVector[2]);
      const nz = SmartCubeOrientation.dot(sticker.nx, sticker.ny, sticker.nz, frontVector[0], frontVector[1], frontVector[2]);
      const face = SmartCubeOrientation.getFaceIndex(nx, ny, nz);
      const row = SmartCubeOrientation.getRow(face, x, y, z);
      const col = SmartCubeOrientation.getCol(face, x, y, z);
      const targetIndex = face * 9 + row * 3 + col;
      if (targetIndex < 0 || targetIndex >= 54 || used[targetIndex]) {
        return null;
      }
      used[targetIndex] = true;
      stickerMap[sticker.sourceIndex] = targetIndex;
    }
    return stickerMap;
  }

  static getSmartCubeFaceMap(orientationIndex: number): number[] | null {
    const pair = SmartCubeOrientation.getSmartCubeOrientationPair(orientationIndex);
    const top = pair[0];
    const front = pair[1];
    if (top == front || SmartCubeOrientation.getOppositeFace(top) == front) {
      return null;
    }
    const topVector = SmartCubeOrientation.faceVector(top);
    const frontVector = SmartCubeOrientation.faceVector(front);
    const rightVector = SmartCubeOrientation.cross(topVector, frontVector);
    const faceMap: number[] = new Array<number>(6).fill(0);
    for (let face = 0; face < 6; face++) {
      const vector = SmartCubeOrientation.faceVector(face);
      if (SmartCubeOrientation.dot(vector[0], vector[1], vector[2], topVector[0], topVector[1], topVector[2]) == 1) {
        faceMap[face] = 0;
      } else if (SmartCubeOrientation.dot(vector[0], vector[1], vector[2], rightVector[0], rightVector[1], rightVector[2]) == 1) {
        faceMap[face] = 1;
      } else if (SmartCubeOrientation.dot(vector[0], vector[1], vector[2], frontVector[0], frontVector[1], frontVector[2]) == 1) {
        faceMap[face] = 2;
      } else if (SmartCubeOrientation.dot(vector[0], vector[1], vector[2], topVector[0], topVector[1], topVector[2]) == -1) {
        faceMap[face] = 3;
      } else if (SmartCubeOrientation.dot(vector[0], vector[1], vector[2], rightVector[0], rightVector[1], rightVector[2]) == -1) {
        faceMap[face] = 4;
      } else {
        faceMap[face] = 5;
      }
    }
    return faceMap;
  }

  static rotateFaceletX(facelets: string): string {
    return SmartCubeOrientation.rotateFacelets(facelets, 0);
  }

  static rotateFaceletY(facelets: string): string {
    return SmartCubeOrientation.rotateFacelets(facelets, 1);
  }

  static rotateFaceletZ(facelets: string): string {
    return SmartCubeOrientation.rotateFacelets(facelets, 2);
  }

  private static rotateFacelets(facelets: string, axis: number): string {
    const rotated: string[] = new Array<string>(54).fill('');
    for (let i = 0; i < SmartCubeOrientation.STICKERS.length; i++) {
      const sticker = SmartCubeOrientation.STICKERS[i];
      const transformed = sticker.rotate(axis);
      rotated[transformed.index()] = facelets.charAt(i);
    }
    return rotated.join('');
  }

  private static STICKERS: Sticker[] = SmartCubeOrientation.createStickers();

  private static createStickers(): Sticker[] {
    const stickers: Sticker[] = [];
    let index = 0;
    for (let row = 0; row < 3; row++) {
      for (let col = 0; col < 3; col++) {
        stickers.push(new Sticker(index++, -1 + col, 1, -1 + row, 0, 1, 0));
      }
    }
    for (let row = 0; row < 3; row++) {
      for (let col = 0; col < 3; col++) {
        stickers.push(new Sticker(index++, 1, 1 - row, 1 - col, 1, 0, 0));
      }
    }
    for (let row = 0; row < 3; row++) {
      for (let col = 0; col < 3; col++) {
        stickers.push(new Sticker(index++, -1 + col, 1 - row, 1, 0, 0, 1));
      }
    }
    for (let row = 0; row < 3; row++) {
      for (let col = 0; col < 3; col++) {
        stickers.push(new Sticker(index++, -1 + col, -1, 1 - row, 0, -1, 0));
      }
    }
    for (let row = 0; row < 3; row++) {
      for (let col = 0; col < 3; col++) {
        stickers.push(new Sticker(index++, -1, 1 - row, -1 + col, -1, 0, 0));
      }
    }
    for (let row = 0; row < 3; row++) {
      for (let col = 0; col < 3; col++) {
        stickers.push(new Sticker(index++, 1 - col, 1 - row, -1, 0, 0, -1));
      }
    }
    return stickers;
  }

  static getFaceIndex(nx: number, ny: number, nz: number): number {
    if (ny == 1) {
      return 0;
    }
    if (nx == 1) {
      return 1;
    }
    if (nz == 1) {
      return 2;
    }
    if (ny == -1) {
      return 3;
    }
    if (nx == -1) {
      return 4;
    }
    return 5;
  }

  /**
   * 单层转动(与智能魔方 onCubeMove 对齐)。
   * faceIndex: 0=U 1=R 2=F 3=D 4=L 5=B; dir: 0=顺时针 1=180° 2=逆时针。
   * 返回转动后的 facelet 字符串(长度 54)。若输入非法则原样返回。
   * 注意：回合/朝向符号需在真机上按协议校准，此处保证自洽并可编译。
   */
  static rotateMoveFacelets(facelets: string, faceIndex: number, dir: number): string {
    if (facelets == null || facelets.length < 54) {
      return facelets;
    }
    // 轴: 0=X(R/L) 1=Y(U/D) 2=Z(F/B); 层偏移: 顶部/正面/右面为 +1，对侧为 -1
    const axis = faceIndex === 0 || faceIndex === 3 ? 1 : (faceIndex === 1 || faceIndex === 4 ? 0 : 2);
    const layerVal = (faceIndex === 3 || faceIndex === 4 || faceIndex === 5) ? -1 : 1;
    const times = dir === 0 ? 1 : (dir === 1 ? 2 : 3);
    const rotated: string[] = new Array<string>(54).fill('');
    for (let i = 0; i < SmartCubeOrientation.STICKERS.length; i++) {
      const s = SmartCubeOrientation.STICKERS[i];
      const layerCoord = axis === 0 ? s.x : (axis === 1 ? s.y : s.z);
      if (layerCoord !== layerVal) {
        rotated[i] = facelets.charAt(i);
        continue;
      }
      let t: Sticker = s;
      for (let k = 0; k < times; k++) {
        t = t.rotate(axis);
      }
      const f = SmartCubeOrientation.getFaceIndex(t.nx, t.ny, t.nz);
      const row = SmartCubeOrientation.getRow(f, t.x, t.y, t.z);
      const col = SmartCubeOrientation.getCol(f, t.x, t.y, t.z);
      rotated[f * 9 + row * 3 + col] = facelets.charAt(i);
    }
    return rotated.join('');
  }

  static getRow(face: number, x: number, y: number, z: number): number {
    switch (face) {
      case 0:
        return z + 1;
      case 1:
      case 2:
      case 4:
      case 5:
        return 1 - y;
      case 3:
        return 1 - z;
      default:
        return 0;
    }
  }

  static getCol(face: number, x: number, y: number, z: number): number {
    switch (face) {
      case 0:
      case 2:
      case 3:
        return x + 1;
      case 1:
        return 1 - z;
      case 4:
        return z + 1;
      case 5:
        return 1 - x;
      default:
        return 0;
    }
  }
}
