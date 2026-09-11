"""turndb/turndb#11 — Publication gate lineage reach for shipped items."""

node GateItem {
    has name: str;
    has state: str = "open";
}

edge Refs {}

obj GateStore {
    has items: dict[str, GateItem] = {};
}

walker DownstreamWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has anchor: str = "";

    can step with GateItem entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.anchor { self.found.append(here.name); }
        visit [->:Refs:->][?:GateItem];
    }
}

def load_gate(
    item_names: list[str],
    ref_edges: list[tuple[str, str]],
    states: dict[str, str] | None = None,
) -> GateStore {
    store = GateStore();
    for name in item_names {
        nd = GateItem(name=name);
        root ++> nd;
        store.items[name] = nd;
    }
    for (src, dst) in ref_edges {
        s = store.items.get(src, None);
        d = store.items.get(dst, None);
        if s is not None and d is not None { s +>:Refs:+> d; }
    }
    if states is not None {
        for (k, v) in states.items() {
            it = store.items.get(k, None);
            if it is not None { it.state = v; }
        }
    }
    return store;
}

def downstream_items(store: GateStore, `root: str) -> list[str] {
    nd = store.items.get(`root, None);
    if nd is None { return []; }
    w = nd spawn DownstreamWalk(claimed={}, anchor=`root);
    return sorted(w.found);
}

def blocked_by_state(store: GateStore, `root: str, blocked_states: list[str]) -> list[str] {
    reach = downstream_items(store, `root);
    blocked: dict[str, bool] = {};
    for st in blocked_states { blocked[st] = True; }
    out: list[str] = [];
    nd = store.items.get(`root, None);
    if nd is not None and nd.state in blocked { out.append(`root); }
    for name in reach {
        it = store.items.get(name, None);
        if it is not None and it.state in blocked { out.append(name); }
    }
    return sorted(out);
}

def unresolved_refs(_store: GateStore) -> list[str] {
    return [];
}
