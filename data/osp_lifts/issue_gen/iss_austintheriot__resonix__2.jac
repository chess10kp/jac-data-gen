"""austintheriot/resonix#2 - Audio dependency graph linearization."""

node AudioNode {
    has nid: str;
}

edge Depends {}

def build_store -> dict[str, AudioNode] {
    store: dict[str, AudioNode] = {};
    return store;
}

def lookup_node(store: dict[str, AudioNode], node_id: str) -> AudioNode | None {
    if node_id in store {
        return store[node_id] as AudioNode;
    }
    return None;
}

def register_node(
    store: dict[str, AudioNode],
    node_id: str,
    depends_on: list[str] | None = None,
) {
    if depends_on is None {
        depends_on = [];
    }
    if node_id not in store {
        nd = AudioNode(nid=node_id);
        root ++> nd;
        store[node_id] = nd;
    }
    target = store[node_id] as AudioNode;
    for dep_id in depends_on {
        if dep_id not in store {
            dep_nd = AudioNode(nid=dep_id);
            root ++> dep_nd;
            store[dep_id] = dep_nd;
        }
        if dep_id != node_id {
            dep = store[dep_id] as AudioNode;
            target +>:Depends:+> dep;
        }
    }
}

walker OrderWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with AudioNode entry {
        if here.nid in self.claimed {
            skip;
        }
        self.claimed[here.nid] = True;
        raw_deps: list[AudioNode] = [];
        for dep in [here ->:Depends:->][?:AudioNode] {
            raw_deps.append(dep);
        }
        dep_names: list[str] = [];
        for d in raw_deps {
            dep_names.append(d.nid);
        }
        dep_names = sorted(dep_names);
        sorted_deps: list[AudioNode] = [];
        for name in dep_names {
            for d in raw_deps {
                if d.nid == name {
                    sorted_deps.append(d);
                }
            }
        }
        if len(sorted_deps) > 0 {
            visit :0: sorted_deps else {
                disengage;
            }
        }
        self.order.append(here.nid);
        print([here.nid, self.order]);
    }
}

def resolve_processing_order(store: dict[str, AudioNode]) -> list[str] {
    shared_claimed: dict[str, bool] = {};
    shared_order: list[str] = [];
    ids: list[str] = sorted(store.keys());
    for nid in ids {
        if nid not in shared_claimed {
            nd = store[nid] as AudioNode;
            w = nd spawn OrderWalker(claimed=shared_claimed, order=shared_order);
            shared_claimed = w.claimed;
            shared_order = w.order;
        }
    }
    return shared_order;
}
