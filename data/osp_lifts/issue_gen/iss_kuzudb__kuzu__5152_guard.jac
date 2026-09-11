"""kuzudb/kuzu#5152 — pairwise hop reach vs bounded backward C closure."""

glob KIND_A = "A";
glob KIND_C = "C";
glob KIND_ATTR = "Attribute";

node GraphNode {
    has nid: str;
    has kind: str;
    has name: str = "";
}

edge ToAttr {}
edge FromAttr {}

obj GraphStore {
    has nodes: dict[str, GraphNode] = {};
}

walker TwoHopFromA {
    has targets: list[str] = [];

    can step with GraphNode entry {
        if here.kind != KIND_A { skip; }
        for attr in [here ->:ToAttr:->][?:GraphNode] {
            for tgt in [attr ->:FromAttr:->][?:GraphNode] {
                if tgt.kind == KIND_C { self.targets.append(tgt.nid); }
            }
        }
    }
}

walker BackwardReach {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has max_depth: int = 6;
    has depth: dict[str, int] = {};

    can step with GraphNode entry {
        if here.nid in self.claimed { skip; }
        cur = self.depth.get(here.nid, 0);
        if cur > self.max_depth { skip; }
        self.claimed[here.nid] = True;
        if here.kind == KIND_C and cur < self.max_depth { self.found.append(here.nid); }
        if cur < self.max_depth {
            preds: list[GraphNode] = [];
            for attr in [here <-:FromAttr:<-][?:GraphNode] {
                for pred in [attr <-:ToAttr:<-][?:GraphNode] { preds.append(pred); }
            }
            names: list[str] = [];
            for p in preds { names.append(p.nid); }
            names = sorted(names);
            ordered: list[GraphNode] = [];
            for nm in names { for p in preds { if p.nid == nm { ordered.append(p); } } }
            i = len(ordered) - 1;
            while i >= 0 {
                nxt = ordered[i];
                if nxt.nid not in self.depth { self.depth[nxt.nid] = cur + 1; }
                visit :0: [nxt];
                i -= 1;
            }
        }
    }
}

def fresh_graph_store -> GraphStore {
    return GraphStore();
}

def register_node(nid: str, kind: str, name: str = "", store: GraphStore | None = None) -> GraphStore {
    s = store;
    if s is None { s = fresh_graph_store(); }
    if nid in s.nodes { raise ValueError("duplicate node id"); }
    nd = GraphNode(nid=nid, kind=kind, name=name);
    root ++> nd;
    s.nodes[nid] = nd;
    return s;
}

def add_pair_hop(from_id: str, attr_id: str, to_id: str, store: GraphStore) {
    if from_id not in store.nodes or attr_id not in store.nodes or to_id not in store.nodes {
        raise KeyError("unknown node id");
    }
    src = store.nodes[from_id];
    attr = store.nodes[attr_id];
    dst = store.nodes[to_id];
    src +>:ToAttr:+> attr;
    attr +>:FromAttr:+> dst;
}

def two_hop_targets(a_id: str, store: GraphStore) -> list[str] {
    if a_id not in store.nodes { raise KeyError(a_id); }
    nd = store.nodes[a_id];
    if nd.kind != KIND_A { return []; }
    w = nd spawn TwoHopFromA(targets=[]);
    return sorted(w.targets);
}

def count_two_hop_a_to_c(store: GraphStore) -> int {
    total = 0;
    for nid in sorted(store.nodes.keys()) {
        nd = store.nodes[nid];
        if nd.kind != KIND_A { continue; }
        w = nd spawn TwoHopFromA(targets=[]);
        total += len(w.targets);
    }
    return total;
}

def backward_c_reach(anchor_id: str, max_depth: int, store: GraphStore) -> list[str] {
    if anchor_id not in store.nodes { raise KeyError(anchor_id); }
    nd = store.nodes[anchor_id];
    w = nd spawn BackwardReach(claimed={}, found=[], max_depth=max_depth, depth={anchor_id: 0});
    return sorted(w.found);
}

def count_backward_c_reach(anchor_name: str, max_depth: int, store: GraphStore) -> int {
    anchor_id = "";
    for nid in store.nodes {
        nd = store.nodes[nid];
        if nd.kind == KIND_C and nd.name == anchor_name { anchor_id = nid; }
    }
    if anchor_id == "" { return 0; }
    return len(backward_c_reach(anchor_id, max_depth, store));
}

