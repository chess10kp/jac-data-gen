# (paste .jac body above — abbreviated: duplicate iss_Dtronix__Quarry__331.jac)

test "cte chain sorted context" {
    r = build_registry();
    r.register_with("base", []);
    r.register_with("step1", ["base"]);
    r.register_with("step2", ["step1", "base"]);
    assert r.column_context("step2") == ["base", "step1", "step2"];
}

test "diamond adversarial revisit" {
    r = build_registry();
    r.register_with("top", []);
    r.register_with("l", ["top"]);
    r.register_with("r", ["top"]);
    r.register_with("bot", ["l", "r", "top"]);
    assert sorted(r.reachable_ctes("bot")) == ["bot", "l", "r", "top"];
}

test "unknown ref flag" {
    r = build_registry();
    r.register_with("a", ["missing"]);
    assert r.has_unknown_ref("a") is True;
}
