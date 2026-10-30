# shared helpers: load/save grid sprite sheets described by a json
# {"image", "frameWidth", "frameHeight", "columns", "rows", "frameCount", "fps"}
import json
import math
import os

import numpy as np
from PIL import Image


def load_meta(json_path):
	with open(json_path, encoding='utf-8') as f:
		meta = json.load(f)
	meta['_dir'] = os.path.dirname(os.path.abspath(json_path))
	return meta


def load_frames(meta):
	# frames as float32 RGBA in 0..1 with premultiplied color
	path = os.path.join(meta['_dir'], meta['image'])
	im = np.asarray(Image.open(path).convert('RGBA')).astype(np.float32) / 255.0
	w, h, cols = meta['frameWidth'], meta['frameHeight'], meta['columns']
	frames = []
	for i in range(meta['frameCount']):
		x, y = (i % cols) * w, (i // cols) * h
		f = im[y:y + h, x:x + w].copy()
		f[..., :3] *= f[..., 3:]
		frames.append(f)
	return frames


def to_rgba8(f):
	f = np.clip(f, 0, 1)
	a = f[..., 3:]
	rgb = np.where(a > 1e-4, f[..., :3] / np.maximum(a, 1e-4), 0)
	return (np.concatenate([np.clip(rgb, 0, 1), a], axis=2) * 255).round().astype(np.uint8)


def save_sheet(frames, json_path, fps, columns=None):
	h, w = frames[0].shape[:2]
	n = len(frames)
	# roughly square sheet, Godot handles up to 16384 px per side
	cols = columns or max(1, round(math.sqrt(n * h / w)))
	rows = math.ceil(n / cols)
	sheet = np.zeros((rows * h, cols * w, 4), dtype=np.uint8)
	for i, f in enumerate(frames):
		x, y = (i % cols) * w, (i // cols) * h
		sheet[y:y + h, x:x + w] = to_rgba8(f)
	image = os.path.splitext(os.path.basename(json_path))[0] + '.png'
	Image.fromarray(sheet).save(os.path.join(os.path.dirname(os.path.abspath(json_path)), image), optimize=True)
	meta = {'image': image, 'frameWidth': w, 'frameHeight': h, 'columns': cols, 'rows': rows, 'frameCount': n, 'fps': fps}
	with open(json_path, 'w', encoding='utf-8') as f:
		json.dump(meta, f, indent=2)
	return meta


def diff(a, b):
	# mean abs difference of premultiplied color + alpha, 0..~200 (x100)
	return float((np.abs(a[..., :3] - b[..., :3]).mean() + np.abs(a[..., 3] - b[..., 3]).mean()) * 100)
