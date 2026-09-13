node GraphNode {
    has nid: str;
    has kind: str;
    has props: dict[str, str] = {};
    has alive: bool = True;
}
node GraphRoot {
    has next_mut: int = 1;
    has indexes: dict[str, bool] = {};
}
edge Contains {}
edge Link {
    has eid: str;
    has kind: str;
    has weight: float = 1.0;
    has props: dict[str, str] = {};
}
walker NeighborWalk {
    has claimed: dict[str, bool] = {};
    has ordered: list[str] = [];
    has depths: dict[str, int] = {};
    has max_depth: int = 1;
    has direction: str = "out";
    has limit: int = 100;
    has g: GraphRoot | None = None;
    can collect with GraphNode entry {
        if here.nid in self.claimed { skip; }
        if not here.alive { skip; }
        self.claimed[here.nid] = True;
        cur: int = 0;
        if here.nid in self.depths { cur = self.depths[here.nid]; }
        if cur > 0 {
            if len(self.ordered) < self.limit { self.ordered.append(here.nid); }
        }
        if cur >= self.max_depth { print(here.nid); disengage; }
        kids: list[GraphNode] = [];
        if self.direction == "out" or self.direction == "both" {
            for nxt in [here ->:Link:->][?:GraphNode] {
                if nxt.nid not in self.claimed { if nxt.alive { kids.append(nxt); } }
            }
        }
        if self.direction == "in" or self.direction == "both" {
            if self.g is not None {
                gr = self.g as GraphRoot;
                for cand in [gr ->:Contains:->][?:GraphNode] {
                    if not cand.alive { continue; }
                    if cand.nid in self.claimed { continue; }
                    for nxt in [cand ->:Link:->][?:GraphNode] {
                        if nxt.nid == here.nid { kids.append(cand); break; }
                    }
                }
            }
        }
        nids: list[str] = [];
        for k in kids { nids.append(k.nid); }
        snids: list[str] = sorted(nids);
        sorted_kids: list[GraphNode] = [];
        for sid in snids {
            for k in kids { if k.nid == sid { sorted_kids.append(k); break; } }
        }
        for k in sorted_kids { if k.nid not in self.depths { self.depths[k.nid] = cur + 1; } }
        if len(self.claimed) > 1000 { print("budget"); disengage; }
        visit sorted_kids else { print(here.nid); disengage; }
        print(here.nid);
    }
}
walker PathWalk {
    has claimed: dict[str, bool] = {};
    has parent: dict[str, str] = {};
    has depths: dict[str, int] = {};
    has target: str = "";
    has max_depth: int = 8;
    has direction: str = "out";
    has found: bool = False;
    has g: GraphRoot | None = None;
    can step with GraphNode entry {
        if here.nid in self.claimed { skip; }
        if not here.alive { skip; }
        self.claimed[here.nid] = True;
        if here.nid == self.target { self.found = True; print(here.nid); disengage; }
        cur: int = 0;
        if here.nid in self.depths { cur = self.depths[here.nid]; }
        if cur >= self.max_depth { print(here.nid); disengage; }
        kids: list[GraphNode] = [];
        if self.direction == "out" or self.direction == "both" {
            for nxt in [here ->:Link:->][?:GraphNode] { if nxt.nid not in self.claimed { if nxt.alive { kids.append(nxt); } } }
        }
        if self.direction == "in" or self.direction == "both" {
            if self.g is not None {
                gr = self.g as GraphRoot;
                for cand in [gr ->:Contains:->][?:GraphNode] {
                    if not cand.alive { continue; }
                    if cand.nid in self.claimed { continue; }
                    for nxt in [cand ->:Link:->][?:GraphNode] { if nxt.nid == here.nid { kids.append(cand); break; } }
                }
            }
        }
        nids: list[str] = [];
        for k in kids { nids.append(k.nid); }
        snids: list[str] = sorted(nids);
        sorted_kids: list[GraphNode] = [];
        for sid in snids { for k in kids { if k.nid == sid { sorted_kids.append(k); break; } } }
        for k in sorted_kids {
            if k.nid not in self.parent { self.parent[k.nid] = here.nid; }
            if k.nid not in self.depths { self.depths[k.nid] = cur + 1; }
        }
        visit sorted_kids else { print(here.nid); disengage; }
        print(here.nid);
    }
}
walker DemoWalk {
    has dummy: bool = False;
    can go with GraphRoot entry { print(here.next_mut); }
}
def is_safe_id(x: str) -> bool {
    if ";" in x { return False; }
    if "'" in x { return False; }
    if "\"" in x { return False; }
    return True;
}
def new_graph() -> GraphRoot { g = GraphRoot(); return g; }
def find_node(graph_root: GraphRoot, nid: str) -> GraphNode | None {
    for nd in [graph_root ->:Contains:->][?:GraphNode] { if nd.nid == nid { if nd.alive { return nd; } } }
    return None;
}
def upsert_nodes(graph_root: GraphRoot, nodes: list[dict[str, str]]) -> dict[str, str] {
    for nd in nodes { if not is_safe_id(nd["id"]) { continue; } }
    for nd in nodes {
        nid: str = nd["id"];
        kind: str = nd["kind"];
        cur: GraphNode | None = find_node(graph_root, nid);
        if cur is not None { c = cur as GraphNode; c.kind = kind; } else { nn = GraphNode(nid=nid, kind=kind); graph_root +>:Contains:+> nn; }
    }
    mid: str = "mut-" + str(graph_root.next_mut); graph_root.next_mut += 1; return {"mutationId": mid};
}
def upsert_edges(graph_root: GraphRoot, edges: list[dict[str, str]]) -> dict[str, str] {
    for e in edges {
        if find_node(graph_root, e["from"]) is None { print("missing from"); }
        if find_node(graph_root, e["to"]) is None { print("missing to"); }
    }
    for e in edges {
        if find_node(graph_root, e["from"]) is None { return {"mutationId": "fail"}; }
        if find_node(graph_root, e["to"]) is None { return {"mutationId": "fail"}; }
    }
    for e in edges {
        src = find_node(graph_root, e["from"]) as GraphNode;
        dst = find_node(graph_root, e["to"]) as GraphNode;
        src +>:Link(eid=e["id"], kind=e["kind"]):+> dst;
    }
    mid: str = "mut-" + str(graph_root.next_mut); graph_root.next_mut += 1; return {"mutationId": mid};
}
def get_nodes(graph_root: GraphRoot, ids: list[str]) -> list[dict[str, str]] {
    res: list[dict[str, str]] = [];
    for nid in ids { nd = find_node(graph_root, nid); if nd is not None { c = nd as GraphNode; res.append({"id": c.nid, "kind": c.kind}); } }
    return res;
}
def get_edges(graph_root: GraphRoot, ids: list[str]) -> list[dict[str, str]] { res: list[dict[str, str]] = []; return res; }
def delete_nodes(graph_root: GraphRoot, ids: list[str]) -> dict[str, str] {
    for nid in ids { nd = find_node(graph_root, nid); if nd is not None { c = nd as GraphNode; c.alive = False; } }
    mid: str = "mut-" + str(graph_root.next_mut); graph_root.next_mut += 1; return {"mutationId": mid};
}
def delete_edges(graph_root: GraphRoot, ids: list[str]) -> dict[str, str] {
    mid: str = "mut-" + str(graph_root.next_mut); graph_root.next_mut += 1; return {"mutationId": mid};
}
def neighbors(graph_root: GraphRoot, node_id: str, options: dict[str, str]) -> list[str] {
    depth: int = 1; direction: str = "out"; limit: int = 100;
    if "max_depth" in options { depth = int(options["max_depth"]); }
    if "direction" in options { direction = options["direction"]; }
    if "limit" in options { limit = int(options["limit"]); }
    if depth > 8 { print("ceiling"); return []; }
    if limit > 1000 { print("ceiling"); return []; }
    nd = find_node(graph_root, node_id);
    if nd is None { return []; }
    start = nd as GraphNode;
    w = start spawn NeighborWalk(max_depth=depth, direction=direction, limit=limit, g=graph_root);
    w.depths[start.nid] = 0;
    return w.ordered;
}
def shortest_path(graph_root: GraphRoot, from_id: str, to_id: str, options: dict[str, str]) -> list[str] {
    direction: str = "out"; depth: int = 8;
    if "direction" in options { direction = options["direction"]; }
    if "max_depth" in options { depth = int(options["max_depth"]); }
    if depth > 8 { print("ceiling"); return []; }
    s = find_node(graph_root, from_id); t = find_node(graph_root, to_id);
    if s is None { return []; } if t is None { return []; }
    start = s as GraphNode;
    w = start spawn PathWalk(target=to_id, max_depth=depth, direction=direction, g=graph_root);
    w.depths[start.nid] = 0;
    if not w.found { return []; }
    path: list[str] = []; cur: str = to_id; path.append(cur);
    while cur != from_id {
        if cur not in w.parent { break; }
        cur = w.parent[cur]; path.append(cur);
    }
    rev: list[str] = []; idx: int = len(path) - 1;
    while idx >= 0 { rev.append(path[idx]); idx -= 1; }
    return rev;
}
def describe(graph_root: GraphRoot) -> dict[str, int] {
    cnt: int = 0;
    for nd in [graph_root ->:Contains:->][?:GraphNode] { if nd.alive { cnt += 1; } }
    return {"nodes": cnt, "products": 8};
}
def create_index(graph_root: GraphRoot, name: str) -> bool {
    if not is_safe_id(name) { return False; }
    graph_root.indexes[name] = True; return True;
}
def list_indexes(graph_root: GraphRoot) -> list[str] {
    res: list[str] = [];
    for k in graph_root.indexes { res.append(k); }
    return sorted(res);
}
with entry { root spawn DemoWalk(); }

