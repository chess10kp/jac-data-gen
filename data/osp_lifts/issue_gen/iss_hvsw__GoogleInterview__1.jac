"""hvsw/GoogleInterview#1 — graph adjacency BFS reach and cycle detection."""

node GNode {
    has nid: str;
}

edge GEdge {}

walker DfsReachWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with GNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.order.append(here.nid);
        kids = _sorted_out(here);
        i = len(kids) - 1;
        while i >= 0 { visit :0: [kids[i]]; i -= 1; }
    }
}

walker CycleProbeWalk {
    has claimed: dict[str, bool] = {};
    has found: bool = False;

    can step with GNode entry {
        if here.nid in self.claimed { self.found = True; skip; }
        self.claimed[here.nid] = True;
        visit [-->];
    }
}

def _sorted_out(nd: GNode) -> list[GNode] {
    kids: list[GNode] = [];
    for ch in [nd ->:GEdge:->][?:GNode] { kids.append(ch); }
    names: list[str] = [];
    for ch in kids { names.append(ch.nid); }
    names = sorted(names);
    ordered: list[GNode] = [];
    for nm in names { for ch in kids { if ch.nid == nm { ordered.append(ch); } } }
    return ordered;
}

def _find_node(nid: str, store: dict) -> GNode | None {
    nmap = store["nodes"] as dict[str, GNode];
    if nid in nmap { return nmap[nid]; }
    return None;
}

def fresh_graph_store() -> dict {
    return {"nodes": {}, "deps": {}, "rev": {}};
}

def register_node(nid: str, store: dict | None = None) -> dict {
    s = store;
    if s is None { s = fresh_graph_store(); }
    nmap = s["nodes"] as dict[str, GNode];
    if nid in nmap { return s; }
    deps = s["deps"] as dict[str, list[str]];
    if nid not in deps { deps[nid] = []; }
    revs = s["rev"] as dict[str, list[str]];
    if nid not in revs { revs[nid] = []; }
    nd = GNode(nid=nid);
    root ++> nd;
    nmap[nid] = nd;
    return s;
}

def add_graph_edge(source_id: str, target_id: str, store: dict) {
    nmap = store["nodes"] as dict[str, GNode];
    if source_id not in nmap or target_id not in nmap { raise KeyError("unknown node id"); }
    if source_id == target_id { return; }
    src_nd = _find_node(source_id, store);
    tgt_nd = _find_node(target_id, store);
    if src_nd is not None and tgt_nd is not None {
        seen = False;
        for ex in [src_nd ->:GEdge:->][?:GNode] { if ex.nid == target_id { seen = True; } }
        if not seen { src_nd +>:GEdge:+> tgt_nd; }
    }
    outs = store["deps"] as dict[str, list[str]];
    if target_id not in outs[source_id] { outs[source_id].append(target_id); outs[source_id] = sorted(outs[source_id]); }
    revs = store["rev"] as dict[str, list[str]];
    if source_id not in revs[target_id] { revs[target_id].append(source_id); revs[target_id] = sorted(revs[target_id]); }
}

def bfs_reach(start_id: str, store: dict) -> list[str] {
    if start_id not in (store["nodes"] as dict) { raise KeyError(start_id); }
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
    reach: list[str] = [];
    for nid in dist { if nid != start_id { reach.append(nid); } }
    reach = sorted(reach);
    return reach;
}

def dfs_reach(start_id: str, store: dict) -> list[str] {
    if start_id not in (store["nodes"] as dict) { raise KeyError(start_id); }
    start_nd = _find_node(start_id, store);
    if start_nd is None { raise KeyError(start_id); }
    w = start_nd spawn DfsReachWalk(claimed={}, order=[]);
    reach: list[str] = [];
    for nid in w.order { if nid != start_id { reach.append(nid); } }
    reach = sorted(reach);
    return reach;
}

def detect_cycle(store: dict) -> bool {
    nmap = store["nodes"] as dict[str, GNode];
    for nid in sorted(nmap.keys()) {
        nd = nmap[nid];
        w = nd spawn CycleProbeWalk(claimed={}, found=False);
        if w.found { return True; }
    }
    return False;
}

def graph_report(start_id: str, store: dict) -> dict {
    if start_id not in (store["nodes"] as dict) { raise KeyError(start_id); }
    bfs = bfs_reach(start_id, store);
    dfs = dfs_reach(start_id, store);
    return {"bfs_reach": bfs, "dfs_reach": dfs, "reach_count": len(bfs), "has_cycle": detect_cycle(store)};
}
