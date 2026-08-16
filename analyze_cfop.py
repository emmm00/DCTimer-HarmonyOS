from PIL import Image
import numpy as np

img = Image.open('cfop_chart.png')
arr = np.array(img)
h, w = arr.shape[:2]

# 再次调整内容区边界
regions = {
    'f2l': (150, 650, 2770, 1290),
    'oll': (150, 1540, 2770, 2400),
    'pll': (150, 2700, 2770, 4000),
}

for name, (x0, y0, x1, y1) in regions.items():
    img.crop((x0, y0, x1, y1)).save(f'content3_{name}.png')
    print(f'saved content3_{name}.png size={x1-x0}x{y1-y0}')
