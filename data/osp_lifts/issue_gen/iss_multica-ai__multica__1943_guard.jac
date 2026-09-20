"""Workflow orchestration graph engine — multica-ai/multica#1943."""

node WfNode {
    has cid: str;
    has kind: str;
    has agent: str = "";
}

edge WfNext {}

obj WorkflowEngine {
    has nodes: dict[str, WfNode] = {};
    has anchor: WfNode;
}

walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with WfNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print {"reach", here.cid};
        kids: list[WfNode] = [];
        for ch in [here ->:WfNext:->][?:WfNode] {
            kids.append(ch);
        }
        if kids {
            visit kids;
        } else {
            disengage;
        }
    }
}

walker BootWalker {
    can run entry {
        print {"workflow", "engine", "ready"};
        disengage;
    }
}

def create_engine -> WorkflowEngine {
    eng = WorkflowEngine();
    anchor = WfNode(cid="__wf_root__", kind="root", agent="");
    root ++> anchor;
    eng.anchor = anchor;
    return eng;
}

def add_node(eng: WorkflowEngine, node_id: str, kind: str, agent: str = "") -> bool {
    if node_id in eng.nodes {
        return False;
    }
    nd = WfNode(cid=node_id, kind=kind, agent=agent);
    eng.nodes[node_id] = nd;
    eng.anchor +>:WfNext:+> nd;
    return True;
}

def connect(eng: WorkflowEngine, src_id: str, dst_id: str) -> bool {
    if src_id not in eng.nodes or dst_id not in eng.nodes {
        return False;
    }
    src = eng.nodes[src_id];
    dst = eng.nodes[dst_id];
    for t in [src ->:WfNext:->][?:WfNode] {
        if t.cid == dst.cid {
            return True;
        }
    }
    src +>:WfNext:+> dst;
    return True;
}

def reachable_ids(eng: WorkflowEngine, start_id: str) -> list[str] {
    if start_id not in eng.nodes {
        return [];
    }
    start = eng.nodes[start_id];
    claimed: dict[str, bool] = {};
    w = start spawn ReachWalker(claimed=claimed);
    return sorted(w.found);
}

def topo_order(eng: WorkflowEngine) -> list[str] {
    indeg: dict[str, int] = {};
    for nid in eng.nodes {
        indeg[nid] = 0;
    }
    for nid in eng.nodes {
        nd = eng.nodes[nid];
        for t in [nd ->:WfNext:->][?:WfNode] {
            if t.cid in eng.nodes {
                indeg[t.cid] += 1;
            }
        }
    }
    queue: list[str] = [];
    for nid in eng.nodes {
        if indeg[nid] == 0 {
            queue.append(nid);
        }
    }
    queue.sort();
    out: list[str] = [];
    while queue {
        cur = queue[0];
        queue = queue[1:];
        out.append(cur);
        nd = eng.nodes[cur];
        for t in [nd ->:WfNext:->][?:WfNode] {
            if t.cid in eng.nodes {
                indeg[t.cid] -= 1;
                if indeg[t.cid] == 0 {
                    queue.append(t.cid);
                    queue.sort();
                }
            }
        }
    }
    if len(out) != len(eng.nodes) {
        return [];
    }
    return out;
}

def remove_node(eng: WorkflowEngine, node_id: str) -> bool {
    if node_id not in eng.nodes {
        return False;
    }
    victim = eng.nodes[node_id];
    src_ids: list[str] = [];
    for sid in eng.nodes {
        src_ids.append(sid);
    }
    for sid in src_ids {
        src = eng.nodes[sid];
        drop: list[WfNode] = [];
        for t in [src ->:WfNext:->][?:WfNode] {
            if t.cid == node_id {
                drop.append(t);
            }
        }
        for t in drop {
            src del_edge(:WfNext:, t);
        }
    }
    out_drop: list[WfNode] = [];
    for t in [victim ->:WfNext:->][?:WfNode] {
        out_drop.append(t);
    }
    for t in out_drop {
        victim del_edge(:WfNext:, t);
    }
    eng.anchor del_edge(:WfNext:, victim);
    del eng.nodes[node_id];
    return True;
}

with entry {
    root spawn BootWalker();
}

test "reachable_sorted_linear" {
    e = create_engine();
    add_node(e, "pm", "task", "pm-agent");
    add_node(e, "code", "task", "code-agent");
    add_node(e, "review", "gateway", "review-agent");
    connect(e, "pm", "code");
    connect(e, "code", "review");
    assert (reachable_ids(e, "pm") == ["code", "pm", "review"]);;
}

test "diamond_revisit_adversarial" {
    e = create_engine();
    add_node(e, "a", "task", "");
    add_node(e, "b", "task", "");
    add_node(e, "c", "task", "");
    add_node(e, "d", "task", "");
    connect(e, "a", "b");
    connect(e, "a", "c");
    connect(e, "b", "d");
    connect(e, "c", "d");
    connect(e, "d", "b");
    assert (reachable_ids(e, "a") == ["a", "b", "c", "d"]);;
}

test "unknown_id_tolerance" {
    e = create_engine();
    add_node(e, "pm", "task", "");
    assert (connect(e, "pm", "missing") == False);;
    assert (connect(e, "missing", "pm") == False);;
    assert (reachable_ids(e, "ghost") == []);;
    assert (remove_node(e, "ghost") == False);;
}

test "topo_valid_dag" {
    e = create_engine();
    add_node(e, "pm", "task", "");
    add_node(e, "research", "task", "");
    add_node(e, "code", "task", "");
    add_node(e, "qa", "task", "");
    connect(e, "pm", "research");
    connect(e, "pm", "code");
    connect(e, "research", "code");
    connect(e, "code", "qa");
    assert (topo_order(e) == ["code", "pm", "qa", "research"]);;
}

test "topo_cycle_returns_empty" {
    e = create_engine();
    add_node(e, "code", "task", "");
    add_node(e, "review", "gateway", "");
    connect(e, "code", "review");
    connect(e, "review", "code");
    assert (topo_order(e) == []);;
}

test "remove_node_disconnects" {
    e = create_engine();
    add_node(e, "pm", "task", "");
    add_node(e, "code", "task", "");
    add_node(e, "qa", "task", "");
    connect(e, "pm", "code");
    connect(e, "code", "qa");
    assert (remove_node(e, "code") == True);;
    assert (reachable_ids(e, "pm") == ["pm"]);;
    assert (topo_order(e) == ["pm", "qa"]);;
}
