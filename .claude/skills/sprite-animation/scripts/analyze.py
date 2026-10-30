# Finds unnatural jumps in a sprite sheet and in the animations built from it.
#
#   python -I analyze.py sheet.json [anims.json]
#
# Prints per-frame steps of the whole sheet, then for every animation its
# largest inner step, the loop seam (looping ones) and the median step.
# A step well above the median of its animation is a visible pop.
# With "entries"/"exits" in the spec it also reports the animation switches.
import json
import os
import statistics
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sheet import load_meta, load_frames, diff
import transitions


def main():
	meta = load_meta(sys.argv[1])
	frames = load_frames(meta)
	steps = [diff(frames[i - 1], frames[i]) for i in range(1, len(frames))]
	print('sheet steps:', ' '.join(f'{i}:{s:.1f}' for i, s in enumerate(steps, 1)))
	print(f'sheet median step {statistics.median(steps):.1f}')

	if len(sys.argv) < 3:
		return
	with open(sys.argv[2], encoding='utf-8') as f:
		anims = json.load(f)['animations']
	for a in anims:
		fr = a['frames']
		inner = [(diff(frames[fr[i - 1]], frames[fr[i]]), fr[i - 1], fr[i]) for i in range(1, len(fr))]
		med = statistics.median(s for s, _, _ in inner) if inner else 0
		worst = max(inner) if inner else (0, 0, 0)
		line = f"{a['name']:<12} {len(fr):>3} fr @ {a['speed']:>4}fps  median {med:5.1f}  worst {worst[0]:5.1f} ({worst[1]}->{worst[2]})"
		if a.get('loop'):
			seam = diff(frames[fr[-1]], frames[fr[0]])
			line += f"  seam {seam:5.1f}" + ('  <-- POP' if seam > 1.5 * max(med, 1) else '')
		print(line)

	spec = {'animations': anims}
	with open(sys.argv[2], encoding='utf-8') as f:
		spec.update(json.load(f))
	if spec.get('entries') or spec.get('exits'):
		print('\n'.join(transitions.compute(frames, spec)[2]))


if __name__ == '__main__':
	main()
