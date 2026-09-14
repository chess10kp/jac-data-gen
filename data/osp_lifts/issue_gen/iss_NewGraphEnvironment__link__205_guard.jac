node Environment {}
node WSG {
    has wsg_id: str;
    has streams_rows: int = 0;
    has habitat_rows: int = 0;
    has accessible: bool = True;
    has mapping_code: str = "1:1";
}
node Barrier {
    has barrier_id: str;
    has blocking: bool = True;
}
edge CONTAINS {}
edge DOWNSTREAM {}
edge HAS_BARRIER {}

walker AccessScan {
    has target_id: str;
    has blocked: bool = False;
    has claimed: dict[str, bool] = {};

    can begin with Environment entry {
        print("access scan " + self.target_id);
        for candidate in [here ->:CONTAINS:->][?:WSG] {
            if candidate.wsg_id == self.target_id {
                visit :0: [candidate];
            }
        }
    }

    can inspect_wsg with WSG entry {
        if here.wsg_id in self.claimed {
            skip;
        }
        self.claimed[here.wsg_id] = True;
        for barrier in [here ->:HAS_BARRIER:->][?:Barrier] {
            visit :0: [barrier];
        }
        for child in [here ->:DOWNSTREAM:->][?:WSG] {
            visit :0: [child];
        }
    }

    can inspect_barrier with Barrier entry {
        print("barrier " + here.barrier_id);
        if here.blocking {
            self.blocked = True;
        }
    }
}

def new_environment() -> Environment {
    return Environment();
}

def add_wsg(
    env: Environment,
    wsg_id: str,
    streams_rows: int = 0,
    habitat_rows: int = 0
) -> WSG {
    wsg = WSG(
        wsg_id=wsg_id,
        streams_rows=streams_rows,
        habitat_rows=habitat_rows
    );
    env +>:CONTAINS:+> wsg;
    return wsg;
}

def add_barrier(wsg: WSG, barrier_id: str, blocking: bool = True) -> Barrier {
    barrier = Barrier(barrier_id=barrier_id, blocking=blocking);
    wsg +>:HAS_BARRIER:+> barrier;
    return barrier;
}

def find_wsg(env: Environment, wsg_id: str) -> WSG | None {
    for wsg in [env ->:CONTAINS:->][?:WSG] {
        if wsg.wsg_id == wsg_id {
            return wsg;
        }
    }
    return None;
}

def connect_downstream_by_id(
    env: Environment,
    upstream_id: str,
    downstream_id: str
) -> bool {
    upstream: WSG | None = find_wsg(env, upstream_id);
    downstream: WSG | None = find_wsg(env, downstream_id);
    if upstream is None {
        return False;
    }
    if downstream is None {
        return False;
    }
    upstream +>:DOWNSTREAM:+> downstream;
    return True;
}

def recompute_access(env: Environment) -> dict[str, bool] {
    result: dict[str, bool] = {};
    for wsg in [env ->:CONTAINS:->][?:WSG] {
        w = env spawn AccessScan(
            target_id=wsg.wsg_id,
            blocked=False,
            claimed={}
        );
        wsg.accessible = not w.blocked;
        result[wsg.wsg_id] = wsg.accessible;
    }
    return result;
}

def post_consolidate_recompute(env: Environment) -> dict[str, str] {
    recompute_access(env);
    result: dict[str, str] = {};
    for wsg in [env ->:CONTAINS:->][?:WSG] {
        if wsg.accessible {
            wsg.mapping_code = "1:1";
        } else {
            wsg.mapping_code = "0:0";
        }
        result[wsg.wsg_id] = wsg.mapping_code;
    }
    return result;
}

def recompute_mapping_code(env: Environment) -> dict[str, str] {
    return post_consolidate_recompute(env);
}

def mapping_code_for(env: Environment, wsg_id: str) -> str {
    for wsg in [env ->:CONTAINS:->][?:WSG] {
        if wsg.wsg_id == wsg_id {
            return wsg.mapping_code;
        }
    }
    return "";
}

test "diamond revisit keeps downstream barrier visible" {
    graph_root = new_environment();
    a = add_wsg(graph_root, "a");
    b = add_wsg(graph_root, "b");
    c = add_wsg(graph_root, "c");
    d = add_wsg(graph_root, "d");
    add_barrier(d, "d-block");
    assert (connect_downstream_by_id(graph_root, "a", "b"));
    assert (connect_downstream_by_id(graph_root, "a", "c"));
    assert (connect_downstream_by_id(graph_root, "b", "d"));
    assert (connect_downstream_by_id(graph_root, "c", "d"));
    codes = post_consolidate_recompute(graph_root);
    assert (codes["a"] == "0:0");
    assert (codes["b"] == "0:0");
    assert (codes["c"] == "0:0");
    assert (codes["d"] == "0:0");
}

test "unknown ids are tolerated" {
    graph_root = new_environment();
    add_wsg(graph_root, "known");
    assert (connect_downstream_by_id(graph_root, "missing", "known") == False);
    assert (connect_downstream_by_id(graph_root, "known", "missing") == False);
    assert (mapping_code_for(graph_root, "missing") == "");
}

test "open barriers do not block access" {
    graph_root = new_environment();
    solo = add_wsg(graph_root, "solo");
    add_barrier(solo, "observation-only", False);
    access = recompute_access(graph_root);
    assert (access["solo"] == True);
    assert (recompute_mapping_code(graph_root)["solo"] == "1:1");
}

test "cross-wsg barrier changes mapping after consolidation" {
    graph_root = new_environment();
    upstream = add_wsg(graph_root, "upstream", 12, 7);
    downstream = add_wsg(graph_root, "downstream", 8, 4);
    assert (connect_downstream_by_id(graph_root, "upstream", "downstream"));
    add_barrier(downstream, "provincial-block");
    codes = post_consolidate_recompute(graph_root);
    assert (upstream.accessible == False);
    assert (downstream.accessible == False);
    assert (codes["upstream"] == "0:0");
    assert (codes["downstream"] == "0:0");
}
