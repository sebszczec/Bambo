# Gemini "exploded view" (parts already apart on a green key) -> 4x4 atlas of 128 px cells for a debris burst.
#
#   python -I cut_parts.py parts.jfif atlas.png preview.png
#
# Every separate piece is one part; a big cluster in the front half (pieces that touch) is split along the
# painted outlines (watershed), the big rear piece (abdomen) into 3 jagged chunks. 16 biggest parts, big ones
# share one scale, small chips are enlarged up to 1.8x so they still read. Used for resources/levels/level2/enemies/quarry_mantis/mantis_shards.png.
import sys, numpy as np, cv2
from PIL import Image
src, out, prev = sys.argv[1:4]
rgb8 = np.array(Image.open(src).convert('RGB'))
rgb = rgb8.astype(np.int32)
r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
alpha = np.clip((90 - (g - np.maximum(r, b))) / 50.0, 0, 1)
body = cv2.morphologyEx((alpha > 0.5).astype(np.uint8), cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
luma = 0.3 * r + 0.59 * g + 0.11 * b
n, lab, stats, _ = cv2.connectedComponentsWithStats(body, 8)
masks = []
for i in range(1, n):
	x, y, w, h, a = stats[i]
	if a < 1500:
		continue
	m = lab == i
	if a > 250000 and x > body.shape[1] * 0.4:
		# front cluster (scythes, thorax, head touch): watershed from the plate interiors
		inner = (m & (luma > 45)).astype(np.uint8)
		inner = cv2.morphologyEx(inner, cv2.MORPH_OPEN, np.ones((9, 9), np.uint8))
		k, ilab, ist, _ = cv2.connectedComponentsWithStats(inner, 8)
		markers = np.zeros(m.shape, np.int32)
		c = 0
		for j in range(1, k):
			if ist[j, 4] > 6000:
				c += 1
				markers[ilab == j] = c
		markers[~m] = c + 1
		ws = cv2.watershed(cv2.cvtColor(rgb8, cv2.COLOR_RGB2BGR), markers)
		for j in range(1, c + 1):
			masks.append(cv2.dilate((ws == j).astype(np.uint8), np.ones((3, 3), np.uint8)).astype(bool) & m)
	elif a > 250000:
		# abdomen: 3 jagged chunks along its length
		rng = np.random.default_rng(3)
		X = np.arange(m.shape[1])[None, :]
		idx = np.zeros(m.shape, int)
		for f in (0.36, 0.68):
			jag = np.interp(np.linspace(0, 8, m.shape[0]), np.arange(9), rng.uniform(-0.05, 0.05, 9) * w)
			idx += X > (x + f * w + jag)[:, None]
		for j in range(3):
			masks.append(m & (idx == j))
	else:
		masks.append(m)
col = rgb.copy()
col[..., 1] = np.minimum(g, np.maximum(r, b) + 10)
rgba = np.dstack([col, (alpha * 255).astype(np.int32)]).astype(np.uint8)
pieces = []
for m in masks:
	ys, xs = np.nonzero(m)
	if len(ys) < 1500:
		continue
	y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
	p = rgba[y0:y1, x0:x1].copy()
	mm = m[y0:y1, x0:x1]
	p[..., 3] = np.where(mm, p[..., 3], 0)
	# a cut through a plate gets a dark rim
	cut = mm & ~cv2.erode(mm.astype(np.uint8), np.ones((7, 7), np.uint8)).astype(bool) & (p[..., 3] > 200) & (luma[y0:y1, x0:x1] > 45)
	p[cut, :3] = (p[cut, :3] * 0.25).astype(np.uint8)
	pieces.append((len(ys), p))
pieces.sort(key=lambda t: -t[0])
print(len(pieces), 'pieces', [t[0] for t in pieces[:16]])
pieces = [p for _, p in pieces[:16]]
CELL, PAD = 128, 4
fit = lambda p: (CELL - 2 * PAD) / max(p.shape[:2])
shared = min(fit(p) for p in pieces)
atlas = Image.new('RGBA', (CELL * 4, CELL * 4))
for k, p in enumerate(pieces):
	# big plates keep their relative size, small chips are enlarged a bit so they still read
	s = min(fit(p), shared * 1.8)
	im = Image.fromarray(p)
	im = im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))), Image.LANCZOS)
	cx, cy = (k % 4) * CELL + CELL // 2, (k // 4) * CELL + CELL // 2
	atlas.alpha_composite(im, (cx - im.width // 2, cy - im.height // 2))
atlas.save(out)
bg = Image.new('RGBA', atlas.size, (20, 22, 30, 255)); bg.alpha_composite(atlas); bg.save(prev)
print('shared scale', round(shared, 4))
