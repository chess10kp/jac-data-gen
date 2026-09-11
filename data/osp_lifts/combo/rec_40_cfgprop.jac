"""Distributed configuration propagation tree, lifted to OSP.

Zones form a ParentZone hierarchy; every configuration write is a Write
node (an auditable override record carrying key and value) linked to its
zone by Applies and to its config key by ForKey. Each zone caches a
materialized effective view in a typed field. Writes follow the two-phase
protocol: an invalidation walker collects the affected subtree once-only
and exits, then caches are dropped outside the walk while a recount ascent
adjusts override counts up the chain. Cycle policy: the tree is acyclic by
construction; sweeps still carry skip-guards because shared subtrees
re-enter nodes. Nearest-override precedence is observable and pinned: the
ancestor-chain order IS the evaluation order.
"""
node Zone {
    has zid: str;
    has cache: dict[str, int] = {};
    has materialized: bool = False;
}

node ConfigKey {
    has name: str;
}

"""One configuration write: an overridable record at one zone."""
node Write {
    has key_name: str;
    has value: int;
    has retired: bool = False;
}

"""Zone hierarchy: parent +>:ParentZone:+> child."""
edge ParentZone {}

"""Zone publishes a write record."""
edge Applies {}

"""Write record targets this config key."""
edge ForKey {}

walker InvalidationSweep {
    """BFS-equivalent descent collecting every zone whose cached view is
    invalidated by an override change at the origin."""
    has claimed: dict[str, bool] = {};
    has affected: set[str] = set();

    can step with Zone entry {
        if here.zid in self.claimed {
            skip;
        }
        self.claimed[here.zid] = True;
        self.affected.add(here.zid);
        visit [->:ParentZone:->];
    }
}

walker CountAscent {
    """Linear ascent over ParentZone recomputing each ancestor's subtree
    override count. Dead ends at the region root disengage."""
    has counter: ConfigTree;

    can step with Zone entry {
        self.counter.counts[here.zid] = self.counter.subtree_overrides(
            here.zid
        );
        visit [here <-:ParentZone:<-] else { disengage; }
    }
}

walker WriteTally {
    """Descends ParentZone edges tallying live override records.
    Skip-guard keeps shared zones once-only."""
    has count: int = 0;
    has claimed: dict[str, bool] = {};

    can step with Zone entry {
        if here.zid in self.claimed {
            skip;
        }
        self.claimed[here.zid] = True;
        mine: list[Write] = [here ->:Applies:->];
        for wr in mine {
            if not wr.retired {
                self.count += 1;
            }
        }
        visit [->:ParentZone:->];
    }
}

walker ZoneAscent {
    """Linear climb over ParentZone including the entry zone."""
    has order: list[str] = [];

    can step with Zone entry {
        self.order.append(here.zid);
        visit [here <-:ParentZone:<-] else { disengage; }
    }
}

walker EffectiveProbe {
    """Nearest-wins search along the parent chain; stops at the first
    live value for the key."""
    has tree: ConfigTree;
    has key: str;
    has value: int | None = None;

    can step with Zone entry {
        v = self.tree._live_value(here, self.key);
        if v is not None {
            self.value = v;
            disengage;
        }
        visit [here <-:ParentZone:<-] else { disengage; }
    }
}

