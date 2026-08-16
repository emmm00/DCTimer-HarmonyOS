/**
 * ScrambleImage 组件 - 打乱状态图
 * 对应 Android 的 scrambleView (SmartCubeImageView)
 * 使用 Canvas 绘制魔方打乱状态图
 * 支持 2x2~7x7、金字塔、斜转、SQ1 等
 */
@Component
export struct ScrambleImage {
  /** 魔方类型 */
  @Prop puzzleType: PuzzleType = PuzzleType.CUBE_3X3
  /** 各面颜色数据，20 个元素（6面 * 最多3.33面/种）实际为面颜色数组 */
  @Prop faceColors: string[] = [
    '#FFFFFF', '#FFFF00', '#FF0000', '#FF8C00',
    '#0000FF', '#00FF00'
  ]
  /** 打乱状态字符串 */
  @Prop scrambleState: string = ''
  /** 图片尺寸(px) */
  @Prop imageSize: number = 200
  /** 是否显示 */
  @Prop visible: boolean = true
  @State canvasWidth: number = 200
  @State canvasHeight: number = 200

  // 颜色映射 - 标准魔方颜色
  private readonly colors: Record<string, string> = {
    'W': '#FFFFFF', // 白
    'Y': '#FFFF00', // 黄
    'R': '#FF0000', // 红
    'O': '#FF8C00', // 橙
    'B': '#0000FF', // 蓝
    'G': '#00FF00', // 绿
    'U': '#FFFFFF', // 白面 (up)
    'D': '#FFFF00', // 黄面 (down)
    'R_': '#FF0000', // 红面 (right)
    'L': '#FF8C00', // 橙面 (left) — 使用橙色
    'F': '#00FF00', // 绿面 (front)
    'B_': '#0000FF' // 蓝面 (back)
  }

  aboutToAppear(): void {
    this.canvasWidth = this.imageSize
    this.canvasHeight = this.imageSize
  }

  build() {
    Column() {
      if (this.visible) {
        Canvas(this.getContext())
          .width(this.canvasWidth)
          .height(this.canvasHeight)
          .onReady(() => {
            this.drawScramble()
          })
          .borderRadius(8)
          .backgroundColor('#1A1A1A')
      }
    }
    .width(this.canvasWidth)
    .height(this.canvasHeight)
  }

  private getContext(): CanvasRenderingContext2D {
    const context = new Object() as CanvasRenderingContext2D
    return context
  }

  /**
   * 绘制打乱状态图
   * Android 端通过 SmartCubeImageView 将打乱状态字符串渲染为魔方面颜色网格
   * 此处简化：绘制 NxN 面的网格
   */
  private drawScramble(): void {
    const ctx = this.getContext()
    if (!ctx) {
      return
    }

    ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight)

