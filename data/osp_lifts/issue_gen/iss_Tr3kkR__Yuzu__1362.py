"""Tr3kkR/Yuzu#1362 — ManagementGroupStore reparent cycle-check (TOCTOU window)."""

from collections import deque


class GroupStore:
    def __init__(self) -> None:
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}

    def add_group(self, gid: str, parent_id: str | None = None) -> None:
        if gid in self._parent:
            raise ValueError(f"duplicate group: {gid}")
        if parent_id is not None and parent_id not in self._parent:
            raise KeyError(parent_id)
        self._parent[gid] = parent_id
        self._children.setdefault(gid, [])
        if parent_id is not None:
            self._children.setdefault(parent_id, []).append(gid)

    def ancestors(self, gid: str) -> list[str]:
        if gid not in self._parent:
            raise KeyError(gid)
        out: list[str] = []
        cur = self._parent.get(gid)
        seen: set[str] = set()
        while cur is not None:
            if cur in seen:
                break
            seen.add(cur)
            out.append(cur)
            cur = self._parent.get(cur)
        return out

    def descendants(self, gid: str) -> list[str]:
        if gid not in self._parent:
            raise KeyError(gid)
        q: deque[str] = deque(self._children.get(gid, []))
        claimed: set[str] = set()
        hits: list[str] = []
        while q:
            n = q.popleft()
            if n in claimed:
                continue
            claimed.add(n)
            hits.append(n)
            for c in self._children.get(n, []):
                if c not in claimed:
                    q.append(c)
        return sorted(hits)

    def would_cycle(self, new_parent: str, gid: str) -> bool:
        if new_parent not in self._parent or gid not in self._parent:
            raise KeyError(new_parent if new_parent not in self._parent else gid)
        if new_parent == gid:
            return True
        return gid in self.ancestors(new_parent)

    def reparent(self, gid: str, new_parent: str | None) -> None:
        if gid not in self._parent:
            raise KeyError(gid)
        if new_parent is not None and self.would_cycle(new_parent, gid):
            raise ValueError("cycle")
        old = self._parent[gid]
        if old is not None:
            self._children[old] = [c for c in self._children[old] if c != gid]
        self._parent[gid] = new_parent
        if new_parent is not None:
            self._children.setdefault(new_parent, []).append(gid)


def build_store() -> GroupStore:
    return GroupStore()
