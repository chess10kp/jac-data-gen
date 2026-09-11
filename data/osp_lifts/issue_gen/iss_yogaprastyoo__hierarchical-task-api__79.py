"""Workspace tree with recursive descendant collection and archive.

yogaprastyoo/hierarchical-task-api#79: collectDescendantIds() recursively
resolves children one node at a time -- a per-node lookup over the whole
workspace table for every step of the walk -- and isDescendant() walks up
the parent chain with one registry lookup per level. archiveWorkspace()
runs the collector, then removes the gathered ids. Tree depth is capped at
3 by domain rule; moves must never create a parent cycle.
"""

MAX_DEPTH = 3


class WorkspaceTree:
    def __init__(self):
        self.parent = {}  # ws id -> parent id or None
        self.name = {}    # ws id -> display name

    def add(self, wid, name, parent=None):
        if parent is not None and parent not in self.parent:
            raise KeyError(parent)
        if parent is not None and self.depth_of(parent) + 1 >= MAX_DEPTH:
            raise ValueError("max_depth")
        self.parent[wid] = parent
        self.name[wid] = name

    def depth_of(self, wid):
        """Distance from the root; ascends by single lookups."""
        d = 0
        cur = self.parent.get(wid)
        while cur is not None:
            d += 1
            cur = self.parent.get(cur)
        return d

    def collect_descendant_ids(self, wid):
        """All descendant ids below wid (wid excluded)."""
        out = []
        stack = [wid]
        while stack:
            cur = stack.pop()
            for cand, par in self.parent.items():  # whole-table rescan/step
                if par == cur:
                    out.append(cand)
                    stack.append(cand)
        return sorted(out)

    def is_descendant(self, candidate, ancestor):
        """True when candidate sits somewhere below ancestor."""
        cur = self.parent.get(candidate)
        while cur is not None:
            if cur == ancestor:
                return True
            if cur not in self.parent:  # dangling ref: fail closed
                raise KeyError(cur)
            cur = self.parent[cur]
        return False

    def move(self, wid, new_parent):
        if wid not in self.parent or (
            new_parent is not None and new_parent not in self.parent
        ):
            raise KeyError(wid)
        if new_parent is not None and (
            new_parent == wid or self.is_descendant(new_parent, wid)
        ):
            raise ValueError("cycle")
        base = 0 if new_parent is None else self.depth_of(new_parent)
        for d in self.collect_descendant_ids(wid):
            if base + self._subtree_height(d) + 1 > MAX_DEPTH - 1 + 1:
                raise ValueError("max_depth")
        self.parent[wid] = new_parent

    def _subtree_height(self, wid):
        kids = [c for c, p in self.parent.items() if p == wid]
        if not kids:
            return 1
        return 1 + max(self._subtree_height(k) for k in kids)

    def archive(self, wid):
        """Remove wid and its whole subtree; returns sorted removed ids."""
        removed = [wid] + self.collect_descendant_ids(wid)
        for r in removed:
            del self.parent[r]
            del self.name[r]
        return sorted(removed)
