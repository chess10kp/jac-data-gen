# Paste full candidate .jac body above, then append:

test "kahn and dfs agree on dag" {
    g = TaskGraph();
    g.add_task("compile");
    g.add_task("link");
    g.add_task("test");
    g.add_task("lint");
    g.add_task("package");
    g.add_dependency("compile", "link");
    g.add_dependency("link", "test");
    g.add_dependency("compile", "lint");
    g.add_dependency("lint", "package");
    g.add_dependency("test", "package");
    k = g.topological_order_kahn();
    d = g.topological_order_dfs();
    assert k == d;
    assert k.index("compile") < k.index("link");
    assert not g.has_cycle();
}

test "cycle raises" {
    g = TaskGraph();
    g.add_task("a");
    g.add_task("b");
    g.add_dependency("a", "b");
    g.add_dependency("b", "a");
    assert g.has_cycle();
}

test "diamond adversarial order" {
    g = TaskGraph();
    g.add_task("root");
    g.add_task("left");
    g.add_task("right");
    g.add_task("join");
    g.add_dependency("root", "join");
    g.add_dependency("root", "left");
    g.add_dependency("root", "right");
    g.add_dependency("left", "join");
    g.add_dependency("right", "join");
    order = g.topological_order_kahn();
    assert order.index("root") < order.index("join");
    reach = g.reachable_from("root");
    assert sorted(reach) == ["join", "left", "right"];
}

test "unknown start is empty" {
    g = TaskGraph();
    g.add_task("only");
    assert g.reachable_from("missing") == [];
}
