"""Training lift for windoze95/saltybytes#42 — GetNodeAncestors without N+1 or cycle loops."""

node RecipeNode {
    has cid: str;
    has title: str = "";
}

edge HasParent {}

obj RecipeTreeStore {
    has graph_root: RecipeNode;
    has index: dict[str, RecipeNode] = {};
}

walker CollectAncestors {
    has claimed: dict[str, bool] = {};
    has ancestors: list[str] = [];
    has max_depth: int = 100;
    has start_cid: str = "";

    can climb with RecipeNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;

        if here.cid != self.start_cid {
            if len(self.ancestors) >= self.max_depth {
                disengage;
            }
            self.ancestors.append(here.cid);
        }

        parents: list[RecipeNode] = [here ->:HasParent:->][?:RecipeNode];
        parent_cids: list[str] = [];
        for p in parents {
            parent_cids.append(p.cid);
        }
        parent_cids = sorted(parent_cids);

        next_nodes: list[RecipeNode] = [];
        for pc in parent_cids {
            for p in parents {
                if p.cid == pc {
                    next_nodes.append(p);
                }
            }
        }

        if len(next_nodes) > 0 {
            visit :0: next_nodes;
        } else {
            disengage;
        }

        print("collect_ancestor", here.cid, self.ancestors);
    }
}

def _ensure_node(store: RecipeTreeStore, cid: str) -> RecipeNode {
    if cid in store.index {
        return store.index[cid];
    }
    nd = RecipeNode(cid=cid, title="");
    store.graph_root ++> nd;
    store.index[cid] = nd;
    return nd;
}

def build_recipe_tree(edges: list[tuple[str, str]]) -> RecipeTreeStore {
    graph_anchor = RecipeNode(cid="__tree_anchor__", title="");
    root ++> graph_anchor;
    idx: dict[str, RecipeNode] = {};
    store = RecipeTreeStore(graph_root=graph_anchor, index=idx);
    for pair in edges {
        child_id = pair[0];
        parent_id = pair[1];
        child = _ensure_node(store, child_id);
        parent = _ensure_node(store, parent_id);
        child +>:HasParent:+> parent;
    }
    return store;
}

def get_node_ancestors(
    store: RecipeTreeStore,
    node_id: str,
    max_depth: int = 100,
) -> list[str] {
    if node_id not in store.index {
        return [];
    }
    start = store.index[node_id];
    claimed0: dict[str, bool] = {};
    ancestors0: list[str] = [];
    w = start spawn CollectAncestors(
        claimed=claimed0,
        ancestors=ancestors0,
        max_depth=max_depth,
        start_cid=node_id,
    );
    return w.ancestors;
}

test "unknown_node_returns_empty" {
    store = build_recipe_tree([]);
    got = get_node_ancestors(store, "missing");
    assert got == [];
}

test "linear_chain_ancestors" {
    edges: list[tuple[str, str]] = [("leaf", "p1"), ("p1", "p2"), ("p2", "root")];
    store = build_recipe_tree(edges);
    got = get_node_ancestors(store, "leaf", max_depth=10);
    assert got == ["p1", "p2", "root"];
}

test "max_depth_limits" {
    edges: list[tuple[str, str]] = [("a", "b"), ("b", "c"), ("c", "d")];
    store = build_recipe_tree(edges);
    got = get_node_ancestors(store, "a", max_depth=1);
    assert got == ["b"];
}

test "adversarial_cycle_revisit_before_dead_end" {
    edges: list[tuple[str, str]] = [
        ("d", "c"),
        ("c", "b"),
        ("b", "a"),
        ("a", "c"),
    ];
    store = build_recipe_tree(edges);
    got = get_node_ancestors(store, "d", max_depth=10);
    assert got == ["c", "b", "a"];
}

test "self_cycle_on_start" {
    edges: list[tuple[str, str]] = [("d", "c"), ("c", "b"), ("b", "d")];
    store = build_recipe_tree(edges);
    got = get_node_ancestors(store, "d", max_depth=10);
    assert got == ["c", "b"];
}

test "start_node_excluded" {
    edges: list[tuple[str, str]] = [("solo", "parent")];
    store = build_recipe_tree(edges);
    got = get_node_ancestors(store, "solo");
    assert "solo" not in got;
}
