"""agent-pipe-shared/agent-pipeline#78 — documentation estate reference graph."""

from __future__ import annotations

from collections import deque


class DocEstate:
    def __init__(self) -> None:
        self.adj: dict[str, list[str]] = {}
        self._kinds: dict[str, str] = {}


def load_estate(
    docs: list[tuple[str, str]],
    refs: list[tuple[str, str]],
) -> DocEstate:
    estate = DocEstate()
    for path, kind in docs:
        estate.adj.setdefault(path, [])
        estate._kinds[path] = kind
    for src, dst in refs:
        if src in estate.adj and dst in estate.adj:
            estate.adj[src].append(dst)
    return estate


def reachable_docs(estate: DocEstate, start: str) -> list[str]:
    if start not in estate.adj:
        return []
    seen: set[str] = set()
    queue: deque[str] = deque([start])
    while queue:
        cur = queue.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in sorted(estate.adj.get(cur, [])):
            if nxt not in seen:
                queue.append(nxt)
    return sorted(seen)


def reference_cycle_nodes(estate: DocEstate) -> list[str]:
    WHITE, GRAY, BLACK = 0, 1, 2
    color: dict[str, int] = {}
    found: set[str] = set()

    def dfs(node: str) -> None:
        color[node] = GRAY
        for nxt in estate.adj.get(node, []):
            st = color.get(nxt, WHITE)
            if st == GRAY:
                found.add(nxt)
            elif st == WHITE:
                dfs(nxt)
        color[node] = BLACK

    for n in sorted(estate.adj):
        if color.get(n, WHITE) == WHITE:
            dfs(n)
    return sorted(found)


def orphan_docs(estate: DocEstate, roots: list[str]) -> list[str]:
    reachable: set[str] = set()
    for r in roots:
        reachable.update(reachable_docs(estate, r))
    return sorted(p for p in estate.adj if p not in reachable)


def journey_layers(estate: DocEstate) -> list[list[str]]:
    indegree: dict[str, int] = {n: 0 for n in estate.adj}
    for node, outs in estate.adj.items():
        for _ in outs:
            pass
    for src, outs in estate.adj.items():
        for dst in outs:
            indegree[dst] += 1
    layers: list[list[str]] = []
    ready = {n for n, d in indegree.items() if d == 0}
    visited: set[str] = set()
    while ready:
        layer = sorted(ready)
        layers.append(layer)
        next_ready: set[str] = set()
        for node in layer:
            visited.add(node)
            for nxt in estate.adj.get(node, []):
                if nxt not in visited:
                    indegree[nxt] -= 1
                    if indegree[nxt] == 0:
                        next_ready.add(nxt)
        ready = next_ready
    return layers
