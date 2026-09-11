# Append hidden tests to candidate .jac content (same as iss_jaseci-labs__jac__8562.jac)

test "cycle abc once-per-node" {
    h = GraphHandle();
    h.seed_cycle_abc();
    assert h.count_reachable_dfs("a") == 3;
    assert h.count_reachable_bfs("a") == 3;
    assert h.reachable_nodes("a") == ["a", "b", "c"];
}

test "diamond reachability" {
    h = GraphHandle();
    h.seed_diamond();
    assert h.count_reachable_dfs("s") == 4;
    assert h.reachable_nodes("s") == ["l", "r", "s", "t"];
}

test "unknown start tolerant" {
    h = GraphHandle();
    h.seed_cycle_abc();
    assert h.count_reachable_dfs("missing") == 0;
    assert h.reachable_nodes("missing") == [];
}

# Adversarial-order diamond: insert edges so revisit fires before deeper first-visits
test "adversarial diamond revisit ordering" {
    h = GraphHandle();
    # Build s->l->t, s->r->t with t reached early via r before l subtree completes
    s = Item(name="s");
    l = Item(name="l");
    r = Item(name="r");
    t = Item(name="t");
    root ++> s;
    s +>:Link:+> r;
    r +>:Link:+> t;
    s +>:Link:+> l;
    l +>:Link:+> t;
    w = root spawn ReachCounter(start_name="s", use_bfs=True);
    assert w.count == 4;
}
