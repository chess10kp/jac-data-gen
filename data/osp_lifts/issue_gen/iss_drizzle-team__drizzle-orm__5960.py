"""drizzle-team/drizzle-orm#5960 — Migration DAG distinct leaf collection."""

from __future__ import annotations


class MigGraph:
    def __init__(self) -> None:
        self._nodes: set[str] = set()
        self._children: dict[str, list[str]] = {}


def load_mig_graph(
    nodes: list[str],
    prev_to_children: dict[str, list[str]],
) -> MigGraph:
    g = MigGraph()
    for nid in nodes:
        g._nodes.add(nid)
        g._children.setdefault(nid, [])
    for parent, kids in prev_to_children.items():
        if parent not in g._nodes:
            continue
        for kid in kids:
            if kid in g._nodes:
                g._children.setdefault(parent, []).append(kid)
    return g


def collect_leaves(g: MigGraph, start_id: str) -> list[str]:
    if start_id not in g._nodes:
        return []
    leaves: list[str] = []
    stack = [start_id]
    visited: set[str] = set()
    while stack:
        cur = stack.pop()
        if cur in visited:
            continue
        visited.add(cur)
        children = g._children.get(cur, [])
        if not children:
            leaves.append(cur)
        else:
            for child in children:
                stack.append(child)
    return sorted(set(leaves))


def distinct_leaf_count(g: MigGraph, start_id: str) -> int:
    return len(collect_leaves(g, start_id))
