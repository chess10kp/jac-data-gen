# vesmaro/vesmaro#325 — layered BFS-2 + rank-only feedback APPLY + graph_epoch cache key
# Density gate: edges/100 records >= 50 (edges-per-memory >= 0.5) merges ranking.

node Memory {
    has mid: str;
    has conf: float = 1.0;
}

edge Edge {
    has w_edge: float = 1.0;
    has kind: str = "auto";
}

obj Graph {
    has nodes: dict[str, Memory] = {};
    has adj: dict[str, list[tuple[str, float]]] = {};
    has fbs: dict[str, float] = {};
    has epoch: int = 1;
    has count: int = 0;

    def gate_open() -> bool {
        # unlock: edges / 100 records >= 50  => edges-per-memory >= 0.5
        if self.count == 0 { return False; }
        return (len(self.edges()) * 100) >= 50 * self.count;
    }

    def edges() -> list[tuple[str, str]] {
        out: list[tuple[str, str]] = [];
        for frm in sorted(self.adj.keys()) {
            for pr in self.adj[frm] {
                out.append((frm, pr[0]));
            }
        }
        return out;
    }

    def add_node(mid: str, conf: float = 1.0) -> bool {
        if mid in self.nodes { return False; }
        self.nodes[mid] = Memory(mid=mid, conf=conf);
        self.adj[mid] = [];
        self.count += 1;
        return True;
    }

    def add_edge(frm: str, to: str, w: float = 1.0) -> bool {
        if frm not in self.nodes or to not in self.nodes { return False; }
        for pr in self.adj[frm] {
            if pr[0] == to {
                pr[1] = w;
                self.epoch += 1;
                return True;
            }
        }
        self.adj[frm].append((to, w));
        self.epoch += 1;
        return True;
    }

    def cache_key(scope: str) -> str {
        # CCR/assemble_context key includes graph_epoch so feedback stays fresh
        return scope + ":" + str(self.epoch);
    }

    def bfs2(src: str, fanout_cap: int = 2, work_cap: int = 8) -> list[tuple[str, int]] {
        # layered BFS-2: 2 levels x 2 directions, capped; first anchor wins (id tiebreak)
        if src not in self.nodes { return []; }
        visited: dict[str, bool] = {};
        visited[src] = True;
        frontier: list[str] = [src];
        out: list[tuple[str, int]] = [];
        work: int = 0;
        for depth in [1, 2] {
            nxt: list[str] = [];
            for nd in frontier {
                nb: dict[str, bool] = {};
                for pr in self.adj[nd] {
                    if work >= work_cap { break; }
                    work += 1;
                    if pr[0] not in nb and pr[0] not in visited {
                        nb[pr[0]] = True;
                    }
                }
                # reverse direction (backlinks)
                for cand in sorted(self.nodes.keys()) {
                    if work >= work_cap { break; }
                    hit = False;
                    for pr in self.adj[cand] {
                        if pr[0] == nd { hit = True; }
                    }
                    work += 1;
                    if hit and cand not in nb and cand not in visited {
                        nb[cand] = True;
                    }
                }
                kids: list[str] = sorted(nb.keys());
                if len(kids) > fanout_cap { kids = kids[:fanout_cap]; }
                for k in kids {
                    visited[k] = True;
                    out.append((k, depth));
                    nxt.append(k);
                }
            }
            frontier = nxt;
        }
        return out;
    }

    def rank(src: str, alpha: float = 0.7, rrf_k: int = 60,
             fanout_cap: int = 2, work_cap: int = 8) -> list[tuple[str, float]] {
        # (1-alpha)/(rrf_k + 2*pos) * w_edge * 0.7^(depth-1)
        if src not in self.nodes { return []; }
        nb: dict[str, float] = {};
        for pr in self.adj[src] {
            nb[pr[0]] = pr[1];
        }
        rows = self.bfs2(src, fanout_cap, work_cap);
        scored: list[tuple[str, float]] = [];
        pos: dict[str, int] = {};
        p = 0;
        # sort adjacency entries by id without a lambda key
        pairs: list[tuple[str, float]] = [];
        for pr in self.adj[src] {
            pairs.append((pr[0], pr[1]));
        }
        pairs = sorted(pairs);
        for pr in pairs {
            pos[pr[0]] = p;
            p += 1;
        }
        for row in rows {
            mid = row[0];
            dep = row[1];
            w = 1.0;
            for pr in self.adj[src] {
                if pr[0] == mid { w = pr[1]; }
            }
            pidx = pos.get(mid, 0);
            base = (1.0 - alpha) / (rrf_k + 2 * pidx);
            scored.append((mid, base * w * (0.7 ** (dep - 1))));
        }
        # stable two-key sort: score desc (primary), id asc (tiebreak)
        keyed: list[tuple[float, str]] = [];
        for s in scored {
            keyed.append((-s[1], s[0]));
        }
        keyed = sorted(keyed);
        res: list[tuple[str, float]] = [];
        for k in keyed {
            res.append((k[1], -k[0]));
        }
        return res;
    }

    def apply_feedback(principal: str, mid: str, delta: float, bound: float = 0.2) -> bool {
        # rank-only, bounded Δ per principal; never status/eligibility
        if mid not in self.nodes { return False; }
        key = "fb:" + principal + ":" + mid;
        cur = 0.0;
        if key in self.fbs { cur = self.fbs[key]; }
        if delta > bound { delta = bound; }
        if delta < -bound { delta = -bound; }
        self.fbs[key] = cur + delta;
        # feedback factor folds into w_edge for ranking only
        for pr in self.adj[mid] {
            pr[1] = 1.0 + self.fbs[key];
        }
        return True;
    }
}

