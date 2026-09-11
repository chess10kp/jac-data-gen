"""Priivacy-ai/spec-kitty#3281 — Lane dependency closure and missing propagation."""

node Lane {
    has lid: str;
    has merged: bool = False;
}

edge LaneDepends {}

obj LaneStore {
    has lanes: dict[str, Lane] = {};
}

walker DepClose {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has anchor: str = "";

    can step with Lane entry {
        if here.lid in self.claimed { skip; }
        self.claimed[here.lid] = True;
        if here.lid != self.anchor {
            self.found.append(here.lid);
        }
        visit [->:LaneDepends:->][?:Lane];
    }
}

def load_lanes(
    lane_ids: list[str],
    depends_edges: list[tuple[str, str]],
) -> LaneStore {
    store = LaneStore();
    for lid in lane_ids {
        nd = Lane(lid=lid);
        root ++> nd;
        store.lanes[lid] = nd;
    }
    for (upstream, downstream) in depends_edges {
        u = store.lanes.get(upstream, None);
        d = store.lanes.get(downstream, None);
        if u is not None and d is not None { d +>:LaneDepends:+> u; }
    }
    return store;
}

def dependency_closure(store: LaneStore, lane: str) -> list[str] {
    nd = store.lanes.get(lane, None);
    if nd is None { return []; }
    w = nd spawn DepClose(claimed={}, anchor=lane);
    return sorted(w.found);
}

def missing_dependencies(store: LaneStore, lane: str) -> list[str] {
    required = dependency_closure(store, lane);
    out: list[str] = [];
    for dep in required {
        l = store.lanes.get(dep, None);
        if l is not None and not l.merged { out.append(dep); }
    }
    return sorted(out);
}

def mark_merged(store: LaneStore, lane: str) -> None {
    nd = store.lanes.get(lane, None);
    if nd is not None { nd.merged = True; }
}

def is_ancestor_merged(store: LaneStore, lane: str) -> bool {
    deps = dependency_closure(store, lane);
    if len(deps) == 0 { return True; }
    for dep in deps {
        l = store.lanes.get(dep, None);
        if l is None or not l.merged { return False; }
    }
    return True;
}
