"""mtetno/devtools#6 — q2 subtree metric rollup uses recursive CTE + per-node fetches."""

from __future__ import annotations

from collections import defaultdict, deque


class MetricTree:
    # Fresh handle per test; hand-rolled parent pointers + child adjacency.
    def __init__(self) -> None:
        self._values: dict[str, int] = {}
        self._parent_id: dict[str, str] = {}
        self._children: dict[str, list[str]] = defaultdict(list)


def load_tree(
    nodes: list[tuple[str, int]],
    parent_edges: list[tuple[str, str]],
) -> MetricTree:
    g = MetricTree()
    for nid, val in nodes:
        g._values[nid] = val
    for child, parent in parent_edges:
        if child in g._values and parent in g._values:
            g._parent_id[child] = parent
            g._children[parent].append(child)
    return g


def _fetch_metric(g: MetricTree, nid: str) -> int:
    # Simulates per-row SELECT in the N+1 loop the issue flags.
    return g._values.get(nid, 0)


def _recursive_cte_collect(g: MetricTree, root: str, acc: set[str]) -> None:
    # Hand-rolled WITH RECURSIVE body over the adjacency dict.
    for ch in sorted(g._children.get(root, [])):
        if ch in acc:
            continue
        acc.add(ch)
        _recursive_cte_collect(g, ch, acc)


def descendant_ids(g: MetricTree, node_id: str) -> list[str]:
    if node_id not in g._values:
        return []
    settled: set[str] = set()
    work: deque[str] = deque([node_id])
    while work:
        cur = work.popleft()
        for ch in sorted(g._children.get(cur, [])):
            if ch in settled:
                continue
            settled.add(ch)
            work.append(ch)
    return sorted(settled)


def recursive_sum(g: MetricTree, node_id: str) -> int:
    if node_id not in g._values:
        return 0
    total = _fetch_metric(g, node_id)
    closure: set[str] = set()
    _recursive_cte_collect(g, node_id, closure)
    for desc in sorted(closure):
        total += _fetch_metric(g, desc)
    return total
