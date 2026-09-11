"""gastownhall/beads#5397 — N+1 engine opens scale descendant list cost by node count."""

glob ENGINE_OPEN_MS = 1800;
glob PER_NODE_MS = 250;
glob LIGHT_PER_NODE_MS = 110;

node IssueNode {
    has nid: str;
}

edge ParentOf {}

walker ReachDescWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with IssueNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.order.append(here.nid);
        kids = _sorted_children(here);
        i = len(kids) - 1;
        while i >= 0 { visit :0: [kids[i]]; i -= 1; }
    }
}

def _sorted_children(nd: IssueNode) -> list[IssueNode] {
    kids: list[IssueNode] = [];
    for ch in [nd ->:ParentOf:->][?:IssueNode] { kids.append(ch); }
    names: list[str] = [];
    for ch in kids { names.append(ch.nid); }
    names = sorted(names);
    ordered: list[IssueNode] = [];
    for nm in names { for ch in kids { if ch.nid == nm { ordered.append(ch); } } }
    return ordered;
}

def _find_node(nid: str, store: dict) -> IssueNode | None {
    nmap = store["nodes"] as dict[str, IssueNode];
    if nid in nmap { return nmap[nid]; }
    return None;
}

def fresh_tree_store() -> dict { return {"nodes_map": {}, "children": {}, "rev": {}, "nodes": {}}; }

def register_node(node_id: str, store: dict | None = None) -> dict {
    s = store;
    if s is None { s = fresh_tree_store(); }
    (s["nodes_map"] as dict[str, bool])[node_id] = True;
    kids = s["children"] as dict[str, list[str]];
    if node_id not in kids { kids[node_id] = []; }
    rev = s["rev"] as dict[str, list[str]];
    if node_id not in rev { rev[node_id] = []; }
    nd = IssueNode(nid=node_id);
    root ++> nd;
    (s["nodes"] as dict[str, IssueNode])[node_id] = nd;
    return s;
}

def add_parent_edge(parent_id: str, child_id: str, store: dict) {
    nmap = store["nodes_map"] as dict[str, bool];
    if parent_id not in nmap or child_id not in nmap { raise KeyError("unknown node id"); }
    if parent_id == child_id { return; }
    par_nd = _find_node(parent_id, store);
    ch_nd = _find_node(child_id, store);
    if par_nd is not None and ch_nd is not None {
        seen = False;
        for ex in [par_nd ->:ParentOf:->][?:IssueNode] { if ex.nid == child_id { seen = True; } }
        if not seen { par_nd +>:ParentOf:+> ch_nd; }
    }
    outs = store["children"] as dict[str, list[str]];
    if parent_id not in outs { outs[parent_id] = []; }
    if child_id not in outs[parent_id] { outs[parent_id].append(child_id); outs[parent_id] = sorted(outs[parent_id]); }
    revs = store["rev"] as dict[str, list[str]];
    if child_id not in revs { revs[child_id] = []; }
    if parent_id not in revs[child_id] { revs[child_id].append(parent_id); revs[child_id] = sorted(revs[child_id]); }
}

def direct_children(parent_id: str, store: dict) -> list[str] {
    if parent_id not in (store["nodes_map"] as dict) { raise KeyError(parent_id); }
    return list((store["children"] as dict[str, list[str]]).get(parent_id, []));
}

def reachable_descendants(start_id: str, store: dict) -> list[str] {
    if start_id not in (store["nodes_map"] as dict) { raise KeyError(start_id); }
    start_nd = _find_node(start_id, store);
    if start_nd is None { raise KeyError(start_id); }
    w = start_nd spawn ReachDescWalk(claimed={}, order=[]);
    reach: list[str] = [];
    for nid in w.order { if nid != start_id { reach.append(nid); } }
    return reach;
}

def list_cost_ms(start_id: str, store: dict, journal_heavy: bool = False) -> int {
    if start_id not in (store["nodes_map"] as dict) { raise KeyError(start_id); }
    reach = reachable_descendants(start_id, store);
    per = PER_NODE_MS if journal_heavy else LIGHT_PER_NODE_MS;
    return ENGINE_OPEN_MS + (len(reach) + 1) * per;
}

def descendant_report(start_id: str, store: dict, journal_heavy: bool = False) -> dict {
    reach = reachable_descendants(start_id, store);
    direct = direct_children(start_id, store);
    return {"direct": direct, "reach": reach, "reach_count": len(reach), "nodes_walked": len(reach) + 1, "cost_ms": list_cost_ms(start_id, store, journal_heavy), "journal_heavy": journal_heavy};
}
