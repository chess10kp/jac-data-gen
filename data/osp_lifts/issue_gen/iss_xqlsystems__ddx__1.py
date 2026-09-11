"""xqlsystems/ddx#1 — SQL rewrite vs Substrait round-trip (recursive CTE reach).

Hand-rolled plan adjacency dict, unsupported-kind gate, and bounded recursive
reach simulating CTE expansion depth.
"""

from __future__ import annotations

from collections import deque

_UNSUPPORTED = frozenset({"recursive_cte", "dml", "scalar_subquery"})


class PlanStore:
    def __init__(self) -> None:
        self._kinds: dict[str, str] = {}
        self._edges: dict[str, list[str]] = {}
        self._max_depth: int = 64


def load_plan(
    kinds: dict[str, str],
    edges: dict[str, list[str]],
    max_depth: int = 64,
) -> PlanStore:
    g = PlanStore()
    g._kinds = dict(kinds)
    g._edges = {k: list(v) for k, v in edges.items()}
    g._max_depth = max_depth
    return g


def can_substrait_emit(g: PlanStore, pid: str) -> bool:
    return g._kinds.get(pid, "") not in _UNSUPPORTED


def recursive_reach(g: PlanStore, root_id: str) -> list[str]:
    # Virtual rewrite roots may appear only in edges, not in kinds.
    if root_id not in g._kinds and root_id not in g._edges:
        return []
    seen: set[str] = set()
    work: deque[tuple[str, int]] = deque([(root_id, 0)])
    hits: list[str] = []
    while work:
        cur, depth = work.popleft()
        if cur in seen or depth >= g._max_depth:
            continue
        seen.add(cur)
        if cur in g._kinds:
            hits.append(cur)
        for nxt in g._edges.get(cur, []):
            if nxt not in seen:
                work.append((nxt, depth + 1))
    return sorted(hits)
