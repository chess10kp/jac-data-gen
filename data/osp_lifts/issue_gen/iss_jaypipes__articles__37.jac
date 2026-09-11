"""jaypipes/articles#37 — bounded-depth hierarchy adjacency and recursive reach."""

glob TRAIT_GPU = "gpu";
glob TRAIT_CPU = "cpu";

node ResNode {
    has nid: str;
    has resources: int = 0;
    has traits: str = "";
}

edge TreeEdge {}
edge GroupLink {}

walker TreeReachWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with ResNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.order.append(here.nid);
        kids = _sorted_tree_out(here);
        i = len(kids) - 1;
        while i >= 0 { visit :0: [kids[i]]; i -= 1; }
    }
}

walker ClosureReachWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with ResNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.order.append(here.nid);
        kids = _sorted_closure_out(here);
        i = len(kids) - 1;
        while i >= 0 { visit :0: [kids[i]]; i -= 1; }
    }
}

def _sorted_tree_out(nd: ResNode) -> list[ResNode] {
    kids: list[ResNode] = [];
    for ch in [nd ->:TreeEdge:->][?:ResNode] { kids.append(ch); }
    names: list[str] = [];
    for ch in kids { names.append(ch.nid); }
    names = sorted(names);
    ordered: list[ResNode] = [];
    for nm in names { for ch in kids { if ch.nid == nm { ordered.append(ch); } } }
    return ordered;
}

def _sorted_closure_out(nd: ResNode) -> list[ResNode] {
    kids: list[ResNode] = [];
    for ch in [nd ->:TreeEdge:->][?:ResNode] { kids.append(ch); }
    for ch in [nd ->:GroupLink:->][?:ResNode] { kids.append(ch); }
    names: list[str] = [];
    for ch in kids { names.append(ch.nid); }
    names = sorted(names);
    ordered: list[ResNode] = [];
    seen: dict[str, bool] = {};
    for nm in names {
        if nm in seen { continue; }
        seen[nm] = True;
        for ch in kids { if ch.nid == nm { ordered.append(ch); break; } }
    }
    return ordered;
}

def _find_node(nid: str, store: dict) -> ResNode | None {
    nmap = store["nodes"] as dict[str, ResNode];
    if nid in nmap { return nmap[nid]; }
    return None;
}

def fresh_resource_store() -> dict {
    return {"nodes_map": {}, "resources": {}, "traits": {}, "tree": {}, "rev": {}, "groups": {}, "nodes": {}, "roots": []};
}

def register_resource(nid: str, resources: int, traits: str, store: dict | None = None) -> dict {
    s = store;
    if s is None { s = fresh_resource_store(); }
    (s["nodes_map"] as dict[str, bool])[nid] = True;
    (s["resources"] as dict[str, int])[nid] = resources;
    (s["traits"] as dict[str, str])[nid] = traits;
    tree = s["tree"] as dict[str, list[str]];
    if nid not in tree { tree[nid] = []; }
    revs = s["rev"] as dict[str, list[str]];
    if nid not in revs { revs[nid] = []; }
    grps = s["groups"] as dict[str, list[str]];
    if nid not in grps { grps[nid] = []; }
    nd = ResNode(nid=nid, resources=resources, traits=traits);
    root ++> nd;
    roots = s["roots"] as list[str];
    roots.append(nid);
    (s["nodes"] as dict[str, ResNode])[nid] = nd;
    return s;
}

def add_tree_edge(parent_id: str, child_id: str, store: dict) {
    nmap = store["nodes_map"] as dict[str, bool];
    if parent_id not in nmap or child_id not in nmap { raise KeyError("unknown node id"); }
    if parent_id == child_id { return; }
    par_nd = _find_node(parent_id, store);
    ch_nd = _find_node(child_id, store);
    if par_nd is not None and ch_nd is not None {
        seen = False;
        for ex in [par_nd ->:TreeEdge:->][?:ResNode] { if ex.nid == child_id { seen = True; } }
        if not seen { par_nd +>:TreeEdge:+> ch_nd; }
        roots = store["roots"] as list[str];
        if child_id in roots { roots.remove(child_id); }
    }
    tree = store["tree"] as dict[str, list[str]];
    if child_id not in tree[parent_id] { tree[parent_id].append(child_id); tree[parent_id] = sorted(tree[parent_id]); }
    revs = store["rev"] as dict[str, list[str]];
    if parent_id not in revs[child_id] { revs[child_id].append(parent_id); revs[child_id] = sorted(revs[child_id]); }
}

def add_group_link(source_id: str, target_id: str, store: dict) {
    nmap = store["nodes_map"] as dict[str, bool];
    if source_id not in nmap or target_id not in nmap { raise KeyError("unknown node id"); }
    if source_id == target_id { return; }
    src_nd = _find_node(source_id, store);
    tgt_nd = _find_node(target_id, store);
    if src_nd is not None and tgt_nd is not None {
        seen = False;
        for ex in [src_nd ->:GroupLink:->][?:ResNode] { if ex.nid == target_id { seen = True; } }
        if not seen { src_nd +>:GroupLink:+> tgt_nd; }
    }
    grps = store["groups"] as dict[str, list[str]];
    if target_id not in grps[source_id] { grps[source_id].append(target_id); grps[source_id] = sorted(grps[source_id]); }
}

def direct_children(node_id: str, store: dict) -> list[str] {
    if node_id not in (store["nodes_map"] as dict) { raise KeyError(node_id); }
    return list((store["tree"] as dict[str, list[str]]).get(node_id, []));
}

def subtree_reach(start_id: str, store: dict) -> list[str] {
    if start_id not in (store["nodes_map"] as dict) { raise KeyError(start_id); }
    start_nd = _find_node(start_id, store);
    if start_nd is None { raise KeyError(start_id); }
    w = start_nd spawn TreeReachWalk(claimed={}, order=[]);
    reach: list[str] = [];
    for nid in w.order { if nid != start_id { reach.append(nid); } }
    reach = sorted(reach);
    return reach;
}

def closure_reach(start_id: str, store: dict) -> list[str] {
    if start_id not in (store["nodes_map"] as dict) { raise KeyError(start_id); }
    start_nd = _find_node(start_id, store);
    if start_nd is None { raise KeyError(start_id); }
    w = start_nd spawn ClosureReachWalk(claimed={}, order=[]);
    reach: list[str] = [];
    for nid in w.order { if nid != start_id { reach.append(nid); } }
    reach = sorted(reach);
    return reach;
}

def hierarchy_report(start_id: str, store: dict, min_resources: int, trait_need: str) -> dict {
    if start_id not in (store["nodes_map"] as dict) { raise KeyError(start_id); }
    subtree = subtree_reach(start_id, store);
    closure = closure_reach(start_id, store);
    direct = direct_children(start_id, store);
    resources = store["resources"] as dict[str, int];
    traits = store["traits"] as dict[str, str];
    flat: list[str] = [];
    for nid in sorted((store["nodes_map"] as dict).keys()) {
        if resources.get(nid, 0) >= min_resources and traits.get(nid, "") == trait_need { flat.append(nid); }
    }
    sub_match: list[str] = [];
    for nid in subtree {
        if resources.get(nid, 0) >= min_resources and traits.get(nid, "") == trait_need { sub_match.append(nid); }
    }
    sub_match = sorted(sub_match);
    return {"direct": direct, "subtree": subtree, "closure": closure, "flat_matches": flat, "subtree_matches": sub_match, "subtree_match_count": len(sub_match)};
}
