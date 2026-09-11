"""Startempire-Wire/focusa#254 — CallGraph frame tree with spawn reachability."""

from __future__ import annotations

from collections import deque


class CallGraphStore:
    # Parent frame pointers plus spawn adjacency for call graph authority.
    def __init__(self) -> None:
        self._parent_of: dict[str, str | None] = {}
        self._spawn_of: dict[str, list[str]] = {}
        self._loaded: set[str] = set()


def load_callgraph(
    frames: list[tuple[str, str | None]],
    spawn_edges: list[tuple[str, str]],
) -> CallGraphStore:
    g = CallGraphStore()
    for name, parent in frames:
        if parent is not None and parent not in g._parent_of:
            raise KeyError("unknown parent frame")
        g._parent_of[name] = parent
        g._spawn_of.setdefault(name, [])
        if parent is not None:
            g._spawn_of.setdefault(parent, []).append(name)
    for caller, callee in spawn_edges:
        if caller in g._parent_of and callee in g._parent_of:
            if callee not in g._spawn_of.setdefault(caller, []):
                g._spawn_of[caller].append(callee)
    return g


def ancestor_frames(store: CallGraphStore, frame: str) -> list[str]:
    if frame not in store._parent_of:
        return []
    chain: list[str] = []
    cur: str | None = frame
    seen: set[str] = set()
    while cur is not None:
        if cur in seen:
            break
        seen.add(cur)
        chain.append(cur)
        cur = store._parent_of.get(cur)
    return list(reversed(chain))


def reachable_spawns(store: CallGraphStore, root: str) -> list[str]:
    if root not in store._parent_of:
        return []
    seen: set[str] = {root}
    queue: deque[str] = deque([root])
    while queue:
        cur = queue.popleft()
        for nxt in store._spawn_of.get(cur, []):
            if nxt not in seen:
                seen.add(nxt)
                queue.append(nxt)
    return sorted(seen)


def frontier_frames(store: CallGraphStore, loaded: list[str]) -> list[str]:
    store._loaded.update(loaded)
    out: list[str] = []
    for name in sorted(store._parent_of):
        parent = store._parent_of.get(name)
        if parent is None:
            continue
        if parent in store._loaded and name not in store._loaded:
            out.append(name)
    return out
