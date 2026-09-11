"""dmidlo/histdata.com-tools#693 — Feature lineage DAG ancestor expansion."""

node LineageNode {
    has nid: str;
}

edge ParentOf {}

obj LineageStore {
    has nodes: dict[str, LineageNode] = {};
}

walker AncestorWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with LineageNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        for p in [here <-:ParentOf:<-][?:LineageNode] {
            if not (p.nid in self.claimed) {
                self.found.append(p.nid);
            }
        }
        visit [<-:ParentOf:<-][?:LineageNode];
    }
}

walker DependentWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has anchor: str = "";

    can step with LineageNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        if here.nid != self.anchor {
            self.found.append(here.nid);
        }
        visit [->:ParentOf:->][?:LineageNode];
    }
}

def load_nodes(
    node_ids: list[str],
    parent_edges: list[tuple[str, str]],
) -> LineageStore {
    ls = LineageStore();
    for nid in node_ids {
        nd = LineageNode(nid=nid);
        root ++> nd;
        ls.nodes[nid] = nd;
    }
    for (child, parent) in parent_edges {
        c = ls.nodes.get(child, None);
        p = ls.nodes.get(parent, None);
        if c is not None and p is not None { p +>:ParentOf:+> c; }
    }
    return ls;
}

def ancestor_hashes(store: LineageStore, node_id: str) -> list[str] {
    nd = store.nodes.get(node_id, None);
    if nd is None { return []; }
    w = nd spawn AncestorWalk(claimed={}, found=[]);
    return sorted(w.found);
}

def dependents_of(store: LineageStore, node_id: str) -> list[str] {
    nd = store.nodes.get(node_id, None);
    if nd is None { return []; }
    w = nd spawn DependentWalk(claimed={}, found=[], anchor=node_id);
    return sorted(w.found);
}

def is_acyclic(store: LineageStore) -> bool {
    indeg: dict[str, int] = {};
    for k in store.nodes.keys() { indeg[k] = 0; }
    for nid in store.nodes.keys() {
        nd = store.nodes[nid];
        cnt = len([nd <-:ParentOf:<-][?:LineageNode]);
        indeg[nid] = cnt;
    }
    queue: list[str] = [];
    for k in store.nodes.keys() {
        if indeg[k] == 0 { queue.append(k); }
    }
    seen = 0;
    while len(queue) > 0 {
        u = queue.pop(0);
        seen = seen + 1;
        und = store.nodes[u];
        for ch in [und ->:ParentOf:->] {
            ln: LineageNode = ch;
            indeg[ln.nid] = indeg[ln.nid] - 1;
            if indeg[ln.nid] == 0 { queue.append(ln.nid); }
        }
    }
    return seen == len(store.nodes);
}
