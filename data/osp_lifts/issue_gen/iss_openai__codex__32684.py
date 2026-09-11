"""openai/codex#32684 — guard recursive USERPROFILE cleanup against path cycles."""

from __future__ import annotations

from collections import deque
from typing import Dict, List, Set


class DirGraph:
    # Hand-rolled adjacency for a directory tree that may contain back-edges (symlink cycles).
    def __init__(self) -> None:
        self.adj: Dict[str, List[str]] = {}
        self.names: Dict[str, str] = {}

    def add_node(self, node_id: str, name: str) -> None:
        self.names[node_id] = name
        self.adj.setdefault(node_id, [])

    def add_child(self, parent_id: str, child_id: str) -> None:
        self.adj.setdefault(parent_id, []).append(child_id)
        self.adj.setdefault(child_id, self.adj.get(child_id, []))

    def reachable(self, root_id: str) -> List[str]:
        seen: Set[str] = set()
        q: deque[str] = deque([root_id])
        while q:
            cur = q.popleft()
            if cur in seen:
                continue
            seen.add(cur)
            for nxt in self.adj.get(cur, []):
                if nxt not in seen:
                    q.append(nxt)
        return sorted(seen)

    def safe_prune_order(self, root_id: str) -> List[str]:
        # Post-order delete list; revisits on cycles are ignored (no infinite recursion).
        order: List[str] = []
        seen: Set[str] = set()

        def dfs(n: str) -> None:
            if n in seen:
                return
            seen.add(n)
            for c in self.adj.get(n, []):
                dfs(c)
            order.append(n)

        dfs(root_id)
        return order

    def has_cycle_from(self, root_id: str) -> bool:
        WHITE, GRAY, BLACK = 0, 1, 2
        color: Dict[str, int] = {n: WHITE for n in self.adj}

        def dfs(n: str) -> bool:
            color[n] = GRAY
            for c in self.adj.get(n, []):
                if color.get(c, WHITE) == GRAY:
                    return True
                if color.get(c, WHITE) == WHITE and dfs(c):
                    return True
            color[n] = BLACK
            return False

        return dfs(root_id)
