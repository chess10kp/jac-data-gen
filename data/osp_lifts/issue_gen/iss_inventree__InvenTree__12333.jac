"""inventree/InvenTree#12333 — MPTT-style parent/child tree traversal."""

node MpttNode { has nid: str; }
edge ChildOf {}

obj MpttStore {
    has nodes: dict[str, MpttNode] = {};
}

walker DescWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with MpttNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.reached.append(here.nid);
        visit [->:ChildOf:->][?:MpttNode];
    }
}

walker AncestorWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with MpttNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        if here.nid != self.start { self.found.append(here.nid); }
        parents = [here <-:ChildOf:<-][?:MpttNode];
        if not parents { disengage; }
        pick = parents[0];
        for p in parents {
            if p.nid < pick.nid { pick = p; }
        }
        visit [pick];
    }

    has start: str = "";
}

def load_mptt_tree(
    nodes: list[str],
    parent_edges: list[tuple[str, str | None]],
) -> MpttStore {
    store = MpttStore();
    for nid in nodes {
        nd = MpttNode(nid=nid);
        root ++> nd;
        store.nodes[nid] = nd;
    }
    for (nid, par) in parent_edges {
        if par is None { continue; }
        p = store.nodes.get(par, None);
        c = store.nodes.get(nid, None);
        if p is not None and c is not None { p +>:ChildOf:+> c; }
    }
    return store;
}

def get_descendants(store: MpttStore, node_id: str) -> list[str] {
    nd = store.nodes.get(node_id, None);
    if nd is None { return []; }
    w = nd spawn DescWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

def get_ancestors(store: MpttStore, node_id: str) -> list[str] {
    nd = store.nodes.get(node_id, None);
    if nd is None { return []; }
    w = nd spawn AncestorWalk(claimed={}, found=[], start=node_id);
    return sorted(w.found);
}

def subtree_size(store: MpttStore, node_id: str) -> int {
    return len(get_descendants(store, node_id));
}
