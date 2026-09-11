#!/usr/bin/env python3
"""Sanitize py2jac output and jac-check it; save .floor.jac if it passes."""
import os
import re
import subprocess
import sys

os.chdir(os.path.dirname(os.path.abspath(__file__)))

GT = 'dict[str, dict[str, list[str]]]'
PARAM_TYPES = {
    'root': 'str', '`root': 'str', 'name': 'str', 'task_id': 'str', 'start': 'str',
    'sid': 'int', 'budget': 'int', 'depth': 'int', 'max_depth': 'int',
    'graph': GT, 'state': 'dict', 'seen': 'set', 'visited': 'set', 'queue': 'dict',
    'g': 'dict', 'tree': 'dict', 'env': 'dict', 'fs': 'dict', 'lock': 'dict',
}


def sanitize(src: str) -> str:
    src = src.replace('`set()', 'set()')
    src = re.sub(r'with entry \{\n    ([A-Z_]+) = (\d+);\n\}\n',
                 lambda m: f'glob {m.group(1)}: int = {m.group(2)};\n', src)

    def type_param(m):
        pname = m.group(1)
        if pname in PARAM_TYPES:
            return f'{pname}: {PARAM_TYPES[pname]}'
        return m.group(0)

    src = re.sub(r'(`?\w+): Any\b(?=[,)])', type_param, src)
    # annotate bare locals initialized from set()/{} /[]
    src = re.sub(r'^(\s+)(\w+) = set\(\);', r'\1\2: set = set();', src, flags=re.M)
    src = re.sub(r'^(\s+)(\w+) = \{(\")?', lambda m: f'{m.group(1)}{m.group(2)}: dict = {{{m.group(3) or ""}', src, flags=re.M)
    src = re.sub(r'^(\s+)(\w+) = \[\];', r'\1\2: list = [];', src, flags=re.M)
    return src


def main():
    base = sys.argv[1]
    out = subprocess.run(['jac', 'tool', 'py2jac', f'issue_gen/{base}.py'],
                         capture_output=True, text=True)
    src = out.stdout
    if out.returncode != 0 or not src.strip():
        print(f'{base}: py2jac failed: {out.stderr[:200]}')
        return 'port_failed'
    floor = f'issue_gen/{base}.floor.jac'
    open(floor, 'w').write(sanitize(src))
    chk = subprocess.run(['jac', 'check', floor], capture_output=True, text=True)
    if chk.returncode == 0:
        print(f'{base}: generated')
        return 'generated'
    errs = [l for l in (chk.stdout + chk.stderr).splitlines() if '✖' in l]
    print(f'{base}: port_failed ({len(errs)} errors)')
    for e in errs[:6]:
        print('   ', e)
    return 'port_failed'


if __name__ == '__main__':
    main()
