"""samyama-ai/samyama-graph#710 — variable-length path endpoint reachability by hop count.

Var-length expand must match endpoints reachable at path lengths min..max hops,
not shortest-path BFS node discovery. The graph uses an adjacency dict; correct
walk queues (node, depth) pairs while the buggy variant uses a once-only
visited set that under-reports fixed-length patterns.
"""

from __future__ import annotations

from collections import deque


class PathGraph:
    def __init__(self) -> None:
        self.nodes: dict[str, bool] = {}
        self.edges: dict[str, list[str]] = {}

    def add_node(self, name: str) -> None:
        self.nodes[name] = True
        self.edges.setdefault(name, [])

    def add_edge(self, src: str, dst: str) -> None:
        if src in self.nodes and dst in self.nodes:
            self.edges[src].append(dst)


def load_graph(
    nodes: list[str],
    edges: list[tuple[str, str]],
) -> PathGraph:
    g = PathGraph()
    for n in nodes:
        g.add_node(n)
    for src, dst in edges:
        g.add_edge(src, dst)
    return g


def reachable_by_path_length(
    g: PathGraph,
    start: str,
    min_len: int,
    max_len: int,
) -> list[str]:
    if start not in g.nodes:
        return []
    results: set[str] = set()
    q: deque[tuple[str, int]] = deque([(start, 0)])
    while q:
        cur, depth = q.popleft()
        if depth > max_len:
            continue
        if min_len <= depth <= max_len and cur != start:
            results.add(cur)
        if depth == max_len:
            continue
        for nxt in g.edges.get(cur, []):
            q.append((nxt, depth + 1))
    return sorted(results)


def shortest_only_broken(
    g: PathGraph,
    start: str,
    min_len: int,
    max_len: int,
) -> list[str]:
    if start not in g.nodes:
        return []
    seen: set[str] = set()
    results: set[str] = set()
    q: deque[tuple[str, int]] = deque([(start, 0)])
    while q:
        cur, depth = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        if min_len <= depth <= max_len and cur != start:
            results.add(cur)
        if depth >= max_len:
            continue
        for nxt in g.edges.get(cur, []):
            if nxt not in seen:
                q.append((nxt, depth + 1))
    return sorted(results)
