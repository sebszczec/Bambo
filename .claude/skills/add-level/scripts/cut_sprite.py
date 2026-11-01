# Cut a single Gemini image on a green background (flat #00FF00 or a dull green like
# #35B43F with a lighter square) into a trimmed, scaled PNG with alpha.
#
#   python -I cut_sprite.py <src image> <dst.png> <width>
#
# The key is "green dominates": alpha from G - max(R, B), so the exact shade of green does
# not matter and gray stone / cyan glow stay opaque. Only the largest blob is kept (drops
# specks), the edge is eroded 1 px and green spill is clamped.
import sys

import cv2
import numpy as np
from PIL import Image

src, dst, width = sys.argv[1], sys.argv[2], int(sys.argv[3])
im = np.asarray(Image.open(src).convert('RGB')).astype(np.float32) / 255.0
r, g, b = im[..., 0], im[..., 1], im[..., 2]
dom = g - np.maximum(r, b)
alpha = np.clip((0.22 - dom) / 0.12, 0, 1).astype(np.float32)
n, lab, stats, _ = cv2.connectedComponentsWithStats((alpha > 0.5).astype(np.uint8))
big = 1 + np.argmax(stats[1:, cv2.CC_STAT_AREA])
mask = cv2.dilate((lab == big).astype(np.uint8), np.ones((5, 5), np.uint8))
alpha *= mask
alpha = cv2.erode(alpha, np.ones((3, 3), np.uint8))
rgb = im.copy()
rgb[..., 1] = np.minimum(g, np.maximum(r, b) + 0.04)
ys, xs = np.nonzero(alpha > 0.02)
m = 8
x0, y0, x1, y1 = max(xs.min() - m, 0), max(ys.min() - m, 0), xs.max() + m, ys.max() + m
out = np.dstack([rgb, alpha])[y0:y1, x0:x1]
img = Image.fromarray((out * 255).round().astype(np.uint8), 'RGBA')
h = round(img.height * width / img.width)
img.resize((width, h), Image.LANCZOS).save(dst)
print(dst, width, h)
