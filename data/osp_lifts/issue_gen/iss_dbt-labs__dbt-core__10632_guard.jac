"""dbt-labs/dbt-core#10632 — candidate + hidden guards."""

# Paste full .jac content above, then append tests:

test "priority among roots" {
    g = ModelDag();
    g.add_model("quick_a");
    g.add_model("quick_b");
    g.add_model("long_run", execution_order=1);
    g.add_model("downstream");
    g.add_ref("downstream", "long_run");
    g.add_ref("downstream", "quick_a");
    assert g.ready_models(set()) == ["long_run", "quick_a", "quick_b"];
    assert g.execution_order() == [
        "long_run", "quick_a", "quick_b", "downstream",
    ];
}

test "diamond adversarial priority" {
    g = ModelDag();
    g.add_model("join", execution_order=5);
    g.add_model("root");
    g.add_model("left", execution_order=2);
    g.add_model("right", execution_order=1);
    g.add_ref("left", "root");
    g.add_ref("right", "root");
    g.add_ref("join", "left");
    g.add_ref("join", "right");
    assert g.execution_order() == ["root", "right", "left", "join"];
}

test "cycle returns none" {
    g = ModelDag();
    g.add_model("a");
    g.add_model("b");
    g.add_model("c");
    g.add_ref("b", "a");
    g.add_ref("c", "b");
    g.add_ref("a", "c");
    assert g.has_cycle() is True;
    assert g.execution_order() is None;
}

test "unknown ref KeyError" {
    g = ModelDag();
    g.add_model("m");
    try {
        g.add_ref("nope", "m");
        assert False;
    } except KeyError {
        # expected
    }
}
