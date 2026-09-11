"""fleetdm/fleet#46263 — batch software installer reachability with cycle guards."""

from __future__ import annotations

from collections import deque
from typing import Dict, List, Set


class InstallerBatch:
    def __init__(self) -> None:
        self.deps: Dict[str, List[str]] = {}
        self.labels: Dict[str, str] = {}

    def add(self, pkg_id: str, label: str) -> None:
        self.labels[pkg_id] = label
        self.deps.setdefault(pkg_id, [])

    def require(self, pkg_id: str, needs: str) -> None:
        self.deps.setdefault(pkg_id, []).append(needs)

    def closure(self, seeds: List[str]) -> List[str]:
        seen: Set[str] = set()
        q: deque[str] = deque(sorted(seeds))
        while q:
            cur = q.popleft()
            if cur in seen:
                continue
            seen.add(cur)
            for dep in self.deps.get(cur, []):
                q.append(dep)
        return sorted(seen)

    def has_dependency_cycle(self) -> bool:
        WHITE, GRAY, BLACK = 0, 1, 2
        color = {k: WHITE for k in self.deps}

        def dfs(n: str) -> bool:
            color[n] = GRAY
            for c in self.deps.get(n, []):
                if color.get(c, WHITE) == GRAY:
                    return True
                if color.get(c, WHITE) == WHITE and dfs(c):
                    return True
            color[n] = BLACK
            return False

        return any(dfs(n) for n in self.deps if color[n] == WHITE)
