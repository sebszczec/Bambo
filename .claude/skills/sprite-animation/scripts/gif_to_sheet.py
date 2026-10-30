# Animated GIFs / MP4 / WebM from Gemini -> one transparent grid sprite sheet + json.
#
#   python -I gif_to_sheet.py out.json idle.gif move.mp4 attack.gif ... [--key 00FF00 | --key auto]
#       [--tol 60 --soft 40] [--width 384] [--margin 6] [--preview preview.png]
#       [--fps 12] [--trim move=0.4:3.1 ...] [--shrink 1]
#
# GIF, MP4, WebM and MOV can be mixed. Every clip is resampled to --fps (Gemini videos
# are usually 24 fps, the pipeline starts from 12). --trim CLIP=START:END (seconds,
# CLIP = file name without extension) cuts the part where the ship is on the key pose,
# e.g. a video that settles in for a moment. Video compression smears the key color
# into the edges: --shrink 1 eats 1 px of the alpha edge if a green fringe is left.
#
# One clip per animation (art_bible.md), all of one ship go into one sheet - the frame
# range of every clip is printed and stored in the json ("clips") for the animation spec.
# The background must be a flat chroma color (art_bible.md asks for #00FF00).
# Alpha comes from the color distance to the key (soft edge between tol and tol+soft),
# key spill is removed. All frames of all clips get the same crop (union of the visible
# pixels) so the ship keeps its size and pivot in every animation.
# Effects baked into the clip (bible rule 7 says they should not be): --effects 0.02 drops
# translucent pixels where the key color still dominates, --keep X0,Y0,X1,Y1 (repeatable)
# keeps only those rects of the source frame (cut off what is in front of the ship).
import argparse
import json
import os
import sys

import cv2
import numpy as np
from PIL import Image, ImageSequence

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sheet import save_sheet


def read_frames(path):
	# returns list of float32 RGB 0..1 frames and fps
	ext = os.path.splitext(path)[1].lower()
	if ext == '.gif':
		im = Image.open(path)
		frames, durations = [], []
		for f in ImageSequence.Iterator(im):
			frames.append(np.asarray(f.convert('RGB')).astype(np.float32) / 255.0)
			durations.append(f.info.get('duration', 83) or 83)
		fps = 1000.0 / float(np.median(durations))
		return frames, fps
	cap = cv2.VideoCapture(path)
	fps = cap.get(cv2.CAP_PROP_FPS) or 12.0
	frames = []
	while True:
		ok, f = cap.read()
		if not ok:
			break
		frames.append(cv2.cvtColor(f, cv2.COLOR_BGR2RGB).astype(np.float32) / 255.0)
	return frames, fps


def detect_key(frames):
	# median of the border pixels of the first frames
	f = np.stack(frames[:5])
	border = np.concatenate([f[:, 0].reshape(-1, 3), f[:, -1].reshape(-1, 3), f[:, :, 0].reshape(-1, 3), f[:, :, -1].reshape(-1, 3)])
	return np.median(border, axis=0)


def matte(frame, key, tol, soft, effects=None, keep=None):
	dist = np.linalg.norm((frame - key) * 255.0, axis=2)
	alpha = np.clip((dist - tol) / max(soft, 1e-3), 0.0, 1.0)
	rgb = frame.copy()
	# despill: the key's dominant channel may not exceed the other two
	k = int(np.argmax(key))
	if key[k] > 0.5 and key[k] - np.sort(key)[1] > 0.3:
		others = [c for c in range(3) if c != k]
		limit = np.maximum(rgb[..., others[0]], rgb[..., others[1]])
		if effects is not None:
			# translucent effects baked over the key (radar waves, glows) keep the key
			# channel above the others, the ship itself does not
			dominance = frame[..., k] - limit
			alpha *= np.clip(1.0 - (dominance - effects) / 0.08, 0.0, 1.0)
		rgb[..., k] = np.minimum(rgb[..., k], limit)
	if keep:
		mask = np.zeros(alpha.shape, dtype=bool)
		for x0, y0, x1, y1 in keep:
			mask[y0:y1, x0:x1] = True
		alpha[~mask] = 0.0
	# a gif has no partial transparency, small specks of key noise are dropped
	alpha = cv2.morphologyEx(alpha, cv2.MORPH_OPEN, np.ones((2, 2), np.uint8))
	return np.concatenate([rgb * alpha[..., None], alpha[..., None]], axis=2)


