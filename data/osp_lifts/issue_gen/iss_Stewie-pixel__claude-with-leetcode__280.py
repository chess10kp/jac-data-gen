"""Stewie-pixel/claude-with-leetcode#280 — Network recovery pathways (DAG reachability)."""

from __future__ import annotations

from collections import deque


class NetworkStore:
    # Adjacency dict with edge weights + online bitmask walk.
    def __init__(self, n: int, online: list[bool]) -> None:
        self.n = n
        self.online = list(online)
        self._adj: dict[int, list[tuple[int, int]]] = {i: [] for i in range(n)}


def load_network(
    n: int,
    online: list[bool],
    edges: list[tuple[int, int, int]],
) -> NetworkStore:
    net = NetworkStore(n, online)
    for u, v, w in edges:
        if 0 <= u < n and 0 <= v < n:
            net._adj.setdefault(u, []).append((v, w))
    return net


def _topo_order(store: NetworkStore) -> list[int]:
    indeg = {i: 0 for i in range(store.n)}
    for u in range(store.n):
        for v, _ in store._adj.get(u, []):
            indeg[v] = indeg.get(v, 0) + 1
    queue: deque[int] = deque([i for i in range(store.n) if indeg[i] == 0])
    order: list[int] = []
    while queue:
        u = queue.popleft()
        order.append(u)
        for v, _ in store._adj.get(u, []):
            indeg[v] -= 1
            if indeg[v] == 0:
                queue.append(v)
    return order


def feasible(store: NetworkStore, threshold: int, budget: int) -> bool:
    order = _topo_order(store)
    if len(order) != store.n:
        return False
    dist = {i: 10**18 for i in range(store.n)}
    dist[0] = 0
    for u in order:
        if dist[u] > budget:
            continue
        for v, w in store._adj.get(u, []):
            if w < threshold:
                continue
            if not store.online[v] and v != store.n - 1:
                continue
            nd = dist[u] + w
            if nd < dist[v]:
                dist[v] = nd
    return dist[store.n - 1] <= budget


def max_min_path(
    n: int,
    online: list[bool],
    edges: list[tuple[int, int, int]],
    budget: int,
) -> int:
    store = load_network(n, online, edges)
    weights = sorted({w for _, _, w in edges})
    lo, hi = 0, len(weights) - 1
    answer = -1
    while lo <= hi:
        mid = (lo + hi) // 2
        if feasible(store, weights[mid], budget):
            answer = weights[mid]
            lo = mid + 1
        else:
            hi = mid - 1
    return answer
