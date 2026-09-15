"""databricks-solutions/flowx#24 — ordered cross-pipeline deploy from control lineage."""

node Pipeline {
    has pid: str;
}

edge Calls {
    has activity_name: str;
    has wait_on_completion: bool = True;
}

walker TopoWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can post with Pipeline entry {
        if here.pid in self.claimed {
            skip;
        }
        self.claimed[here.pid] = True;
        kids: list[Pipeline] = [here ->:Calls:->][?:Pipeline];
        kid_pids: list[str] = [];
        for kid in kids {
            kid_pids.append(kid.pid);
        }
        kid_pids = sorted(kid_pids);
        kid_nodes: list[Pipeline] = [];
        for kp in kid_pids {
            for kid in kids {
                if kid.pid == kp {
                    kid_nodes.append(kid);
                }
            }
        }
        visit kid_nodes;
        self.order.append(here.pid);
        topo_msg: str = "topo " + here.pid;
        print(topo_msg);
    }
}

walker DemoWalker {
    can boot with Pipeline entry {
        demo_msg: str = "flowx24 " + here.pid;
        print(demo_msg);
        disengage;
    }
}

def build_lineage(
    pipelines: list[str], edge_records: list[dict]
) -> dict[str, Pipeline] {
    pid_to_node: dict[str, Pipeline] = {};
    for pid in pipelines {
        nd = Pipeline(pid=pid);
        pid_to_node[pid] = nd;
    }
    for rec in edge_records {
        caller: str = rec["caller_pipeline"];
        callee: str = rec["callee_pipeline"];
        if caller in pid_to_node and callee in pid_to_node {
            cnd = pid_to_node[caller];
            ked = pid_to_node[callee];
            act: str = rec["activity_name"];
            woc: bool = True;
            if "wait_on_completion" in rec {
                woc = rec["wait_on_completion"];
            }
            cnd +>:Calls(activity_name=act, wait_on_completion=woc):+> ked;
        }
    }
    return pid_to_node;
}

def deploy_order(pipelines: list[str], edge_records: list[dict]) -> list[str] {
    pid_to_node: dict[str, Pipeline] = build_lineage(pipelines, edge_records);
    claimed: dict[str, bool] = {};
    order: list[str] = [];
    sorted_pids: list[str] = sorted(pipelines);
    for pid in sorted_pids {
        if pid in pid_to_node {
            pid_to_node[pid] spawn TopoWalker(claimed=claimed, order=order);
        }
    }
    result: list[str] = [];
    seen: dict[str, bool] = {};
    for pid in order {
        if pid in pid_to_node and pid not in seen {
            seen[pid] = True;
            result.append(pid);
        }
    }
    for pid in sorted_pids {
        if pid not in seen {
            result.append(pid);
        }
    }
    return result;
}

def orchestration_depends_on(
    pipelines: list[str], edge_records: list[dict]
) -> dict[str, list[str]] {
    store: dict[str, list[str]] = {};
    for pid in pipelines {
        store[pid] = [];
    }
    for rec in edge_records {
        caller: str = rec["caller_pipeline"];
        callee: str = rec["callee_pipeline"];
        woc: bool = True;
        if "wait_on_completion" in rec {
            woc = rec["wait_on_completion"];
        }
        if woc and caller in store and callee in store {
            store[caller].append(callee);
        }
    }
    for pid in pipelines {
        store[pid] = sorted(store[pid]);
    }
    return store;
}

def unknown_pipeline_ids(
    pipelines: list[str], edge_records: list[dict]
) -> list[str] {
    known: dict[str, bool] = {};
    for pid in pipelines {
        known[pid] = True;
    }
    unk: list[str] = [];
    seen_unk: dict[str, bool] = {};
    for rec in edge_records {
        caller: str = rec["caller_pipeline"];
        callee: str = rec["callee_pipeline"];
        if caller not in known and caller not in seen_unk {
            seen_unk[caller] = True;
            unk.append(caller);
        }
        if callee not in known and callee not in seen_unk {
            seen_unk[callee] = True;
            unk.append(callee);
        }
    }
    return sorted(unk);
}

with entry {
    seed = Pipeline(pid="__demo__");
    root ++> seed;
    seed spawn DemoWalker;
}

test "deploy_linear" {
    pids: list[str] = ["a", "b", "c"];
    e0: dict = {};
    e0["caller_pipeline"] = "a";
    e0["callee_pipeline"] = "b";
    e0["activity_name"] = "call_b";
    e1: dict = {};
    e1["caller_pipeline"] = "b";
    e1["callee_pipeline"] = "c";
    e1["activity_name"] = "call_c";
    edges: list[dict] = [];
    edges.append(e0);
    edges.append(e1);
    got: list[str] = deploy_order(pids, edges);
    assert (got == ["c", "b", "a"]);
}

test "depends_wait" {
    pids: list[str] = ["p1", "p2"];
    e0: dict = {};
    e0["caller_pipeline"] = "p1";
    e0["callee_pipeline"] = "p2";
    e0["activity_name"] = "x";
    e0["wait_on_completion"] = True;
    edges: list[dict] = [];
    edges.append(e0);
    got: dict[str, list[str]] = orchestration_depends_on(pids, edges);
    assert (got["p1"] == ["p2"]);
    assert (got["p2"] == []);
}

test "unknown_sorted" {
    pids: list[str] = ["known"];
    e0: dict = {};
    e0["caller_pipeline"] = "ghost";
    e0["callee_pipeline"] = "known";
    e0["activity_name"] = "x";
    edges: list[dict] = [];
    edges.append(e0);
    got: list[str] = unknown_pipeline_ids(pids, edges);
    assert (got == ["ghost"]);
}

test "cycle_deploy_all" {
    pids: list[str] = ["a", "b"];
    e0: dict = {};
    e0["caller_pipeline"] = "a";
    e0["callee_pipeline"] = "b";
    e0["activity_name"] = "x";
    e1: dict = {};
    e1["caller_pipeline"] = "b";
    e1["callee_pipeline"] = "a";
    e1["activity_name"] = "y";
    edges: list[dict] = [];
    edges.append(e0);
    edges.append(e1);
    got: list[str] = deploy_order(pids, edges);
    got_s: list[str] = sorted(got);
    assert (got_s == ["a", "b"]);
    assert (len(got) == 2);
}

test "skip_nowait_edge" {
    pids: list[str] = ["a", "b"];
    e0: dict = {};
    e0["caller_pipeline"] = "a";
    e0["callee_pipeline"] = "b";
    e0["activity_name"] = "x";
    e0["wait_on_completion"] = False;
    edges: list[dict] = [];
    edges.append(e0);
    got: dict[str, list[str]] = orchestration_depends_on(pids, edges);
    assert (got["a"] == []);
}

test "disconnected_sorted_tail" {
    pids: list[str] = ["z", "a"];
    edges: list[dict] = [];
    got: list[str] = deploy_order(pids, edges);
    assert (got == ["a", "z"]);
}
