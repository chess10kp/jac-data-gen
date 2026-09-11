"""flyteorg/flyte#7338 — Bounded sync_node_execution tree walk."""

node ExecNode {
    has nid: str;
}

edge ChildExec {}

obj ExecStore {
    has nodes: dict[str, ExecNode] = {};
}

walker NodeCount {
    has claimed: dict[str, bool] = {};
    has count: int = 0;

    can step with ExecNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.count += 1;
        visit [->:ChildExec:->][?:ExecNode];
    }
}

walker DepthCheck {
    has max_depth: int = 0;
    has ok: bool = True;
    has depth: int = 0;

    can step with ExecNode entry {
        if self.depth > self.max_depth {
            self.ok = False;
            disengage;
        }
        self.depth += 1;
        visit [->:ChildExec:->][?:ExecNode];
    }
}

walker MaxDepth {
    has claimed: dict[str, bool] = {};
    has depth: int = 0;
    has max_seen: int = 0;

    can step with ExecNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        if self.depth > self.max_seen { self.max_seen = self.depth; }
        self.depth += 1;
        visit [->:ChildExec:->][?:ExecNode];
    }
}

def load_execution(
    node_ids: list[str],
    child_edges: list[tuple[str, str]],
) -> ExecStore {
    store = ExecStore();
    for nid in node_ids {
        nd = ExecNode(nid=nid);
        root ++> nd;
        store.nodes[nid] = nd;
    }
    for (parent, child) in child_edges {
        p = store.nodes.get(parent, None);
        c = store.nodes.get(child, None);
        if p is not None and c is not None { p +>:ChildExec:+> c; }
    }
    return store;
}

def count_nodes(store: ExecStore, `root: str) -> int {
    nd = store.nodes.get(`root, None);
    if nd is None { return 0; }
    w = nd spawn NodeCount(claimed={});
    return w.count;
}

def sync_depth(store: ExecStore, `root: str, max_depth: int) -> bool {
    nd = store.nodes.get(`root, None);
    if nd is None { return False; }
    w = nd spawn DepthCheck(max_depth=max_depth, ok=True, depth=0);
    return w.ok;
}

def max_observed_depth(store: ExecStore, `root: str) -> int {
    nd = store.nodes.get(`root, None);
    if nd is None { return -1; }
    w = nd spawn MaxDepth(claimed={}, depth=0, max_seen=0);
    return w.max_seen;
}

test "bounded sync tree walk" {
    store = load_execution(
        ["root", "lp1", "lp2", "leaf"],
        [("root", "lp1"), ("lp1", "lp2"), ("lp2", "leaf")],
    );
    assert count_nodes(store, "root") == 4;
    assert sync_depth(store, "root", 3) is True;
    assert sync_depth(store, "root", 2) is False;
    assert max_observed_depth(store, "root") == 3;
}
