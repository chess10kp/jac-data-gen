"""netkeep80/pjson#38 — Persistent $ref resolution with cycle-safe bounds."""

node RefNode {
    has nid: str;
    has value: str | None = None;
}

edge PointsTo {}

obj RefStore {
    has nodes: dict[str, RefNode] = {};
}

walker RefResolve {
    has claimed: dict[str, bool] = {};
    has depth: int = 0;
    has max_depth: int = 0;
    has cyclic: bool = False;
    has result: str | None = None;

    can step with RefNode entry {
        if here.nid in self.claimed {
            self.cyclic = True;
            disengage;
        }
        self.claimed[here.nid] = True;
        if self.depth >= self.max_depth {
            self.cyclic = True;
            disengage;
        }
        outs = [here ->:PointsTo:->][?:RefNode];
        if len(outs) == 0 {
            self.result = here.value;
            disengage;
        }
        self.depth += 1;
        visit [->:PointsTo:->][?:RefNode];
    }
}

walker RefChain {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can step with RefNode entry {
        if here.nid in self.claimed { disengage; }
        self.claimed[here.nid] = True;
        outs = [here ->:PointsTo:->][?:RefNode];
        if len(outs) == 0 { disengage; }
        self.chain.append(here.nid);
        visit [->:PointsTo:->][?:RefNode];
    }
}

def load_refs(
    nodes: list[tuple[str, str | None]],
    ref_edges: list[tuple[str, str]],
) -> RefStore {
    store = RefStore();
    for (nid, value) in nodes {
        nd = RefNode(nid=nid, value=value);
        root ++> nd;
        store.nodes[nid] = nd;
    }
    for (ref_id, target_id) in ref_edges {
        src = store.nodes.get(ref_id, None);
        tgt = store.nodes.get(target_id, None);
        if src is not None and tgt is not None { src +>:PointsTo:+> tgt; }
    }
    return store;
}

def resolve(store: RefStore, ref_id: str, max_depth: int) -> str | None {
    nd = store.nodes.get(ref_id, None);
    if nd is None { return None; }
    w = nd spawn RefResolve(claimed={}, depth=0, max_depth=max_depth, cyclic=False);
    if w.cyclic { return None; }
    return w.result;
}

def is_cyclic_ref(store: RefStore, ref_id: str) -> bool {
    return resolve(store, ref_id, 32) is None and ref_id in store.nodes and len([store.nodes[ref_id] ->:PointsTo:->][?:RefNode]) > 0;
}

def deref_chain(store: RefStore, ref_id: str) -> list[str] {
    nd = store.nodes.get(ref_id, None);
    if nd is None { return []; }
    w = nd spawn RefChain(claimed={});
    return w.chain;
}
