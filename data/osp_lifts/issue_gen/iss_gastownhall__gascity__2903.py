"""gastownhall/gascity#2903 — idle open-bead stability via dependency closure.

Hand-rolled bead adjacency dict, deque BFS dependency closure over
tracks/blocks/parent-child edges, and open-wisp protection scan for reaper safety.
"""

from __future__ import annotations

from collections import defaultdict, deque


class BeadStore:
    def __init__(self) -> None:
        self._bead_status: dict[str, str] = {}
        self._bead_tier: dict[str, str] = {}
        self._deps: dict[str, list[tuple[str, str]]] = defaultdict(list)


def load_bead_graph(
    bead_status: dict[str, str],
    bead_tier: dict[str, str],
    edges: list[tuple[str, str, str]],
) -> BeadStore:
    store = BeadStore()
    store._bead_status = dict(bead_status)
    store._bead_tier = dict(bead_tier)
    for src, dst, kind in edges:
        if src in store._bead_status and dst in store._bead_status:
            store._deps[src].append((dst, kind))
    return store


def dependency_closure(store: BeadStore, bead_id: str) -> list[str]:
    if bead_id not in store._bead_status:
        return []
    seen: set[str] = set()
    work: deque[str] = deque([bead_id])
    hits: list[str] = []
    while work:
        cur = work.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for tgt, _kind in store._deps.get(cur, []):
            if tgt not in seen:
                work.append(tgt)
                if tgt != bead_id:
                    hits.append(tgt)
    return sorted(hits)


def protected_from_reap(store: BeadStore, target_id: str) -> bool:
    if target_id not in store._bead_status:
        return False
    if store._bead_status[target_id] != "closed":
        return False
    for bid, status in store._bead_status.items():
        if status != "open":
            continue
        if store._bead_tier.get(bid, "issue") != "wisp":
            continue
        if target_id in dependency_closure(store, bid):
            return True
    return False


def idle_open_counts(store: BeadStore) -> tuple[int, int]:
    issues = 0
    wisps = 0
    for bid, status in store._bead_status.items():
        if status != "open":
            continue
        if store._bead_tier.get(bid, "issue") == "wisp":
            wisps += 1
        else:
            issues += 1
    return issues, wisps