obj ConfigTree {
    """Compatibility facade. Zone ids and config keys are public API
    currency; lookup maps are domain state."""
    has by_zid: dict[str, Zone] = {};
    has by_key: dict[str, ConfigKey] = {};
    has counts: dict[str, int] = {};

    def add_zone(zid: str, parent: str | None = None) -> str {
        if zid in self.by_zid {
            raise ValueError("duplicate zone " + zid);
        }
        z := Zone(zid=zid);
        if parent is not None {
            p = self.by_zid[parent];
            p +>:ParentZone:+> z;
        }
        self.by_zid[zid] = z;
        return zid;
    }

    """Two-phase write: sweep the affected subtree, then drop caches,
    update or create the Write record, and recount up the chain."""
    def set_override(zid: str, key: str, value: int) -> None {
        z = self.by_zid[zid];
        k = self._intern(key);
        w = z spawn InvalidationSweep();
        mine: list[Write] = [z ->:Applies:->];
        hit: Write | None = None;
        for wr in mine {
            if not wr.retired and wr.key_name == key {
                hit = wr;
            }
        }
        if hit is None {
            wr := Write(key_name=key, value=value);
            z +>:Applies:+> wr;
            wr +>:ForKey:+> k;
        } else {
            hit.value = value;
        }
        self._invalidate(w);
        z spawn CountAscent(counter=self);
    }

    def clear_override(zid: str, key: str) -> bool {
        z = self.by_zid[zid];
        k = self.by_key.get(key);
        if k is None {
            return False;
        }
        mine: list[Write] = [z ->:Applies:->];
        hit: Write | None = None;
        for wr in mine {
            if not wr.retired and wr.key_name == key {
                hit = wr;
            }
        }
        if hit is None {
            return False;
        }
        w = z spawn InvalidationSweep();
        # retire the record and sever its links
        hit.retired = True;
        z del ->:Applies:-> hit;
        keys: list[ConfigKey] = [hit ->:ForKey:->];
        for kk in keys {
            hit del ->:ForKey:-> kk;
        }
        self._invalidate(w);
        z spawn CountAscent(counter=self);
        return True;
    }

    """Nearest override wins; the ascent order is the documented
    evaluation order and is pinned by tests."""
    def effective(zid: str, key: str) -> int | None {
        # nearest override wins; spawn the probe from zid itself
        w = self.by_zid[zid] spawn EffectiveProbe(tree=self, key=key);
        return w.value;
    }

    def _intern(name: str) -> ConfigKey {
        k = self.by_key.get(name);
        if k is None {
            k = ConfigKey(name=name);
            self.by_key[name] = k;
        }
        return k;
    }

    def _invalidate(w: InvalidationSweep) -> None {
        for t in w.affected {
            tz = self.by_zid[t];
            tz.cache = {};
            tz.materialized = False;
        }
    }

    def _live_value(z: Zone, key: str) -> int | None {
        mine: list[Write] = [z ->:Applies:->];
        for wr in mine {
            if not wr.retired and wr.key_name == key {
                return wr.value;
            }
        }
        return None;
    }

    def chain(zid: str) -> list[str] {
        w = self.by_zid[zid] spawn ZoneAscent();
        return w.order;
    }

    """Walker-based: counts live write records across the subtree."""
    def subtree_overrides(zid: str) -> int {
        w: WriteTally = self.by_zid[zid] spawn WriteTally();
        return w.count;
    }

    def materialize_view(zid: str) -> dict[str, int | None] {
        truth = self.recompute_view(zid);
        z = self.by_zid[zid];
        fresh: dict[str, int] = {};
        for kn in truth.keys() {
            v = truth[kn];
            if v is not None {
                fresh[kn] = v as int;
            }
        }
        z.cache = fresh;
        z.materialized = True;
        return truth;
    }

    def recompute_view(zid: str) -> dict[str, int | None] {
        truth: dict[str, int | None] = {};
        ids = reversed(self.chain(zid));
        for t in ids {
            tz = self.by_zid[t];
            mine: list[Write] = [tz ->:Applies:->];
            for wr in mine {
                if not wr.retired {
                    truth[wr.key_name] = wr.value;
                }
            }
        }
        return truth;
    }

    def effective_view(zid: str) -> dict[str, int | None] {
        return self.materialize_view(zid);
    }

    def override_count(zid: str) -> int {
        return self.counts.get(zid, 0);
    }

    """Invariant probe: materialized views must match recomputation."""
    def coherent() -> bool {
        for zid in self.by_zid.keys() {
            z = self.by_zid[zid];
            if not z.materialized {
                continue;
            }
            truth = self.recompute_view(zid);
            same: bool = True;
            if len(z.cache.keys()) != len(truth.keys()) {
                same = False;
            }
            for kn in truth.keys() {
                if z.cache.get(kn, None) != truth[kn] {
                    same = False;
                }
            }
            if not same {
                return False;
            }
        }
        return True;
    }
}
