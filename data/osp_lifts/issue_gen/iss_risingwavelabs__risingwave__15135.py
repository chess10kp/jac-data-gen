"""risingwavelabs/risingwave#15135 — minimal recursive CTE iteration oracle.

Models anchor + UNION ALL recursive expansion with MAX_RECURSIVE_ITERATION=16,
cycle-safe settled guard, and CteRef-style back-edge reachability.
"""

from __future__ import annotations

from collections import deque

MAX_RECURSIVE_ITERATION = 16


class RcteGraph:
    """In-memory edge store for bounded recursive-union evaluation."""

    def __init__(self) -> None:
        self.adj: dict[str, list[str]] = {}
        self.nodes: set[str] = set()


def build_rcte_graph(edges: list[tuple[str, str]]) -> RcteGraph:
    store = RcteGraph()
    for src, dst in edges:
        store.adj.setdefault(src, []).append(dst)
        store.adj.setdefault(dst, [])
        store.nodes.add(src)
        store.nodes.add(dst)
    return store


def recursive_union_expand(
    store: RcteGraph,
    seed: str,
    max_iter: int = MAX_RECURSIVE_ITERATION,
) -> list[str]:
    # Bounded BFS rounds: one epoch per hop, capped at max_iter depths.
    if seed not in store.nodes:
        return []
    settled: set[str] = set()
    order: list[str] = []
    work: deque[tuple[str, int]] = deque([(seed, 0)])
    while work:
        node, depth = work.popleft()
        if node in settled:
            continue
        settled.add(node)
        order.append(node)
        if depth >= max_iter:
            continue
        for nxt in sorted(store.adj.get(node, [])):
            if nxt not in settled:
                work.append((nxt, depth + 1))
    return order


def cte_ref_reachable(store: RcteGraph, seed: str) -> list[str]:
    return sorted(set(recursive_union_expand(store, seed)))


def stopped_by_iteration_cap(store: RcteGraph, seed: str) -> bool:
    if seed not in store.nodes:
        return False
    full = recursive_union_expand(store, seed, max_iter=10_000)
    capped = recursive_union_expand(store, seed, max_iter=MAX_RECURSIVE_ITERATION)
    return len(set(full)) > len(set(capped))