def query_row_count(anchor_name: str, max_depth: int, store: GraphStore) -> int {
    anchor_id = "";
    for nid in store.nodes {
        nd = store.nodes[nid];
        if nd.kind == KIND_C and nd.name == anchor_name { anchor_id = nid; }
    }
    if anchor_id == "" { return 0; }
    reach = backward_c_reach(anchor_id, max_depth, store);
    reach_set: dict[str, bool] = {};
    for cid in reach { reach_set[cid] = True; }
    rows = 0;
    for nid in sorted(store.nodes.keys()) {
        nd = store.nodes[nid];
        if nd.kind != KIND_A { continue; }
        w = nd spawn TwoHopFromA(targets=[]);
        for tgt in w.targets { if reach_set.get(tgt, False) { rows += 1; } }
    }
    return rows;
}

test "diamond backward closure skips revisit" {
    s = fresh_graph_store();
    register_node("kuzu", KIND_C, "Kùzu", s);
    register_node("c_left", KIND_C, "", s);
    register_node("c_right", KIND_C, "", s);
    register_node("hub", KIND_C, "", s);
    register_node("a1", KIND_A, "", s);
    register_node("at1", KIND_ATTR, "", s);
    register_node("at2", KIND_ATTR, "", s);
    add_pair_hop("a1", "at1", "c_left", s);
    add_pair_hop("a1", "at2", "c_right", s);
    add_pair_hop("c_left", "at1", "hub", s);
    add_pair_hop("c_right", "at2", "hub", s);
    add_pair_hop("hub", "at2", "kuzu", s);
    assert sorted(backward_c_reach("kuzu", 6, s)) == ["c_left", "c_right", "hub", "kuzu"];
}

test "unknown node tolerance" {
    s = fresh_graph_store();
    register_node("a0", KIND_A, "", s);
    caught = False;
    try { two_hop_targets("ghost", s); } except KeyError { caught = True; }
    assert caught;
    try { backward_c_reach("ghost", 3, s); } except KeyError { caught = True; }
    assert caught;
}

test "two hop and backward counts match explicit pattern" {
    s = fresh_graph_store();
    register_node("kuzu", KIND_C, "Kùzu", s);
    register_node("c1", KIND_C, "", s);
    register_node("a1", KIND_A, "", s);
    register_node("a2", KIND_A, "", s);
    register_node("at1", KIND_ATTR, "", s);
    register_node("at2", KIND_ATTR, "", s);
    register_node("at3", KIND_ATTR, "", s);
    add_pair_hop("c1", "at1", "kuzu", s);
    add_pair_hop("a1", "at2", "c1", s);
    add_pair_hop("a2", "at3", "c1", s);
    assert count_backward_c_reach("Kùzu", 6, s) == 2;
    assert count_two_hop_a_to_c(s) == 2;
    assert query_row_count("Kùzu", 6, s) == 2;
}

test "shared attribute two hop matches joined row count" {
    s = fresh_graph_store();
    register_node("kuzu", KIND_C, "Kùzu", s);
    register_node("c1", KIND_C, "", s);
    register_node("a1", KIND_A, "", s);
    register_node("at1", KIND_ATTR, "", s);
    add_pair_hop("c1", "at1", "kuzu", s);
    add_pair_hop("a1", "at1", "c1", s);
    explicit = count_two_hop_a_to_c(s);
    joined = query_row_count("Kùzu", 6, s);
    assert explicit == joined;
    assert explicit == 2;
}

test "depth cap limits backward reach" {
    s = fresh_graph_store();
    register_node("kuzu", KIND_C, "Kùzu", s);
    register_node("c1", KIND_C, "", s);
    register_node("c2", KIND_C, "", s);
    register_node("at1", KIND_ATTR, "", s);
    register_node("at2", KIND_ATTR, "", s);
    add_pair_hop("c2", "at2", "c1", s);
    add_pair_hop("c1", "at1", "kuzu", s);
    assert backward_c_reach("kuzu", 1, s) == ["kuzu"];
    assert backward_c_reach("kuzu", 3, s) == ["c1", "c2", "kuzu"];
}
