# Rewrites the SpriteFrames (and its AtlasTextures) of a .tscn from an animation spec.
#
#   python -I spriteframes.py scene.tscn sheet.json anims.json
#
# anims.json: {"texture_id": "2_sheet", "spriteframes_id": "SpriteFrames_worm",
#   "animations": [{"name": "Idle", "frames": [0, 1, ...], "loop": true, "speed": 24.0}, ...],
#   "entries": [...], "exits": {...}}   optional, see transitions.py
# The ext_resource with texture_id is pointed at the sheet image (res:// path is
# derived from the json location), load_steps is recomputed.
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sheet import load_meta, load_frames
import transitions


def res_path(path):
	# res:// path, project root is the folder holding project.godot
	d = os.path.dirname(os.path.abspath(path))
	root = d
	while not os.path.exists(os.path.join(root, 'project.godot')):
		parent = os.path.dirname(root)
		if parent == root:
			sys.exit('project.godot not found above ' + path)
		root = parent
	return 'res://' + os.path.relpath(os.path.abspath(path), root).replace('\\', '/')


def main():
	scene, sheet_json, anims_json = sys.argv[1:4]
	meta = load_meta(sheet_json)
	with open(anims_json, encoding='utf-8') as f:
		spec = json.load(f)
	tex_id, sf_id = spec['texture_id'], spec['spriteframes_id']
	w, h, cols = meta['frameWidth'], meta['frameHeight'], meta['columns']

	with open(scene, encoding='utf-8') as f:
		src = f.read()

	used = sorted({i for a in spec['animations'] for i in a['frames']})
	bad = [i for i in used if i >= meta['frameCount']]
	if bad:
		sys.exit(f'frames out of range: {bad}')

	subs = [f'[sub_resource type="AtlasTexture" id="AtlasTexture_{i}"]\natlas = ExtResource("{tex_id}")\n'
			f'region = Rect2({(i % cols) * w}, {(i // cols) * h}, {w}, {h})\n' for i in used]
	parts = []
	for a in spec['animations']:
		fr = ', '.join('{\n"duration": 1.0,\n"texture": SubResource("AtlasTexture_%d")\n}' % i for i in a['frames'])
		parts.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %s\n}'
			% (fr, 'true' if a.get('loop') else 'false', a['name'], float(a['speed'])))
	sf = f'[sub_resource type="SpriteFrames" id="{sf_id}"]\nanimations = [' + ', '.join(parts) + ']\n'
	if spec.get('entries') or spec.get('exits'):
		entries, exits, report = transitions.compute(load_frames(meta), spec)
		sf += transitions.to_tscn(entries, exits)
		print('\n'.join(report))

	# drop the old atlas textures and spriteframes, keep any other sub resources
	blocks = re.split(r'(?=^\[)', src, flags=re.M)
	kept = []
	inserted = False
	for b in blocks:
		if b.startswith('[sub_resource type="AtlasTexture"') and f'ExtResource("{tex_id}")' in b:
			continue
		if b.startswith(f'[sub_resource type="SpriteFrames" id="{sf_id}"]'):
			continue
		if b.startswith('[node') and not inserted:
			kept.append('\n'.join(subs) + '\n' + sf + '\n')
			inserted = True
		kept.append(b)
	src = ''.join(kept)

	image_res = res_path(os.path.join(meta['_dir'], meta['image']))
	src, n = re.subn(r'(\[ext_resource type="Texture2D"[^\]]*?path=")[^"]*("[^\]]*id="%s"\])' % re.escape(tex_id),
		r'\g<1>%s\g<2>' % image_res, src)
	if n != 1:
		sys.exit(f'ext_resource {tex_id} not found')
	# a stale uid would win over the new path
	src = re.sub(r'(\[ext_resource type="Texture2D") uid="[^"]*"([^\]]*id="%s"\])' % re.escape(tex_id), r'\1\2', src)
	steps = src.count('[ext_resource') + src.count('[sub_resource') + 1
	src = re.sub(r'load_steps=\d+', f'load_steps={steps}', src, count=1)

	with open(scene, 'w', encoding='utf-8', newline='\n') as f:
		f.write(src)
	print(f'{len(used)} frames, {len(spec["animations"])} animations -> {scene} ({image_res})')


if __name__ == '__main__':
	main()
