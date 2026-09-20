"""SFC macro flow graph policy metrics — DyadLang/DyadIssues#21."""

node Sector {
    has sid: str;
}

edge Flow {
    has weight: float = 1.0;
}

walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has origin: str = "";
    has reached: list[str] = [];

    can step with Sector entry {
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        if here.sid != self.origin {
            self.reached.append(here.sid);
        }
        print("reach", here.sid);
        kids: list[Sector] = [here ->:Flow:->][?:Sector];
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker LagWalker {
    has claimed: dict[str, bool] = {};
    has origin: str = "";
    has cur_depth: int = 0;
    has depth_sum: int = 0;
    has node_count: int = 0;

    can measure with Sector entry {
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        my_depth: int = self.cur_depth;
        if here.sid != self.origin {
            self.depth_sum += my_depth;
            self.node_count += 1;
        }
        print("lag", here.sid, my_depth);
        kids: list[Sector] = [here ->:Flow:->][?:Sector];
        if kids {
            self.cur_depth = my_depth + 1;
            visit :0: kids;
            self.cur_depth = my_depth;
        } else {
            disengage;
        }
    }
}

def build_flow_graph(sector_ids: list[str], flows: list) -> dict[str, object] {
    sectors: dict[str, Sector] = {};
    weights: dict[str, float] = {};
    anchor = Sector(sid="__anchor__");
    root ++> anchor;
    for sid in sector_ids {
        nd = Sector(sid=sid);
        sectors[sid] = nd;
        anchor ++> nd;
    }
    for fl in flows {
        src_id = fl[0];
        tgt_id = fl[1];
        w: float = 1.0;
        if len(fl) > 2 {
            w = fl[2];
        }
        if src_id not in sectors {
            continue;
        }
        if tgt_id not in sectors {
            continue;
        }
        src_nd = sectors[src_id] as Sector;
        tgt_nd = sectors[tgt_id] as Sector;
        src_nd +>:Flow(weight=w):+> tgt_nd;
        key = src_id + "|" + tgt_id;
        weights[key] = w;
    }
    out: dict[str, object] = {};
    out["anchor"] = anchor;
    out["sectors"] = sectors;
    out["weights"] = weights;
    return out;
}

def direct_flow(graph: dict[str, object], source_id: str, target_id: str) -> float {
    sectors = graph["sectors"] as dict[str, Sector];
    weights = graph["weights"] as dict[str, float];
    if source_id not in sectors {
        return 0.0;
    }
    if target_id not in sectors {
        return 0.0;
    }
    key = source_id + "|" + target_id;
    if key not in weights {
        return 0.0;
    }
    return weights[key];
}

def policy_reach(graph: dict[str, object], source_id: str) -> list[str] {
    sectors = graph["sectors"] as dict[str, Sector];
    if source_id not in sectors {
        return [];
    }
    src = sectors[source_id] as Sector;
    claimed: dict[str, bool] = {};
    w = src spawn ReachWalker(claimed=claimed, origin=source_id);
    return sorted(w.reached);
}

def policy_multiplier(graph: dict[str, object], source_id: str, target_id: str) -> float {
    d = direct_flow(graph, source_id, target_id);
    if d == 0.0 {
        return 0.0;
    }
    reach = policy_reach(graph, source_id);
    total: float = d;
    for sid in reach {
        v = direct_flow(graph, sid, target_id);
        total += v;
    }
    return total / d;
}

def transmission_lag(graph: dict[str, object], source_id: str) -> float {
    sectors = graph["sectors"] as dict[str, Sector];
    if source_id not in sectors {
        return 0.0;
    }
    src = sectors[source_id] as Sector;
    claimed: dict[str, bool] = {};
    w = src spawn LagWalker(claimed=claimed, origin=source_id, cur_depth=0);
    if w.node_count == 0 {
        return 0.0;
    }
    return w.depth_sum / w.node_count;
}

test "direct_flow_unknown" {
    flows: list = [];
    flows.append(["A", "B", 1.0]);
    g = build_flow_graph(["A"], flows);
    assert direct_flow(g, "X", "A") == 0.0;
    assert direct_flow(g, "A", "Y") == 0.0;
}

test "policy_reach_linear" {
    flows: list = [];
    flows.append(["A", "B"]);
    flows.append(["B", "C"]);
    g = build_flow_graph(["A", "B", "C"], flows);
    assert policy_reach(g, "A") == ["B", "C"];
}

test "policy_reach_cycle" {
    flows: list = [];
    flows.append(["A", "B"]);
    flows.append(["B", "A"]);
    g = build_flow_graph(["A", "B"], flows);
    assert policy_reach(g, "A") == ["B"];
}

test "policy_multiplier_diamond" {
    flows: list = [];
    flows.append(["A", "C", 2.0]);
    flows.append(["A", "B", 1.0]);
    flows.append(["B", "C", 3.0]);
    g = build_flow_graph(["A", "B", "C"], flows);
    assert policy_multiplier(g, "A", "C") == 2.5;
}

test "transmission_lag_linear" {
    flows: list = [];
    flows.append(["A", "B"]);
    flows.append(["B", "C"]);
    g = build_flow_graph(["A", "B", "C"], flows);
    assert transmission_lag(g, "A") == 1.5;
}

test "missing_source" {
    g = build_flow_graph(["A"], []);
    assert policy_reach(g, "Z") == [];
    assert transmission_lag(g, "Z") == 0.0;
    assert policy_multiplier(g, "A", "Z") == 0.0;
}
