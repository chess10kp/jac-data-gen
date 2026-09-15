"""ClickHouse/ClickHouse#115799 — recursive CTE self-reference under parallel replicas."""

node CteGraph {
    has table_name: str;
}

node TableRow {
    has n: int;
    has p: int;
}

edge ParentLink {}

walker CteStep {
    has frontier: dict[int, bool] = {};
    has discovered: dict[int, bool] = {};
    has claimed: dict[str, bool] = {};

    can begin with CteGraph entry {
        root spawn CteStep;
        print("cte-step", here.table_name);
        visit [here ->][?:TableRow];
    }

    can scan with TableRow entry {
        key = str(here.n);
        if key in self.claimed {
            skip;
        }
        self.claimed[key] = True;
        if here.p in self.frontier {
            self.discovered[here.n] = True;
            print("cte-hit", here.n);
        }
        visit :0: [here ->][?:TableRow];
    }
}

walker RecursiveRefCheck {
    has claimed: dict[str, bool] = {};
    has has_self_ref: bool = False;

    can begin with CteGraph entry {
        root spawn RecursiveRefCheck;
        print("ref-check", here.table_name);
        visit [here ->][?:TableRow];
    }

    can scan with TableRow entry {
        key = str(here.n);
        if key in self.claimed {
            skip;
        }
        self.claimed[key] = True;
        if here.n > 1 {
            parents: list[TableRow] = [here ->:ParentLink:->][?:TableRow];
            if len(parents) > 0 {
                self.has_self_ref = True;
            }
        }
        print("ref-row", here.n, self.has_self_ref);
        visit [here ->][?:TableRow];
    }
}

walker ClosureWalk {
    has graph: CteGraph;
    has claimed: dict[str, bool] = {};
    has order: list[int] = [];

    can begin with TableRow entry {
        root spawn ClosureWalk;
        key = str(here.n);
        if key in self.claimed {
            skip;
        }
        self.claimed[key] = True;
        self.order.append(here.n);
        print("closure", here.n);
        rows: list[TableRow] = [self.graph ->][?:TableRow];
        kids: list[TableRow] = [];
        for row in rows {
            if row.p == here.n {
                kids.append(row);
            }
        }
        visit :0: kids;
    }
}

def build_pr_cte_table -> CteGraph {
    g = CteGraph(table_name="t_pr_cte");
    root ++> g;
    r1 = TableRow(n=1, p=0);
    r2 = TableRow(n=2, p=1);
    r3 = TableRow(n=3, p=2);
    g ++> r1;
    g ++> r2;
    g ++> r3;
    r2 +>:ParentLink:+> r1;
    r3 +>:ParentLink:+> r2;
    w = g spawn RecursiveRefCheck(claimed={});
    print("built", g.table_name, w.has_self_ref);
    return g;
}

def build_diamond_table -> CteGraph {
    g = CteGraph(table_name="diamond");
    root ++> g;
    r1 = TableRow(n=1, p=0);
    r4 = TableRow(n=4, p=2);
    r2 = TableRow(n=2, p=1);
    r3 = TableRow(n=3, p=1);
    g ++> r1;
    g ++> r4;
    g ++> r2;
    g ++> r3;
    r2 +>:ParentLink:+> r1;
    r3 +>:ParentLink:+> r1;
    r4 +>:ParentLink:+> r2;
    r4 +>:ParentLink:+> r3;
    print("built", g.table_name);
    return g;
}

def expand_recursive_union(graph_root: CteGraph, max_depth: int = 1000) -> list[int] {
    accumulated: dict[int, bool] = {};
    accumulated[1] = True;
    frontier: dict[int, bool] = {};
    frontier[1] = True;
    depth = 0;
    while len(frontier) > 0 and depth < max_depth {
        depth = depth + 1;
        w = graph_root spawn CteStep(frontier=frontier, claimed={});
        next_frontier: dict[int, bool] = {};
        for nk in w.discovered {
            if nk not in accumulated {
                accumulated[nk] = True;
                next_frontier[nk] = True;
            }
        }
        if len(next_frontier) == 0 {
            break;
        }
        frontier = next_frontier;
    }
    keys: list[int] = [];
    for k in accumulated {
        keys.append(k);
    }
    return sorted(keys);
}

def expand_broken_parallel(graph_root: CteGraph, max_depth: int = 1000) -> list[int] {
    accumulated: dict[int, bool] = {};
    accumulated[1] = True;
    depth = 0;
    while depth < max_depth {
        depth = depth + 1;
        stuck_frontier: dict[int, bool] = {};
        stuck_frontier[1] = True;
        w = graph_root spawn CteStep(frontier=stuck_frontier, claimed={});
        added = False;
        for nk in w.discovered {
            if nk not in accumulated {
                accumulated[nk] = True;
                added = True;
            }
        }
        if not added {
            break;
        }
    }
    keys: list[int] = [];
    for k in accumulated {
        keys.append(k);
    }
    return sorted(keys);
}

def count_in_filter(graph_root: CteGraph, keys: list[int]) -> int {
    allow: dict[int, bool] = {};
    for k in keys {
        allow[k] = True;
    }
    total = 0;
    rows: list[TableRow] = [];
    for linked in [graph_root ->] {
        if linked is TableRow {
            rows.append(linked);
        }
    }
    for row in rows {
        if row.n in allow {
            total = total + 1;
        }
    }
    return total;
}

def union_is_recursive(graph_root: CteGraph) -> bool {
    w = graph_root spawn RecursiveRefCheck(claimed={});
    return w.has_self_ref;
}

def filter_known_keys(graph_root: CteGraph, keys: list[int]) -> list[int] {
    known: dict[int, bool] = {};
    rows: list[TableRow] = [];
    for linked in [graph_root ->] {
        if linked is TableRow {
            rows.append(linked);
        }
    }
    for row in rows {
        known[row.n] = True;
    }
    out: list[int] = [];
    for k in keys {
        if k in known {
            out.append(k);
        }
    }
    return sorted(out);
}

def walk_closure_order(graph_root: CteGraph) -> list[int] {
    rows: list[TableRow] = [];
    for linked in [graph_root ->] {
        if linked is TableRow {
            rows.append(linked);
        }
    }
    anchor = rows[0];
    for row in rows {
        if row.n == 1 {
            anchor = row;
        }
    }
    w = anchor spawn ClosureWalk(graph=graph_root, claimed={}, order=[]);
    return w.order;
}

test "expand_recursive_union_linear" {
    g = build_pr_cte_table;
    got = expand_recursive_union(g);
    assert got == [1, 2, 3];;
}

test "expand_broken_parallel_stuck" {
    g = build_pr_cte_table;
    got = expand_broken_parallel(g);
    assert got == [1, 2];;
}

test "union_is_recursive_detects_parent_links" {
    g = build_pr_cte_table;
    assert union_is_recursive(g) == True;;
}

test "filter_known_keys_sorted_subset" {
    g = build_pr_cte_table;
    got = filter_known_keys(g, [2, 4, 3]);
    assert got == [2, 3];;
}

test "walk_closure_order_diamond_adversarial" {
    g = build_diamond_table;
    got = walk_closure_order(g);
    assert got == [1, 3, 2, 4];;
}

test "count_in_filter_matches_keys" {
    g = build_pr_cte_table;
    assert count_in_filter(g, [1, 2, 3]) == 3;;
}
