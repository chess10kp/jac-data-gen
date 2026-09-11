"""reflective-org/SANDBOX#66 — dependency-graph engine and override semantics.

Hand-rolled derived_from adjacency, DFS cycle detection, and downstream cascade
sweep with auto-recompute vs stale override preservation.
"""

from __future__ import annotations

from collections import deque


class DeriveStore:
    def __init__(self) -> None:
        self._derived_from: dict[str, list[str]] = {}
        self._modes: dict[str, str] = {}
        self._values: dict[str, object] = {}


def load_registry(
    derived_from: dict[str, list[str]],
    modes: dict[str, str],
    values: dict[str, object],
) -> DeriveStore:
    g = DeriveStore()
    g._derived_from = {k: list(v) for k, v in derived_from.items()}
    g._modes = dict(modes)
    g._values = dict(values)
    return g


def detect_cycle(g: DeriveStore) -> bool:
    state: dict[str, int] = {}  # 0=unseen 1=stack 2=done

    def dfs(fid: str) -> bool:
        state[fid] = 1
        for dep in g._derived_from.get(fid, []):
            st = state.get(dep, 0)
            if st == 1:
                return True
            if st == 0 and dfs(dep):
                return True
        state[fid] = 2
        return False

    for fid in g._derived_from:
        if state.get(fid, 0) == 0 and dfs(fid):
            return True
    return False


def downstream_closure(g: DeriveStore, field_id: str) -> list[str]:
    if field_id not in g._derived_from:
        return []
    adj = {k: [d for d in v if d in g._derived_from] for k, v in g._derived_from.items()}
    seen: set[str] = set()
    work: deque[str] = deque(adj.get(field_id, []))
    hits: list[str] = []
    while work:
        cur = work.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        hits.append(cur)
        work.extend(adj.get(cur, []))
    return sorted(hits)


def resolve_change(g: DeriveStore, field_id: str, new_value: object) -> tuple[dict[str, object], list[str]]:
    out = dict(g._values)
    stale: list[str] = []
    out[field_id] = new_value
    for fid in downstream_closure(g, field_id):
        if g._modes.get(fid, "auto") == "auto":
            out[fid] = f"derived({field_id})"
        else:
            stale.append(fid)
    return out, sorted(stale)
