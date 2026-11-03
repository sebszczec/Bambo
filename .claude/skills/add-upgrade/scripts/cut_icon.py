# Cut a Gemini upgrade-card icon (one emblem on a flat green background) into a 256 px PNG with alpha.
#
#   python -I cut_icon.py <src image> <dst.png> [size=256]
#
# Alpha comes from green dominance (G - max(R, B)), so the exact green does not matter. Green spill
# on partly transparent edges is removed. The emblem is trimmed to its bounding box and placed on a
# square canvas with a 10 % margin (art_level1.md 12.4), then scaled to size.
import sys

import numpy as np
from PIL import Image

src, dst = sys.argv[1], sys.argv[2]
size = int(sys.argv[3]) if len(sys.argv) > 3 else 256

im = np.asarray(Image.open(src).convert('RGB')).astype(float)
r, g, b = im[..., 0], im[..., 1], im[..., 2]
greenness = g - np.maximum(r, b)
alpha = np.clip(1 - (greenness - 40) / 60, 0, 1)
g = np.where(alpha < 1, np.minimum(g, np.maximum(r, b)), g)
img = Image.fromarray(np.dstack([r, g, b, alpha * 255]).clip(0, 255).astype(np.uint8), 'RGBA')

bbox = img.getchannel('A').point(lambda v: 255 if v > 20 else 0).getbbox()
if bbox is None:
	sys.exit('no emblem found: the background is not green enough')
crop = img.crop(bbox)
side = int(max(crop.size) / 0.8)
canvas = Image.new('RGBA', (side, side), (0, 0, 0, 0))
canvas.paste(crop, ((side - crop.width) // 2, (side - crop.height) // 2), crop)
canvas.resize((size, size), Image.LANCZOS).save(dst)
print('saved', dst, size, 'px, emblem bbox', bbox)
