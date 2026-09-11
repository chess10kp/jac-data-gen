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

test "basic_scheduling" {
    g = create_graph();
    root ++> g;
    add_fact(g, "b1", "binding");
    add_inference(g, "s1", "scope");
    add_inference(g, "e1", "expr");
    assert(add_dependency(g, "b1", "s1"));
    assert(add_dependency(g, "b1", "e1"));
    r = record_changed_facts(g, ["b1"]);
    assert(r == ["e1", "s1"]);
}

test "adversarial_insertion_order_diamond" {
    g = create_graph();
    root ++> g;
    add_fact(g, "f", "binding");
    add_inference(g, "left", "scope");
    add_inference(g, "right", "scope");
    add_inference(g, "bottom", "scope");
    assert(add_dependency(g, "f", "right"));
    assert(add_dependency(g, "f", "left"));
    assert(add_dependency(g, "left", "bottom"));
    assert(add_dependency(g, "right", "bottom"));
    r = record_changed_facts(g, ["f"]);
    assert(r == ["bottom", "left", "right"]);
}

test "unknown_id_tolerance" {
    g = create_graph();
    root ++> g;
    add_fact(g, "f1", "binding");
    add_inference(g, "s1", "scope");
    assert(add_dependency(g, "f1", "s1"));
    r = record_changed_facts(g, ["unknown", "f1"]);
    assert(r == ["s1"]);
    assert(add_dependency(g, "nope", "s1") == False);
    assert(add_dependency(g, "f1", "nope") == False);
    r2 = record_changed_facts(g, ["missing"]);
    assert(r2 == []);
}

test "cycle_does_not_hang" {
    g = create_graph();
    root ++> g;
    add_fact(g, "f", "binding");
    add_inference(g, "a", "expr");
    add_inference(g, "b", "expr");
    assert(add_dependency(g, "f", "a"));
    assert(add_dependency(g, "a", "b"));
    assert(add_dependency(g, "b", "a"));
    r = record_changed_facts(g, ["f"]);
    assert(r == ["a", "b"]);
    r2 = schedule_scopes(g, ["f"]);
    assert(r2 == []);
}
