"""Rushow111/Knowledge-Ball#117 — KVOP acceptance audit.

Knowledge Version & Opposition Protocol: version lineage (parent pointers)
and workflow depends graph must match spec for page acceptance audits.
"""

from __future__ import annotations

from collections import deque


class KVOPGraph:
    def __init__(self) -> None:
        self._versions: dict[str, str] = {}
        self._lineage: dict[str, str] = {}  # child -> parent (C1)
        self._depends: dict[str, list[str]] = {}  # src -> [deps] (C2)


def load_kvop(
    versions: list[tuple[str, str]],
    depends: list[tuple[str, str]],
    lineage: list[tuple[str, str]],
) -> KVOPGraph:
    g = KVOPGraph()
    for vid, label in versions:
        g._versions[vid] = label
        g._depends.setdefault(vid, [])
    for child, parent in lineage:
        if child in g._versions and parent in g._versions:
            g._lineage[child] = parent
    for src, dst in depends:
        if src in g._versions and dst in g._versions:
            g._depends.setdefault(src, []).append(dst)
            g._depends.setdefault(dst, g._depends.get(dst, []))
    return g


def lineage_ancestors(g: KVOPGraph, vid: str) -> list[str]:
    if vid not in g._versions:
        return []
    out: list[str] = []
    cur: str | None = g._lineage.get(vid)
    while cur:
        out.append(cur)
        cur = g._lineage.get(cur)
    return sorted(out)


def dep_closure(g: KVOPGraph, vid: str) -> list[str]:
  # Transitive build prerequisites: src depends on dst, walk depends edges.
    if vid not in g._versions:
        return []
    seen: set[str] = {vid}
    q: deque[str] = deque([vid])
    hits: list[str] = []
    while q:
        cur = q.popleft()
        for dep in g._depends.get(cur, []):
            if dep in seen:
                continue
            seen.add(dep)
            hits.append(dep)
            q.append(dep)
    return sorted(hits)


def audit_reachable(g: KVOPGraph, start: str, target: str) -> bool:
    if start not in g._versions or target not in g._versions:
        return False
    if start == target:
        return True
    return target in dep_closure(g, start)


def has_dep_cycle(g: KVOPGraph) -> bool:
    color: dict[str, int] = {v: 0 for v in g._versions}
    def dfs(u: str) -> bool:
        color[u] = 1
        for v in g._depends.get(u, []):
            if color[v] == 1:
                return True
            if color[v] == 0 and dfs(v):
                return True
        color[u] = 2
        return False
    return any(dfs(v) for v in sorted(g._versions) if color[v] == 0)


def audit_closure(g: KVOPGraph, vid: str) -> list[str]:
    if vid not in g._versions:
        return []
    scope: set[str] = {vid}
    scope.update(lineage_ancestors(g, vid))
    scope.update(dep_closure(g, vid))
    return sorted(scope)
