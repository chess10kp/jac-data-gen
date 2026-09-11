"""developerz-ai/universal-lsp#4 — graph-lite BFS/DFS with in-walk type filters."""

from __future__ import annotations

from collections import deque


class GraphLite:
    def __init__(self) -> None:
        self.kinds: dict[str, str] = {}
        self.labels: dict[str, str] = {}
        self.adj: dict[str, list[str]] = {}


def load_graph(
    nodes: list[tuple[str, str, str]],
    edges: list[tuple[str, str]],
) -> GraphLite:
    g = GraphLite()
    for nid, kind, label in nodes:
        g.kinds[nid] = kind
        g.labels[nid] = label
        g.adj.setdefault(nid, [])
    for src, tgt in edges:
        if src in g.kinds and tgt in g.kinds:
            g.adj.setdefault(src, []).append(tgt)
            g.adj.setdefault(tgt, g.adj.get(tgt, []))
    return g


def bfs_typed(g: GraphLite, start: str, want: str) -> list[str]:
    if start not in g.kinds:
        return []
    seen: set[str] = set()
    work: deque[str] = deque([start])
    hits: list[str] = []
    while work:
        cur = work.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        if g.kinds[cur] == want:
            hits.append(cur)
        for nxt in g.adj.get(cur, []):
            if nxt not in seen:
                work.append(nxt)
    return sorted(hits)


def dfs_typed(g: GraphLite, start: str, want: str) -> list[str]:
    if start not in g.kinds:
        return []
    seen: set[str] = set()
    stack: list[str] = [start]
    hits: list[str] = []
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        if g.kinds[cur] == want:
            hits.append(cur)
        for nxt in reversed(g.adj.get(cur, [])):
            if nxt not in seen:
                stack.append(nxt)
    return sorted(hits)
