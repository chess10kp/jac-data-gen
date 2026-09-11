"""Guard: proletariat64/openwiki#7."""

node ReduceNode { has nid: str; }
edge ParentOf {}

obj ReduceTree { has nodes: dict[str, ReduceNode] = {}; }

def load_reduce_tree(
    node_ids: list[str],
    parent_edges: list[tuple[str, str]],
) -> ReduceTree {
    tree = ReduceTree();
    for nid in node_ids {
        if nid not in tree.nodes {
            nd = ReduceNode(nid=nid);
            root ++> nd;
            tree.nodes[nid] = nd;
        }
    }
    for (parent, child) in parent_edges {
        p = tree.nodes.get(parent, None);
        c = tree.nodes.get(child, None);
        if p is not None and c is not None { p +>:ParentOf:+> c; }
    }
    return tree;
}

def lineage(tree: ReduceTree, node_id: str) -> list[str] {
    start = tree.nodes.get(node_id, None);
    if start is None { return []; }
    chain: list[str] = [];
    cur: ReduceNode | None = start;
    seen: dict[str, bool] = {};
    while cur is not None {
        if cur.nid in seen { break; }
        seen[cur.nid] = True;
        chain.append(cur.nid);
        parents = [cur <-:ParentOf:<-][?:ReduceNode];
        cur = parents[0] if len(parents) > 0 else None;
    }
    chain.reverse();
    return chain;
}

def pending_leaves(tree: ReduceTree, committed: list[str]) -> list[str] {
    done: dict[str, bool] = {};
    for c in committed { done[c] = True; }
    leaves: list[str] = [];
    for nid in tree.nodes.keys() {
        children = [tree.nodes[nid] ->:ParentOf:->][?:ReduceNode];
        if len(children) > 0 { continue; }
        ancestors = lineage(tree, nid);
        ok = True;
        for a in ancestors {
            if a != nid and a not in done { ok = False; }
        }
        if ok and nid not in done { leaves.append(nid); }
    }
    leaves.sort();
    return leaves;
}

test "reduce checkpoint lineage" {
    t = load_reduce_tree(
        ["root", "L1a", "L1b", "L2a", "L2b", "leaf"],
        [("root", "L1a"), ("root", "L1b"), ("L1a", "L2a"), ("L1b", "L2b"), ("L2a", "leaf")],
    );
    assert lineage(t, "leaf") == ["root", "L1a", "L2a", "leaf"];
    assert pending_leaves(t, ["root", "L1a", "L2a"]) == ["leaf"];
}

test "no leaves until ancestors committed" {
    t = load_reduce_tree(["root", "mid", "leaf"], [("root", "mid"), ("mid", "leaf")]);
    assert pending_leaves(t, []) == [];
    assert pending_leaves(t, ["root", "mid"]) == ["leaf"];
}

test "unknown node tolerant" {
    t = load_reduce_tree(["solo"], []);
    assert lineage(t, "ghost") == [];
}
