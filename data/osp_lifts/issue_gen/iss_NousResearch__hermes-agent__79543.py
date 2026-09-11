"""Writer primitives, attempt fencing, and lineage reachability.

Source: NousResearch/hermes-agent#79543.
"""

from __future__ import annotations

from collections import deque
from typing import Dict, List, Set


class FenceError(ValueError):
    pass


class WriterStore:
    def __init__(
        self,
        scopes: list[str],
        parent_edges: list[tuple[str, str]],
        dep_edges: list[tuple[str, str]],
        ref_edges: list[tuple[str, str]],
    ) -> None:
        self.scopes: Set[str] = set(scopes)
        self._parent_pairs = list(parent_edges)
        self.parent_adj: Dict[str, List[str]] = {s: [] for s in scopes}
        self.dep_adj: Dict[str, List[str]] = {s: [] for s in scopes}
        self.ref_adj: Dict[str, List[str]] = {s: [] for s in scopes}
        for parent, child in parent_edges:
            if parent in self.scopes and child in self.scopes:
                self.parent_adj[parent].append(child)
        for blocker, blocked in dep_edges:
            if blocker in self.scopes and blocked in self.scopes:
                self.dep_adj[blocker].append(blocked)
        for src, dst in ref_edges:
            if src in self.scopes and dst in self.scopes:
                self.ref_adj[src].append(dst)
        self._active: Dict[str, str | None] = {s: None for s in scopes}
        self._buffers: Dict[str, deque[str]] = {s: deque() for s in scopes}


def build_writer_store(
    scopes: list[str],
    parent_edges: list[tuple[str, str]],
    dep_edges: list[tuple[str, str]],
    ref_edges: list[tuple[str, str]],
) -> WriterStore:
    return WriterStore(scopes, parent_edges, dep_edges, ref_edges)


def writer_children(store: WriterStore, scope_id: str) -> list[str]:
    if scope_id not in store.scopes:
        return []
    kids: list[str] = []
    for parent, child in store._parent_pairs:
        if parent == scope_id and child not in kids:
            kids.append(child)
    return sorted(kids)


def begin_attempt(store: WriterStore, scope_id: str, attempt_id: str) -> bool:
    if scope_id not in store.scopes:
        return False
    if store._active[scope_id] is not None:
        return False
    store._active[scope_id] = attempt_id
    return True


def write_primitive(
    store: WriterStore, scope_id: str, attempt_id: str, primitive: str
) -> bool:
    if scope_id not in store.scopes:
        return False
    if store._active.get(scope_id) != attempt_id:
        return False
    store._buffers[scope_id].append(primitive)
    return True


def commit_attempt(store: WriterStore, scope_id: str, attempt_id: str) -> list[str]:
    if scope_id not in store.scopes:
        return []
    if store._active.get(scope_id) != attempt_id:
        raise FenceError("attempt not active")
    out = list(store._buffers[scope_id])
    store._buffers[scope_id].clear()
    store._active[scope_id] = None
    return out


def reachable_scopes(store: WriterStore, scope_id: str) -> list[str]:
    if scope_id not in store.scopes:
        return []
    seen: Set[str] = set()
    q: deque[str] = deque([scope_id])
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in store.dep_adj.get(cur, []):
            if nxt not in seen:
                q.append(nxt)
    seen.discard(scope_id)
    return sorted(seen)


def _collect_invalidate_targets(store: WriterStore, scope_id: str) -> list[str]:
    targets: list[str] = []
    seen: Set[str] = set()
    q: deque[str] = deque([scope_id])
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        targets.append(cur)
        for child in store.parent_adj.get(cur, []):
            q.append(child)
        for dep in store.dep_adj.get(cur, []):
            q.append(dep)
    return targets


def invalidate_downstream(store: WriterStore, scope_id: str) -> list[str]:
    if scope_id not in store.scopes:
        return []
    cleared: list[str] = []
    for sid in sorted(_collect_invalidate_targets(store, scope_id)):
        had = store._active[sid] is not None or len(store._buffers[sid]) > 0
        store._active[sid] = None
        store._buffers[sid].clear()
        if had:
            cleared.append(sid)
    return cleared
