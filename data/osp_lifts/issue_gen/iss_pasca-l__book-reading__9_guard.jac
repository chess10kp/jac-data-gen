"""Guard: pasca-l/book-reading#9."""

obj TreeStore {
    has nodes: dict[str, TreeNode] = {};
}

node TreeNode { has nid: str; }
edge ChildOf {}

walker DescWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with TreeNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.reached.append(here.nid);
        visit [->:ChildOf:->];
    }
}

walker AncestorWalk {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can step with TreeNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.chain.append(here.nid);
        parents = [here <-:ChildOf:<-][?:TreeNode];
        if not parents { disengage; }
        pick = parents[0];
        for p in parents {
            if p.nid < pick.nid { pick = p; }
        }
        visit [pick];
    }
}

def load_tree(
    nodes: list[str],
    parent_edges: list[tuple[str, str | None]],
) -> TreeStore {
    t = TreeStore();
    for nid in nodes {
        if nid not in t.nodes {
            nd = TreeNode(nid=nid);
            root ++> nd;
            t.nodes[nid] = nd;
        }
    }
    for (nid, par) in parent_edges {
        if par is None { continue; }
        p = t.nodes.get(par, None);
        c = t.nodes.get(nid, None);
        if p is not None and c is not None { p +>:ChildOf:+> c; }
    }
    return t;
}

def tree_descendants(store: TreeStore, node_id: str) -> list[str] {
    anchor = store.nodes.get(node_id, None);
    if anchor is None { return []; }
    w = anchor spawn DescWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

def ancestor_path(store: TreeStore, node_id: str) -> list[str] {
    anchor = store.nodes.get(node_id, None);
    if anchor is None { return []; }
    w = anchor spawn AncestorWalk(claimed={}, chain=[]);
    return w.chain;
}

test "tree descendants and ancestor path" {
    t = load_tree(
        ["root", "a", "b", "c"],
        [("root", None), ("a", "root"), ("b", "a"), ("c", "b")],
    );
    assert tree_descendants(t, "root") == ["a", "b", "c", "root"];
    assert ancestor_path(t, "c") == ["c", "b", "a", "root"];
}

test "branching tree descendants" {
    t = load_tree(
        ["hub", "left", "right", "leaf"],
        [
            ("hub", None),
            ("left", "hub"),
            ("right", "hub"),
            ("leaf", "left"),
        ],
    );
    assert tree_descendants(t, "hub") == ["hub", "leaf", "left", "right"];
}

test "unknown node tolerant" {
    t = load_tree(["solo"], [("solo", None)]);
    assert tree_descendants(t, "missing") == [];
    assert ancestor_path(t, "missing") == [];
}
