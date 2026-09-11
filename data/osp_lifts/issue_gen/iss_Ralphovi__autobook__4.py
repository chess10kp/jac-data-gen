"""Ralphovi/autobook#4 — recurring bookings into GnuCash scheduled transactions."""

from __future__ import annotations

from collections import deque


class BookingStore:
    def __init__(self) -> None:
        self._children: dict[str, list[str]] = {}
        self._depends: dict[str, list[str]] = {}


def load_booking_store(
    series_edges: list[tuple[str, str]],
    depends_edges: list[tuple[str, str]],
) -> BookingStore:
    g = BookingStore()
    nodes: set[str] = set()
    for parent, child in series_edges:
        nodes.update([parent, child])
        g._children.setdefault(parent, []).append(child)
        g._children.setdefault(child, g._children.get(child, []))
    for a, b in depends_edges:
        nodes.update([a, b])
        g._depends.setdefault(a, []).append(b)
        g._depends.setdefault(b, g._depends.get(b, []))
    for n in nodes:
        g._children.setdefault(n, [])
        g._depends.setdefault(n, [])
    return g


def instance_lineage(store: BookingStore, series_id: str) -> list[str]:
    if series_id not in store._children and series_id not in {
        c for kids in store._children.values() for c in kids
    }:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([series_id])
    out: list[str] = []
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        out.append(cur)
        for kid in store._children.get(cur, []):
            if kid not in seen:
                q.append(kid)
    return sorted(out)


def schedule_order(store: BookingStore) -> list[str]:
    nodes = set(store._depends) | {d for ds in store._depends.values() for d in ds}
    indeg = {n: 0 for n in nodes}
    for n, preds in store._depends.items():
        for p in preds:
            indeg[n] += 1
    ready = sorted(n for n, d in indeg.items() if d == 0)
    order: list[str] = []
    while ready:
        order.extend(ready)
        nxt: list[str] = []
        for u in ready:
            for v in nodes:
                if u in store._depends.get(v, []):
                    indeg[v] -= 1
                    if indeg[v] == 0:
                        nxt.append(v)
        ready = sorted(nxt)
    return order if len(order) == len(nodes) else []


def expand_occurrences(store: BookingStore, series_id: str, limit: int) -> list[str]:
    lineage = instance_lineage(store, series_id)
    order = schedule_order(store)
    ranked = sorted(lineage, key=lambda x: (order.index(x) if x in order else 10**9, x))
    return ranked[: max(0, limit)]
