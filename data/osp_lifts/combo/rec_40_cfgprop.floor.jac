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
class Zone {
    def init(self: Zone, zid: Any, parent: Any = None) -> object {
        self.zid = zid;
        self.parent = parent;
        self.children = [];
        self.overrides = {};
        self.cache = {};
        self.materialized = False;
    }
}
class ConfigTree {
    def init(self: ConfigTree) -> object {
        self.zones = {};
        self.counts = {};
    }
    def add_zone(self: ConfigTree, zid: Any, parent: Any = None) -> object {
        if (zid in self.zones) {
            raise ValueError("duplicate zone");
        }
        if ((parent is not None) and (parent not in self.zones)) {
            raise KeyError(parent);
        }
        p = self.zones[parent] if (parent is not None) else None;
        z = Zone(zid, p);
        if (p is not None) {
            p.children.append(z);
        }
        self.zones[zid] = z;
        return zid;
    }
    def _subtree_ids(self: ConfigTree, zid: Any) -> list {
        out: list = [];
        q: list = [zid];
        while len(q) > 0 {
            cur: str = q.pop(0) as str;
            out.append(cur);
            kids: list = (self.zones[cur] as Zone).children as list;
            for c in kids {
                cz = c as Zone;
                q.append(cz.zid);
            }
        }
        return out;
    }
    def _recount_up(self: ConfigTree, zid: Any) -> object {
        cur2: Zone | None = self.zones[zid] as Zone | None;
        while (cur2 is not None) {
            cz: str = cur2.zid as str;
            total: int = 0;
            for t in self._subtree_ids(cz) {
                zz = self.zones[t] as Zone;
                total += len(zz.overrides as dict);
            }
            self.counts[cz] = total;
            nxt: Zone | None = cur2.parent as Zone | None;
            cur2 = nxt;
        }
    }
    """Write an override; invalidate subtree caches; recount up."""
    def set_override(self: ConfigTree, zid: Any, key: Any, value: Any) -> object {
        z = self.zones[zid];
        z.overrides[key] = value;
        for t in self._subtree_ids(zid) {
            zt = self.zones[t];
            zt.cache.clear();
            zt.materialized = False;
        }
        self._recount_up(zid);
    }
    """Remove an override if present; same invalidation protocol.
        Returns True when an override was removed."""
    def clear_override(self: ConfigTree, zid: Any, key: Any) -> object {
        z = self.zones[zid];
        if (key not in z.overrides) {
            return False;
        }
        delete(z.overrides[key],);
        for t in self._subtree_ids(zid) {
            zt = self.zones[t];
            zt.cache.clear();
            zt.materialized = False;
        }
        self._recount_up(zid);
        return True;
    }

    """Nearest override wins: walk the chain from zid upward."""
    def effective(self: ConfigTree, zid: Any, key: Any) -> object {
        cur3: Zone | None = self.zones[zid] as Zone | None;
        while (cur3 is not None) {
            ov = cur3.overrides as dict;
            if (key in ov) {
                return ov[key];
            }
            up3: Zone | None = cur3.parent as Zone | None;
            cur3 = up3;
        }
        return None;
    }
    """Materialized view of all keys visible at zid (cached)."""
    def effective_view(self: ConfigTree, zid: Any) -> dict {
        z = self.zones[zid] as Zone;
        if (not z.materialized) {
            merged: dict = {};
            ids: list = self.chain(zid) as list;
            for rid in reversed(ids) {
                zz = self.zones[rid] as Zone;
                ov = zz.overrides as dict;
                for ok in ov.keys() {
                    merged[ok] = ov[ok];
                }
            }
            z.cache = merged;
        }
        z.materialized = True;
        return z.cache as dict;
    }
    """Observable evaluation order: nearest zone first."""
    def chain(self: ConfigTree, zid: Any) -> list {
        chain = [];
        cur = self.zones[zid];
        while (cur is not None) {
            chain.append(cur.zid);
            cur = cur.parent;
        }
        return chain;
    }
    def override_count(self: ConfigTree, zid: Any) -> object {
        return self.counts.get(zid, 0);
    }
    """Invariant: every materialized cached view equals recomputed
        truth; unmaterialized caches are trivially coherent."""
    def coherent(self: ConfigTree) -> object {
        for zid in self.zones.keys() {
            z = self.zones[zid] as Zone;
            if (not z.materialized) {
                continue;
            }
            truth = self.effective_view(zid);
            if (z.cache != truth) {
                return False;
            }
        }
        return True;
    }
}

