#!/usr/bin/env python3
"""Check that every signal connection stored in a .tscn points at a method that exists.

A connection like [connection signal="area_entered" from="HitBox" to="." method="_on_hit_box_area_entered"]
fails only when the signal fires, so a renamed or deleted method crashes mid-game. This checks each one
against the script attached to the target node, following `extends` chains (EnemyBase, BossBase, Bullet...).

Usage (run from anywhere, use -I so nothing in the project shadows the stdlib):
    python -I check_connections.py <project root>
Connections to built-in nodes (no script on the target) are counted as skipped, not checked.
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
    gd_src = {}
    class_files = {}
    for p in walk(root, ".gd"):
        rp = res_path(root, p)
        src = open(p, encoding="utf-8", errors="ignore").read()
        gd_src[rp] = src
        m = re.search(r"^class_name\s+(\w+)", src, re.M)
        if m:
            class_files[m.group(1)] = rp

    def methods(rp, seen=None):
        seen = seen or set()
        if rp in seen or rp not in gd_src:
            return set()
        seen.add(rp)
        src = gd_src[rp]
        names = set(re.findall(r"^func\s+(\w+)", src, re.M))
        m = re.search(r"^extends\s+(\w+)", src, re.M)
        if m and m.group(1) in class_files:
            names |= methods(class_files[m.group(1)], seen)
        return names

    checked = resolved = problems = 0
    for p in walk(root, ".tscn"):
        text = open(p, encoding="utf-8", errors="ignore").read()
        ext = dict((i, path) for path, i in re.findall(r'\[ext_resource[^\]]*?path="([^"]+)"[^\]]*?id="([^"]+)"', text))
        node_script = {}
        for m in re.finditer(r'\[node name="([^"]+)"(.*)\]\n((?:(?!\[).*\n)*)', text):
            name, attrs, body = m.group(1), m.group(2), m.group(3)
            parent = re.search(r'parent="([^"]*)"', attrs)
            if parent is None:
                path = "."
            elif parent.group(1) == ".":
                path = name
            else:
                path = parent.group(1) + "/" + name
            sm = re.search(r'script\s*=\s*ExtResource\("([^"]+)"\)', body)
            if sm and sm.group(1) in ext:
                node_script[path] = ext[sm.group(1)]

        for cm in re.finditer(r'\[connection signal="([^"]+)" from="([^"]+)" to="([^"]+)" method="([^"]+)"', text):
            signal, _src, to, method = cm.groups()
            checked += 1
            script = node_script.get(to)
            if script is None:
                continue
            resolved += 1
            if script not in gd_src:
                print(f"MISSING SCRIPT {script} (connection in {os.path.relpath(p, root)})")
                problems += 1
            elif method not in methods(script):
                print(f"MISSING METHOD {method} on {script} (signal {signal} in {os.path.relpath(p, root)})")
                problems += 1

    print(f"connections checked: {checked}, resolved to a script: {resolved}, problems: {problems}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else ".")))