    if (this.puzzleType === PuzzleType.PYRAMINX) {
      this.drawPyraminx(ctx)
    } else if (this.puzzleType === PuzzleType.SKEWB) {
      this.drawSkewb(ctx)
    } else if (this.puzzleType === PuzzleType.SQ1) {
      this.drawSQ1(ctx)
    } else {
      this.drawNxNCube(ctx)
    }
  }

  /** 获取 N 值（2x2~7x7） */
  private getN(): number {
    switch (this.puzzleType) {
      case PuzzleType.CUBE_2X2: return 2
      case PuzzleType.CUBE_3X3: return 3
      case PuzzleType.CUBE_4X4: return 4
      case PuzzleType.CUBE_5X5: return 5
      case PuzzleType.CUBE_6X6: return 6
      case PuzzleType.CUBE_7X7: return 7
      default: return 3
    }
  }

  /** 绘制 NxN 魔方展开图（3 行 x 4 面布局） */
  private drawNxNCube(ctx: CanvasRenderingContext2D): void {
    const n = this.getN()
    // 动态调整面间距与单元格尺寸
    const totalW = this.canvasWidth
    const totalH = this.canvasHeight
    const cols = 4 // 一行最多 4 个面（空白+上+空白+空白 / 左+前+右+后 / 空白+下+空白+空白）
    const rows = 3
    const cellSize = Math.min(totalW / (cols * n + cols + 1), totalH / (rows * n + rows + 1))
    const offsetX = (totalW - (cols * n * cellSize + (cols - 1) * cellSize)) / 2
    const offsetY = (totalH - (rows * n * cellSize + (rows - 1) * cellSize)) / 2

    // 面布局：[row][col] -> 面顺序
    // row 0: [空, U/白, 空, 空]
    // row 1: [L/橙, F/绿, R/红, B/蓝]
    // row 2: [空, D/黄, 空, 空]
    const faceOrder: string[][] = [
      ['', 'U', '', ''],
      ['L', 'F', 'R', 'B'],
      ['', 'D', '', '']
    ]

    for (let row = 0; row < rows; row++) {
      for (let col = 0; col < cols; col++) {
        const face = faceOrder[row][col]
        if (face === '') {
          continue
        }

        const x = offsetX + col * (n * cellSize + cellSize)
        const y = offsetY + row * (n * cellSize + cellSize)
        const color = this.colors[face] || '#888888'

        for (let i = 0; i < n; i++) {
          for (let j = 0; j < n; j++) {
            const cx = x + j * cellSize
            const cy = y + i * cellSize
            ctx.fillStyle = color
            ctx.fillRect(cx + 1, cy + 1, cellSize - 2, cellSize - 2)

            // 边框
            ctx.strokeStyle = '#333333'
            ctx.lineWidth = 0.5
            ctx.strokeRect(cx, cy, cellSize, cellSize)
          }
        }
      }
    }
  }

  /** 绘制金字塔图 */
  private drawPyraminx(ctx: CanvasRenderingContext2D): void {
    const w = this.canvasWidth
    const h = this.canvasHeight
    const ox = w / 2
    const oy = h * 0.3

    // 简化：绘制 4 个三角形
    const size = w * 0.35
    const colors = ['#FF0000', '#00FF00', '#0000FF', '#FFFF00']

    for (let i = 0; i < 4; i++) {
      const angle = (i * Math.PI * 2) / 3 + Math.PI / 6
      const cx = ox + Math.cos(angle) * size * 0.5
      const cy = oy + Math.sin(angle) * size * 0.5

      ctx.fillStyle = colors[i]
      ctx.beginPath()
      ctx.moveTo(ox, oy - size)
      if (i < 3) {
        ctx.lineTo(ox + Math.cos(angle - Math.PI / 6) * size, oy + Math.sin(angle - Math.PI / 6) * size * 0.7)
        ctx.lineTo(ox + Math.cos(angle + Math.PI / 6) * size, oy + Math.sin(angle + Math.PI / 6) * size * 0.7)
      } else {
        // 底部三角形
        ctx.lineTo(ox - size * 0.5, oy + size * 0.6)
        ctx.lineTo(ox + size * 0.5, oy + size * 0.6)
      }
      ctx.closePath()
      ctx.fill()
      ctx.stroke()
    }
  }

  /** 绘制斜转图 */
  private drawSkewb(ctx: CanvasRenderingContext2D): void {
    // 简化斜转绘制：4 种颜色交错的正方形
    const w = this.canvasWidth
    const h = this.canvasHeight
    const size = w * 0.6
    const ox = (w - size) / 2
    const oy = (h - size) / 2

    const colors = ['#FFFFFF', '#FFFF00', '#FF0000', '#00FF00', '#0000FF', '#FF8C00']
    const n = 2
    const cs = size / n

    for (let i = 0; i < n; i++) {
      for (let j = 0; j < n; j++) {
        ctx.fillStyle = colors[(i * n + j) % colors.length]
        ctx.fillRect(ox + j * cs + 1, oy + i * cs + 1, cs - 2, cs - 2)
        ctx.strokeStyle = '#333'
        ctx.lineWidth = 1
        ctx.strokeRect(ox + j * cs, oy + i * cs, cs, cs)
      }
    }
  }

  /** 绘制 SQ1 图 */
  private drawSQ1(ctx: CanvasRenderingContext2D): void {
    const w = this.canvasWidth
    const h = this.canvasHeight

    // 上层（梯形/三角形环）
    const cx = w / 2
    const cy = h * 0.35
    const r = w * 0.3

    // 上层环 - 12 段（30 度每段）
    ctx.fillStyle = '#FFFF00'
    for (let i = 0; i < 12; i++) {
      const a1 = (i * Math.PI * 2) / 12 - Math.PI / 2
      const a2 = ((i + 1) * Math.PI * 2) / 12 - Math.PI / 2
      ctx.fillStyle = i % 2 === 0 ? '#FFFF00' : '#FF8C00'
      ctx.beginPath()
      ctx.moveTo(cx, cy)
      ctx.arc(cx, cy, r, a1, a2)
      ctx.closePath()
      ctx.fill()
      ctx.stroke()
    }

    // 中层
    ctx.fillStyle = '#FF0000'
    ctx.fillRect(cx - r * 0.7, cy + r * 0.1, r * 1.4, r * 0.15)
    ctx.strokeRect(cx - r * 0.7, cy + r * 0.1, r * 1.4, r * 0.15)

    // 下层环
    const cy2 = cy + r * 0.4
    ctx.fillStyle = '#FFFFFF'
    for (let i = 0; i < 12; i++) {
      const a1 = (i * Math.PI * 2) / 12 - Math.PI / 2
      const a2 = ((i + 1) * Math.PI * 2) / 12 - Math.PI / 2
      ctx.fillStyle = i % 2 === 0 ? '#FFFFFF' : '#00FF00'
      ctx.beginPath()
      ctx.moveTo(cx, cy2)
      ctx.arc(cx, cy2, r, a1, a2)
      ctx.closePath()
      ctx.fill()
      ctx.stroke()
    }
  }
}

/** 魔方类型枚举 */
export enum PuzzleType {
  CUBE_2X2 = '2x2',
  CUBE_3X3 = '3x3',
  CUBE_4X4 = '4x4',
  CUBE_5X5 = '5x5',
  CUBE_6X6 = '6x6',
  CUBE_7X7 = '7x7',
  PYRAMINX = 'pyraminx',
  SKEWB = 'skewb',
  SQ1 = 'sq1',
  MEGAMINX = 'megaminx',
  CLOCK = 'clock',
  MINX = 'minx'
}
