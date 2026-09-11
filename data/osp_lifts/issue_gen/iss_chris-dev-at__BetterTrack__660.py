"""chris-dev-at/BetterTrack#660 — Portfolio nesting DAG flatten and cycle guard."""

from __future__ import annotations

from collections import deque


class PortfolioStore:
    def __init__(self) -> None:
        self._ports: set[str] = set()
        self._links: dict[str, list[str]] = {}
        self._depth_cap: int = 3


def load_portfolios(
    portfolios: list[str],
    nest_links: list[tuple[str, str]],
    depth_cap: int = 3,
) -> PortfolioStore:
    s = PortfolioStore()
    s._depth_cap = depth_cap
    for pid in portfolios:
        s._ports.add(pid)
        s._links.setdefault(pid, [])
    for parent, child in nest_links:
        if parent not in s._ports or child not in s._ports:
            continue
        s._links[parent].append(child)
    return s


def _reachable_from(store: PortfolioStore, start: str) -> set[str]:
    seen: set[str] = set()
    q: deque[tuple[str, int]] = deque([(start, 0)])
    while q:
        cur, depth = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        if depth >= store._depth_cap:
            continue
        for ch in store._links.get(cur, []):
            if ch not in seen:
                q.append((ch, depth + 1))
    return seen


def would_create_cycle(store: PortfolioStore, parent: str, child: str) -> bool:
    if parent not in store._ports or child not in store._ports:
        return False
    if parent == child:
        return True
    closure = _reachable_from(store, child)
    return parent in closure


def flattened_portfolios(store: PortfolioStore, root_id: str) -> list[str]:
    if root_id not in store._ports:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([root_id])
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for ch in store._links.get(cur, []):
            if ch not in seen:
                q.append(ch)
    return sorted(seen)
