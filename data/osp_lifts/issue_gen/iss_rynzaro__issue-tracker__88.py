"""rynzaro/issue-tracker#88 — Wayfinder: handing a sub-task to another user.

Hand-rolled parent/child maps, handover windows, reference adjacency, and
deque BFS closures for downstream reach, visible-root selection, and
cross-boundary reference checks.
"""

from __future__ import annotations

from collections import deque


class WayfinderBoard:
    def __init__(self) -> None:
        self._tasks: set[str] = set()
        self._owner: dict[str, str] = {}
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._handovers: dict[str, tuple[str, str]] = {}
        self._refs: dict[str, list[str]] = {}


def build_board(
    tasks: list[str],
    owners: dict[str, str],
    child_of: list[tuple[str, str]],
    handovers: list[tuple[str, str, str]],
    refs: list[tuple[str, str]] | None = None,
) -> WayfinderBoard:
    g = WayfinderBoard()
    for tid in tasks:
        g._tasks.add(tid)
        g._owner[tid] = owners[tid]
        g._parent[tid] = None
        g._children.setdefault(tid, [])
        g._refs.setdefault(tid, [])
    for child, parent in child_of:
        if child not in g._tasks or parent not in g._tasks:
            continue
        g._parent[child] = parent
        g._children.setdefault(parent, []).append(child)
    for hander, handee, root_task in handovers:
        if root_task in g._tasks:
            g._handovers[root_task] = (hander, handee)
    for src, dst in refs or []:
        if src in g._tasks and dst in g._tasks:
            g._refs[src].append(dst)
    return g


def _subtree_bfs(g: WayfinderBoard, root_task: str) -> list[str]:
    if root_task not in g._tasks:
        return []
    q: deque[str] = deque([root_task])
    claimed: set[str] = set()
    hits: list[str] = []
    while q:
        cur = q.popleft()
        if cur in claimed:
            continue
        claimed.add(cur)
        hits.append(cur)
        for ch in g._children.get(cur, []):
            if ch not in claimed:
                q.append(ch)
    return hits


def handed_subtree(g: WayfinderBoard, root_task: str) -> list[str]:
    return sorted(_subtree_bfs(g, root_task))


def visible_roots(g: WayfinderBoard, user: str) -> list[str]:
    out: list[str] = []
    for tid in sorted(g._tasks):
        if tid in g._handovers and g._handovers[tid][1] == user:
            out.append(tid)
            continue
        if g._owner.get(tid) != user:
            continue
        parent = g._parent.get(tid)
        if parent is None or g._owner.get(parent) != user:
            out.append(tid)
    return out


def downstream_order(g: WayfinderBoard, root_task: str) -> list[str]:
    return handed_subtree(g, root_task)


def subtree_reachable(g: WayfinderBoard, root_task: str, target: str) -> bool:
    return target in _subtree_bfs(g, root_task)


def ref_violations(g: WayfinderBoard, scope_root: str) -> list[str]:
    if scope_root not in g._tasks:
        return []
    scope = set(_subtree_bfs(g, scope_root))
    violations: list[str] = []
    for src in sorted(scope):
        for dst in g._refs.get(src, []):
            if dst not in scope:
                violations.append(f"{src}->{dst}")
    return sorted(violations)


def hander_for(g: WayfinderBoard, task: str) -> str | None:
    rec = g._handovers.get(task)
    return rec[0] if rec else None


def can_see_hander(g: WayfinderBoard, task: str, viewer: str) -> bool:
    rec = g._handovers.get(task)
    if rec is None:
        return False
    hander, handee = rec
    return viewer == handee and hander is not None
