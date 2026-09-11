"""JustAHobbyDev/more-agent-protocol#20 — Manager delegation + coordination reconciliation.

Hand-rolled manager parent/children maps, coordination adjacency lists,
deque BFS for delegated subtrees and coord closures, reconcile scans
coord edges against the manager's delegation boundary.
"""

from __future__ import annotations

from collections import deque


class CoordGraph:
    """Fresh handle per fixture; all graph state lives here."""

    def __init__(self) -> None:
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._coord: dict[str, list[str]] = {}
        self._nodes: set[str] = set()


def build_coord_graph(
    specs: list[tuple[str, str | None, list[str]]],
) -> CoordGraph:
    # Each spec: (agent_name, manager_name|None, coord_target_names).
    g = CoordGraph()
    for name, _mgr, _coords in specs:
        g._nodes.add(name)
        g._parent.setdefault(name, None)
        g._children.setdefault(name, [])
        g._coord.setdefault(name, [])
    for name, mgr, coords in specs:
        if mgr is not None and mgr in g._nodes:
            g._parent[name] = mgr
            g._children.setdefault(mgr, []).append(name)
        for tgt in coords:
            if tgt in g._nodes:
                g._coord[name].append(tgt)
    return g


def manager_chain(g: CoordGraph, agent: str) -> list[str]:
    if agent not in g._nodes:
        return []
    out: list[str] = []
    seen: set[str] = set()
    cur = g._parent.get(agent)
    while cur is not None:
        if cur in seen:
            break
        seen.add(cur)
        out.append(cur)
        cur = g._parent.get(cur)
    return out


def delegated_subtree(g: CoordGraph, manager: str) -> list[str]:
    if manager not in g._nodes:
        return []
    queue: deque[str] = deque([manager])
    claimed: set[str] = set()
    hits: list[str] = []
    while queue:
        cur = queue.popleft()
        if cur in claimed:
            continue
        claimed.add(cur)
        hits.append(cur)
        for child in g._children.get(cur, []):
            if child not in claimed:
                queue.append(child)
    return sorted(hits)


def coord_successors(g: CoordGraph, agent: str) -> list[str]:
    if agent not in g._nodes:
        return []
    return sorted(g._coord.get(agent, []))


def coord_reachable(g: CoordGraph, agent: str) -> list[str]:
    if agent not in g._nodes:
        return []
    queue: deque[str] = deque(g._coord.get(agent, []))
    claimed: set[str] = {agent}
    hits: list[str] = []
    while queue:
        cur = queue.popleft()
        if cur in claimed:
            continue
        claimed.add(cur)
        hits.append(cur)
        for nxt in g._coord.get(cur, []):
            if nxt not in claimed:
                queue.append(nxt)
    return sorted(hits)


def reconcile(g: CoordGraph, manager: str) -> list[str]:
    if manager not in g._nodes:
        return []
    scope = set(delegated_subtree(g, manager))
    violations: list[str] = []
    for src in scope:
        for dst in g._coord.get(src, []):
            if dst not in scope:
                violations.append(f"{src}->{dst}")
    return sorted(violations)
