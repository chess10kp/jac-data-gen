"""Guard tests for iss_jordan-thirkle__ai-game-development-pipeline__305.jac"""

import from iss_jordan-thirkle__ai-game-development-pipeline__305 {
    PipelineGraph,
}

def _build_perf_pipeline() -> PipelineGraph {
    g = PipelineGraph();
    for s in [
        "bundle-three",
        "vite-serve",
        "headless-browser",
        "perf-harness",
        "metrics-rollup",
    ] {
        g.add_stage(s);
    }
    g.add_dependency("headless-browser", "bundle-three");
    g.add_dependency("headless-browser", "vite-serve");
    g.add_dependency("perf-harness", "headless-browser");
    g.add_dependency("metrics-rollup", "perf-harness");
    return g;
}

def _build_cycle() -> PipelineGraph {
    g = PipelineGraph();
    for s in ["alpha", "beta", "gamma"] {
        g.add_stage(s);
    }
    g.add_dependency("beta", "alpha");
    g.add_dependency("gamma", "beta");
    g.add_dependency("alpha", "gamma");
    return g;
}

def _build_diamond() -> PipelineGraph {
    g = PipelineGraph();
    for s in ["root", "left", "right", "join"] {
        g.add_stage(s);
    }
    # adversarial insertion order
    g.add_dependency("join", "left");
    g.add_dependency("join", "right");
    g.add_dependency("left", "root");
    g.add_dependency("right", "root");
    return g;
}

test "acyclic perf pipeline downstream" {
    g = _build_perf_pipeline();
    assert g.find_cycle() == [];
    assert g.downstream("bundle-three") == [
        "headless-browser",
        "metrics-rollup",
        "perf-harness",
    ];
    assert g.downstream("headless-browser") == ["metrics-rollup", "perf-harness"];
}

test "cycle detected multiset" {
    g = _build_cycle();
    cyc = g.find_cycle();
    assert len(cyc) >= 2;
    assert sorted(set(cyc)) == ["alpha", "beta", "gamma"];
}

test "diamond adversarial downstream once" {
    g = _build_diamond();
    assert g.find_cycle() == [];
    assert g.downstream("root") == ["join", "left", "right"];
    assert g.downstream("left") == ["join"];
    assert g.downstream("right") == ["join"];
}

test "unknown stage empty downstream" {
    g = _build_perf_pipeline();
    assert g.downstream("missing-stage") == [];
}

test "unknown dependency KeyError" {
    g = _build_perf_pipeline();
    try {
        g.add_dependency("nope", "bundle-three");
        assert False;
    } except KeyError {
        assert True;
    }
}
