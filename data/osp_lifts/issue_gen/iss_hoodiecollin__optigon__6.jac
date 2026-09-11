"""hoodiecollin/optigon#6 — shortest path with applicability-masked impl selection."""

glob IMPL_BFS = "bfs";
glob IMPL_DIJKSTRA = "dijkstra";
glob IMPL_BELLMAN = "bellman_ford";

node SpNode {
    has nid: str;
}

edge SpEdge {
    has weight: int = 1;
}

walker SpReachWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with SpNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.order.append(here.nid);
        kids = _sorted_out(here);
        i = len(kids) - 1;
        while i >= 0 { visit :0: [kids[i]]; i -= 1; }
    }
}

def _sorted_out(nd: SpNode) -> list[SpNode] {
    kids: list[SpNode] = [];
    for ch in [nd ->:SpEdge:->][?:SpNode] { kids.append(ch); }
    names: list[str] = [];
    for ch in kids { names.append(ch.nid); }
    names = sorted(names);
    ordered: list[SpNode] = [];
    for nm in names { for ch in kids { if ch.nid == nm { ordered.append(ch); } } }
    return ordered;
}

def _find_node(nid: str, store: dict) -> SpNode | None {
    nmap = store["nodes"] as dict[str, SpNode];
    if nid in nmap { return nmap[nid]; }
    return None;
}

def _pair_weight(source_id: str, target_id: str, store: dict) -> int {
    key = source_id + ">" + target_id;
    weights = store["weights"] as dict[str, int];
    if key in weights { return weights[key]; }
    return 1;
}

def fresh_path_store() -> dict {
    return {"nodes": {}, "deps": {}, "weights": {}, "has_negative": False, "unweighted": True};
}

def register_node(nid: str, store: dict | None = None) -> dict {
    s = store;
    if s is None { s = fresh_path_store(); }
    nmap = s["nodes"] as dict[str, SpNode];
    if nid in nmap { return s; }
    deps = s["deps"] as dict[str, list[str]];
    if nid not in deps { deps[nid] = []; }
    nd = SpNode(nid=nid);
    root ++> nd;
    nmap[nid] = nd;
    return s;
}

def add_sp_edge(source_id: str, target_id: str, weight: int, store: dict) {
    nmap = store["nodes"] as dict[str, SpNode];
    if source_id not in nmap or target_id not in nmap { raise KeyError("unknown node id"); }
    if source_id == target_id { return; }
    src_nd = _find_node(source_id, store);
    tgt_nd = _find_node(target_id, store);
    if src_nd is not None and tgt_nd is not None {
        seen = False;
        for ex in [src_nd ->:SpEdge:->][?:SpNode] { if ex.nid == target_id { seen = True; } }
        if not seen { src_nd +>:SpEdge(weight=weight):+> tgt_nd; }
    }
    key = source_id + ">" + target_id;
    (store["weights"] as dict[str, int])[key] = weight;
    if weight < 0 { store["has_negative"] = True; }
    if weight != 1 { store["unweighted"] = False; }
    outs = store["deps"] as dict[str, list[str]];
    if target_id not in outs[source_id] { outs[source_id].append(target_id); outs[source_id] = sorted(outs[source_id]); }
}

def applicable_impls(store: dict) -> list[str] {
    if store["has_negative"] as bool { return [IMPL_BELLMAN]; }
    if store["unweighted"] as bool { return [IMPL_BFS, IMPL_DIJKSTRA]; }
    return [IMPL_DIJKSTRA];
}

def reach_nodes(start_id: str, store: dict) -> list[str] {
    if start_id not in (store["nodes"] as dict) { raise KeyError(start_id); }
    start_nd = _find_node(start_id, store);
    if start_nd is None { raise KeyError(start_id); }
    w = start_nd spawn SpReachWalk(claimed={}, order=[]);
    reach: list[str] = [];
    for nid in w.order { if nid != start_id { reach.append(nid); } }
    reach = sorted(reach);
    return reach;
}

def _bfs_distances(start_id: str, store: dict) -> dict[str, int] {
    dist: dict[str, int] = {};
    dist[start_id] = 0;
    queue: list[str] = [start_id];
    qi = 0;
    while qi < len(queue) {
        cur = queue[qi];
        qi += 1;
        for dst in (store["deps"] as dict[str, list[str]]).get(cur, []) {
            if dst not in dist {
                dist[dst] = dist[cur] + 1;
                queue.append(dst);
            }
        }
    }
    return dist;
}

def _dijkstra_distances(start_id: str, store: dict) -> dict[str, int] {
    dist: dict[str, int] = {};
    dist[start_id] = 0;
    pending: list[str] = [start_id];
    while len(pending) > 0 {
        best_i = 0;
        bi = 1;
        while bi < len(pending) {
            if dist[pending[bi]] < dist[pending[best_i]] { best_i = bi; }
            bi += 1;
        }
        cur = pending[best_i];
        nxt: list[str] = [];
        pi = 0;
        while pi < len(pending) {
            if pi != best_i { nxt.append(pending[pi]); }
            pi += 1;
        }
        pending = nxt;
        for dst in (store["deps"] as dict[str, list[str]]).get(cur, []) {
            w = _pair_weight(cur, dst, store);
            cand = dist[cur] + w;
            if dst not in dist or cand < dist[dst] {
                dist[dst] = cand;
                found = False;
                for p in pending { if p == dst { found = True; } }
                if not found { pending.append(dst); }
            }
        }
    }
    return dist;
}

def _bellman_distances(start_id: str, store: dict) -> dict[str, int] {
    dist: dict[str, int] = {};
    nodes = sorted((store["nodes"] as dict).keys());
    dist[start_id] = 0;
    rounds = len(nodes) - 1;
    r = 0;
    while r < rounds {
        for src in nodes {
            if src not in dist { continue; }
            for dst in (store["deps"] as dict[str, list[str]]).get(src, []) {
                w = _pair_weight(src, dst, store);
                cand = dist[src] + w;
                if dst not in dist or cand < dist[dst] { dist[dst] = cand; }
            }
        }
        r += 1;
    }
    return dist;
}

def shortest_distances(start_id: str, store: dict, `impl: str) -> dict[str, int] {
    if start_id not in (store["nodes"] as dict) { raise KeyError(start_id); }
    apps = applicable_impls(store);
    ok = False;
    for name in apps { if name == `impl { ok = True; } }
    if not ok { raise ValueError("impl not applicable"); }
    if `impl == IMPL_BFS { return _bfs_distances(start_id, store); }
    if `impl == IMPL_BELLMAN { return _bellman_distances(start_id, store); }
    return _dijkstra_distances(start_id, store);
}

def path_report(start_id: str, store: dict) -> dict {
    apps = applicable_impls(store);
    base = shortest_distances(start_id, store, apps[0]);
    agree = True;
    for name in apps {
        got = shortest_distances(start_id, store, name);
        for nid in base {
            if nid not in got or got[nid] != base[nid] { agree = False; }
        }
    }
    reach = reach_nodes(start_id, store);
    return {"applicable": apps, "distances": base, "agree": agree, "reach": reach, "reach_count": len(reach)};
}