def bbox(frames):
	acc = np.zeros(frames[0].shape[:2], dtype=bool)
	for f in frames:
		acc |= f[..., 3] > 0.05
	ys, xs = np.nonzero(acc)
	return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def main():
	ap = argparse.ArgumentParser()
	ap.add_argument('dst')
	ap.add_argument('src', nargs='+')
	ap.add_argument('--key', default='00FF00', help='hex color or auto')
	ap.add_argument('--tol', type=float, default=60.0)
	ap.add_argument('--soft', type=float, default=40.0)
	ap.add_argument('--width', type=int, default=0, help='scale the cropped frame to this width')
	ap.add_argument('--margin', type=int, default=6)
	ap.add_argument('--preview', default='')
	ap.add_argument('--fps', type=float, default=12.0, help='resample every clip to this frame rate, 0 keeps it')
	ap.add_argument('--trim', action='append', default=[], help='CLIP=START:END in seconds')
	ap.add_argument('--shrink', type=int, default=0, help='erode the alpha edge by N px')
	ap.add_argument('--effects', type=float, default=None, help='drop translucent effects over the key, e.g. 0.02')
	ap.add_argument('--keep', action='append', default=[], help='X0,Y0,X1,Y1 in source pixels, only these rects stay')
	args = ap.parse_args()

	out, clips, fps_all, size = [], {}, [], None
	keep = [tuple(int(v) for v in r.split(',')) for r in args.keep]
	trims = {}
	for t in args.trim:
		clip, span = t.split('=')
		a, b = span.split(':')
		trims[clip] = (float(a or 0), float(b) if b else None)

	for src in args.src:
		frames, fps = read_frames(src)
		name = os.path.splitext(os.path.basename(src))[0]
		if name in trims:
			a, b = trims[name]
			frames = frames[int(round(a * fps)):None if b is None else int(round(b * fps))]
		if args.fps and abs(fps - args.fps) > 0.5:
			# nearest source frame for every output frame
			count = max(1, int(round(len(frames) * args.fps / fps)))
			frames = [frames[min(len(frames) - 1, int(round(i * fps / args.fps)))] for i in range(count)]
			fps = args.fps
		if size is None:
			size = frames[0].shape[:2]
			key = detect_key(frames) if args.key == 'auto' else np.array([int(args.key[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])
		elif frames[0].shape[:2] != size:
			sys.exit(f'{src}: {frames[0].shape[1]}x{frames[0].shape[0]} differs from the first clip - every clip of a ship needs the same canvas')
		clips[name] = [len(out), len(out) + len(frames) - 1]
		fps_all.append(fps)
		out.extend(matte(f, key, args.tol, args.soft, args.effects, keep) for f in frames)
		print(f'{name}: frames {clips[name][0]}..{clips[name][1]} ({len(frames)} @ {fps:.1f} fps)')
	fps = float(np.median(fps_all))
	if args.shrink:
		kernel = np.ones((2 * args.shrink + 1, 2 * args.shrink + 1), np.uint8)
		for f in out:
			eroded = cv2.erode(f[..., 3], kernel)
			# premultiplied color follows the new alpha
			f[..., :3] *= (eroded / np.maximum(f[..., 3], 1e-4))[..., None]
			f[..., 3] = eroded
	print(f'key #{"".join(f"{int(round(c * 255)):02X}" for c in key)}')

	union = list(bbox(out))
	h, w = out[0].shape[:2]
	x0, y0 = max(0, union[0] - args.margin), max(0, union[1] - args.margin)
	x1, y1 = min(w, union[2] + args.margin), min(h, union[3] + args.margin)
	out = [f[y0:y1, x0:x1] for f in out]

	if args.width:
		s = args.width / out[0].shape[1]
		size = (args.width, max(1, round(out[0].shape[0] * s)))
		out = [cv2.resize(f, size, interpolation=cv2.INTER_AREA) for f in out]

	meta = save_sheet(out, args.dst, round(fps))
	meta['clips'] = clips
	with open(args.dst, 'w', encoding='utf-8') as f:
		json.dump(meta, f, indent=2)
	print(f"-> {meta['image']}: {meta['frameCount']} frames {meta['frameWidth']}x{meta['frameHeight']}, crop ({x0},{y0})-({x1},{y1}), {meta['fps']} fps")

	if args.preview:
		# first frame over dark and light backgrounds to judge the edges
		f = out[0]
		tiles = [f[..., :3] + np.array(bg) * (1 - f[..., 3:]) for bg in ((0.04, 0.05, 0.09), (0.85, 0.85, 0.85))]
		Image.fromarray((np.clip(np.concatenate(tiles, axis=1), 0, 1) * 255).astype(np.uint8)).save(args.preview)


if __name__ == '__main__':
	main()
