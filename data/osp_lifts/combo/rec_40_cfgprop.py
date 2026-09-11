"""Distributed configuration propagation tree.

Zones form a region -> cluster -> node hierarchy. Configuration overrides
are attached at any zone; the effective value of a key at a zone is defined
by the NEAREST zone on its ancestor chain that overrides it. Every zone
caches a materialized effective view; writes must invalidate caches down
the subtree and maintain override counts up the chain.

Hand-rolled machinery:
- parent/children pointers over the zone tree with recursive ascent and
  queue-based subtree invalidation sweeps (C1)
- per-key override adjacency dicts plus BFS frontier walks (C2)
- two-phase cache invalidation cascade with coherence invariants (C5)
"""


class Zone:
    def __init__(self, zid, parent=None):
        self.zid = zid
        self.parent = parent
        self.children = []
        self.overrides = {}   # key -> value written directly here
        self.cache = {}       # materialized effective view
        self.materialized = False


class ConfigTree:
    def __init__(self):
        self.zones = {}     # zid -> Zone
        self.counts = {}    # zid -> number of overrides in its subtree

    def add_zone(self, zid, parent=None):
        if zid in self.zones:
            raise ValueError("duplicate zone " + zid)
        if parent is not None and parent not in self.zones:
            raise KeyError(parent)
        p = self.zones[parent] if parent is not None else None
        z = Zone(zid, p)
        if p is not None:
            p.children.append(z)
        self.zones[zid] = z
        return zid

    def _subtree_ids(self, zid):
        out = []
        q = [zid]
        while q:
            cur = q.pop(0)
            out.append(cur)
            q.extend(c.zid for c in self.zones[cur].children)
        return out

    def _recount_up(self, zid):
        cur = self.zones[zid]
        while cur is not None:
            self.counts[cur.zid] = sum(
                len(self.zones[t].overrides) for t in self._subtree_ids(cur.zid)
            )
            cur = cur.parent

    def set_override(self, zid, key, value):
        """Write an override; invalidate subtree caches; recount up."""
        z = self.zones[zid]
        z.overrides[key] = value
        for t in self._subtree_ids(zid):
            zt = self.zones[t]
            zt.cache.clear()
            zt.materialized = False
        self._recount_up(zid)

    def clear_override(self, zid, key):
        """Remove an override if present; same invalidation protocol.
        Returns True when an override was removed."""
        z = self.zones[zid]
        if key not in z.overrides:
            return False
        del z.overrides[key]
        for t in self._subtree_ids(zid):
            zt = self.zones[t]
            zt.cache.clear()
            zt.materialized = False
        self._recount_up(zid)
        return True

    def effective(self, zid, key):
        """Nearest override wins: walk the chain from zid upward."""
        cur = self.zones[zid]
        while cur is not None:
            if key in cur.overrides:
                return cur.overrides[key]
            cur = cur.parent
        return None

    def effective_view(self, zid):
        """Materialized view of all keys visible at zid (cached)."""
        z = self.zones[zid]
        if not z.cache:
            merged = {}
            for rid in reversed(self.chain(zid)):
                merged.update(self.zones[rid].overrides)
            z.cache.update(merged)
        z.materialized = True
        return dict(z.cache)

    def chain(self, zid):
        """Observable evaluation order: nearest zone first."""
        chain = []
        cur = self.zones[zid]
        while cur is not None:
            chain.append(cur.zid)
            cur = cur.parent
        return chain

    def override_count(self, zid):
        return self.counts.get(zid, 0)

    def coherent(self):
        """Invariant: every materialized cached view equals recomputed
        truth; unmaterialized caches are trivially coherent."""
        for zid in self.zones:
            z = self.zones[zid]
            if not z.materialized:
                continue
            truth = {}
            for rid in reversed(self.chain(zid)):
                truth.update(self.zones[rid].overrides)
            if z.cache != truth:
                return False
        return True
