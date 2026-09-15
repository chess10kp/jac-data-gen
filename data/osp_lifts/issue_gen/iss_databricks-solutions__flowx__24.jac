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
