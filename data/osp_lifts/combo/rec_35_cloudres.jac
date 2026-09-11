"""Cloud resource dependency manager, lifted to OSP.

Resources form a ChildOf deployment tree with an incrementally maintained
subtree aggregate; DependsOn edges are cross-stack dependency cross-links.
Cascade deletion follows the two-phase protocol: a walker collects the
doomed set (with once-only guards for shared descendants), the facade
checks external dependencies, disconnects edges and drops registry entries
outside any walk, then ancestor aggregates are recomputed up the chain.
Cycle policy: the source rejected direct self-dependencies (kept) and its
sweeps carried visited guards (kept as skip-guards).
"""
node Resource {
    has rid: str;
    has cost: int;
    has agg: int;
    has dead: bool = False;
}

"""Deployment tree: parent +>:ChildOf:+> nested resource."""
edge ChildOf {}

"""Cross-stack dependency: src +>:DependsOn:+> dst."""
edge DependsOn {}

walker CascadeCollector {
    """Queue-equivalent descendant sweep over ChildOf; once-only per node."""
    has origin: str;
    has claimed: dict[str, bool] = {};
    has doomed: set[str] = set();

    can step with Resource entry {
        if here.rid in self.claimed {
            skip;
        }
        self.claimed[here.rid] = True;
        self.doomed.add(here.rid);
        visit [->:ChildOf:->];
    }
}

walker DepClosure {
    """Stack-equivalent closure over forward DependsOn edges. The origin
    is entered once to seed the walk and discarded by the facade; a cycle
    back to an already-seen node skips without aborting sibling branches."""
    has claimed: dict[str, bool] = {};

    can step with Resource entry {
        if here.rid in self.claimed {
            skip;
        }
        self.claimed[here.rid] = True;
        visit [->:DependsOn:->];
    }
}

walker AggAdjuster {
    """Linear ascent over ChildOf applying a cost delta to each ancestor.
    Dead ends at the root disengage the walk."""
    has delta: int;

    can step with Resource entry {
        here.agg += self.delta;
        visit [here <-:ChildOf:<-] else { disengage; }
    }
}

walker ChainAscent {
    """Linear climb over ChildOf including the entry resource."""
    has chain: list[str] = [];

    can step with Resource entry {
        self.chain.append(here.rid);
        visit [here <-:ChildOf:<-] else { disengage; }
    }
}

obj CloudManager {
    """Compatibility facade. Resource ids are public API currency, so
    by_id is domain lookup state."""
    has by_id: dict[str, Resource] = {};

    def add_resource(rid: str, parent: str | None = None, cost: int = 0) -> str {
        if rid in self.by_id {
            raise ValueError("duplicate resource " + rid);
        }
        r := Resource(rid=rid, cost=cost, agg=cost);
        if parent is not None {
            p = self.by_id[parent];
            p +>:ChildOf:+> r;
            p spawn AggAdjuster(delta=cost);
        }
        self.by_id[rid] = r;
        return rid;
    }

    def attach_dependency(src: str, dst: str) -> None {
        if src == dst {
            raise ValueError("self dependency");
        }
        s = self.by_id[src];
        d = self.by_id[dst];
        outgoing: list[Resource] = [s ->:DependsOn:->];
        if d in outgoing {
            return;
        }
        s +>:DependsOn:+> d;
    }

    def dependency_closure(rid: str) -> list[str] {
        w: DepClosure = self.by_id[rid] spawn DepClosure();
        return sorted(k for k in w.claimed.keys() if k != rid);
    }

    """Two-phase cascade delete. Phase 1 collects the doomed subtree;
    phase 2 validates external dependencies, disconnects every edge
    touching the set, drops registry entries and recomputes ancestors."""
    def delete(rid: str) -> list[str] {
        if rid not in self.by_id {
            raise KeyError(rid);
        }
        w: CascadeCollector = self.by_id[rid] spawn CascadeCollector(origin=rid);
        doomed: set[str] = w.doomed;
        # external dependency check: any live incoming DependsOn edge
        # from outside the doomed set blocks deletion
        for d in doomed {
            ins: list[Resource] = [self.by_id[d] <-:DependsOn:<-];
            for i in ins {
                if i.rid not in doomed {
                    raise ValueError("resource in use: " + rid);
                }
            }
        }
        removed_cost: int = 0;
        for d in doomed {
            removed_cost += self.by_id[d].cost;
        }
        parent: Resource | None = None;
        ups: list[Resource] = [self.by_id[rid] <-:ChildOf:<-];
        if len(ups) > 0 {
            parent = ups[0];
        }
        for d in doomed {
            r = self.by_id.pop(d);
            r.dead = True;
            # sever hierarchy edges to/from the dead node
            kids: list[Resource] = [r ->:ChildOf:->];
            for k in kids {
                r del ->:ChildOf:-> k;
            }
            for up in [r <-:ChildOf:<-] {
                up del ->:ChildOf:-> r;
            }
            outs: list[Resource] = [r ->:DependsOn:->];
            for o in outs {
                r del ->:DependsOn:-> o;
            }
            ins: list[Resource] = [r <-:DependsOn:<-];
            for i in ins {
                i del ->:DependsOn:-> r;
            }
        }
        if parent is not None {
            parent spawn AggAdjuster(delta=-removed_cost);
        }
        return sorted(doomed);
    }

    def aggregate(rid: str) -> int {
        return self.by_id[rid].agg;
    }

    def ancestors(rid: str) -> list[str] {
        # spawn the linear climb; drop the start id like the source
        w = self.by_id[rid] spawn ChainAscent();
        return w.chain[1:];
    }
}
