"""byzatic/Tessera-DFE#6 multi-root intersecting DAG configuration."""

node DagNode {
    has nid: str;
}

edge Dep {}

walker CycleCheck {
    has claimed: dict[str, bool] = {};
    has on_stack: dict[str, bool] = {};
    has cyclic: bool = False;

    can probe with DagNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.on_stack[here.nid] = True;
        kids: list[DagNode] = [here ->:Dep:->][?:DagNode];
        for ch in kids {
            if ch.nid in self.on_stack {
                self.cyclic = True;
            } else {
                visit ch;
            }
        }
        self.on_stack[here.nid] = False;
        print("cycle_probe", here.nid, self.cyclic);
    }
}

walker TopoCollect {
    has claimed: dict[str, bool] = {};
    has post: list[str] = [];

    can collect with DagNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        kids: list[DagNode] = [here ->:Dep:->][?:DagNode];
        kid_nids: list[str] = [];
        for k in kids { kid_nids.append(k.nid); }
        kid_nids = sorted(kid_nids);
        ordered_kids: list[DagNode] = [];
        for kn in kid_nids {
            for k in kids {
                if k.nid == kn { ordered_kids.append(k); }
            }
        }
        for ch in ordered_kids { visit ch; }
        self.post.append(here.nid);
        print("topo_post", here.nid);
    }
}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can walk with DagNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.reached.append(here.nid);
        kids: list[DagNode] = [here ->:Dep:->][?:DagNode];
        visit kids else { disengage; }
        print("reach", here.nid);
    }
}

def materialize_graph(node_ids: list[str], edges: list[list[str]]) -> dict[str, DagNode] {
    store: dict[str, DagNode] = {};
    for nid in node_ids {
        nd = DagNode(nid=nid);
        root ++> nd;
        store[nid] = nd;
    }
    for e in edges {
        if len(e) < 2 { continue; }
        src_id = e[0];
        dst_id = e[1];
        if src_id not in store { continue; }
        if dst_id not in store { continue; }
        src_nd = store[src_id] as DagNode;
        dst_nd = store[dst_id] as DagNode;
        src_nd +>: Dep:+> dst_nd;
    }
    return store;
}

def has_cycle(node_ids: list[str], edges: list[list[str]]) -> bool {
    store = materialize_graph(node_ids, edges);
    for nid in node_ids {
        nd = store[nid] as DagNode;
        w = nd spawn CycleCheck(claimed={}, on_stack={}, cyclic=False);
        if w.cyclic { return True; }
    }
    return False;
}

def validate_dag(node_ids: list[str], edges: list[list[str]], roots: list[str]) -> bool {
    if has_cycle(node_ids, edges) { return False; }
    store = materialize_graph(node_ids, edges);
    for rid in roots {
        if rid not in store { return False; }
    }
    return True;
}

def execution_order(node_ids: list[str], edges: list[list[str]], roots: list[str]) -> list[str] {
    if has_cycle(node_ids, edges) { return []; }
    store = materialize_graph(node_ids, edges);
    starts: list[str] = [];
    for rid in roots {
        if rid in store { starts.append(rid); }
    }
    for nid in sorted(node_ids) {
        present = False;
        for s in starts {
            if s == nid { present = True; }
        }
        if not present { starts.append(nid); }
    }
    run_claimed: dict[str, bool] = {};
    merged_post: list[str] = [];
    for sid in starts {
        nd = store[sid] as DagNode;
        w = nd spawn TopoCollect(claimed=run_claimed, post=[]);
        run_claimed = w.claimed;
        for p in w.post {
            dup = False;
            for m in merged_post {
                if m == p { dup = True; }
            }
            if not dup { merged_post.append(p); }
        }
    }
    rev: list[str] = [];
    idx = len(merged_post) - 1;
    while idx >= 0 {
        rev.append(merged_post[idx]);
        idx -= 1;
    }
    return rev;
}

def reachable_nodes(node_ids: list[str], edges: list[list[str]], roots: list[str]) -> list[str] {
    store = materialize_graph(node_ids, edges);
    merged: list[str] = [];
    seen: dict[str, bool] = {};
    for rid in roots {
        if rid not in store { continue; }
        nd = store[rid] as DagNode;
        w = nd spawn ReachWalk(claimed={}, reached=[]);
        for x in w.reached {
            if x not in seen {
                seen[x] = True;
                merged.append(x);
            }
        }
    }
    return sorted(merged);
}

test "no_cycle_linear" {
    nodes: list[str] = ["a", "b", "c"];
    edges: list[list[str]] = [["a", "b"], ["b", "c"]];
    assert (not has_cycle(nodes, edges));
}

test "cycle_detected" {
    nodes: list[str] = ["a", "b", "c"];
    edges: list[list[str]] = [["a", "b"], ["b", "c"], ["c", "a"]];
    assert (has_cycle(nodes, edges));
}

test "validate_dag_ok" {
    nodes: list[str] = ["a", "b", "c"];
    edges: list[list[str]] = [["a", "b"], ["b", "c"]];
    roots: list[str] = ["a"];
    assert (validate_dag(nodes, edges, roots));
}

test "converging_dag_topo_deterministic" {
    nodes: list[str] = ["a", "b", "c", "d"];
    edges: list[list[str]] = [["a", "c"], ["b", "c"], ["c", "d"]];
    roots: list[str] = ["a", "b"];
    order = execution_order(nodes, edges, roots);
    assert (order == ["b", "a", "c", "d"]);
}

test "execution_order_cycle_empty" {
    nodes: list[str] = ["a", "b", "c"];
    edges: list[list[str]] = [["a", "b"], ["b", "c"], ["c", "a"]];
    roots: list[str] = ["a"];
    order = execution_order(nodes, edges, roots);
    assert (order == []);
}

test "reachable_multi_root_sorted" {
    nodes: list[str] = ["a", "b", "c", "d"];
    edges: list[list[str]] = [["a", "c"], ["b", "c"], ["c", "d"]];
    roots: list[str] = ["a"];
    reached = reachable_nodes(nodes, edges, roots);
    assert (reached == ["a", "c", "d"]);
}
