"""Guard: jurrebuunk/ticket-cmdb#2."""

obj CmdbStore {
    has items: dict[str, CmdbItem] = {};
}

node CmdbItem {
    has iid: str;
}

edge Contains {}

walker ImpactWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with CmdbItem entry {
        if here.iid in self.claimed { skip; }
        self.claimed[here.iid] = True;
        self.reached.append(here.iid);
        visit [->:Contains:->] else { disengage; };
    }
}

walker AncestorWalk {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can step with CmdbItem entry {
        if here.iid in self.claimed { skip; }
        self.claimed[here.iid] = True;
        self.chain.append(here.iid);
        parents = [here <-:Contains:<-][?:CmdbItem];
        if not parents { disengage; }
        pick = parents[0];
        for p in parents {
            if p.iid < pick.iid { pick = p; }
        }
        visit [pick];
    }
}

def load_cmdb(
    items: list[str],
    contains_edges: list[tuple[str, str]],
) -> CmdbStore {
    g = CmdbStore();
    for iid in items {
        if iid not in g.items {
            nd = CmdbItem(iid=iid);
            root ++> nd;
            g.items[iid] = nd;
        }
    }
    for (parent, child) in contains_edges {
        p = g.items.get(parent, None);
        c = g.items.get(child, None);
        if p is not None and c is not None { p +>:Contains:+> c; }
    }
    return g;
}

def impact_radius(store: CmdbStore, item_id: str) -> list[str] {
    anchor = store.items.get(item_id, None);
    if anchor is None { return []; }
    w = anchor spawn ImpactWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

def ancestor_chain(store: CmdbStore, item_id: str) -> list[str] {
    anchor = store.items.get(item_id, None);
    if anchor is None { return []; }
    w = anchor spawn AncestorWalk(claimed={}, chain=[]);
    return w.chain;
}

test "linear hierarchy impact and ancestors" {
    g = load_cmdb(
        ["app", "api", "db", "cache"],
        [("app", "api"), ("app", "cache"), ("api", "db")],
    );
    assert impact_radius(g, "app") == ["api", "app", "cache", "db"];
    assert ancestor_chain(g, "db") == ["db", "api", "app"];
    assert impact_radius(g, "cache") == ["app", "cache"];
    assert ancestor_chain(g, "app") == ["app"];
}

test "diamond adversarial revisit before deep first-visit" {
    g = load_cmdb(
        ["hub", "left", "right", "leaf"],
        [("right", "leaf"), ("hub", "left"), ("left", "leaf"), ("hub", "right")],
    );
    assert impact_radius(g, "hub") == ["hub", "leaf", "left", "right"];
}

test "contains cycle terminates once per item" {
    g = load_cmdb(
        ["a", "b", "c"],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert ancestor_chain(g, "a") == ["a", "b", "c"];
    assert impact_radius(g, "b") == ["a", "b", "c"];
}

test "unknown item tolerant" {
    g = load_cmdb(["solo"], []);
    assert impact_radius(g, "missing") == [];
    assert ancestor_chain(g, "missing") == [];
}
