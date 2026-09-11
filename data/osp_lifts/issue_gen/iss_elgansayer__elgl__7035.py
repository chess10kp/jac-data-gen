"""elgansayer/elgl#7035 — path locks and dependency-aware factory scheduling."""

from __future__ import annotations

from collections import deque


class FactoryGraph:
    def __init__(self) -> None:
        self._deps: dict[str, list[str]] = {}
        self._locked: set[str] = set()


def load_factory(
    deps: list[tuple[str, str]],
    locked: list[str],
) -> FactoryGraph:
    g = FactoryGraph()
    nodes: set[str] = set()
    for blocker, blocked in deps:
        nodes.update([blocker, blocked])
        g._deps.setdefault(blocker, []).append(blocked)
        g._deps.setdefault(blocked, g._deps.get(blocked, []))
    for n in nodes:
        g._deps.setdefault(n, [])
    g._locked = set(locked)
    return g


def ready_steps(g: FactoryGraph) -> list[str]:
    indeg = {n: 0 for n in g._deps}
    for preds in g._deps.values():
        for p in preds:
            indeg[p] = indeg.get(p, 0)
    for n, preds in g._deps.items():
        for p in preds:
            indeg[n] += 1
    return sorted(
        n for n, d in indeg.items() if d == 0 and n not in g._locked
    )


def has_lock_cycle(g: FactoryGraph) -> bool:
    color: dict[str, int] = {n: 0 for n in g._deps}
    stack: list[str] = []

    def dfs(u: str) -> bool:
        color[u] = 1
        stack.append(u)
        for v in g._deps.get(u, []):
            if color.get(v, 0) == 1:
                return True
            if color.get(v, 0) == 0 and dfs(v):
                return True
        stack.pop()
        color[u] = 2
        return False

    return any(dfs(n) for n in sorted(g._deps) if color[n] == 0)


def locked_reachable(g: FactoryGraph, start: str) -> list[str]:
    if start not in g._deps:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([start])
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in g._deps.get(cur, []):
            if nxt not in seen:
                q.append(nxt)
    return sorted(n for n in seen if n in g._locked)
