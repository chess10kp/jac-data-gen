"""rajat-wyrm/InternOps#1755 — recursive team hierarchy with depth cap."""

from __future__ import annotations
from collections import deque

class TeamStore:
    def __init__(self) -> None:
        self._manager_of: dict[str, str] = {}
        self._depth_cap: int = 100

def load_team(manager_of: dict[str, str], depth_cap: int = 100) -> TeamStore:
    g = TeamStore()
    g._manager_of = dict(manager_of)
    g._depth_cap = depth_cap
    return g

def team_members(g: TeamStore, manager_id: str) -> list[str]:
    children: dict[str, list[str]] = {}
    for u, m in g._manager_of.items():
        children.setdefault(m, []).append(u)
    seen: set[str] = set()
    work: deque[tuple[str, int]] = deque((c, 1) for c in children.get(manager_id, []))
    hits: list[str] = []
    while work:
        cur, depth = work.popleft()
        if cur in seen or depth >= g._depth_cap:
            continue
        seen.add(cur)
        hits.append(cur)
        for nxt in children.get(cur, []):
            if nxt not in seen:
                work.append((nxt, depth + 1))
    return sorted(hits)

def would_cycle(g: TeamStore, user_id: str, new_manager: str) -> bool:
    if user_id == new_manager:
        return True
    return new_manager in team_members(g, user_id)
