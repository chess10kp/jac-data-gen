# iss_tree-sitter-perl__perl-lsp__120.jac
# tree-sitter-perl/perl-lsp#120 — Session B iterative builder walk (depth-gated CST collect)

node CstNode {
    has cid: str;
    has kind: str;
    has depth: int = 0;
}

edge Child {}

walker BuilderW {
    has claimed: dict[str, bool] = {};
    has depth_limit: int = 0;
    has kinds: list[str] = [];

    can walk with CstNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.depth <= self.depth_limit {
            self.kinds.append(here.kind);
        }
        log: list[str] = [];
        log.append("builder");
        log.append(here.cid);
        depth_s: str = f"{here.depth}";
        log.append(depth_s);
        print log;
        if here.depth >= self.depth_limit {
            disengage;
        }
        kids: list[CstNode] = [here ->:Child:->][?:CstNode];
        ri: int = len(kids) - 1;
        while ri >= 0 {
            visit :0: [kids[ri]];
            ri -= 1;
        }
    }
}

walker OrderW {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can walk with CstNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        log: list[str] = [];
        log.append("order");
        log.append(here.cid);
        print log;
        kids: list[CstNode] = [here ->:Child:->][?:CstNode];
        ri: int = len(kids) - 1;
        while ri >= 0 {
            visit :0: [kids[ri]];
            ri -= 1;
        }
    }
}

walker MarkPruneW {
    has claimed: dict[str, bool] = {};
    has drop_kinds: dict[str, bool] = {};
    has mark_nodes: list[CstNode] = [];

    can walk with CstNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.kind in self.drop_kinds {
            self.mark_nodes.append(here);
        }
        log: list[str] = [];
        log.append("mark");
        log.append(here.cid);
        print log;
        kids: list[CstNode] = [here ->:Child:->][?:CstNode];
        for ch in kids {
            visit [ch];
        }
    }
}

def mk_drop_map(kinds: list[str]) -> dict[str, bool] {
    out: dict[str, bool] = {};
    for k in kinds {
        out[k] = True;
    }
    return out;
}

def builder_index(graph_root: CstNode, depth_limit: int) -> list[str] {
    w = graph_root spawn BuilderW(depth_limit=depth_limit, claimed={});
    return w.kinds;
}

def builder_order(graph_root: CstNode) -> list[str] {
    w = graph_root spawn OrderW(claimed={});
    return w.order;
}

def find_by_cid(graph_root: CstNode, target_cid: str) -> str | None {
    w = graph_root spawn OrderW(claimed={});
    for cid in w.order {
        if cid == target_cid {
            return cid;
        }
    }
    return None;
}

def cascade_prune_kinds(graph_root: CstNode, kinds: list[str] | None = None) -> list[str] {
    use_kinds: list[str] = [];
    if kinds is not None {
        use_kinds = kinds;
    }
    dk = mk_drop_map(use_kinds);
    w = graph_root spawn MarkPruneW(drop_kinds=dk, claimed={});
    pruned: list[str] = [];
    for nd in w.mark_nodes {
        pruned.append(nd.cid);
    }
    pruned = sorted(pruned);
    for nd in w.mark_nodes {
        destroy nd;
    }
    return pruned;
}

def make_cst_fixture() -> CstNode {
    graph_root = CstNode(cid="r", kind="Root", depth=0);
    root ++> graph_root;
    a = CstNode(cid="a", kind="Stmt", depth=1);
    b = CstNode(cid="b", kind="Stmt", depth=1);
    leaf = CstNode(cid="l", kind="Leaf", depth=2);
    graph_root +>:Child:+> a;
    graph_root +>:Child:+> b;
    a +>:Child:+> leaf;
    return graph_root;
}

test "builder_index_depth_gate" {
    g = make_cst_fixture();
    got = builder_index(g, 1);
    assert got == ["Root", "Stmt", "Stmt"];
}

test "builder_order_preorder" {
    g = make_cst_fixture();
    got = builder_order(g);
    assert got == ["r", "a", "l", "b"];
}

test "find_by_cid_hit_and_miss" {
    g = make_cst_fixture();
    assert find_by_cid(g, "l") == "l";
    assert find_by_cid(g, "missing") is None;
}

test "cascade_prune_kinds_sorted" {
    g = make_cst_fixture();
    got = cascade_prune_kinds(g, ["Stmt"]);
    assert got == ["a", "b"];
}

test "cascade_prune_kinds_empty_drop" {
    g = make_cst_fixture();
    got = cascade_prune_kinds(g, None);
    assert got == [];
}
