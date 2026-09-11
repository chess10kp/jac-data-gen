"""Guard tests for iss_dunay2__dvt__2594.jac"""

import from iss_dunay2__dvt__2594 {
    CardPipeline,
    CycleError,
}

def _build_acyclic() -> CardPipeline {
    p = CardPipeline();
    for c in ["read", "filter", "project", "write"] {
        p.add_card(c);
    }
    p.depends("filter", "read");
    p.depends("project", "read");
    p.depends("write", "filter");
    p.depends("write", "project");
    return p;
}

def _build_cycle() -> CardPipeline {
    p = CardPipeline();
    for c in ["a", "b", "c"] {
        p.add_card(c);
    }
    p.depends("b", "a");
    p.depends("c", "b");
    p.depends("a", "c");
    return p;
}

def _build_diamond() -> CardPipeline {
    p = CardPipeline();
    for c in ["root", "left", "right", "join"] {
        p.add_card(c);
    }
    p.depends("join", "left");
    p.depends("join", "right");
    p.depends("left", "root");
    p.depends("right", "root");
    return p;
}

test "acyclic linearize and downstream" {
    p = _build_acyclic();
    assert p.linearize() == ["read", "filter", "project", "write"];
    assert p.downstream("read") == ["filter", "project", "read", "write"];
}

test "cycle raises CycleError on linearize" {
    p = _build_cycle();
    try {
        p.linearize();
        assert False, "expected CycleError";
    } except CycleError {
        assert True;
    }
}

test "diamond adversarial closure" {
    p = _build_diamond();
    assert p.linearize() == ["root", "left", "right", "join"];
    assert p.downstream("root") == ["join", "left", "right", "root"];
}

test "unknown id tolerance" {
    p = _build_acyclic();
    assert p.downstream("missing") == [];
    try {
        p.depends("missing", "read");
        assert False, "expected KeyError";
    } except KeyError {
        assert True;
    }
}
