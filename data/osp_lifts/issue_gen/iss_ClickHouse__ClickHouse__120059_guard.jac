"""ClickHouse/ClickHouse#120059 — recursive CTE GLOBAL join non-convergence."""

node TreeNode {
    has cid: str;
    has parent_id: str;
}

edge Child {}

obj TooDeepRecursionError : Exception {
    has limit: int;
}

walker CollectTree {
    has claimed: dict[str, bool] = {};
    has nodes: list[TreeNode] = [];
    can step with TreeNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.nodes.append(here);
        kids: list[TreeNode] = [here ->:Child:->][?:TreeNode];
        for ch in kids {
            visit :0: [ch];
        }
        print "collect " + here.cid;
    }
}

walker MainDemo {
    can run entry {
        gr = build_demo_graph();
        n = recursive_cte_count_local(gr);
        print "demo_local=" + str(n);
        disengage;
    }
}

def row_key(cid: str, depth: int) -> str {
    return cid + "|" + str(depth);
}

def parse_row(key: str) -> tuple[str, int] {
    bar = 0;
    i = 0;
    while i < len(key) {
        if key[i] == "|" { bar = i; }
        i = i + 1;
    }
    cid = key[0:bar];
    d = int(key[bar + 1:]);
    return (cid, d);
}

def working_has(working: list[str], key: str) -> bool {
    for wk in working {
        if wk == key { return True; }
    }
    return False;
}

def expand_local(nodes: list[TreeNode], working: list[str]) -> list[str] {
    out: list[str] = [];
    for wk in working {
        pr = parse_row(wk);
        st_id = pr[0];
        st_depth = pr[1];
        for nd in nodes {
            if nd.parent_id == st_id {
                nk = row_key(nd.cid, st_depth + 1);
                if not working_has(working, nk) and not working_has(out, nk) {
                    out.append(nk);
                }
            }
        }
    }
    return out;
}

def expand_global(nodes: list[TreeNode], frozen_st: list[str]) -> list[str] {
    out: list[str] = [];
    for wk in frozen_st {
        pr = parse_row(wk);
        st_id = pr[0];
        st_depth = pr[1];
        for nd in nodes {
            if nd.parent_id == st_id {
                nk = row_key(nd.cid, st_depth + 1);
                out.append(nk);
            }
        }
    }
    return out;
}

def build_demo_graph -> TreeNode {
    a = TreeNode(cid="a", parent_id="");
    b = TreeNode(cid="b", parent_id="a");
    c = TreeNode(cid="c", parent_id="b");
    root ++> a;
    root ++> b;
    root ++> c;
    a +>:Child:+> b;
    b +>:Child:+> c;
    return a;
}

def build_diamond_graph -> TreeNode {
    a = TreeNode(cid="a", parent_id="");
    b = TreeNode(cid="b", parent_id="a");
    c = TreeNode(cid="c", parent_id="a");
    d = TreeNode(cid="d", parent_id="b");
    root ++> a;
    root ++> b;
    root ++> c;
    root ++> d;
    a +>:Child:+> b;
    a +>:Child:+> c;
    b +>:Child:+> d;
    c +>:Child:+> d;
    return a;
}

def build_unknown_parent_graph -> TreeNode {
    z = TreeNode(cid="z", parent_id="missing");
    root ++> z;
    return z;
}

def recursive_cte_rows_local(graph_root: TreeNode) -> list[str] {
    w = graph_root spawn CollectTree(claimed={});
    print "local_rows_start";
    working: list[str] = [];
    for nd in w.nodes {
        working.append(row_key(nd.cid, 0));
    }
    changed = True;
    while changed {
        changed = False;
        new_rows = expand_local(w.nodes, working);
        for nr in new_rows {
            working.append(nr);
            changed = True;
        }
    }
    return sorted(working);
}

def recursive_cte_count_local(graph_root: TreeNode) -> int {
    rows = recursive_cte_rows_local(graph_root);
    print "local_count=" + str(len(rows));
    return len(rows);
}

def recursive_cte_count_global(graph_root: TreeNode, max_depth: int = 20) -> int {
    w = graph_root spawn CollectTree(claimed={});
    print "global_count_start";
    working: list[str] = [];
    frozen_st: list[str] = [];
    for nd in w.nodes {
        anchor = row_key(nd.cid, 0);
        working.append(anchor);
        frozen_st.append(anchor);
    }
    rnd = 0;
    while rnd < max_depth {
        new_rows = expand_global(w.nodes, frozen_st);
        if len(new_rows) == 0 {
            return len(working);
        }
        for nr in new_rows {
            working.append(nr);
        }
        rnd = rnd + 1;
    }
    print "global_too_deep";
    err = TooDeepRecursionError(limit=max_depth);
    raise err;
}

with entry {
    root spawn MainDemo;
}

test "local_demo_count_converges" {
    gr = build_demo_graph();
    assert recursive_cte_count_local(gr) == 6;
}

test "local_diamond_count_converges" {
    gr = build_diamond_graph();
    assert recursive_cte_count_local(gr) == 8;
}

test "local_unknown_parent_anchor_only" {
    gr = build_unknown_parent_graph();
    assert recursive_cte_count_local(gr) == 1;
}

test "local_rows_sorted_deterministic" {
    gr = build_demo_graph();
    rows = recursive_cte_rows_local(gr);
    assert rows == ["a|0", "b|0", "b|1", "c|0", "c|1", "c|2"];
}

test "global_unknown_parent_converges" {
    gr = build_unknown_parent_graph();
    assert recursive_cte_count_global(gr, 20) == 1;
}

test "global_demo_raises_too_deep" {
    caught = False;
    lim = 0;
    gr = build_demo_graph();
    try {
        recursive_cte_count_global(gr, 5);
    } except TooDeepRecursionError as e {
        caught = True;
        lim = e.limit;
    }
    assert caught;
    assert lim == 5;
}
