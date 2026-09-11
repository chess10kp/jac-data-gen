"""Guard tests for iss_officeus-create__Hermes__346.jac"""

import from iss_officeus-create__Hermes__346 {
    BacklogStore,
    CycleError,
}

def _build_revenue_independent() -> BacklogStore {
    s = BacklogStore();
    s.add_task("lo", 10);
    s.add_task("hi", 50);
    s.add_task("mid", 30);
    return s;
}

def _build_acyclic_fan() -> BacklogStore {
    s = BacklogStore();
    for tid in ["a", "b", "c", "d"] {
        s.add_task(tid, 0);
    }
    s.add_depends("b", "a");
    s.add_depends("c", "a");
    s.add_depends("d", "b");
    s.add_depends("d", "c");
    return s;
}

def _build_diamond_adversarial() -> BacklogStore {
    s = BacklogStore();
    s.add_task("root", 0);
    s.add_task("left", 10);
    s.add_task("right", 20);
    s.add_task("join", 5);
    s.add_depends("join", "left");
    s.add_depends("join", "right");
    s.add_depends("left", "root");
    s.add_depends("right", "root");
    return s;
}

def _build_cycle() -> BacklogStore {
    s = BacklogStore();
    for tid in ["x", "y", "z"] {
        s.add_task(tid, 0);
    }
    s.add_depends("y", "x");
    s.add_depends("z", "y");
    s.add_depends("x", "z");
    return s;
}

test "revenue-first independent order" {
    s = _build_revenue_independent();
    assert s.find_cycle() == [];
    assert s.execution_order() == ["hi", "mid", "lo"];
}

test "acyclic fan execution order" {
    s = _build_acyclic_fan();
    assert s.find_cycle() == [];
    assert s.execution_order() == ["a", "b", "c", "d"];
    assert s.reachable_from("a") == ["a", "b", "c", "d"];
}

test "diamond adversarial revenue tie-break and reach" {
    s = _build_diamond_adversarial();
    assert s.find_cycle() == [];
    assert s.execution_order() == ["root", "right", "left", "join"];
    assert s.reachable_from("root") == ["join", "left", "root", "right"];
}

test "cycle detected and execution_order raises" {
    s = _build_cycle();
    cyc = s.find_cycle();
    assert len(cyc) >= 2;
    assert sorted(set(cyc)) == ["x", "y", "z"];
    try {
        s.execution_order();
        assert False, "expected CycleError";
    } except CycleError {
        assert True;
    }
}

test "unknown id KeyError" {
    s = _build_acyclic_fan();
    try {
        s.add_depends("nope", "a");
        assert False, "expected KeyError";
    } except KeyError {
        assert True;
    }
}

test "duplicate task ValueError" {
    s = _build_acyclic_fan();
    try {
        s.add_task("a", 99);
        assert False, "expected ValueError";
    } except ValueError {
        assert True;
    }
}

test "missing start returns empty reach" {
    s = _build_acyclic_fan();
    assert s.reachable_from("missing") == [];
}
