# Optical-flow in-betweening for a sprite sheet (no AI model, OpenCV DIS flow).
#
#   python -I interpolate.py in.json out.json [--factor 2] [--bridge 119:81:3 ...]
#
# Output frame k = source frame k / factor for k % factor == 0, the rest are
# in-betweens. Every --bridge FROM:TO:N appends N frames morphing source frame
# FROM into TO (for loop seams), they get the indices after the last frame.
import argparse
import os
import sys

import cv2
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sheet import load_meta, load_frames, save_sheet

PAD = 24

_dis = cv2.DISOpticalFlow_create(cv2.DISOPTICAL_FLOW_PRESET_ULTRAFAST)
_dis.setFinestScale(0)
_dis.setPatchSize(8)
_dis.setPatchStride(3)
_dis.setGradientDescentIterations(25)
_dis.setVariationalRefinementIterations(10)


def _gray(f):
	# alpha weighs in so the silhouette drives the flow too
	g = 0.6 * cv2.cvtColor(np.ascontiguousarray(f[..., :3]), cv2.COLOR_RGB2GRAY) + 0.4 * f[..., 3]
	return (np.clip(g, 0, 1) * 255).astype(np.uint8)


def _warp(img, fl):
	h, w = fl.shape[:2]
	gx, gy = np.meshgrid(np.arange(w, dtype=np.float32), np.arange(h, dtype=np.float32))
	return cv2.remap(img, gx + fl[..., 0], gy + fl[..., 1], cv2.INTER_LINEAR, borderMode=cv2.BORDER_CONSTANT, borderValue=0)


def between(a, b, ts):
	# frames between a and b at times ts (0..1), Super SloMo flow approximation
	pa = np.pad(a, ((PAD, PAD), (PAD, PAD), (0, 0)))
	pb = np.pad(b, ((PAD, PAD), (PAD, PAD), (0, 0)))
	f01 = _dis.calc(_gray(pa), _gray(pb), None)
	f10 = _dis.calc(_gray(pb), _gray(pa), None)
	h, w = a.shape[:2]
	out = []
	for t in ts:
		ft0 = -(1 - t) * t * f01 + t * t * f10
		ft1 = (1 - t) * (1 - t) * f01 - t * (1 - t) * f10
		f = (1 - t) * _warp(pa, ft0) + t * _warp(pb, ft1)
		out.append(f[PAD:PAD + h, PAD:PAD + w])
	return out


def main():
	ap = argparse.ArgumentParser()
	ap.add_argument('src')
	ap.add_argument('dst')
	ap.add_argument('--factor', type=int, default=2)
	ap.add_argument('--bridge', action='append', default=[], help='FROM:TO:N source frame indices')
	args = ap.parse_args()

	meta = load_meta(args.src)
	frames = load_frames(meta)
	k = args.factor
	ts = [i / k for i in range(1, k)]

	out = []
	for i, f in enumerate(frames):
		out.append(f)
		if i + 1 < len(frames) and k > 1:
			out.extend(between(f, frames[i + 1], ts))

	for spec in args.bridge:
		a, b, n = (int(x) for x in spec.split(':'))
		start = len(out)
		out.extend(between(frames[a], frames[b], [i / (n + 1) for i in range(1, n + 1)]))
		print(f'bridge {a}->{b}: frames {start}..{len(out) - 1}')

	res = save_sheet(out, args.dst, meta['fps'] * k)
	print(f"{res['frameCount']} frames, {res['columns']}x{res['rows']}, {res['columns'] * res['frameWidth']}x{res['rows'] * res['frameHeight']} px")


if __name__ == '__main__':
	main()
