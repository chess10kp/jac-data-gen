#!/usr/bin/env python3
"""Arrow-backed rewrite of graph_shaped_scan.py.

Old version iterated load_dataset rows (HF Python row-deserialization of
`tests`/`tests_failed` columns was the bottleneck). This one memory-maps the
cached arrow file directly, filters coverage>=90 with pyarrow column ops,
substring-prefilters, and only then regexes survivors in Python.
Same signals, same output: data/graph_shaped_scan.jsonl
"""
import collections
import glob
import json
import re
import time

import pyarrow as pa
import pyarrow.compute as pc
import pyarrow.ipc as ipc

OUT = 'data/graph_shaped_scan.jsonl'
CACHE_GLOB = ('/home/jac/.cache/huggingface/datasets/'
              'nuprl___stack-dedup-python-testgen-starcoder-filter-v2/'
              'default/0.0.0/*/stack-dedup-python-testgen-starcoder-filter-v2-train.arrow')

t0 = time.perf_counter()

# --- load arrow-backed table (memory-mapped, zero row decode) ---
arrow_file = glob.glob(CACHE_GLOB)[0]
with pa.memory_map(arrow_file) as src:
    tbl = ipc.open_stream(src).read_all()
print(f'loaded {tbl.num_rows} rows in {time.perf_counter()-t0:.1f}s', flush=True)

# --- column mask: coverage >= 90 ---
cov_mask = pc.greater_equal(tbl['coverage'], 90)
cov_tbl = tbl.filter(cov_mask)
n_cov = cov_tbl.num_rows
print(f'cov>=90: {n_cov} rows {time.perf_counter()-t0:.1f}s', flush=True)

# --- substring prefilter: needs 'class ' OR 'deque' OR adjacency-ish names ---
sub_tbl = cov_tbl.select(['id', 'content', 'entrypoint'])
content = sub_tbl['content']
has_class = pc.match_substring(content, 'class ')
has_deque = pc.match_substring(content, 'deque')
has_adj = pc.match_substring(content, 'adj')
pre = pc.or_(pc.or_(has_class, has_deque), has_adj)
sub_tbl = sub_tbl.filter(pre)
print(f'prefilter (class/deque/adj): {sub_tbl.num_rows} rows {time.perf_counter()-t0:.1f}s', flush=True)

# --- master dedup ---
MASTER_IDS = set()
for ln in open('data/composer_dataset.jsonl'):
    try:
        MASTER_IDS.add(json.loads(ln)['id'])
    except Exception:
        pass
print(f'master ids: {len(MASTER_IDS)}', flush=True)

# --- regex signals (backtracking-safe) ---
# RE_TREE/RE_STATE in the original used `(?:\s+.*\n)*?` lazy nested
# quantifiers -> catastrophic backtracking on large sources (0.5s+/record).
# Replaced with substring equivalents that preserve the intent.
RE_ADJ = re.compile(r'\b(adjacency|adj_list|adj|edges|graph)\s*[:=]\s*(\{|\[)')
RE_NEIGH = re.compile(r'self\.(neighbors|neighbours|neighbour|nbrs)\s*[:=]')
RE_BFS = re.compile(r'(popleft|pop\(0\))')
RE_DEQUE = re.compile(r'\bdeque\b')
RE_PAR = re.compile(r'self\.parent\s*=')
RE_CHILD = re.compile(r'self\.(children|childs|kids)\s*[:=]')
RE_TRANS = re.compile(r'def\s+(transition|next_state|advance|step)\b')


def classify(src: str) -> list[str]:
    tags = []
    if 'class ' in src and ('self.left' in src or 'self.right' in src):
        tags.append('tree')
    if 'self.next' in src:
        tags.append('linkedlist')
    if RE_ADJ.search(src):
        tags.append('adjacency')
    if RE_NEIGH.search(src):
        tags.append('graphnode')
    if (RE_DEQUE.search(src) or RE_BFS.search(src)) and (RE_ADJ.search(src) or RE_NEIGH.search(src)):
        tags.append('bfs_dfs')
    if RE_PAR.search(src) and RE_CHILD.search(src):
        tags.append('parent_child')
    if 'class ' in src and ('self.state' in src or 'self.states' in src) and RE_TRANS.search(src):
        tags.append('statemachine')
    return tags


ids = sub_tbl['id'].to_pylist()
srcs = sub_tbl['content'].to_pylist()
eps = sub_tbl['entrypoint'].to_pylist()

scanned = hits = 0
with open(OUT, 'w') as f:
    for rec_id, src, ep in zip(ids, srcs, eps):
        scanned += 1
        if scanned % 20000 == 0:
            print(f'  [{scanned}] hits={hits} {time.perf_counter()-t0:.0f}s', flush=True)
        if 'class ' not in src and 'deque' not in src and not RE_ADJ.search(src):
            continue
        if rec_id in MASTER_IDS:
            continue  # already banked — don't count
        tags = classify(src)
        if not tags:
            continue
        hits += 1
        f.write(json.dumps({'id': rec_id, 'tags': tags,
                            'lines': src.count('\n') + 1,
                            'entrypoint': ep}) + '\n')

print(f'done in {time.perf_counter()-t0:.0f}s: cov>=90 total={n_cov} '
      f'deep-scanned={scanned} hits={hits}')
c = collections.Counter()
for ln in open(OUT):
    for t in json.loads(ln)['tags']:
        c[t] += 1
print('tag counts (multi-tag):', dict(c.most_common()))
