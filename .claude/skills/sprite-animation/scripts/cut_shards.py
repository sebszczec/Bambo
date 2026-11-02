# Cuts a Gemini key pose (flat green background) into shell shards for a debris particle atlas.
#
#   python -I cut_shards.py key_pose.png atlas.png preview.png
#
# Parts are found along the painted dark outlines and cyan seams (watershed from the plate interiors),
# the three biggest parts are split further with jagged cuts, and every cut edge gets a dark rim with
# a cyan glow vein (broken hive tissue). The atlas is 4x4 cells of 128 px, one shared scale so the
# relative sizes stay true. Used for resources/levels/level2/enemies/boulder_beetle/beetle_shards.png.
import sys, numpy as np, cv2
from PIL import Image
src, out, prev = sys.argv[1:4]
rgb = np.array(Image.open(src).convert('RGB'))
im = rgb.astype(np.float32)


def find_parts(rgb):
	im = rgb.astype(int)
	r, g, b = im[..., 0], im[..., 1], im[..., 2]
	body = ((g - np.maximum(r, b)) < 60).astype(np.uint8)
	body = cv2.morphologyEx(body, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
	luma = 0.3 * r + 0.59 * g + 0.11 * b
	cut = ((luma < 26) | ((b > r + 60) & (g > r + 60))) & (body > 0)
	interior = ((body > 0) & ~cut).astype(np.uint8)
	interior = cv2.morphologyEx(interior, cv2.MORPH_OPEN, np.ones((7, 7), np.uint8))
	n, lab, stats, _ = cv2.connectedComponentsWithStats(interior, 8)
	markers = np.zeros(lab.shape, np.int32)
	k = 0
	for i in range(1, n):
		if stats[i, 4] > 0.004 * body.sum():
			k += 1
			markers[lab == i] = k
	markers[body == 0] = k + 1
	return cv2.watershed(cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR), markers), k + 1


ws, BG = find_parts(rgb)
H, W = ws.shape
rng = np.random.default_rng(7)
BODY = (ws > 0) | (ws == -1)
BODY = cv2.morphologyEx(BODY.astype(np.uint8), cv2.MORPH_CLOSE, np.ones((5, 5), np.uint8))
BODY[ws == BG] = 0
# despill the green key out of the edge pixels
g = im[..., 1]; m = np.maximum(im[..., 0], im[..., 2])
im[..., 1] = np.minimum(g, m + 10)

def jag(n, amp):
	# piecewise linear random offsets along a cut, n samples
	k = rng.uniform(-amp, amp, 13)
	return np.interp(np.linspace(0, 12, n), np.arange(13), k)

def split_x(mask, fracs, slope=0.0):
	ys, xs = np.nonzero(mask)
	x0, x1, yc = xs.min(), xs.max(), ys.mean()
	yy = np.arange(H)
	idx = np.zeros(mask.shape, np.int32)
	X = np.arange(W)[None, :]
	for f in fracs:
		cut = x0 + f * (x1 - x0) + slope * rng.choice([-1, 1]) * (yy - yc) + jag(H, 75)
		idx += (X > cut[:, None])
	return [mask & (idx == i) for i in range(len(fracs) + 1)]

def split_y(mask, fracs):
	ys, xs = np.nonzero(mask)
	y0, y1 = ys.min(), ys.max()
	Y = np.arange(H)[:, None]
	idx = np.zeros(mask.shape, np.int32)
	for f in fracs:
		cut = y0 + f * (y1 - y0) + jag(W, 60)
		idx += (Y > cut[None, :])
	return [mask & (idx == i) for i in range(len(fracs) + 1)]

parts = []
labels = [j for j in np.unique(ws) if j > 0 and j != BG]
sizes = {j: (ws == j).sum() for j in labels}
big = sorted(labels, key=lambda j: -sizes[j])[:3]
for j in labels:
	mask = ws == j
	if j not in big:
		parts.append(mask)
		continue
	xs = np.nonzero(mask)[1]
	if xs.mean() > W * 0.55:
		# front: head off, thorax split along the seam
		front, head = split_x(mask, [0.52])
		parts += split_y(front, [0.5]) + [head]
	else:
		fr = [0.3, 0.55, 0.78] if len(parts) % 2 else [0.36, 0.68]
		parts += split_x(mask, fr, slope=0.35)
parts = [p for p in parts if p.sum() > 3000]
print(len(parts), 'shards')

shards = []
for p in parts:
	p8 = p.astype(np.uint8)
	p8 = cv2.morphologyEx(p8, cv2.MORPH_OPEN, np.ones((5, 5), np.uint8))
	n, lab, st, _ = cv2.connectedComponentsWithStats(p8, 8)
	if n > 2:
		p8 = (lab == 1 + np.argmax(st[1:, 4])).astype(np.uint8)
	ys, xs = np.nonzero(p8)
	y0, y1, x0, x1 = ys.min() - 12, ys.max() + 13, xs.min() - 12, xs.max() + 13
	mask = p8[y0:y1, x0:x1]
	col = im[y0:y1, x0:x1].copy()
	# the cuts through the shell get the hive look: a cyan glowing vein inside a dark rim
	# (only where the cut runs through the body, the original outline stays as painted)
	inner = cv2.erode(mask, np.ones((3, 3), np.uint8), iterations=22)
	rim = (mask > 0) & (inner == 0)
	cutedge = rim.copy()
	body_edge = cv2.erode(BODY[y0:y1, x0:x1], np.ones((3, 3), np.uint8), iterations=26)
	cutedge &= body_edge > 0
	outer = cv2.erode(mask, np.ones((3, 3), np.uint8), iterations=11)
	dark = cutedge & (outer == 0)
	glow = cutedge & (outer > 0)
	col[dark] = (18, 19, 20)
	col[glow] = col[glow] * 0.3 + np.array([107, 219, 235]) * 0.7
	a = cv2.GaussianBlur(mask.astype(np.float32), (3, 3), 0) * 255
	shards.append(np.dstack([col, a]).clip(0, 255).astype(np.uint8))

CELL, COLS = 128, 4
rows = (len(shards) + COLS - 1) // COLS
big = max(max(s.shape[:2]) for s in shards)
f = (CELL - 6) / big
atlas = Image.new('RGBA', (CELL * COLS, CELL * COLS), (0, 0, 0, 0))
order = list(range(len(shards)))
for k, i in enumerate(order[:COLS * COLS]):
	s = Image.fromarray(shards[i])
	s = s.resize((max(1, round(s.width * f)), max(1, round(s.height * f))), Image.LANCZOS)
	cx, cy = (k % COLS) * CELL, (k // COLS) * CELL
	atlas.alpha_composite(s, (cx + (CELL - s.width) // 2, cy + (CELL - s.height) // 2))
atlas.save(out)
bg = Image.new('RGBA', atlas.size, (25, 27, 34, 255)); bg.alpha_composite(atlas); bg.save(prev)
print('scale source->atlas %.4f' % f)
