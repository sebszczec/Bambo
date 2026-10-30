# Runs an enemy scene in the real game (autoloads loaded) and measures every
# animation switch its AI makes: the jump between the last shown frame and the
# first new one, and whether the crossfade ghost covered it.
#
#   python -I switch_test.py <godot_console_exe> res://scenes/worm_boss.tscn sheet.json
#       [--sprite Ship/AnimatedSprite2D] [--ghost Ship/Ghost] [--seconds 240]
#       [--call _play_hurt --every 5.3]
#
# Temporary files are written to the repo root (they must be under res://) and removed.
import argparse
import collections
import os
import re
import statistics
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sheet import load_meta, load_frames, diff
import transitions

PLAYER = '''extends Node2D
var isDead = false
func addShake(_a = 0, _b = 0): pass
'''

TEST = '''extends Node2D

var enemy
var sprite
var ghost
var tracked = &""
var last_region = Rect2()

func _ready():
	var player = Node2D.new()
	player.set_script(load("res://zz_player_tmp.gd"))
	player.add_to_group("player")
	player.position = Vector2(900, 500)
	add_child(player)
	enemy = load("%(scene)s").instantiate()
	enemy.position = Vector2(400, 500)
	add_child(enemy)
	sprite = enemy.get_node("%(sprite)s")
	ghost = enemy.get_node_or_null("%(ghost)s")
	sprite.animation_changed.connect(_on_changed)
	sprite.frame_changed.connect(_on_frame)
	tracked = sprite.animation
	Engine.time_scale = 4.0
	get_tree().create_timer(%(seconds)s).timeout.connect(func(): get_tree().quit())
	if "%(call)s" != "":
		for i in range(int(%(seconds)s / %(every)s)):
			get_tree().create_timer(2.0 + i * %(every)s).timeout.connect(func(): enemy.call("%(call)s"))

func _region():
	return sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame).region

func _on_frame():
	if sprite.animation == tracked:
		last_region = _region()

func _on_changed():
	var from = tracked
	var from_region = last_region
	tracked = sprite.animation
	_log.call_deferred(from, from_region)

func _log(from, from_region):
	last_region = _region()
	var faded = ghost != null and ghost.visible
	print("SWITCH %%s -> %%s %%d,%%d -> %%d,%%d crossfade=%%s" %% [from, sprite.animation, from_region.position.x, from_region.position.y, last_region.position.x, last_region.position.y, str(faded)])
'''

SCENE = '[gd_scene format=3]\n\n[ext_resource type="Script" path="res://zz_switch_test_tmp.gd" id="1"]\n\n[node name="T" type="Node2D"]\nscript = ExtResource("1")\n'


def main():
	ap = argparse.ArgumentParser()
	ap.add_argument('godot')
	ap.add_argument('scene')
	ap.add_argument('sheet')
	ap.add_argument('--sprite', default='Ship/AnimatedSprite2D')
	ap.add_argument('--ghost', default='Ship/Ghost')
	ap.add_argument('--seconds', type=float, default=240.0)
	ap.add_argument('--call', default='')
	ap.add_argument('--every', type=float, default=5.3)
	args = ap.parse_args()

	files = {'zz_player_tmp.gd': PLAYER, 'zz_switch_test_tmp.tscn': SCENE,
		'zz_switch_test_tmp.gd': TEST % {'scene': args.scene, 'sprite': args.sprite, 'ghost': args.ghost,
			'seconds': args.seconds, 'call': args.call, 'every': args.every}}
	try:
		for name, text in files.items():
			with open(name, 'w', encoding='utf-8', newline='\n') as f:
				f.write(text)
		out = subprocess.run([args.godot, '--headless', '--path', '.', 'res://zz_switch_test_tmp.tscn'],
			capture_output=True, text=True, errors='replace', timeout=args.seconds / 4 + 120).stdout
	finally:
		for name in list(files) + [n + '.uid' for n in files]:
			if os.path.exists(name):
				os.remove(name)

	for line in out.splitlines():
		if 'SCRIPT ERROR' in line:
			print(line)

	meta = load_meta(args.sheet)
	frames = transitions._small(load_frames(meta))
	w, h, cols = meta['frameWidth'], meta['frameHeight'], meta['columns']
	groups = collections.defaultdict(list)
	for line in out.splitlines():
		m = re.match(r'SWITCH (\w+) -> (\w+) (\d+),(\d+) -> (\d+),(\d+) crossfade=(\w+)', line)
		if not m:
			continue
		a, b, x1, y1, x2, y2, faded = m.groups()
		i = (int(y1) // h) * cols + int(x1) // w
		j = (int(y2) // h) * cols + int(x2) // w
		groups[f'{a} -> {b}'].append((diff(frames[i], frames[j]), faded == 'true'))
	for k, v in sorted(groups.items()):
		d = [x for x, _ in v]
		print(f'{k:<26} n={len(v):>3}  jump avg {statistics.mean(d):5.1f} max {max(d):5.1f}  crossfaded {sum(f for _, f in v)}/{len(v)}')


if __name__ == '__main__':
	main()
