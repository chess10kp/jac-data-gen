"""Causal graph: temporal cause-effect mapping over decision traces.

A CausalGraph records cause -> effect links between decision traces
(weighted, typed edges) and must stay a DAG: adding an edge that would
close a cycle is rejected up front by checking whether the cause is
already reachable from the effect. The hand-rolled version keeps
id-keyed adjacency maps, walks them with recursive DFS and color maps
for the cycle pre-check, and recomputes root/leaf lists by scanning all
nodes.
Ref: web3guru888/asi-build#280
"""
from collections import deque


def new_graph():
    return {"traces": {}, "succ": {}, "pred": {}}


def add_trace(graph, trace_id, phase):
    graph["traces"][trace_id] = phase


def _reachable(succ, start, target):
    seen = {start}
    queue = deque([start])
    while queue:
        cur = queue.popleft()
        for nxt in succ.get(cur, []):
            if nxt == target:
                return True
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return False


def add_cause(graph, cause_id, effect_id, weight=1.0):
    """Link cause -> effect; raises ValueError('causal_cycle') when the
    edge would close a cycle (cause already reachable from effect)."""
    if cause_id == effect_id or _reachable(graph["succ"], effect_id, cause_id):
        raise ValueError("causal_cycle")
    graph["succ"].setdefault(cause_id, []).append(effect_id)
    graph["pred"].setdefault(effect_id, []).append(cause_id)


def effects_of(graph, trace_id):
    """Transitive downstream effects of ``trace_id`` (exclusive), sorted."""
    seen = set()
    queue = deque([trace_id])
    while queue:
        cur = queue.popleft()
        for nxt in graph["succ"].get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)


def causes_of(graph, trace_id):
    """Transitive upstream causes of ``trace_id`` (exclusive), sorted."""
    seen = set()
    queue = deque([trace_id])
    while queue:
        cur = queue.popleft()
        for nxt in graph["pred"].get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)


def roots_and_leaves(graph):
    """(roots, leaves): traces with no causes / no effects. Sorted pair."""
    has_cause = set()
    has_effect = set()
    for c, effs in graph["succ"].items():
        has_effect.add(c)
        has_cause.update(effs)
    roots = sorted(t for t in graph["traces"] if t not in has_cause)
    leaves = sorted(t for t in graph["traces"] if t not in has_effect)
    return roots, leaves
