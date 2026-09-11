"""Architecture metrics graph — cq27-dev/rag-rat#105."""
from __future__ import annotations
from collections import deque
from typing import Dict, List, Set

class ArchGraph:
    def __init__(self) -> None:
        self._adj: Dict[str, List[str]] = {}

    def add_dep(self, src: str, dst: str) -> None:
        self._adj.setdefault(src, [])
        if dst not in self._adj[src]:
            self._adj[src].append(dst)
        self._adj.setdefault(dst, [])

    def shortest_path(self, src: str, dst: str) -> List[str] | None:
        if src not in self._adj or dst not in self._adj:
            return None
        q: deque[str] = deque([src])
        prev: Dict[str, str | None] = {src: None}
        while q:
            cur = q.popleft()
            if cur == dst:
                path = []
                while cur is not None:
                    path.append(cur)
                    cur = prev[cur]
                return list(reversed(path))
            for nxt in self._adj.get(cur, []):
                if nxt not in prev:
                    prev[nxt] = cur
                    q.append(nxt)
        return None

    def has_cycle(self) -> bool:
        seen: Set[str] = set(); stack: Set[str] = set()
        def dfs(u: str) -> bool:
            if u in stack: return True
            if u in seen: return False
            stack.add(u)
            for v in self._adj.get(u, []):
                if dfs(v): return True
            stack.remove(u); seen.add(u); return False
        return any(dfs(n) for n in sorted(self._adj))

    def affected(self, start: str) -> List[str]:
        if start not in self._adj:
            return []
        out: List[str] = []; seen: Set[str] = set(); q = deque([start])
        while q:
            cur = q.popleft()
            if cur in seen: continue
            seen.add(cur); out.append(cur)
            q.extend(self._adj.get(cur, []))
        return out

def build_arch_graph() -> ArchGraph:
    return ArchGraph()
