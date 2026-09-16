"""Tree traversal lifts for pythonds-style adjacency walks — raychenv/blog#106."""

node TNode { has cid: str; }
edge Child {}

walker PreWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with TNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print(here.cid);
        kids: list[TNode] = [here ->:Child:->][?:TNode];
        for ch in kids {
            visit :0: ch;
        }
    }
}

walker PostWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with TNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        kids: list[TNode] = [here ->:Child:->][?:TNode];
        for ch in kids {
            visit ch;
        }
        self.order.append(here.cid);
        print(here.cid);
    }
}

walker BfsWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with TNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print(here.cid);
        kids: list[TNode] = [here ->:Child:->][?:TNode];
        visit kids;
    }
}

def ensure_node(store: dict[str, TNode], cid: str) -> TNode {
    if cid in store {
        return store[cid];
    }
    nd = TNode(cid=cid);
    root ++> nd;
    store[cid] = nd;
    return nd;
}

def wire_tree(edges: list[tuple[str, str]]) -> dict[str, TNode] {
    store: dict[str, TNode] = {};
    for e in edges {
        par = ensure_node(store, e[0]);
        ch = ensure_node(store, e[1]);
        par +>:Child:+> ch;
    }
    return store;
}

def preorder_traversal(edges: list[tuple[str, str]], start: str) -> list[str] {
    store = wire_tree(edges);
    if start not in store {
        return [];
    }
    w = store[start] spawn PreWalk(claimed={}, order=[]);
    return w.order;
}

def postorder_traversal(edges: list[tuple[str, str]], start: str) -> list[str] {
    store = wire_tree(edges);
    if start not in store {
        return [];
    }
    w = store[start] spawn PostWalk(claimed={}, order=[]);
    return w.order;
}

def bfs_traversal(edges: list[tuple[str, str]], start: str) -> list[str] {
    store = wire_tree(edges);
    if start not in store {
        return [];
    }
    w = store[start] spawn BfsWalk(claimed={}, order=[]);
    return w.order;
}

test "preorder_small_tree" {
    edges: list[tuple[str, str]] = [
        ("A", "B"), ("A", "C"), ("B", "D"), ("B", "E")
    ];
    got = preorder_traversal(edges, "A");
    assert got == ["A", "B", "D", "E", "C"];
}

test "postorder_small_tree" {
    edges: list[tuple[str, str]] = [
        ("A", "B"), ("A", "C"), ("B", "D"), ("B", "E")
    ];
    got = postorder_traversal(edges, "A");
    assert got == ["D", "E", "B", "C", "A"];
}

test "bfs_small_tree" {
    edges: list[tuple[str, str]] = [
        ("A", "B"), ("A", "C"), ("B", "D"), ("B", "E")
    ];
    got = bfs_traversal(edges, "A");
    assert got == ["A", "B", "C", "D", "E"];
}

test "missing_start_empty" {
    edges: list[tuple[str, str]] = [("A", "B")];
    assert preorder_traversal(edges, "Z") == [];
    assert postorder_traversal(edges, "Z") == [];
    assert bfs_traversal(edges, "Z") == [];
}

test "single_node_preorder" {
    edges: list[tuple[str, str]] = [("X", "Y")];
    got = preorder_traversal(edges, "X");
    assert got == ["X"];
}

test "subtree_postorder" {
    edges: list[tuple[str, str]] = [
        ("A", "B"), ("A", "C"), ("B", "D"), ("B", "E")
    ];
    got = postorder_traversal(edges, "B");
    assert got == ["D", "E", "B"];
}
