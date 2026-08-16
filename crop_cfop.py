from PIL import Image, ImageDraw
import numpy as np
import os

img = Image.open('cfop_chart.png')
arr = np.array(img)
h, w = arr.shape[:2]

def detect_cube_bbox(x0, y0, x1, y1, pad=5):
    """在格子里检测红/蓝魔方贴纸，返回内容边界框（限制在格子内）"""
    cell = arr[y0:y1, x0:x1]
    r, g, b = cell[:,:,0], cell[:,:,1], cell[:,:,2]
    red = (r > 180) & (g < 120) & (b < 120)
    blue = (b > 100) & (r < 120) & (g < 170)
    mask = red | blue
    ys, xs = np.where(mask)
    if len(xs) == 0:
        return None
    bx1, by1, bx2, by2 = xs.min(), ys.min(), xs.max(), ys.max()
    return (
        max(x0, x0 + bx1 - pad),
        max(y0, y0 + by1 - pad),
        min(x1, x0 + bx2 + pad),
        min(y1, y0 + by2 + pad)
    )

def crop_category(name, x0, x1, row_bounds, cols_per_row, start_index, total):
    """使用精确行边界裁剪"""
    out_dir = f'entry/src/main/resources/rawfile/cfop/{name}'
    os.makedirs(out_dir, exist_ok=True)
    cell_w = (x1 - x0) / cols_per_row
    idx = start_index
    count = 0
    for row, (cy0, cy1) in enumerate(row_bounds):
        for col in range(cols_per_row):
            if idx > total:
                break
            cx0 = int(x0 + col * cell_w)
            cx1 = int(x0 + (col + 1) * cell_w)
            bbox = detect_cube_bbox(cx0, cy0, cx1, cy1, pad=5)
            if bbox is None:
                print(f'[{name}] case {idx}: no cube detected in cell ({row},{col})')
                idx += 1
                continue
            cropped = img.crop(bbox)
            cropped.save(f'{out_dir}/{idx}.png')
            count += 1
            idx += 1
    print(f'[{name}] cropped {count} cases to {out_dir}')

# 精确行边界
f2l_rows = [(818, 1080), (1080, 1343), (1343, 1613), (1613, 1874)]
oll_rows = [(1874, 2207), (2207, 2418), (2418, 2629), (2629, 2840), (2840, 3058)]
pll_rows = [(3178, 3385), (3385, 3578)]

crop_category('f2l', 180, 2740, f2l_rows, 12, 1, 41)
crop_category('oll', 150, 2770,