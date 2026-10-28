#!/usr/bin/env python3
"""Outline the visible text of a saved Figma MCP dump.

Reads either a FigJam `get_figjam` dump or a design file `get_metadata` dump
(the JSON-wrapped one the MCP saves when the result is too big). Both are
usually too big to read whole. This prints only the visible text: sections,
stickies, boxes and screen labels, grouped by screen, plus every arrow that
touches them, with absolute canvas positions so swimlanes, timeline order and
which label sits next to which screen can be worked out.

Usage:
  python3 -I figma_outline.py <dump-file>
  python3 -I figma_outline.py <dump-file> --within <node-id>
  python3 -I figma_outline.py <dump-file> --near <node-id> [--radius <px>]
"""

import argparse
import html
import json
import math
import re
import xml.etree.ElementTree as ElementTree

TEXT_TAGS = {'shape-with-text', 'sticky', 'section', 'text', 'widget'}
LEAF_TAGS = {'shape-with-text', 'sticky', 'text'}
SCREEN_MAX_WIDTH = 1920
ROW_HEIGHT = 150


def number(element, attribute):
    try:
        return float(element.get(attribute, 0))
    except ValueError:
        return 0.0


def clean(text):
    return re.sub(r'\s+', ' ', html.unescape(text or '')).strip()


def load_root(path):
    with open(path, encoding='utf-8') as dump:
        source = dump.read()

    if source.lstrip().startswith('['):
        xml_items = [
            item['text']
            for item in json.loads(source)
            if item.get('text', '').lstrip().startswith('<')
        ]
        if not xml_items:
            raise SystemExit('no XML found in this JSON dump')
        source = xml_items[0]

    return ElementTree.fromstring(source)


def walk(element, offset_x, offset_y, screen, ancestors, nodes):
    if element.get('hidden') == 'true':
        return

    x = offset_x + number(element, 'x')
    y = offset_y + number(element, 'y')
    width = number(element, 'width')
    tag = element.tag
    node_id = element.get('id', '')

    if tag == 'frame' and screen is None and 0 < width <= SCREEN_MAX_WIDTH:
        screen = node_id

    if tag == 'section':
        text = clean(element.get('name'))
    elif tag in TEXT_TAGS:
        text = clean(''.join(element.itertext())) or clean(element.get('name'))
    else:
        text = ''

    nodes[node_id] = {
        'tag': tag,
        'x': x,
        'y': y,
        'centre': (x + width / 2, y + number(element, 'height') / 2),
        'color': element.get('color', ''),
        'name': clean(element.get('name')),
        'text': text if tag in TEXT_TAGS else '',
        'screen': screen,
        'ancestors': ancestors,
    }

    if tag in LEAF_TAGS:
        return

    for child in element:
        if child.tag != 'connector':
            walk(child, x, y, screen, ancestors | {node_id}, nodes)


def label(node_id, nodes):
    node = nodes.get(node_id)
    if not node:
        return f'? {node_id}'
    return f"{node['tag']} {node_id} \"{(node['text'] or node['name'])[:60]}\""


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('dump')
    parser.add_argument('--within', help='only this node and what is inside it, e.g. 3067:90256')
    parser.add_argument('--near', help='only what is within --radius of this node, e.g. 782:34208')
    parser.add_argument('--radius', type=float, default=4000)
    args = parser.parse_args()

    root = load_root(args.dump)
    nodes = {}
    walk(root, 0, 0, None, frozenset(), nodes)
    root_id = root.get('id', '')

    in_scope = set(nodes)
    if args.within:
        target = args.within.replace('-', ':')
        if target not in nodes:
            raise SystemExit(f'node {args.within} is not in this dump, or is hidden')
        in_scope = {key for key, node in nodes.items() if key == target or target in node['ancestors']}
    if args.near:
        target = args.near.replace('-', ':')
        if target not in nodes:
            raise SystemExit(f'node {args.near} is not in this dump, or is hidden')
        centre = nodes[target]['centre']
        in_scope = {key for key in in_scope if math.dist(nodes[key]['centre'], centre) <= args.radius}

    boxes = [key for key in in_scope if nodes[key]['text']]

    by_screen = {}
    for key in boxes:
        by_screen.setdefault(nodes[key]['screen'], []).append(key)

    def print_rows(keys):
        rows = []
        for key in sorted(keys, key=lambda key: nodes[key]['y']):
            if rows and nodes[key]['y'] - nodes[rows[-1][0]]['y'] <= ROW_HEIGHT:
                rows[-1].append(key)
            else:
                rows.append([key])
        for row in rows:
            for key in sorted(row, key=lambda key: nodes[key]['x']):
                node = nodes[key]
                colour = f" {node['color']}" if node['color'] else ''
                print(f"  {node['tag']}{colour}\t{key}\tx={node['x']:.0f}\ty={node['y']:.0f}\t{node['text']}")

    print(f'# Visible text, absolute x, y, in rows of {ROW_HEIGHT}px read left to right')
    loose = by_screen.pop(None, [])
    if loose:
        print('\n## Outside any screen')
        print_rows(loose)
    for screen in sorted(by_screen, key=lambda key: (nodes[key]['y'], nodes[key]['x'])):
        node = nodes[screen]
        print(f"\n## Screen frame {screen} \"{node['name']}\" x={node['x']:.0f} y={node['y']:.0f}")
        print_rows(by_screen[screen])

    print('\n# Arrows with at least one end in this outline')
    for connector in root.iter('connector'):
        start, end = connector.get('connectorStart'), connector.get('connectorEnd')
        if start == end or root_id in (start, end):
            continue
        if start not in in_scope and end not in in_scope:
            continue
        text = clean(''.join(connector.itertext()))
        suffix = f'  [{text}]' if text else ''
        print(f'{label(start, nodes)}  ->  {label(end, nodes)}{suffix}')


if __name__ == '__main__':
    main()
