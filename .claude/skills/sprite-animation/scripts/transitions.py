# Best frames for switching between animations, stored as SpriteFrames metadata.
#
# spec (in the animations json):
#   "entries": ["Idle", "Move"]   loops the script may start from any frame:
#       entry_<Loop> = {&"Anim": PackedInt32Array(best loop frame for every frame of Anim)}
#       the picked loop frame is the one whose *previous* frame looks most like the last
#       shown frame, so the loop simply continues from it
#   "exits": {"Move": ["Spread", ...]}   planned switches out of a loop:
#       exit_<Loop> = {&"Spread": loop frame whose *next* frame looks most like Spread's first}
#       the script times the loop to sit on that frame when it switches
import statistics

import cv2
import numpy as np

from sheet import diff


def _small(frames):
	# quarter size is plenty to compare poses and keeps the tables fast
	return [cv2.resize(f, (f.shape[1] // 4, f.shape[0] // 4), interpolation=cv2.INTER_AREA) for f in frames]


def compute(frames, spec):
	anims = {a['name']: a['frames'] for a in spec['animations']}
	small = _small(frames)
	cache = {}

	def d(a, b):
		key = (a, b) if a < b else (b, a)
		if key not in cache:
			cache[key] = diff(small[a], small[b])
		return cache[key]

	entries, exits, report = {}, {}, []
	for loop in spec.get('entries', []):
		lf = anims[loop]
		n = len(lf)
		table = {}
		for name, fr in anims.items():
			best = []
			for f in fr:
				j = min(range(n), key=lambda j: d(f, lf[j - 1]))
				best.append((j, d(f, lf[j - 1])))
			table[name] = [j for j, _ in best]
			cost = [c for _, c in best]
			report.append(f'entry {name:>12} -> {loop:<6} last frame {cost[-1]:5.1f}  avg {statistics.mean(cost):5.1f}  worst {max(cost):5.1f}'
				f'  (from frame 0: last {d(fr[-1], lf[0]):5.1f})')
		entries[loop] = table

	for loop, targets in spec.get('exits', {}).items():
		lf = anims[loop]
		n = len(lf)
		step = statistics.median(d(lf[i], lf[(i + 1) % n]) for i in range(n))
		table = {}
		for t in targets:
			first = anims[t][0]
			i = min(range(n), key=lambda i: d(lf[(i + 1) % n], first))
			table[t] = i
			avg = statistics.mean(d(f, first) for f in lf)
			report.append(f'exit  {loop:>12} -> {t:<12} at frame {i:>3}: {d(lf[(i + 1) % n], first):5.1f} instead of {d(lf[i], first):5.1f}'
				f' (random frame avg {avg:5.1f}, loop step {step:4.1f})')
		exits[loop] = table
	return entries, exits, report


def to_tscn(entries, exits):
	lines = []
	for loop, table in entries.items():
		body = ', '.join(f'&"{name}": PackedInt32Array({", ".join(map(str, v))})' for name, v in table.items())
		lines.append(f'metadata/entry_{loop} = {{{body}}}')
	for loop, table in exits.items():
		body = ', '.join(f'&"{name}": {i}' for name, i in table.items())
		lines.append(f'metadata/exit_{loop} = {{{body}}}')
	return '\n'.join(lines) + ('\n' if lines else '')
