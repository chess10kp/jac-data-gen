"""lirei-lab/thingsflow#1 — tenant-scoped twin relation graph expand."""

node Twin {
    has tid: str;
    has tenant: str = "default";
}

edge RelatesTo {}

obj TwinStore {
    has twins: dict[str, Twin] = {};
}

walker ExpandWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has max_depth: int = 0;
    has depth: int = 0;

    can step with Twin entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.reached.append(here.tid);
        if self.depth >= self.max_depth { disengage; }
        for nxt in [here ->:RelatesTo:->][?:Twin] {
            if not (nxt.tid in self.claimed) {
                child = nxt spawn ExpandWalk(
                    claimed=self.claimed,
                    reached=self.reached,
                    max_depth=self.max_depth,
                    depth=self.depth + 1,
                );
                self.claimed = child.claimed;
                self.reached = child.reached;
            }
        }
    }
}

def load_twin_graph(
    twins: list[str],
    tenants: dict[str, str],
    relations: list[tuple[str, str]],
) -> TwinStore {
    store = TwinStore();
    for tid in twins {
        ten = tenants.get(tid, "default");
        nd = Twin(tid=tid, tenant=ten);
        root ++> nd;
        store.twins[tid] = nd;
    }
    for (src, dst) in relations {
        s = store.twins.get(src, None);
        d = store.twins.get(dst, None);
        if s is not None and d is not None and s.tenant == d.tenant {
            s +>:RelatesTo:+> d;
        }
    }
    return store;
}

def neighbors(store: TwinStore, twin_id: str) -> list[str] {
    nd = store.twins.get(twin_id, None);
    if nd is None { return []; }
    nbrs: list[str] = [];
    for n in [nd ->:RelatesTo:->][?:Twin] { nbrs.append(n.tid); }
    return sorted(nbrs);
}

def expand_relations(store: TwinStore, twin_id: str, max_depth: int) -> list[str] {
    nd = store.twins.get(twin_id, None);
    if nd is None or max_depth < 0 { return []; }
    w = nd spawn ExpandWalk(
        claimed={},
        reached=[],
        max_depth=max_depth,
        depth=0,
    );
    return sorted(w.reached);
}
