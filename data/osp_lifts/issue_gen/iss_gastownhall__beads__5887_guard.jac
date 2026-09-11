"""Guard tests for iss_gastownhall__beads__5887.jac"""

import from iss_gastownhall__beads__5887 {
    build_dependency_graph,
    has_cycle,
    render_tree,
    render_tree_naive,
    all_nodes,
}

test "naive render revisits on diamond fan-in" {
    store = build_dependency_graph([("d", "a"), ("d", "b"), ("a", "c"), ("b", "c")]);
    got = render_tree_naive(store, "d");
    assert got == ["d", "a", "c", "b", "c"];
}

test "safe render once-only on diamond" {
    store = build_dependency_graph([("d", "a"), ("d", "b"), ("a", "c"), ("b", "c")]);
    assert not has_cycle(store);
    assert render_tree(store, "d") == ["d", "a", "c", "b"];
}

test "cycle blocks safe render" {
    store = build_dependency_graph([("a", "b"), ("b", "c"), ("c", "a")]);
    assert has_cycle(store);
    raised = False;
    try {
        render_tree(store, "a");
    } except ValueError {
        raised = True;
    }
    assert raised;
}

test "tree render happy path" {
    store = build_dependency_graph([("r", "a"), ("r", "b"), ("a", "c")]);
    assert render_tree(store, "r") == ["r", "a", "c", "b"];
    assert all_nodes(store) == ["a", "b", "c", "r"];
}
