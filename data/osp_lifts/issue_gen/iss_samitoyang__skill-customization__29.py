"""samitoyang/skill-customization#29 — Architecture deepening and TypeScript migration.

Hand-rolled module parent/child maps, requires adjacency lists, deque BFS for
transitive blocker closure, and frontier sweeps for migration ordering.
"""

from __future__ import annotations

from collections import deque


class ModuleGraph:
    """Fresh handle per fixture; all graph state lives here."""

    def __init__(self) -> None:
        self.stamp = 1
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._requires: dict[str, list[str]] = {}
        self._nodes: set[str] = set()


def load_modules(
    specs: list[tuple[str, str | None, list[str]]],
) -> ModuleGraph:
    g = ModuleGraph()
    for name, _parent, _reqs in specs:
        g._nodes.add(name)
        g._parent.setdefault(name, None)
        g._children.setdefault(name, [])
        g._requires.setdefault(name, [])
    for name, parent, reqs in specs:
        for req in reqs:
            if req in g._nodes:
                g._requires[name].append(req)
        if parent is not None and parent in g._nodes:
            g._parent[name] = parent
            g._children.setdefault(parent, []).append(name)
    return g


def child_modules(g: ModuleGraph, name: str) -> list[str]:
    if name not in g._nodes:
        return []
    return sorted(g._children.get(name, []))


def ancestor_modules(g: ModuleGraph, name: str) -> list[str]:
    if name not in g._nodes:
        return []
    out: list[str] = []
    seen: set[str] = set()
    cur = g._parent.get(name)
    while cur is not None:
        if cur in seen:
            break
        seen.add(cur)
        out.append(cur)
        cur = g._parent.get(cur)
    return out


def blocking_deps(g: ModuleGraph, name: str) -> list[str]:
    if name not in g._nodes:
        return []
    return sorted(g._requires.get(name, []))


def transitive_blockers(g: ModuleGraph, name: str) -> list[str]:
    if name not in g._nodes:
        return []
    visited: set[str] = {name}
    queue: deque[str] = deque(g._requires.get(name, []))
    hits: list[str] = []
    while queue:
        cur = queue.popleft()
        if cur in visited:
            continue
        visited.add(cur)
        hits.append(cur)
        for nxt in g._requires.get(cur, []):
            if nxt not in visited:
                queue.append(nxt)
    return sorted(hits)


def frontier(g: ModuleGraph, done: list[str]) -> list[str]:
    done_set = set(done)
    ready: list[str] = []
    for nm in sorted(g._nodes):
        if nm in done_set:
            continue
        reqs = g._requires.get(nm, [])
        if all(r in done_set for r in reqs):
            ready.append(nm)
    return ready


def migration_order(g: ModuleGraph) -> list[str] | None:
    pending = {n: True for n in g._nodes}
    order: list[str] = []
    progress = True
    while progress:
        progress = False
        for nm in sorted(pending.keys()):
            ready = all(r not in pending for r in g._requires.get(nm, []))
            if ready:
                del pending[nm]
                order.append(nm)
                progress = True
    return order if not pending else None
