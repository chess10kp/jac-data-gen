"""Guard tests for iss_nicpadilla__whisperIMEplus__13.jac"""

import from iss_nicpadilla__whisperIMEplus__13 {
    RoadmapStore,
    CycleError,
}

def _build_phase_priority_independent() -> RoadmapStore {
    s = RoadmapStore();
    s.add_item("ci", 0, 100);
    s.add_item("vad", 1, 90);
    s.add_item("buf", 1, 70);
    return s;
}

def _build_fork_subset() -> RoadmapStore {
    s = RoadmapStore();
    s.add_item("10", 0, 100);
    s.add_item("1", 1, 90);
    s.add_item("5", 1, 70);
    s.add_item("4", 2, 60);
    s.add_item("3", 2, 50);
    s.add_depends("4", "5");
    s.add_depends("3", "4");
    s.add_depends("3", "5");
    return s;
}

def _build_diamond_adversarial() -> RoadmapStore {
    s = RoadmapStore();
    s.add_item("root", 0, 0);
    s.add_item("left", 1, 10);
    s.add_item("right", 1, 20);
    s.add_item("join", 2, 5);
    s.add_depends("join", "left");
    s.add_depends("join", "right");
    s.add_depends("left", "root");
    s.add_depends("right", "root");
    return s;
}

def _build_cycle() -> RoadmapStore {
    s = RoadmapStore();
    for iid in ["x", "y", "z"] {
        s.add_item(iid, 1, 0);
    }
    s.add_depends("y", "x");
    s.add_depends("z", "y");
    s.add_depends("x", "z");
    return s;
}

test "phase-priority independent order" {
    s = _build_phase_priority_independent();
    assert s.find_cycle() == [];
    assert s.implementation_order() == ["ci", "vad", "buf"];
}

test "fork subset implementation order and reach" {
    s = _build_fork_subset();
    assert s.find_cycle() == [];
    assert s.implementation_order() == ["10", "1", "5", "4", "3"];
    assert s.reachable_from("5") == ["3", "4", "5"];
}

test "diamond adversarial reach closure" {
    s = _build_diamond_adversarial();
    assert s.find_cycle() == [];
    assert s.implementation_order() == ["root", "right", "left", "join"];
    assert s.reachable_from("root") == ["join", "left", "root", "right"];
}

test "cycle detected and implementation_order raises" {
    s = _build_cycle();
    cyc = s.find_cycle();
    assert len(cyc) >= 2;
    assert sorted(set(cyc)) == ["x", "y", "z"];
    try {
        s.implementation_order();
        assert False, "expected CycleError";
    } except CycleError {
        assert True;
    }
}

test "unknown id KeyError" {
    s = _build_fork_subset();
    try {
        s.add_depends("nope", "1");
        assert False, "expected KeyError";
    } except KeyError {
        assert True;
    }
}

test "duplicate item ValueError" {
    s = _build_fork_subset();
    try {
        s.add_item("1", 1, 99);
        assert False, "expected ValueError";
    } except ValueError {
        assert True;
    }
}

test "missing start returns empty reach" {
    s = _build_fork_subset();
    assert s.reachable_from("missing") == [];
}
