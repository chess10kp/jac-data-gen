node FactNode { has uid: str; has kind: str; }
node InferenceNode { has uid: str; has kind: str; }
node GraphRoot { has gid: str = "root"; has fact_index: dict[str, FactNode] = {}; has inf_index: dict[str, InferenceNode] = {}; }
edge Depends {}

walker CollectAffected {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can collect_fact with FactNode entry {
        if here.uid in self.claimed { skip; }
        self.claimed[here.uid] = True;
        for nxt in [here ->:Depends:->][?:InferenceNode] {
            visit :0: [nxt];
        }
        print(here.uid);
    }
    can collect_inf with InferenceNode entry {
        if here.uid in self.claimed { skip; }
        self.claimed[here.uid] = True;
        self.found.append(here.uid);
        for nxt in [here ->:Depends:->][?:InferenceNode] {
            visit :0: [nxt];
        }
        print(here.uid);
    }
}

walker Bootstrap {
    has dummy: bool = False;
    can boot with GraphRoot entry {
        print("bootstrap:" + here.gid);
    }
}

def create_graph() -> GraphRoot {
    g = GraphRoot();
    return g;
}

def add_fact(graph_root: GraphRoot, uid: str, kind: str) -> FactNode {
    if uid in graph_root.fact_index {
        return graph_root.fact_index[uid];
    }
    nd: FactNode = FactNode(uid=uid, kind=kind);
    graph_root.fact_index[uid] = nd;
    graph_root ++> nd;
    return nd;
}

def add_inference(graph_root: GraphRoot, uid: str, kind: str) -> InferenceNode {
    if uid in graph_root.inf_index {
        return graph_root.inf_index[uid];
    }
    nd: InferenceNode = InferenceNode(uid=uid, kind=kind);
    graph_root.inf_index[uid] = nd;
    graph_root ++> nd;
    return nd;
}

def add_dependency(graph_root: GraphRoot, src: str, dst: str) -> bool {
    if src in graph_root.fact_index {
        if dst in graph_root.inf_index {
            s: FactNode = graph_root.fact_index[src];
            d: InferenceNode = graph_root.inf_index[dst];
            s +>:Depends:+> d;
            return True;
        }
        return False;
    }
    if src in graph_root.inf_index {
        if dst in graph_root.inf_index {
            s2: InferenceNode = graph_root.inf_index[src];
            d2: InferenceNode = graph_root.inf_index[dst];
            s2 +>:Depends:+> d2;
            return True;
        }
        return False;
    }
    return False;
}

def record_changed_facts(graph_root: GraphRoot, changed: list[str]) -> list[str] {
    claimed: dict[str, bool] = {};
    all_found: list[str] = [];
    for fid in changed {
        if fid in graph_root.fact_index {
            nd: FactNode = graph_root.fact_index[fid];
            w = nd spawn CollectAffected(claimed=claimed, found=all_found);
            claimed = w.claimed;
            all_found = w.found;
        }
    }
    return sorted(all_found);
}

def schedule_scopes(graph_root: GraphRoot, changed: list[str]) -> list[str] {
    all: list[str] = record_changed_facts(graph_root, changed);
    scopes: list[str] = [];
    for nid in all {
        nd: InferenceNode = graph_root.inf_index[nid];
        if nd.kind == "scope" {
            scopes.append(nid);
        }
    }
    return sorted(scopes);
}

with entry {
    g = GraphRoot();
    root ++> g;
    b = root spawn Bootstrap();
    c = g spawn Bootstrap();
    print("ready");
}
