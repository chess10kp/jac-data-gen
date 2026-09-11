"""lirei-lab/thingsflow#1 — tenant-scoped twin relation graph expand."""

from __future__ import annotations

from collections import deque


class TwinStore:
    def __init__(self) -> None:
        self._twins: set[str] = set()
        self._tenant: dict[str, str] = {}
        self._adj: dict[str, list[str]] = {}


def load_twin_graph(
    twins: list[str],
    tenants: dict[str, str],
    relations: list[tuple[str, str]],
) -> TwinStore:
    store = TwinStore()
    for tid in twins:
        store._twins.add(tid)
        store._tenant[tid] = tenants.get(tid, "default")
        store._adj.setdefault(tid, [])
    for src, dst in relations:
        if src in store._twins and dst in store._twins:
            if store._tenant[src] == store._tenant[dst]:
                store._adj.setdefault(src, []).append(dst)
    return store


def neighbors(store: TwinStore, twin_id: str) -> list[str]:
    if twin_id not in store._twins:
        return []
    return sorted(store._adj.get(twin_id, []))


def expand_relations(store: TwinStore, twin_id: str, max_depth: int) -> list[str]:
    if twin_id not in store._twins or max_depth < 0:
        return []
    seen: set[str] = {twin_id}
    reached: list[str] = [twin_id]
    q: deque[tuple[str, int]] = deque([(twin_id, 0)])
    while q:
        cur, depth = q.popleft()
        if depth >= max_depth:
            continue
        for nxt in sorted(store._adj.get(cur, [])):
            if nxt in seen:
                continue
            seen.add(nxt)
            reached.append(nxt)
            q.append((nxt, depth + 1))
    return sorted(reached)
