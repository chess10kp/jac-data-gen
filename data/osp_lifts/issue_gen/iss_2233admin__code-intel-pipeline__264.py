"""2233admin/code-intel-pipeline#264 — snapshot-bound multi-view query index."""

from __future__ import annotations

from collections import deque
from typing import Dict, List, Set, Tuple


class SnapshotIndex:
    def __init__(self) -> None:
        self._views: Set[str] = set()
        self._deps: Dict[str, List[str]] = {}
        self._memo: Dict[Tuple[str, str], List[str]] = {}

    def add_view(self, view_id: str) -> None:
        self._views.add(view_id)
        self._deps.setdefault(view_id, [])

    def link(self, dst: str, src: str) -> None:
        if dst not in self._views or src not in self._views:
            raise KeyError("unknown view")
        if src not in self._deps[dst]:
            self._deps[dst].append(src)

    def ancestors(self, view_id: str) -> List[str]:
        if view_id not in self._views:
            return []
        key = ("anc", view_id)
        if key in self._memo:
            return list(self._memo[key])
        seen: Set[str] = set()
        out: List[str] = []
        stack = [view_id]
        while stack:
            cur = stack.pop()
            if cur in seen:
                continue
            seen.add(cur)
            for dep in sorted(self._deps.get(cur, [])):
                if dep not in seen:
                    out.append(dep)
                    stack.append(dep)
        out = sorted(set(out))
        self._memo[key] = list(out)
        return out

    def reachable(self, seed: str) -> List[str]:
        if seed not in self._views:
            return []
        settled: Set[str] = set()
        work: deque[str] = deque([seed])
        while work:
            u = work.popleft()
            if u in settled:
                continue
            settled.add(u)
            for v in sorted(self._deps.get(u, [])):
                if v not in settled:
                    work.append(v)
        return sorted(settled)


def load_index(views: List[str], requires: List[Tuple[str, str]]) -> SnapshotIndex:
    idx = SnapshotIndex()
    for v in views:
        idx.add_view(v)
    for dst, src in requires:
        idx.link(dst, src)
    return idx
