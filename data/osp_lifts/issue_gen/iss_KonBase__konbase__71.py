"""KonBase/konbase#71 -- hierarchical organization queries."""

from __future__ import annotations

from collections import deque

class OrgHierarchy:
    def __init__(self) -> None:
        self.orgs: set[str] = set()
        self.parent: dict[str, str | None] = {}
        self.children: dict[str, list[str]] = {}

def make_hierarchy() -> OrgHierarchy:
    return OrgHierarchy()

def add_org(h: OrgHierarchy, org_id: str, parent: str | None) -> None:
    if org_id in h.orgs:
        raise ValueError("duplicate org")
    h.orgs.add(org_id)
    h.parent[org_id] = parent
    h.children.setdefault(org_id, [])
    if parent is not None:
        if parent not in h.orgs:
            h.orgs.add(parent)
            h.parent.setdefault(parent, None)
            h.children.setdefault(parent, [])
        h.children[parent].append(org_id)

def descendants(h: OrgHierarchy, root: str) -> list[str]:
    if root not in h.orgs:
        return []
    out: list[str] = []
    q: deque[str] = deque([root])
    seen: set[str] = set()
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        if cur != root:
            out.append(cur)
        for ch in h.children.get(cur, []):
            if ch not in seen:
                q.append(ch)
    return sorted(out)

def ancestors(h: OrgHierarchy, leaf: str) -> list[str]:
    if leaf not in h.orgs:
        return []
    chain: list[str] = []
    cur: str | None = leaf
    seen: set[str] = set()
    while cur is not None:
        parent = h.parent.get(cur)
        if parent is None:
            break
        if parent in seen:
            break
        chain.append(parent)
        seen.add(parent)
        cur = parent
    return chain  # already root-ward order

def depth_of(h: OrgHierarchy, org_id: str) -> int:
    if org_id not in h.orgs:
        raise KeyError(org_id)
    d = 0
    cur = org_id
    seen: set[str] = set()
    while True:
        parent = h.parent.get(cur)
        if parent is None:
            break
        if parent in seen:
            raise ValueError("cycle")
        seen.add(parent)
        d += 1
        cur = parent
    return d

def has_cycle(h: OrgHierarchy) -> bool:
    visited: set[str] = set()
    stack: set[str] = set()
    def dfs(n: str) -> bool:
        visited.add(n)
        stack.add(n)
        for ch in h.children.get(n, []):
            if ch not in visited:
                if dfs(ch):
                    return True
            elif ch in stack:
                return True
        stack.remove(n)
        return False
    for n in list(h.orgs):
        if n not in visited:
            if dfs(n):
                return True
    return False
