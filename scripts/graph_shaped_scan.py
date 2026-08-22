#!/usr/bin/env python3
"""Scan the MultiPL-T cov>=90 pool for GRAPH-SHAPED records — candidates for
honest OSP idiomization (node/edge/walker lifts, not forced idioms).

Structural signals (cheap, no LLM):
  T1 tree node class     : class with both 'left'/'right' fields, or 'children'
  T2 linked list         : class with 'next' (and optional 'prev') attribute
  T3 adjacency container : dict/list-of-lists named adjacency/adj/graph/edges
  T4 graph node class    : class with 'neighbors' or 'neighbours' field
  T5 explicit BFS/DFS    : deque/appended (popleft|pop\(0\)) OR stack-based walk,
                           plus edge-like pair iteration
  T6 parent/child refs   : class with 'parent' + child-list or vice versa
  T7 state machine       : class with 'state'/'states' + transition methods
Filter: NOT already banked in composer master (dedup vs master ids).
Out: data/graph_shaped_scan.jsonl + summary counts.
"""
import json, re, sys, time
sys.path.insert(0, 'scripts')
import step4_full_loop as S
from datasets import load_dataset

OUT = 'data/graph_shaped_scan.jsonl'

MASTER_IDS = set()
for ln in open('data/composer_dataset.jsonl'):
    try: MASTER_IDS.add(json.loads(ln)['id'])
    except Exception: pass

RE_TREE   = re.compile(r'class\s+\w+.*?:\s*\n(?:\s+.*\n)*?\s+self\.(left|right)\s*=', re.M)
RE_LL     = re.compile(r'self\.next\s*=')
RE_ADJ    = re.compile(r'\b(adjacency|adj_list|adj|edges|graph)\s*[:=]\s*(\{|\[)')
RE_NEIGH  = re.compile(r'self\.(neighbors|neighbours|neighbour|nbrs)\s*[:=]')
RE_BFS    = re.compile(r'(popleft|pop\(0\))')
RE_DEQUE  = re.compile(r'\bdeque\b')
RE_PAR    = re.compile(r'self\.parent\s*=')
RE_CHILD  = re.compile(r'self\.(children|childs|kids)\s*[:=]')
RE_STATE  = re.compile(r'class\s+\w+.*?:\s*\n(?:\s+.*\n)*?\s+self\.(state|states)\s*[:=]', re.M)
RE_TRANS  = re.compile(r'def\s+(transition|next_state|advance|step)\b')

def classify(src: str) -> list[str]:
    tags = []
    if RE_TREE.search(src): tags.append('tree')
    if RE_LL.search(src): tags.append('linkedlist')
    if RE_ADJ.search(src): tags.append('adjacency')
    if RE_NEIGH.search(src): tags.append('graphnode')
    if (RE_DEQUE.search(src) or RE_BFS.search(src)) and (RE_ADJ.search(src) or RE_NEIGH.search(src)):
        tags.append('bfs_dfs')
    if RE_PAR.search(src) and RE_CHILD.search(src): tags.append('parent_child')
    if RE_STATE.search(src) and RE_TRANS.search(src): tags.append('statemachine')
    return tags

t0 = time.perf_counter()
n = scanned = hits = 0
with open(OUT, 'w') as f:
    for rec in load_dataset(S.DATASET, split='train'):
        cov = rec.get('coverage')
        if cov is None or cov < 90: continue
        n += 1
        if n % 20000 == 0:
            print(f'  [{n}] scanned={scanned} hits={hits} {time.perf_counter()-t0:.0f}s', flush=True)
        src = rec['content']
        if 'class ' not in src and 'deque' not in src and not RE_ADJ.search(src):
            continue
        scanned += 1
        if rec['id'] in MASTER_IDS: continue   # already banked — don't count
        tags = classify(src)
        if not tags: continue
        hits += 1
        f.write(json.dumps({'id': rec['id'], 'tags': tags,
                            'lines': src.count('\n') + 1,
                            'entrypoint': rec.get('entrypoint')}) + '\n')

print(f'done in {time.perf_counter()-t0:.0f}s: cov>=90 total={n} deep-scanned={scanned} hits={hits}')
import collections
c = collections.Counter()
for ln in open(OUT):
    for t in json.loads(ln)['tags']: c[t] += 1
print('tag counts (multi-tag):', dict(c.most_common()))
