"""chaoz23/charactercheck#13 — INPUT-001 container lineage validation.

Hand-rolled parent->child adjacency, deque reach walk with visited-set,
DFS cycle detection, and stable error codes instead of tracebacks.
"""

from __future__ import annotations

from collections import deque


class InputStore:
    def __init__(self) -> None:
        self._children: dict[str, list[str]] = {}
        self._max_depth: int = 32


def load_containers(
    children: dict[str, list[str]],
    max_depth: int = 32,
) -> InputStore:
    g = InputStore()
    g._children = {k: list(v) for k, v in children.items()}
    g._max_depth = max_depth
    return g


def _known_ids(g: InputStore) -> set[str]:
    ids: set[str] = set()
    for parent, kids in g._children.items():
        ids.add(parent)
        ids.update(kids)
    return ids


def detect_cycles(g: InputStore, root_id: str) -> bool:
    if root_id not in _known_ids(g):
        return False
    seen: set[str] = set()
    stack: set[str] = set()

    def dfs(cid: str) -> bool:
        if cid in stack:
            return True
        if cid in seen:
            return False
        seen.add(cid)
        stack.add(cid)
        for kid in g._children.get(cid, []):
            if dfs(kid):
                return True
        stack.remove(cid)
        return False

    return dfs(root_id)


def bounded_walk(g: InputStore, root_id: str) -> list[str]:
    if root_id not in _known_ids(g):
        return []
    seen: set[str] = set()
    work: deque[tuple[str, int]] = deque([(root_id, 0)])
    hits: list[str] = []
    while work:
        cur, depth = work.popleft()
        if cur in seen:
            continue
        if depth > g._max_depth:
            continue
        seen.add(cur)
        hits.append(cur)
        for kid in g._children.get(cur, []):
            if kid not in seen:
                work.append((kid, depth + 1))
    return sorted(hits)


def validate_input(g: InputStore, root_id: str) -> str | None:
    if not root_id:
        return "invalid_path"
    if root_id not in _known_ids(g):
        return "invalid_path"
    if detect_cycles(g, root_id):
        return "cycle_detected"
    seen: set[str] = set()
    work: deque[tuple[str, int]] = deque([(root_id, 0)])
    while work:
        cur, depth = work.popleft()
        if cur in seen:
            continue
        if depth > g._max_depth:
            return "depth_exceeded"
        seen.add(cur)
        for kid in g._children.get(cur, []):
            work.append((kid, depth + 1))
    return None
