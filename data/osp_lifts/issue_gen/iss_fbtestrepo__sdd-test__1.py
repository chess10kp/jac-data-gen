"""fbtestrepo/sdd-test#1 — Component Dependency Graph API.

Hand-rolled parent/child maps, adjacency lists, deque BFS for transitive
deps, stack DFS for cycle detection, and Kahn-style build ordering.
"""

from __future__ import annotations

from collections import deque


class ComponentGraph:
    """Fresh handle per fixture; all graph state lives here."""

    def __init__(self) -> None:
        self.stamp = 1
        self._pkg: dict[str, str] = {}
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._deps: dict[str, list[str]] = {}
        self._nodes: set[str] = set()


def build_graph(
    specs: list[tuple[str, str, str | None, list[str]]],
) -> ComponentGraph:
    g = ComponentGraph()
    for name, pkg, _parent, _deps in specs:
        g._nodes.add(name)
        g._pkg[name] = pkg
        g._parent.setdefault(name, None)
        g._children.setdefault(name, [])
        g._deps.setdefault(name, [])
    for name, _pkg, parent, deps in specs:
        for dep in deps:
            if dep in g._nodes:
                g._deps[name].append(dep)
        if parent is not None and parent in g._nodes:
            g._parent[name] = parent
            g._children.setdefault(parent, []).append(name)
    return g


def direct_deps(g: ComponentGraph, name: str) -> list[str]:
    if name not in g._nodes:
        return []
    return sorted(g._deps.get(name, []))


def transitive_deps(g: ComponentGraph, name: str) -> list[str]:
    if name not in g._nodes:
        return []
    visited: set[str] = {name}
    queue: deque[str] = deque(g._deps.get(name, []))
    hits: list[str] = []
    while queue:
        cur = queue.popleft()
        if cur in visited:
            continue
        visited.add(cur)
        hits.append(cur)
        for nxt in g._deps.get(cur, []):
            if nxt not in visited:
                queue.append(nxt)
    return sorted(hits)


def children(g: ComponentGraph, name: str) -> list[str]:
    if name not in g._nodes:
        return []
    return sorted(g._children.get(name, []))


def ancestors(g: ComponentGraph, name: str) -> list[str]:
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


def _has_cycle(g: ComponentGraph) -> bool:
    state: dict[str, int] = {n: 0 for n in g._nodes}  # 0=unseen,1=active,2=done

    def dfs(n: str) -> bool:
        state[n] = 1
        for d in g._deps.get(n, []):
            if d not in state:
                continue
            if state[d] == 1:
                return True
            if state[d] == 0 and dfs(d):
                return True
        state[n] = 2
        return False

    return any(state[n] == 0 and dfs(n) for n in g._nodes)


def has_cycle(g: ComponentGraph) -> bool:
    return _has_cycle(g)


def path_to(g: ComponentGraph, src: str, dst: str) -> list[str] | None:
    if src not in g._nodes or dst not in g._nodes:
        return None
    if src == dst:
        return [src]
    parent_map: dict[str, str] = {}
    queue: deque[str] = deque([src])
    seen: set[str] = {src}
    while queue:
        cur = queue.popleft()
        for nxt in g._deps.get(cur, []):
            if nxt in seen:
                continue
            seen.add(nxt)
            parent_map[nxt] = cur
            if nxt == dst:
                path = [dst]
                walk = dst
                while walk != src:
                    walk = parent_map[walk]
                    path.append(walk)
                path.reverse()
                return path
            queue.append(nxt)
    return None


def build_order(g: ComponentGraph) -> list[str] | None:
    if _has_cycle(g):
        return None
    pending = {n: True for n in g._nodes}
    order: list[str] = []
    progress = True
    while progress:
        progress = False
        for nm in sorted(pending.keys()):
            ready = all(d not in pending for d in g._deps.get(nm, []))
            if ready:
                del pending[nm]
                order.append(nm)
                progress = True
    return order if not pending else None
