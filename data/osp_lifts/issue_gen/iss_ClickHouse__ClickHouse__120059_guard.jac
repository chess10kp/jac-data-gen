"""Recursive CTE row accumulation over a parent/child tree — ClickHouse/ClickHouse#120059."""

node TreeNode {
    has id: str;
    has parent_id: str;
}

edge Child {}

obj TreeGraph {
    has nodes: list[TreeNode] = [];
    has by_id: dict[str, TreeNode] = {};
}

exception TooDeepRecursionError {
    has limit: int = 0;
}

def load_tree(rows: list[tuple[str, str]]) -> TreeGraph {
    g = TreeGraph();
    for pair in rows {
        nid = pair[0];
        pid = pair[1];
        if nid not in g.by_id {
            nd = TreeNode(id=nid, parent_id=pid);
            g.by_id[nid] = nd;
            g.nodes.append(nd);
            root ++> nd;
        }
    }
    for pair in rows {
        nid = pair[0];
        pid = pair[1];
        if pid != "" and pid in g.by_id {
            parent = g.by_id[pid];
            child = g.by_id[nid];
            parent +>:Child:+> child;
        }
    }
    return g;
}

walker CollectBase {
    has rows: list[tuple[str, str, int]] = [];
    has claimed: dict[str, bool] = {};

    can walk with TreeNode entry {
        if here.id in self.claimed {
            skip;
        }
        self.claimed[here.id] = True;
        self.rows.append((here.id, here.parent_id, 0));
        print("base", here.id, 0);
        for ch in [here ->:Child:->][?:TreeNode] {
            visit :0: [ch];
        }
    }
}

walker Reachable {
    has found: list[str] = [];
    has claimed: dict[str, bool] = {};

    can walk with TreeNode entry {
        if here.id in self.claimed {
            skip;
        }
        self.claimed[here.id] = True;
        self.found.append(here.id);
        print("visit", here.id);
        for ch in [here ->:Child:->][?:TreeNode] {
            visit :0: [ch];
        }
    }
}

def _base_rows(g: TreeGraph) -> list[tuple[str, str, int]] {
    empty: list[tuple[str, str, int]] = [];
    if len(g.nodes) == 0 {
        return empty;
    }
    start = g.nodes[0];
    w = start spawn CollectBase(claimed={});
    return w.rows;
}

def _sort_rows(rows: list[tuple[str, str, int]]) -> list[tuple[str, str, int]] {
    keys: list[tuple[int, str, int]] = [];
    i = 0;
    while i < len(rows) {
        r = rows[i];
        keys.append((r[2], r[0], i));
        i += 1;
    }
    keys = sorted(keys);
    out: list[tuple[str, str, int]] = [];
    for k in keys {
        out.append(rows[k[2]]);
    }
    return out;
}

def recursive_cte_rows(
    g: TreeGraph,
    prefer_global: bool = False,
    max_iterations: int = 20,
) -> list[tuple[str, str, int]] {
    accumulated: list[tuple[str, str, int]] = _base_rows(g);
    frozen_global: list[tuple[str, str, int]] = [];
    has_frozen = False;
    iter_count = 0;
    while True {
        new_rows: list[tuple[str, str, int]] = [];
        if prefer_global and has_frozen {
            for fr in frozen_global {
                new_rows.append(fr);
            }
        } else {
            join_set: list[tuple[str, str, int]] = accumulated;
            for st_row in join_set {
                st_id = st_row[0];
                st_depth = st_row[2];
                for nd in g.nodes {
                    if nd.parent_id == st_id {
                        cand: tuple[str, str, int] = (nd.id, nd.parent_id, st_depth + 1);
                        is_dup = False;
                        for ex in accumulated {
                            if ex[0] == cand[0] and ex[2] == cand[2] {
                                is_dup = True;
                            }
                        }
                        for ex in new_rows {
                            if ex[0] == cand[0] and ex[2] == cand[2] {
                                is_dup = True;
                            }
                        }
                        if not is_dup {
                            new_rows.append(cand);
                        }
                    }
                }
            }
        }
        if len(new_rows) == 0 {
            break;
        }
        if iter_count >= max_iterations {
            raise TooDeepRecursionError(limit=max_iterations);
        }
        for nr in new_rows {
            accumulated.append(nr);
        }
        if prefer_global and not has_frozen {
            depth1: list[tuple[str, str, int]] = [];
            for acc in accumulated {
                if acc[2] == 1 {
                    depth1.append(acc);
                }
            }
            if len(depth1) > 0 {
                frozen_global = depth1;
                has_frozen = True;
            }
        }
        iter_count += 1;
    }
    return _sort_rows(accumulated);
}

def recursive_cte_count(
    g: TreeGraph,
    prefer_global: bool = False,
    max_iterations: int = 20,
) -> int {
    rows = recursive_cte_rows(g, prefer_global, max_iterations);
    return len(rows);
}

test "empty_tree_rows" {
    empty_rows: list[tuple[str, str]] = [];
    g = load_tree(empty_rows);
    got = recursive_cte_rows(g);
    exp: list[tuple[str, str, int]] = [];
    assert got == exp;
}

test "linear_chain_converges" {
    rows: list[tuple[str, str]] = [("a", ""), ("b", "a"), ("c", "b")];
    g = load_tree(rows);
    got = recursive_cte_rows(g);
    exp: list[tuple[str, str, int]] = [("a", "", 0), ("b", "a", 1), ("c", "b", 2)];
    assert got == exp;
}

test "count_matches_rows" {
    rows: list[tuple[str, str]] = [("a", ""), ("b", "a"), ("c", "b")];
    g = load_tree(rows);
    got_rows = recursive_cte_rows(g);
    got_count = recursive_cte_count(g);
    assert got_count == len(got_rows);
}

test "prefer_global_false_same_as_default" {
    rows: list[tuple[str, str]] = [("a", ""), ("b", "a"), ("c", "b")];
    g = load_tree(rows);
    got_default = recursive_cte_rows(g);
    got_local = recursive_cte_rows(g, False, 20);
    assert got_default == got_local;
}

test "prefer_global_raises_too_deep" {
    rows: list[tuple[str, str]] = [("a", ""), ("b", "a")];
    g = load_tree(rows);
    caught = False;
    limit_hit = 0;
    try {
        recursive_cte_rows(g, True, 2);
    } except TooDeepRecursionError as err {
        caught = True;
        limit_hit = err.limit;
    }
    assert caught;
    assert limit_hit == 2;
}

test "prefer_global_nonconvergent_grows_past_base" {
    rows: list[tuple[str, str]] = [("a", ""), ("b", "a")];
    g = load_tree(rows);
    got = recursive_cte_rows(g, True, 5);
    assert len(got) > 2;
}
