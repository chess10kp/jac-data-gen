"""entif-ai/rosetta#676 — DocID registry lineage with cycle guard (pre-OSP)."""

from __future__ import annotations

from collections import deque
from typing import Dict, List, Set


class DocRegistry:
    def __init__(self) -> None:
        self._docs: Set[str] = set()
        self._supersedes: Dict[str, List[str]] = {}

    def register(self, doc_id: str) -> None:
        if doc_id in self._docs:
            raise ValueError(f"duplicate doc id: {doc_id}")
        self._docs.add(doc_id)
        self._supersedes.setdefault(doc_id, [])

    def supersedes(self, new_id: str, old_id: str) -> None:
        if new_id not in self._docs or old_id not in self._docs:
            raise KeyError("unknown doc id")
        self._supersedes[new_id].append(old_id)

    def lineage(self, doc_id: str) -> List[str]:
        if doc_id not in self._docs:
            return []
        settled: Set[str] = set()
        work: deque[str] = deque([doc_id])
        while work:
            u = work.popleft()
            if u in settled:
                continue
            settled.add(u)
            for p in sorted(self._supersedes.get(u, [])):
                if p not in settled:
                    work.append(p)
        return sorted(settled)

    def find_cycle(self) -> List[str]:
        WHITE, GRAY, BLACK = 0, 1, 2
        color: Dict[str, int] = {n: WHITE for n in self._docs}
        stack: List[str] = []

        def dfs(u: str) -> List[str]:
            color[u] = GRAY
            stack.append(u)
            for v in self._supersedes.get(u, []):
                if color[v] == GRAY and v in stack:
                    i = stack.index(v)
                    return stack[i:] + [v]
                if color[v] == WHITE:
                    found = dfs(v)
                    if found:
                        return found
            stack.pop()
            color[u] = BLACK
            return []

        for n in sorted(self._docs):
            if color[n] == WHITE:
                cyc = dfs(n)
                if cyc:
                    return cyc
        return []