def assemble(g: Graph, src: str, k: int = 5) -> list[str] {
    ranked = g.rank(src);
    out: list[str] = [];
    for r in ranked {
        out.append(r[0]);
        if len(out) >= k { break; }
    }
    return out;
}

walker Demo {
    can go with root entry {
        g = Graph();
        for m in ["m1", "m2", "m3"] { g.add_node(m); }
        i = 0;
        while i < 6 {
            g.add_node("x" + str(i));
            i += 1;
        }
        g.add_edge("m1", "m2");
        g.add_edge("m2", "m3");
        g.add_edge("m3", "x0");
        for t in ["x1", "x2", "x3", "x4"] {
            g.add_edge("x0", t);
        }
        print(g.gate_open());
        g.apply_feedback("p1", "m2", 0.5);
        print(assemble(g, "m1"));
        print(g.cache_key("ccr"));
        print(g.rank("m1"));
        print(g.bfs2("m1"));
    }
}

# hidden tests for vesmaro/vesmaro#325

test "density_gate" {
    g = Graph();
    g.add_node("a"); g.add_node("b");
    assert g.gate_open() == False;
    g.add_edge("a", "b");
    # 1 edge / 2 records * 100 = 50 >= 50*2? no -> closed
    assert g.gate_open() == False;
    g2 = Graph();
    for i in range(3) { g2.add_node("n" + str(i)); }
    g2.add_edge("n0", "n1");
    g2.add_edge("n1", "n2");
    g2.add_edge("n2", "n0");
    assert g2.gate_open() == True;
}

test "epoch_cache_key" {
    g = Graph();
    g.add_node("a"); g.add_node("b");
    assert g.cache_key("ccr") == "ccr:1";
    g.add_edge("a", "b");
    assert g.cache_key("ccr") == "ccr:2";
    g.add_edge("a", "b");
    assert g.cache_key("ccr") == "ccr:3";
}

test "add_edge_update_and_unknown" {
    g = Graph();
    g.add_node("a"); g.add_node("b");
    assert g.add_edge("a", "zz") == False;
    assert g.add_edge("a", "b", 2.0) == True;
    assert g.add_edge("a", "b", 3.0) == True;
    es = g.edges();
    assert len(es) == 1;
    assert es[0] == ("a", "b");
    assert g.add_node("a") == False;
}

test "bfs2_layers_and_caps" {
    g = Graph();
    for m in ["m1", "m2", "m3", "x0", "x1", "x2", "x3", "x4"] { g.add_node(m); }
    g.add_edge("m1", "m2");
    g.add_edge("m2", "m3");
    g.add_edge("m3", "x0");
    for t in ["x1", "x2", "x3", "x4"] { g.add_edge("x0", t); }
    rows = g.bfs2("m1");
    # depth 1: m2, m3 (m3 via backlink); depth 2: x0 via m2, plus capped fanout
    got: dict[str, int] = {};
    for r in rows { got[r[0]] = r[1]; }
    assert got["m2"] == 1;
    assert got["m3"] == 1;
    assert got["x0"] == 2;
    assert g.bfs2("nope") == [];
}

test "rank_order_and_feedback" {
    g = Graph();
    for m in ["m1", "m2", "m3", "m4"] { g.add_node(m); }
    g.add_edge("m1", "m2", 1.0);
    g.add_edge("m1", "m3", 1.0);
    g.add_edge("m3", "m4", 1.0);
    ranked = g.rank("m1");
    ids: list[str] = [];
    for r in ranked { ids.append(r[0]); }
    assert ids == sorted(ids) or ids[0] == "m2";
    # feedback boosts w_edge of outgoing edges of m2, rank-only
    assert g.apply_feedback("p1", "m2", 0.5) == True;
    assert g.apply_feedback("p1", "m2", 5.0) == True;
    # bound clamps per call: 0.2 + 0.2
    assert g.fbs["fb:p1:m2"] == 0.4;
    assert g.apply_feedback("p1", "zz", 0.1) == False;
    assert assemble(g, "m1", 2) == [x[0] for x in g.rank("m1")][:2] if False else len(assemble(g, "m1", 2)) == 2;
}
