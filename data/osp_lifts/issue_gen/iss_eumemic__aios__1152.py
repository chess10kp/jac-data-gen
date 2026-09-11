"""Task-tree cancel cascade with edge-owned lifetime and sweep.

Before-code synthesized from eumemic/aios#1152 (P1 cancel-cascade):
tasks own their children through parent links; ``cancel`` must cascade
revocation down the ACTIVE descendants (fulfilled tasks stay
terminal -- the fulfilled/revoked asymmetry), and a sweep pass detaches
terminated leaves so the tree carries no dead weight. The cascade here
collects the revocation set in one walk, then applies it outside the
walk.
"""

ACTIVE = "active"
FULFILLED = "fulfilled"
REVOKED = "revoked"


class TaskTree:
    def __init__(self):
        self.state = {}     # tid -> ACTIVE | FULFILLED | REVOKED
        self.parent = {}    # tid -> tid | None

    def spawn_task(self, parent_tid=None):
        if parent_tid is not None and parent_tid not in self.state:
            raise KeyError("unknown parent task")
        tid = "t%d" % (len(self.state) + 1)
        self.state[tid] = ACTIVE
        self.parent[tid] = parent_tid
        return tid

    def complete(self, tid):
        if tid not in self.state:
            raise KeyError("unknown task")
        if self.state[tid] == ACTIVE:
            self.state[tid] = FULFILLED
        return self.state[tid]

    def _children_map(self):
        children = {}
        for tid, p in self.parent.items():
            if p is not None:
                children.setdefault(p, []).append(tid)
        return children

    def cancel(self, tid):
        """Revoke ``tid`` and every active descendant; return count."""
        if tid not in self.state:
            raise KeyError("unknown task")
        # Phase 1 -- collect the revocation set in a single walk.
        to_revoke = []
        children = self._children_map()
        seen = set()
        frontier = [tid]
        while frontier:
            cur = frontier.pop()
            if cur in seen:
                continue
            seen.add(cur)
            if self.state[cur] == ACTIVE:
                to_revoke.append(cur)
            frontier.extend(children.get(cur, []))
        # Phase 2 -- apply outside the walk.
        for t in to_revoke:
            self.state[t] = REVOKED
        return len(to_revoke)

    def sweep(self):
        """Detach terminated leaf tasks; returns how many were removed."""
        children = self._children_map()
        removed = 0
        for tid in sorted(self.state):
            st = self.state[tid]
            if st == ACTIVE or tid not in self.state:
                continue
            if not children.get(tid):
                del self.state[tid]
                del self.parent[tid]
                removed += 1
        return removed

    def active_children(self, tid):
        """Sorted ids of active direct children of ``tid``."""
        kids = [t for t, p in self.parent.items() if p == tid]
        return sorted(t for t in kids if self.state[t] == ACTIVE)

    def active_descendants(self, tid):
        """Sorted ids of all active tasks below ``tid`` (inclusive)."""
        children = self._children_map()
        out = set()
        frontier = [tid]
        while frontier:
            cur = frontier.pop()
            if cur in out:
                continue
            if self.state.get(cur) == ACTIVE:
                out.add(cur)
            frontier.extend(children.get(cur, []))
        return sorted(out)
