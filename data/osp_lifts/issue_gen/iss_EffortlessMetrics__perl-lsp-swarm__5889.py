"""EffortlessMetrics/perl-lsp-swarm#5889 — Crate publish order and cascade unpublish."""

from __future__ import annotations

from collections import deque


class CrateGraph:
    def __init__(self) -> None:
        self._crates: set[str] = set()
        self._deps: dict[str, set[str]] = {}
        self._dependents: dict[str, set[str]] = {}


def load_crate_graph(
    crates: list[str],
    depends: list[tuple[str, str]],
) -> CrateGraph:
    g = CrateGraph()
    for name in crates:
        g._crates.add(name)
        g._deps.setdefault(name, set())
        g._dependents.setdefault(name, set())
    for crate, dep in depends:
        if crate in g._crates and dep in g._crates:
            g._deps[crate].add(dep)
            g._dependents[dep].add(crate)
    return g


def publish_order(g: CrateGraph) -> list[str]:
    indeg = {n: len(g._deps[n]) for n in g._crates}
    q: deque[str] = deque(sorted(n for n, d in indeg.items() if d == 0))
    out: list[str] = []
    while q:
        cur = q.popleft()
        out.append(cur)
        for dep in sorted(g._dependents.get(cur, ())):
            indeg[dep] -= 1
            if indeg[dep] == 0:
                q.append(dep)
    if len(out) != len(g._crates):
        raise ValueError("publish cycle")
    return out


def _collect_dependents(g: CrateGraph, root: str) -> set[str]:
    seen: set[str] = set()
    stack = [root]
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in g._dependents.get(cur, ()):
            if nxt not in seen:
                stack.append(nxt)
    return seen


def remove_crate_cascade(g: CrateGraph, crate_name: str) -> list[str]:
    if crate_name not in g._crates:
        return []
    doomed = _collect_dependents(g, crate_name)
    for name in sorted(doomed):
        g._crates.discard(name)
        for deps in g._deps.values():
            deps.discard(name)
        for dps in g._dependents.values():
            dps.discard(name)
        g._deps.pop(name, None)
        g._dependents.pop(name, None)
    return sorted(doomed)
