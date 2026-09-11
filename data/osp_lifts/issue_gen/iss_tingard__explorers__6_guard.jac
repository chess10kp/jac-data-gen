"""tingard/explorers#6 — RRT rewiring can create parent cycles in get_parent_chain."""

node RrtNode {
    has nid: int;
}

edge ParentOf {}

obj RrtStore {
    has nodes: dict[int, RrtNode] = {};
}

walker AncestorCollect {
    has claimed: dict[int, bool] = {};
    has found: list[int] = [];

    can step with RrtNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.found.append(here.nid);
        visit [<-:ParentOf:<-][?:RrtNode];
    }
}

walker DescendantProbe {
    has target: int = 0;
    has hit: bool = False;

    can step with RrtNode entry {
        if here.nid == self.target {
            self.hit = True;
            disengage;
        }
        visit [->:ParentOf:->][?:RrtNode];
    }
}

def load_tree(
    node_ids: list[int],
    parent_edges: list[tuple[int, int]],
) -> RrtStore {
    store = RrtStore();
    for nid in node_ids {
        nd = RrtNode(nid=nid);
        root ++> nd;
        store.nodes[nid] = nd;
    }
    for (child, parent) in parent_edges {
        p = store.nodes.get(parent, None);
        c = store.nodes.get(child, None);
        if p is not None and c is not None { p +>:ParentOf:+> c; }
    }
    return store;
}

def get_parent_chain(store: RrtStore, `node: int) -> list[int] {
    nd = store.nodes.get(`node, None);
    if nd is None { return []; }
    chain: list[int] = [];
    cur: RrtNode | None = nd;
    seen: dict[int, bool] = {};
    while cur is not None {
        if cur.nid in seen { break; }
        seen[cur.nid] = True;
        chain.append(cur.nid);
        parent: RrtNode | None = None;
        for p in [cur <-:ParentOf:<-][?:RrtNode] {
            parent = p;
            break;
        }
        cur = parent;
    }
    return chain;
}

def neighborhood_ancestors(store: RrtStore, seeds: list[int]) -> list[int] {
    acc: dict[int, bool] = {};
    for seed in seeds {
        nd = store.nodes.get(seed, None);
        if nd is None { continue; }
        w = nd spawn AncestorCollect(claimed={});
        for nid in w.found { acc[nid] = True; }
    }
    return sorted(acc.keys());
}

def safe_rewire(store: RrtStore, new_index: int, best_parent: int, candidate: int) -> bool {
    if new_index not in store.nodes or best_parent not in store.nodes { return False; }
    cnd = store.nodes.get(candidate, None);
    if cnd is None { return False; }
    ancestors: dict[int, bool] = {};
    for nid in get_parent_chain(store, best_parent) { ancestors[nid] = True; }
    if candidate in ancestors or candidate == best_parent { return False; }
    for old_p in [cnd <-:ParentOf:<-][?:RrtNode] { old_p del ->:ParentOf:-> cnd; }
    p = store.nodes[new_index];
    p +>:ParentOf:+> cnd;
    return True;
}

test "rrt parent chain and safe rewire" {
    g = load_tree([0, 1, 2, 3, 4], [(1, 0), (2, 1), (3, 2), (4, 3)]);
    assert get_parent_chain(g, 4) == [4, 3, 2, 1, 0];
    g2 = load_tree([0, 1, 2, 3, 10], [(1, 0), (2, 1), (3, 2), (10, 1)]);
    assert safe_rewire(g2, 10, 1, 3) is True;
    assert get_parent_chain(g2, 3) == [3, 10, 1, 0];
}
