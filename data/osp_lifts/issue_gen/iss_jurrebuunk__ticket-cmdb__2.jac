"""jurrebuunk/ticket-cmdb#2 — Nested CMDB items for hierarchical impact analysis."""

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
