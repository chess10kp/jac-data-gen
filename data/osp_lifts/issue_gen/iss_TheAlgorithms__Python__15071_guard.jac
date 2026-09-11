"""Guard: TheAlgorithms/Python#15071."""
# Paste full .jac candidate, then:

test "dense topo" {
    g = load_graph([(0, 1), (1, 2), (0, 2)]);
    assert topological_sort(g) == [0, 1, 2];
    assert reachable_from(g, 0) == [0, 1, 2];
}

test "sparse ids safe in jac" {
    g = load_graph([(0, 5), (5, 10)]);
    assert topological_sort(g) == [0, 5, 10];
}

test "diamond adversarial" {
    g = load_graph([(0, 1), (0, 2), (1, 3), (2, 3)]);
    assert reachable_from(g, 0) == [0, 1, 2, 3];
}
