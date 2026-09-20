"""vesmaro/vesmaro#325 — layered BFS-2, rank-only feedback APPLY, graph_epoch cache key."""

node GraphRoot {
    has record_count: int = 100;
    has graph_epoch: int = 0;
    has edge_count: int = 0;
}

node Memory {
    has mid: str;
    has pipeline_confidence: float = 1.0;
}

edge Link {
    has weight: float = 1.0;
}

walker Bfs2Walker {
    has claimed: dict[str, bool] = {};
    has anchor_of: dict[str, str] = {};
    has node_depth: dict[str, int] = {};
    has nodes: dict[str, Memory] = {};
    has sorted_anchors: list[str] = [];
    has bootstrapped: bool = False;
    has fanout_cap: int = 2;
    has work_cap: int = 32;
    has work_used: int = 0;
    has depth_limit: int = 2;

    can walk with Memory entry {
        if not self.bootstrapped {
            self.bootstrapped = True;
            for aid in self.sorted_anchors {
                if aid in self.nodes {
                    if aid not in self.anchor_of {
                        self.anchor_of[aid] = aid;
                    }
                    if aid not in self.node_depth {
                        self.node_depth[aid] = 0;
                    }
                    if aid != here.mid {
                        seed = self.nodes[aid];
                        visit seed;
                    }
                }
            }
        }
        mid = here.mid;
        if mid in self.claimed {
            skip;
        }
        if self.work_used >= self.work_cap {
            disengage;
        }
        self.claimed[mid] = True;
        self.work_used = self.work_used + 1;
        d: int = 0;
        if mid in self.node_depth {
            d = self.node_depth[mid];
        }
        print("bfs2", mid, d);
        if d >= self.depth_limit {
            disengage;
        }
        kids: list[Memory] = [];
        fwd: list[Memory] = [here ->:Link:->][?:Memory];
        rev: list[Memory] = [here <-:Link:-<][?:Memory];
        for ch in fwd {
            kids.append(ch);
        }
        for ch in rev {
            kids.append(ch);
        }
        taken: int = 0;
        for ch in kids {
            if taken >= self.fanout_cap {
                break;
            }
            cmid = ch.mid;
            if cmid not in self.anchor_of {
                if mid in self.anchor_of {
                    self.anchor_of[cmid] = self.anchor_of[mid];
                } else {
                    self.anchor_of[cmid] = mid;
                }
            }
            nd: int = d + 1;
            if cmid not in self.node_depth {
                self.node_depth[cmid] = nd;
            }
            if cmid not in self.claimed {
                visit ch;
            }
            taken = taken + 1;
        }
    }
}

def density_gate_open(edge_count: int, record_count: int) -> bool {
    if record_count <= 0 {
        return False;
    }
    scaled: int = (edge_count * 100) // record_count;
    return scaled >= 50;
}

def bump_graph_epoch(epoch: int) -> int {
    return epoch + 1;
}

def record_edge_write(g: GraphRoot) -> int {
    g.edge_count = g.edge_count + 1;
    g.graph_epoch = bump_graph_epoch(g.graph_epoch);
    return g.graph_epoch;
}

def assemble_cache_key(graph_epoch: int, principal_id: str, query_id: str) -> str {
    return str(graph_epoch) + ":" + principal_id + ":" + query_id;
}

def rank_score(alpha: float, rrf_k: float, pos: int, w_edge: float, depth: int) -> float {
    num: float = 1.0 - alpha;
    denom: float = rrf_k + (2.0 * pos);
    base: float = num / denom;
    factor: float = 1.0;
    steps: int = depth - 1;
    i: int = 0;
    while i < steps {
        factor = factor * 0.7;
        i = i + 1;
    }
    return base * w_edge * factor;
}

def effective_weight(pipeline_confidence: float, feedback_factor: float) -> float {
    return pipeline_confidence * feedback_factor;
}

def apply_feedback_rank_only(
    ranks: dict[str, float],
    deltas: dict[str, float],
    max_delta: float
) -> dict[str, float] {
    out: dict[str, float] = {};
    for pid in ranks {
        base = ranks[pid];
        delta: float = 0.0;
        if pid in deltas {
            raw = deltas[pid];
            if raw > max_delta {
                delta = max_delta;
            } else if raw < -max_delta {
                delta = -max_delta;
            } else {
                delta = raw;
            }
        }
        out[pid] = base + delta;
    }
    return out;
}

def connect_memory(a: Memory, b: Memory, w: float, g: GraphRoot) {
    a +>:Link(weight=w):+> b;
    b +>:Link(weight=w):+> a;
    record_edge_write(g);
    record_edge_write(g);
}

def layered_bfs2_anchor_map(
    nodes: dict[str, Memory],
    anchors: list[str],
    fanout_cap: int,
    work_cap: int
) -> dict[str, str] {
    sorted_anchors: list[str] = sorted(anchors);
    if len(sorted_anchors) == 0 {
        empty: dict[str, str] = {};
        return empty;
    }
    first_id = sorted_anchors[0];
    if first_id not in nodes {
        empty2: dict[str, str] = {};
        return empty2;
    }
    first_nd = nodes[first_id];
    wk = first_nd spawn Bfs2Walker(
        nodes=nodes,
        sorted_anchors=sorted_anchors,
        fanout_cap=fanout_cap,
        work_cap=work_cap,
        depth_limit=2
    );
    return wk.anchor_of;
}

test "density_gate_open_threshold" {
    assert density_gate_open(50, 100) == True;
    assert density_gate_open(49, 100) == False;
    assert density_gate_open(10, 0) == False;
}

test "apply_feedback_rank_only_clamps" {
    ranks: dict[str, float] = {"a": 1.0, "b": 2.0, "c": 3.0};
    deltas: dict[str, float] = {"a": 5.0, "b": -5.0, "c": 0.5};
    out = apply_feedback_rank_only(ranks, deltas, 2.0);
    assert out["a"] == 3.0;
    assert out["b"] == 0.0;
    assert out["c"] == 3.5;
}

test "assemble_cache_key_and_epoch_bump" {
    g = GraphRoot(record_count=100);
    root ++> g;
    assert assemble_cache_key(0, "principal", "query") == "0:principal:query";
    assert record_edge_write(g) == 1;
    assert g.graph_epoch == 1;
    assert g.edge_count == 1;
}

test "rank_score_depth_decay" {
    s = rank_score(0.5, 60.0, 1, 1.0, 2);
    expected: float = (0.5 / 62.0) * 1.0 * 0.7;
    assert s == expected;
}

test "connect_memory_bumps_epoch_twice" {
    g = GraphRoot(record_count=100);
    a = Memory(mid="x");
    b = Memory(mid="y");
    root ++> g;
    root ++> a;
    root ++> b;
    connect_memory(a, b, 0.8, g);
    assert g.edge_count == 2;
    assert g.graph_epoch == 2;
}

test "layered_bfs2_anchor_map_sorted_anchors" {
    g = GraphRoot(record_count=100);
    m1 = Memory(mid="a");
    m2 = Memory(mid="b");
    m3 = Memory(mid="c");
    root ++> g;
    root ++> m1;
    root ++> m2;
    root ++> m3;
    connect_memory(m1, m2, 1.0, g);
    connect_memory(m2, m3, 1.0, g);
    nodes: dict[str, Memory] = {"a": m1, "b": m2, "c": m3};
    am = layered_bfs2_anchor_map(nodes, ["c", "a"], 2, 32);
    assert am["a"] == "a";
    assert am["b"] == "a";
    assert am["c"] == "c";
}
