# paste full contents of iss_kristtst01__codetrace__47.jac above, then:

test "dag topo and ancestors" {
    g = TaskDag();
    for t in ["a", "b", "c", "d", "e"] {
        g.add_task(t);
    }
    g.add_dependency("b", "a");
    g.add_dependency("c", "a");
    g.add_dependency("d", "b");
    g.add_dependency("d", "c");
    g.add_dependency("e", "d");
    assert g.has_cycle() is False;
    order = g.topological_order();
    assert order.index("a") < order.index("b");
    assert order.index("a") < order.index("c");
    assert order.index("b") < order.index("d");
    assert order.index("c") < order.index("d");
    assert order.index("d") < order.index("e");
    assert g.ancestors("d") == ["a", "b", "c"];
}

test "cycle detected" {
    g = TaskDag();
    for t in ["x", "y", "z"] {
        g.add_task(t);
    }
    g.add_dependency("y", "x");
    g.add_dependency("z", "y");
    g.add_dependency("x", "z");
    assert g.has_cycle() is True;
    try {
        g.topological_order();
        assert False, "expected CycleError";
    } except CycleError {
        assert True;
    }
}

test "diamond ancestors multiset" {
    g = TaskDag();
    for t in ["p1", "p2", "mid", "leaf"] {
        g.add_task(t);
    }
    g.add_dependency("mid", "p1");
    g.add_dependency("mid", "p2");
    g.add_dependency("leaf", "mid");
    assert sorted(g.ancestors("leaf")) == ["mid", "p1", "p2"];
}

test "unknown task KeyError" {
    g = TaskDag();
    g.add_task("a");
    try {
        g.add_dependency("missing", "a");
        assert False, "expected KeyError";
    } except KeyError {
        assert True;
    }
}
