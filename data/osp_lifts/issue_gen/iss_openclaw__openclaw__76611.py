"""openclaw/openclaw#76611 — Matrix crypto-store: dirty paths flushed on timer, not inline."""

from __future__ import annotations

from collections import deque


class CryptoStore:
    def __init__(self) -> None:
        self._children: dict[str, list[str]] = {}
        self._dirty: set[str] = set()
        self._persisted: set[str] = set()


def load_crypto_store(edges: list[tuple[str, str]]) -> CryptoStore:
    g = CryptoStore()
    nodes: set[str] = set()
    for parent, child in edges:
        nodes.update([parent, child])
        g._children.setdefault(parent, []).append(child)
        g._children.setdefault(child, g._children.get(child, []))
    for n in nodes:
        g._children.setdefault(n, [])
    return g


def mark_dirty(g: CryptoStore, key: str) -> None:
    if key not in g._children and key not in {c for xs in g._children.values() for c in xs}:
        return
    g._dirty.add(key)
    cur = key
    seen: set[str] = set()
    while cur is not None and cur not in seen:
        seen.add(cur)
        g._dirty.add(cur)
        parents = [p for p, kids in g._children.items() if cur in kids]
        cur = parents[0] if parents else None


def pending_persist(g: CryptoStore) -> list[str]:
    return sorted(g._dirty - g._persisted)


def _collect_flush_targets(g: CryptoStore) -> list[str]:
    targets: list[str] = []
    seen: set[str] = set()
    q: deque[str] = deque(sorted(g._dirty))
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        targets.append(cur)
        for kid in g._children.get(cur, []):
            if kid in g._dirty:
                q.append(kid)
    return targets


def flush_dirty(g: CryptoStore) -> list[str]:
    flushed: list[str] = []
    for key in sorted(_collect_flush_targets(g)):
        if key in g._dirty:
            g._persisted.add(key)
            g._dirty.discard(key)
            flushed.append(key)
    return flushed


def reachable_keys(g: CryptoStore, root: str) -> list[str]:
    if root not in g._children:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([root])
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in g._children.get(cur, []):
            if nxt not in seen:
                q.append(nxt)
    return sorted(seen)
