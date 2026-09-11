"""Comfy-Org/ComfyUI#15517 — ModelPatcher mints a fresh namedtuple class per weight backup.

Workflow DAG links tensor weights; lineage walks traverse dependents via adjacency dicts,
deque BFS, and parent refs. The per-key backup hot path calls collections.namedtuple()
inline so every entry gets its own Dimension type and class-shaped cyclic garbage on clear.
"""

from __future__ import annotations

from collections import deque, namedtuple


class PatcherStore:
    def __init__(self) -> None:
        self.weights: dict[str, float] = {}
        self.adj: dict[str, list[str]] = {}
        self.parent: dict[str, str | None] = {}
        self.dependents: dict[str, list[str]] = {}
        self.backup: dict[str, object] = {}


def make_patcher_store(
    weights: dict[str, float],
    edges: list[tuple[str, str]],
) -> PatcherStore:
    store = PatcherStore()
    for key, val in weights.items():
        store.weights[key] = val
        store.adj[key] = []
        store.dependents[key] = []
        store.parent[key] = None
    for consumer, dep in edges:
        if consumer in store.weights and dep in store.weights:
            store.adj[consumer].append(dep)
            store.dependents[dep].append(consumer)
            if store.parent[consumer] is None:
                store.parent[consumer] = dep
    for key in store.adj:
        store.adj[key].sort()
        store.dependents[key].sort()
    return store


def backup_weight(store: PatcherStore, key: str, inplace: bool = False) -> None:
    if key not in store.weights:
        return
    wt = store.weights[key]
    entry = namedtuple("Dimension", ["weight", "inplace_update"])(wt, inplace)
    store.backup[key] = entry


def clear_backups(store: PatcherStore) -> None:
    store.backup.clear()


def backup_entry_count(store: PatcherStore) -> int:
    return len(store.backup)


def unique_backup_entry_types(store: PatcherStore) -> int:
    return len({type(entry) for entry in store.backup.values()})


def workflow_downstream(store: PatcherStore, start: str) -> list[str]:
    if start not in store.weights:
        return []
    claimed: set[str] = {start}
    hits: list[str] = []
    q: deque[str] = deque([start])
    while q:
        cur = q.popleft()
        for nxt in store.dependents.get(cur, []):
            if nxt not in claimed:
                claimed.add(nxt)
                hits.append(nxt)
                q.append(nxt)
    return sorted(hits)


def weight_parent_chain(store: PatcherStore, start: str) -> list[str]:
    if start not in store.weights:
        return []
    chain: list[str] = []
    cur = start
    seen: set[str] = set()
    while True:
        parent = store.parent.get(cur)
        if parent is None or parent in seen:
            break
        seen.add(parent)
        chain.append(parent)
        cur = parent
    return chain


def cycle_member_weights(store: PatcherStore) -> list[str]:
    white, gray, black = 0, 1, 2
    color: dict[str, int] = {k: white for k in store.weights}
    on_cycle: set[str] = set()

    def dfs(node: str) -> None:
        color[node] = gray
        for dep in store.adj.get(node, []):
            if color[dep] == gray:
                on_cycle.add(node)
                on_cycle.add(dep)
            elif color[dep] == white:
                dfs(dep)
                if dep in on_cycle:
                    on_cycle.add(node)
        color[node] = black

    for key in sorted(store.weights):
        if color[key] == white:
            dfs(key)
    return sorted(on_cycle)
