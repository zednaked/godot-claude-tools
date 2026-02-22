#!/usr/bin/env python3
"""
script-outline.py — Resume .gd ou .cs para Claude Code
Extrai estrutura sem corpo de funções.
Uso: python3 script-outline.py <arquivo.gd|.cs>
"""

import sys
import re

def outline_gdscript(path):
    with open(path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    print(f'# GDScript: {path}')
    in_func = False
    func_indent = 0
    skip_body = False

    for i, line in enumerate(lines):
        stripped = line.rstrip()
        content = stripped.lstrip()

        # Blank lines between top-level items
        if not content:
            if not in_func:
                continue
            continue

        indent = len(stripped) - len(content)

        # Detect end of function body
        if in_func:
            if indent <= func_indent and content:
                in_func = False
            else:
                continue  # skip function body

        # extends
        if content.startswith('extends ') or content.startswith('class_name '):
            print(stripped)
            continue

        # @export / @onready / @export_group / @export_category
        if re.match(r'@(export|onready|warning_ignore|tool)', content):
            print(stripped)
            continue

        # signal
        if re.match(r'signal\s+\w+', content):
            print(stripped)
            continue

        # const / var at top level (indent 0)
        if indent == 0 and re.match(r'(const|var|enum)\s+', content):
            # For enum, print the whole block signature
            print(stripped)
            # If it's a multi-line enum, skip body (handled below)
            if content.startswith('enum') and '{' in content and '}' not in content:
                # Will close on }
                pass
            continue

        # func
        m = re.match(r'(func\s+\w+\s*\([^)]*\).*?):', content)
        if m or re.match(r'func\s+\w+', content):
            print(stripped + ':')
            in_func = True
            func_indent = indent
            continue

        # class (inner class)
        if re.match(r'class\s+\w+', content) and indent == 0:
            print(stripped)
            continue


def outline_csharp(path):
    with open(path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    print(f'# C#: {path}')

    # Track brace depth for method bodies
    class_depth = 0
    method_depth = None
    in_method = False

    for line in lines:
        stripped = line.rstrip()
        content = stripped.lstrip()

        if not content or content.startswith('//') or content.startswith('*') or content.startswith('/*'):
            # Keep using/namespace/class-level comments? No, skip all.
            pass

        # using / namespace
        if re.match(r'(using |namespace )', content):
            print(stripped)
            continue

        # [attributes]
        if re.match(r'\[(\w+)', content):
            print(stripped)
            continue

        # class / struct / interface declaration
        if re.match(r'(public|private|protected|internal|static|abstract|partial|sealed)?\s*(class|struct|interface|enum)\s+', content):
            print(stripped)
            continue

        # fields/properties: lines with type + name at class level (heuristic)
        if re.match(r'(public|private|protected|internal|static|readonly|const|override|virtual|new)\s+', content):
            # Method signature (has parentheses before brace/semicolon)
            if re.search(r'\w+\s*\(', content):
                # It's a method/property — print signature only
                # Remove body on same line
                sig = re.sub(r'\s*\{.*', '', stripped)
                print(sig + ' { ... }' if '{' in stripped else sig + ';')
                in_method = True
                method_depth = stripped.count('{') - stripped.count('}')
                if method_depth <= 0:
                    in_method = False
                continue
            else:
                # Field or property
                print(stripped)
                continue

        if in_method:
            method_depth += content.count('{') - content.count('}')
            if method_depth <= 0:
                in_method = False
            continue

        # Braces for class body
        if content in ('{', '}'):
            print(stripped)
            continue


def main():
    if len(sys.argv) < 2:
        print('Uso: python3 script-outline.py <arquivo.gd|.cs>', file=sys.stderr)
        sys.exit(1)

    path = sys.argv[1]
    if path.endswith('.cs'):
        outline_csharp(path)
    elif path.endswith('.gd'):
        outline_gdscript(path)
    else:
        print(f'Extensão não suportada: {path}', file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
