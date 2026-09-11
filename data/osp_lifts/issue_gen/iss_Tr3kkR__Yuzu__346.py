"""Tr3kkR/Yuzu#346 — management group hierarchy walks."""

from __future__ import annotations

from collections import deque


class GroupStore:
    def __init__(self) -> None:
        self.parent: dict[str, str | None] = {}
        self.children: dict[str, list[str]] = {}


def load_groups(groups: list[tuple[str, str | None]]) -> GroupStore:
    g = GroupStore()
    for gid, par in groups:
        g.parent[gid] = par
        g.children.setdefault(gid, [])
        if par is not None:
            g.children.setdefault(par, []).append(gid)
    return g


def descendant_ids(g: GroupStore, start: str) -> list[str]:
    if start not in g.parent:
        return []
    seen: set[str] = set()
    q: deque[str] = deque([start])
    out: list[str] = []
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        if cur != start:
            out.append(cur)
        for ch in sorted(g.children.get(cur, [])):
            if ch not in seen:
                q.append(ch)
    return sorted(out)


def ancestor_ids(g: GroupStore, start: str) -> list[str]:
    if start not in g.parent:
        return []
    seen: set[str] = set()
    cur: str | None = start
    out: list[str] = []
    while cur is not None:
        par = g.parent.get(cur)
        if par is None or par in seen:
            break
        seen.add(par)
        out.append(par)
        cur = par
    return sorted(out)
