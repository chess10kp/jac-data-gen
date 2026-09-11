"""tox-dev/peryx#1343 — Detect aliased requirement include cycles."""

from __future__ import annotations

from collections import defaultdict, deque


class IncludeGraph:
    """Hand-rolled include graph (adjacency lists + manual traversals)."""

    def __init__(self) -> None:
        self._adj: dict[str, list[str]] = defaultdict(list)

    def add_include(self, source: str, target: str) -> None:
        if target not in self._adj[source]:
            self._adj[source].append(target)
        if target not in self._adj:
            self._adj[target] = []

    def includes_of(self, alias: str) -> list[str]:
        return sorted(self._adj.get(alias, []))

    def closure(self, alias: str) -> list[str]:
        if alias not in self._adj:
            return []
        seen: set[str] = set()
        q: deque[str] = deque([alias])
        while q:
            cur = q.popleft()
            if cur in seen:
                continue
            seen.add(cur)
            for nxt in self._adj.get(cur, []):
                if nxt not in seen:
                    q.append(nxt)
        seen.discard(alias)
        return sorted(seen)

    def find_include_cycle(self) -> list[str] | None:
        WHITE, GRAY, BLACK = 0, 1, 2
        color: dict[str, int] = {a: WHITE for a in self._adj}
        parent: dict[str, str | None] = {a: None for a in self._adj}

        def dfs(u: str) -> list[str] | None:
            color[u] = GRAY
            for v in self._adj.get(u, []):
                if v not in color:
                    color[v] = WHITE
                    parent[v] = u
                if color[v] == GRAY:
                    cycle = [v]
                    x = u
                    while x != v:
                        cycle.append(x)
                        x = parent[x]  # type: ignore[assignment]
                    cycle.reverse()
                    cycle.append(v)
                    return cycle
                if color[v] == WHITE:
                    parent[v] = u
                    found = dfs(v)
                    if found:
                        return found
            color[u] = BLACK
            return None

        for start in sorted(self._adj):
            if color[start] == WHITE:
                hit = dfs(start)
                if hit:
                    return hit
        return None
