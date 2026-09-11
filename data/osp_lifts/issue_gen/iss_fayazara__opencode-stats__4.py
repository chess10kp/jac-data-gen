"""fayazara/opencode-stats#4 — subagent sessions excluded from cost rollup (parent_id IS NULL)."""

from __future__ import annotations

from collections import defaultdict, deque


class SessionCostStore:
    # Fresh handle per test; hand-rolled parent pointers + child adjacency.
    def __init__(self) -> None:
        self._costs: dict[str, int] = {}
        self._tokens: dict[str, int] = {}
        self._parent_id: dict[str, str] = {}
        self._subagent_children: dict[str, list[str]] = defaultdict(list)


def load_sessions(
    sessions: list[tuple[str, int, int]],
    subagents: list[tuple[str, str]],
) -> SessionCostStore:
    store = SessionCostStore()
    for sid, cost, tokens in sessions:
        store._costs[sid] = cost
        store._tokens[sid] = tokens
    for child, parent in subagents:
        if child in store._costs and parent in store._costs:
            store._parent_id[child] = parent
            store._subagent_children[parent].append(child)
    return store


def session_costs(store: SessionCostStore, sid: str) -> tuple[int, int]:
    if sid not in store._costs:
        return (0, 0)
    return (store._costs[sid], store._tokens[sid])


def roots_only_cost(store: SessionCostStore) -> int:
    # Buggy production query: WHERE parent_id IS NULL — drops every subagent.
    total = 0
    for sid, cost in store._costs.items():
        if sid not in store._parent_id:
            total += cost
    return total


def _descendant_ids(store: SessionCostStore, root_sid: str) -> list[str]:
    if root_sid not in store._costs:
        return []
    settled: set[str] = set()
    work: deque[str] = deque([root_sid])
    while work:
        cur = work.popleft()
        for ch in sorted(store._subagent_children.get(cur, [])):
            if ch in settled:
                continue
            settled.add(ch)
            work.append(ch)
    return sorted(settled)


def total_cost(store: SessionCostStore, root_sid: str) -> int:
    if root_sid not in store._costs:
        return 0
    total = store._costs[root_sid]
    for sid in _descendant_ids(store, root_sid):
        total += store._costs[sid]
    return total


def all_session_ids(store: SessionCostStore, root_sid: str) -> list[str]:
    if root_sid not in store._costs:
        return []
    return sorted({root_sid, *_descendant_ids(store, root_sid)})
