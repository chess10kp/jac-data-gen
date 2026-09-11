"""Read-only hierarchical Roadmap projection over Kanban scopes.

Source: NousResearch/hermes-agent#89493.
"""

from __future__ import annotations

from collections import deque


class Roadmap:
    def __init__(
        self,
        scopes: list[str],
        parent_edges: list[tuple[str, str]],
        dep_edges: list[tuple[str, str]],
        ref_edges: list[tuple[str, str]],
    ) -> None:
        self.scopes = set(scopes)
        self._parent_pairs = list(parent_edges)
        self.parent_adj: dict[str, list[str]] = {s: [] for s in scopes}
        self.dep_adj: dict[str, list[str]] = {s: [] for s in scopes}
        self.ref_adj: dict[str, list[str]] = {s: [] for s in scopes}
        for parent, child in parent_edges:
            if parent in self.scopes and child in self.scopes:
                self.parent_adj[parent].append(child)
        for blocker, blocked in dep_edges:
            if blocker in self.scopes and blocked in self.scopes:
                self.dep_adj[blocker].append(blocked)
        for src, dst in ref_edges:
            if src in self.scopes and dst in self.scopes:
                self.ref_adj[src].append(dst)


def build_roadmap(
    scopes: list[str],
    parent_edges: list[tuple[str, str]],
    dep_edges: list[tuple[str, str]],
    ref_edges: list[tuple[str, str]],
) -> Roadmap:
    return Roadmap(scopes, parent_edges, dep_edges, ref_edges)


def roadmap_children(g: Roadmap, scope_id: str) -> list[str]:
    # N+1-style: linear scan of raw parent pairs per lookup.
    if scope_id not in g.scopes:
        return []
    kids: list[str] = []
    for parent, child in g._parent_pairs:
        if parent == scope_id and child not in kids:
            kids.append(child)
    return sorted(kids)


def roadmap_closure(g: Roadmap, scope_id: str) -> list[str]:
    if scope_id not in g.scopes:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([scope_id])
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for child in g.parent_adj.get(cur, []):
            if child not in seen:
                q.append(child)
    seen.discard(scope_id)
    return sorted(seen)


def has_hierarchy_cycle(g: Roadmap) -> bool:
    visited: set[str] = set()
    stack: set[str] = set()

    def dfs(node: str) -> bool:
        visited.add(node)
        stack.add(node)
        for child in g.parent_adj.get(node, []):
            if child not in visited:
                if dfs(child):
                    return True
            elif child in stack:
                return True
        stack.remove(node)
        return False

    for scope in sorted(g.scopes):
        if scope not in visited and dfs(scope):
            return True
    return False
