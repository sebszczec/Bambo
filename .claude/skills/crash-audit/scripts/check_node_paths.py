#!/usr/bin/env python3
"""Check that $Node and get_node("path") references in a script exist in the scenes that attach it.

A wrong path is a null @onready var or a "Node not found" error the first time that line runs.
Each script is checked against every scene that attaches it; relative paths resolve from the node
the script sits on. The checker cannot see nodes that come from an instanced scene
(e.g. Blast/Debris from beetle_blast.tscn) or nodes made with .new() in code (level_up_menu.gd),
so every MISSING line is a lead to confirm by hand, not a verdict.

Usage:
    python -I check_node_paths.py <project root>
"""
import os
import re
import sys

SKIP_DIRS = ("addons", ".claude", ".godot")


def walk(root, ext):
    for dp, dn, fn in os.walk(root):
        rel = os.path.relpath(dp, root).replace(os.sep, "/")
        if any(rel == d or rel.startswith(d + "/") for d in SKIP_DIRS):
            continue
        for f in fn:
            if f.endswith(ext):
                yield os.path.join(dp, f)


def res_path(root, path):
    return "res://" + os.path.relpath(path, root).replace(os.sep, "/")


def main(root):
    attached = {}  # script res path -> [(scene, node path)]
    scene_paths = {}  # scene -> set of node paths
    for p in walk(root, ".tscn"):
        text = open(p, encoding="utf-8", errors="ignore").read()
        ext = dict((i, path) for path, i in re.findall(r'\[ext_resource[^\]]*?path="([^"]+)"[^\]]*?id="([^"]+)"', text))
        scene = os.path.relpath(p, root).replace(os.sep, "/")
        paths = set()
        for m in re.finditer(r'\[node name="([^"]+)"(.*)\]\n((?:(?!\[).*\n)*)', text):
            name, attrs, body = m.group(1), m.group(2), m.group(3)
            parent = re.search(r'parent="([^"]*)"', attrs)
            if parent is None:
                path = "."
            elif parent.group(1) == ".":
                path = name
            else:
                path = parent.group(1) + "/" + name
            paths.add(path)
            sm = re.search(r'script\s*=\s*ExtResource\("([^"]+)"\)', body)
            if sm and sm.group(1) in ext:
                attached.setdefault(ext[sm.group(1)], []).append((scene, path))
        scene_paths[scene] = paths

    checked = problems = 0
    for p in walk(root, ".gd"):
        rp = res_path(root, p)
        if rp not in attached:
            continue
        src = open(p, encoding="utf-8", errors="ignore").read()
        refs = set(re.findall(r'\$"?([A-Za-z_][\w/]*)', src))
        refs |= set(re.findall(r'get_node(?:_or_null)?\(\s*"([^"]+)"', src))
        for scene, node in attached[rp]:
            for ref in sorted(refs):
                checked += 1
                full = ref if node == "." else node + "/" + ref
                if full in scene_paths[scene]:
                    continue
                print(f"MISSING {ref!r} used by {os.path.relpath(p, root)} (node {node!r} in {scene})")
                problems += 1

    print(f"node paths checked: {checked}, unresolved: {problems} (confirm each by hand: instanced or code-made nodes)")
    return 0


if __name__ == "__main__":
    sys.exit(main(os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else ".")))
