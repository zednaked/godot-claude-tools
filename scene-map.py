#!/usr/bin/env python3
"""
scene-map.py — Resume .tscn para Claude Code
Reduz ~676 linhas para ~20 linhas ignorando ruído.
Uso: python3 scene-map.py <arquivo.tscn>
"""

import sys
import re

def parse_tscn(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    lines = content.splitlines()
    nodes = []
    connections = []
    current_node = None
    in_sub_resource = False
    in_animation = False

    for line in lines:
        stripped = line.strip()

        # Skip sub_resource blocks (inline resources, animations, bone data)
        if stripped.startswith('[sub_resource'):
            in_sub_resource = True
            continue
        if in_sub_resource:
            if stripped.startswith('[') and not stripped.startswith('[sub_resource'):
                in_sub_resource = False
            else:
                continue

        # Connections
        if stripped.startswith('[connection'):
            m = re.search(r'signal="([^"]+)".*?from="([^"]+)".*?to="([^"]+)".*?method="([^"]+)"', stripped)
            if m:
                connections.append(f'  signal {m.group(1)}: {m.group(2)} -> {m.group(3)}.{m.group(4)}')
            continue

        # Node definition
        if stripped.startswith('[node'):
            if current_node:
                nodes.append(current_node)
            name = re.search(r'name="([^"]+)"', stripped)
            ntype = re.search(r'type="([^"]+)"', stripped)
            parent = re.search(r'parent="([^"]+)"', stripped)
            current_node = {
                'name': name.group(1) if name else '?',
                'type': ntype.group(1) if ntype else 'Node',
                'parent': parent.group(1) if parent else None,
                'script': None,
                'collision_layer': None,
                'visible': None,
            }
            in_animation = False
            continue

        if current_node is None:
            continue

        # Skip animation keys and bone data inside nodes
        if re.match(r'^\s*(tracks/|bones/|blend_shapes/)', line):
            in_animation = True
            continue
        if in_animation and re.match(r'^\s+', line) and not stripped.startswith('['):
            continue
        else:
            in_animation = False

        # Script
        if stripped.startswith('script = ExtResource(') or stripped.startswith('script = SubResource('):
            ref = re.search(r'\((\d+)\)', stripped)
            current_node['script'] = f'script({ref.group(1)})' if ref else 'script(?)'

        # Collision layer
        elif stripped.startswith('collision_layer ='):
            val = stripped.split('=', 1)[1].strip()
            current_node['collision_layer'] = val

        # Visible
        elif stripped.startswith('visible ='):
            val = stripped.split('=', 1)[1].strip()
            if val == 'false':
                current_node['visible'] = False

    if current_node:
        nodes.append(current_node)

    # --- Build script lookup from [ext_resource] ---
    script_map = {}
    for m in re.finditer(r'\[ext_resource[^\]]*?id="?(\d+)"?[^\]]*?path="([^"]+)"', content):
        script_map[m.group(1)] = m.group(2)
    # Also try without quotes on id
    for m in re.finditer(r'\[ext_resource[^\]]*?id=(\d+)[^\]]*?path="([^"]+)"', content):
        script_map[m.group(1)] = m.group(2)

    # --- Output ---
    print(f'# Scene: {path}')
    print(f'# Nodes: {len(nodes)}  Connections: {len(connections)}')
    print()

    for node in nodes:
        parent_str = ''
        if node['parent'] is None:
            parent_str = ''
        elif node['parent'] == '.':
            parent_str = ' (root child)'
        else:
            parent_str = f' (parent: {node["parent"]})'

        extras = []
        if node['script']:
            ref_id = re.search(r'\((\d+)\)', node['script'])
            if ref_id and ref_id.group(1) in script_map:
                script_path = script_map[ref_id.group(1)]
                # Show only filename
                extras.append(f'script={script_path.split("/")[-1]}')
            else:
                extras.append(node['script'])
        if node['collision_layer']:
            extras.append(f'collision_layer={node["collision_layer"]}')
        if node['visible'] is False:
            extras.append('hidden')

        extra_str = f'  [{", ".join(extras)}]' if extras else ''
        print(f'  {node["name"]} ({node["type"]}){parent_str}{extra_str}')

    if connections:
        print()
        print('# Connections:')
        for c in connections:
            print(c)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Uso: python3 scene-map.py <arquivo.tscn>', file=sys.stderr)
        sys.exit(1)
    parse_tscn(sys.argv[1])
