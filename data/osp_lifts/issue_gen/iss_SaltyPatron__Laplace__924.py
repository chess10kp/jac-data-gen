"""SaltyPatron/Laplace#924 — N-hop substrate reachability."""

from __future__ import annotations

from collections import deque


class SubstrateGraph:
    def __init__(self) -> None:
        self._entities: set[str] = set()
        self._links: dict[str, list[str]] = {}


def load_substrate(
    entities: list[str],
    links: list[tuple[str, str]],
) -> SubstrateGraph:
    g = SubstrateGraph()
    for eid in entities:
        g._entities.add(eid)
        g._links.setdefault(eid, [])
    for src, dst in links:
        if src in g._entities and dst in g._entities:
            g._links.setdefault(src, []).append(dst)
    return g


def n_hop_neighbors(graph: SubstrateGraph, seed: str, hops: int) -> list[str]:
    if seed not in graph._entities or hops < 0:
        return []
    seen: set[str] = set()
    queue: deque[tuple[str, int]] = deque([(seed, 0)])
    while queue:
        cur, depth = queue.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        if depth >= hops:
            continue
        for nxt in graph._links.get(cur, []):
            if nxt not in seen:
                queue.append((nxt, depth + 1))
    return sorted(seen)


def reachable_within(graph: SubstrateGraph, seed: str, hops: int) -> bool:
    return len(n_hop_neighbors(graph, seed, hops)) > 0
