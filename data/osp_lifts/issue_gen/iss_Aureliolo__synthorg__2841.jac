"""Plan decomposition persistence, lifted to OSP.

Plan items become PlanItem nodes; the decomposition tree becomes typed
Parent edges (parent item -> child item) and the sibling dependency DAG
becomes typed Depends edges (item -> its dependency). Depth assignment
becomes a walker that records each child's depth as its parent's depth
plus one while descending Parent edges (claim map guards corrupt
cycles); reading a row's parent reads its incoming Parent edge; the
transitive dependency query becomes a walker over Depends edges seeded
at the item's direct dependencies, so a cycle rides back to its own
start. The façade keeps the original id-based signatures.
Ref: Aureliolo/synthorg#2841
"""
node PlanItem {
    has iid: str;
}
edge Parent {}
edge Depends {}

"""Plan handle: item ids resolve through this lookup map."""
obj Plan {
    has items: dict[str, PlanItem];
    has tree_ids: dict[str, bool];

    def resolve(iid: str) -> PlanItem | None {
        return self.items.get(iid);
    }
}

"""Deterministic fresh-graph builder from tree and items specs."""
def load_plan(tree: dict, items: dict) -> Plan {
    pl = Plan(items={}, tree_ids={});
    names: set[str] = set(items.keys());
    for k in items.keys() {
        ds: list[str] = items[k];
        for d in ds {
            names.add(d);
        }
    }
    for k in tree.keys() {
        names.add(k);
        pl.tree_ids[k] = True;
        ch: list[str] = tree[k];
        for c in ch {
            names.add(c);
            pl.tree_ids[c] = True;
        }
    }
    for n in names {
        it = PlanItem(iid=n);
        root ++> it;
        pl.items[n] = it;
    }
    for k in tree.keys() {
        p = pl.resolve(k);
        ch: list[str] = tree[k];
        for c in ch {
            ci = pl.resolve(c);
            if p is not None and ci is not None {
                p +>:Parent:+> ci;
            }
        }
    }
    for k in items.keys() {
        a = pl.resolve(k);
        ds: list[str] = items[k];
        for d in ds {
            b = pl.resolve(d);
            if a is not None and b is not None {
                a +>:Depends:+> b;
            }
        }
    }
    return pl;
}

"""Depth assignment down the decomposition forest."""
walker DepthWalk {
    has depths: dict[str, int];
    has claimed: dict[str, bool] = {};

    can step with PlanItem entry {
        if here.iid in self.claimed {
            skip;
        }
        self.claimed[here.iid] = True;
        d = self.depths.get(here.iid);
        if d is None {
            d = 0;  # a root: no parent edge assigned it a depth
        }
        self.depths[here.iid] = d;
        for c in [here ->:Parent:->] {
            ch: PlanItem = c;
            self.depths[ch.iid] = d + 1;
        }
        visit [->:Parent:->] else { disengage; }
    }
}

"""Durable rows for the decomposition tree, sorted by item id."""
def materialize(tree: dict, items: dict) -> dict {
    pl = load_plan(tree, items);
    depths: dict[str, int] = {};
    claimed: dict[str, bool] = {};
    for n in sorted(pl.items.keys()) {
        it = pl.resolve(n);
        if it is None {
            continue;
        }
        ps: list[PlanItem] = [it <-:Parent:<-];
        if len(ps) == 0 and n in pl.tree_ids {
            it spawn DepthWalk(claimed=claimed, depths=depths);
        }
    }
    rows: list[dict] = [];
    for n in sorted(pl.items.keys()) {
        it = pl.resolve(n);
        if it is None {
            continue;
        }
        ps: list[PlanItem] = [it <-:Parent:<-];
        parent_id: str | None = None;
        if len(ps) > 0 {
            p0: PlanItem = ps[0];
            parent_id = p0.iid;
        }
        rows.append({"id": n, "parent_id": parent_id, "depth": depths.get(n)});
    }
    md = 0;
    for v in depths.values() {
        if v > md {
            md = v;
        }
    }
    return {"rows": rows, "max_depth": md};
}

"""Transitive depends_on closure, once per sibling."""
walker DependsWalk {
    has claimed: dict[str, bool] = {};
    has hit: list[str] = [];

    can step with PlanItem entry {
        if here.iid in self.claimed {
            skip;
        }
        self.claimed[here.iid] = True;
        self.hit.append(here.iid);
        visit [->:Depends:->] else { disengage; }
    }
}

"""Sorted transitive depends_on ids of ``id`` (KeyError when unknown)."""
def dependency_closure(items: dict, id: str) -> list[str] {
    if id not in items {
        raise KeyError(f"unknown plan item {id}");
    }
    pl = load_plan({}, items);
    it = pl.resolve(id);
    claimed: dict[str, bool] = {};
    hit: list[str] = [];
    if it is not None {
        # seed at the direct dependencies: a cycle rides back to id itself
        deps: list[PlanItem] = [it ->:Depends:->];
        for d in deps {
            d spawn DependsWalk(claimed=claimed, hit=hit);
        }
    }
    return sorted(hit);
}
