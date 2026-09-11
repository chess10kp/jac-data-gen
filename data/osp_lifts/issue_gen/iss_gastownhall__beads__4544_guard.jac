"""Guard tests for iss_gastownhall__beads__4544.jac"""

import from iss_gastownhall__beads__4544 {
    build_dependency_graph,
    has_cycle,
    has_cycle_naive,
    all_nodes,
}

test "cycle detected naive and fast" {
    store = build_dependency_graph([("a", "b"), ("b", "c"), ("c", "a")]);
    assert has_cycle_naive(store);
    assert has_cycle(store);
}

test "acyclic diamond fan-in adversarial order" {
    # d->a, d->b, a->c, b->c — revisit fires before deeper first-visits
    store = build_dependency_graph([("d", "a"), ("d", "b"), ("a", "c"), ("b", "c")]);
    assert not has_cycle_naive(store);
    assert not has_cycle(store);
    assert all_nodes(store) == ["a", "b", "c", "d"];
}

test "empty graph" {
    store = build_dependency_graph([]);
    assert not has_cycle_naive(store);
    assert not has_cycle(store);
    assert all_nodes(store) == [];
}

test "linear chain acyclic" {
    store = build_dependency_graph([("x", "y"), ("y", "z")]);
    assert not has_cycle_naive(store);
    assert not has_cycle(store);
    assert all_nodes(store) == ["x", "y", "z"];
}