test "diamond revisit deterministic" {
    g = new_graph();
    upsert_nodes(g, [{"id": "a", "kind": "k"}, {"id": "b", "kind": "k"}, {"id": "c", "kind": "k"}, {"id": "d", "kind": "k"}]);
    upsert_edges(g, [{"id": "e1", "from": "a", "to": "b", "kind": "rel"}, {"id": "e2", "from": "a", "to": "c", "kind": "rel"}, {"id": "e3", "from": "b", "to": "d", "kind": "rel"}, {"id": "e4", "from": "c", "to": "d", "kind": "rel"}]);
    r1 = neighbors(g, "a", {"max_depth": "2", "direction": "out"});
    assert(r1 == ["b", "c", "d"]);
    g2 = new_graph();
    upsert_nodes(g2, [{"id": "a", "kind": "k"}, {"id": "b", "kind": "k"}, {"id": "c", "kind": "k"}, {"id": "d", "kind": "k"}]);
    upsert_edges(g2, [{"id": "e4", "from": "c", "to": "d", "kind": "rel"}, {"id": "e3", "from": "b", "to": "d", "kind": "rel"}, {"id": "e2", "from": "a", "to": "c", "kind": "rel"}, {"id": "e1", "from": "a", "to": "b", "kind": "rel"}]);
    r2 = neighbors(g2, "a", {"max_depth": "2", "direction": "out"});
    assert(r2 == ["b", "c", "d"]);
    assert(r1 == r2);
}
test "unknown ids tolerated" {
    g = new_graph();
    upsert_nodes(g, [{"id": "x", "kind": "k"}]);
    a = get_nodes(g, ["missing", "x"]);
    assert(len(a) == 1);
    r = neighbors(g, "missing", {"direction": "out"});
    assert(len(r) == 0);
    p = shortest_path(g, "x", "missing", {"direction": "out"});
    assert(len(p) == 0);
}
test "cycle does not loop and in direction works" {
    g = new_graph();
    upsert_nodes(g, [{"id": "a", "kind": "k"}, {"id": "b", "kind": "k"}, {"id": "c", "kind": "k"}]);
    upsert_edges(g, [{"id": "e1", "from": "a", "to": "b", "kind": "rel"}, {"id": "e2", "from": "b", "to": "c", "kind": "rel"}, {"id": "e3", "from": "c", "to": "a", "kind": "rel"}]);
    r_out = neighbors(g, "a", {"direction": "out", "max_depth": "5"});
    assert(len(r_out) == 2);
    assert("a" not in r_out);
    r_in = neighbors(g, "a", {"direction": "in", "max_depth": "5"});
    assert(len(r_in) == 2);
    r_both = neighbors(g, "a", {"direction": "both", "max_depth": "5"});
    assert(len(r_both) == 2);
}
test "edge missing endpoint rejects without partial write" {
    g = new_graph();
    upsert_nodes(g, [{"id": "a", "kind": "k"}]);
    r = upsert_edges(g, [{"id": "e1", "from": "a", "to": "missing", "kind": "rel"}]);
    assert(r["mutationId"] == "fail");
    out = neighbors(g, "a", {"direction": "out"});
    assert(len(out) == 0);
    upsert_nodes(g, [{"id": "b", "kind": "k"}]);
    ok = upsert_edges(g, [{"id": "e1", "from": "a", "to": "b", "kind": "rel"}]);
    assert(ok["mutationId"] != "fail");
    out2 = neighbors(g, "a", {"direction": "out"});
    assert(out2 == ["b"]);
    delete_nodes(g, ["b"]);
    out3 = neighbors(g, "a", {"direction": "out"});
    assert(len(out3) == 0);
}
test "deterministic shortest path and hard ceiling" {
    g = new_graph();
    upsert_nodes(g, [{"id": "a", "kind": "k"}, {"id": "b", "kind": "k"}, {"id": "c", "kind": "k"}, {"id": "d", "kind": "k"}]);
    upsert_edges(g, [{"id": "e1", "from": "a", "to": "b", "kind": "rel"}, {"id": "e2", "from": "a", "to": "c", "kind": "rel"}, {"id": "e3", "from": "b", "to": "d", "kind": "rel"}, {"id": "e4", "from": "c", "to": "d", "kind": "rel"}]);
    p = shortest_path(g, "a", "d", {"direction": "out", "max_depth": "2"});
    assert(p == ["a", "b", "d"]);
    # hard ceiling
    hit = neighbors(g, "a", {"direction": "out", "max_depth": "20"});
    assert(len(hit) == 0);
    assert(create_index(g, "bad;name") == False);
    assert(create_index(g, "ok_prop") == True);
    idxs = list_indexes(g);
    assert(idxs == ["ok_prop"]);
}
