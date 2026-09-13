node Project { has pid: str; }
node Module { has mid: str; has coverage: float = 0.0; has threshold: float = 0.0; }
node Suite { has sid: str; has runner: str; }
node Step { has name: str; }
edge Contains {}
edge Depends {}
edge Covers {}
edge Next {}

walker AllModules {
    has claimed: dict[str, bool] = {};
    has nodes: list[Module] = [];
    can start with Project entry {
        print(here.pid);
        for nxt in [here ->:Contains:->][?:Module] {
            visit :0: [nxt];
        }
    }
    can gather with Module entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        self.nodes.append(here);
        print(here.mid);
        for nxt in [here ->:Depends:->][?:Module] {
            visit :0: [nxt];
        }
    }
}

walker ModuleReach {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can collect with Module entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        self.found.append(here.mid);
        print(here.mid);
        for nxt in [here ->:Depends:->][?:Module] {
            visit :0: [nxt];
        }
    }
}

walker AllSteps {
    has claimed: dict[str, bool] = {};
    has nodes: list[Step] = [];
    can visit_step with Step entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.nodes.append(here);
        print(here.name);
        for nxt in [here ->:Next:->][?:Step] {
            visit :0: [nxt];
        }
    }
}

def find_module(graph_root: Project, mid: str) -> Module | None {
    w = graph_root spawn AllModules(claimed={});
    for m in w.nodes {
        if m.mid == mid {
            return m;
        }
    }
    return None;
}

def find_step(graph_root: Step, name: str) -> Step | None {
    w = graph_root spawn AllSteps(claimed={});
    for s in w.nodes {
        if s.name == name {
            return s;
        }
    }
    return None;
}

def create_project(pid: str) -> Project {
    p = Project(pid=pid);
    return p;
}

def add_module(graph_root: Project, mid: str, coverage: float, threshold: float) -> Module {
    m = Module(mid=mid, coverage=coverage, threshold=threshold);
    graph_root +>:Contains:+> m;
    return m;
}

def add_dependency(src: Module, dst: Module) {
    src +>:Depends:+> dst;
}

def add_suite(mod: Module, sid: str, runner: str) -> Suite {
    s = Suite(sid=sid, runner=runner);
    mod +>:Covers:+> s;
    return s;
}

def link_steps(a: Step, b: Step) {
    a +>:Next:+> b;
}

def get_transitive_deps(graph_root: Project, start_mid: str) -> list[str] {
    start = find_module(graph_root, start_mid);
    if start is None {
        return [];
    }
    w = start spawn ModuleReach(claimed={});
    return sorted(w.found);
}

def get_coverage_failures(graph_root: Project) -> list[str] {
    w = graph_root spawn AllModules(claimed={});
    fails: list[str] = [];
    for m in w.nodes {
        if m.coverage < m.threshold {
            fails.append(m.mid);
        }
    }
    return sorted(fails);
}

def list_unit_suites(graph_root: Project) -> list[str] {
    w = graph_root spawn AllModules(claimed={});
    out: list[str] = [];
    for m in w.nodes {
        for s in [m ->:Covers:->][?:Suite] {
            if s.runner == "vitest" {
                out.append(s.sid);
            }
        }
    }
    return sorted(out);
}

def get_pipeline_order(graph_root: Step, start_name: str) -> list[str] {
    start = find_step(graph_root, start_name);
    if start is None {
        return [];
    }
    w = start spawn AllSteps(claimed={});
    out: list[str] = [];
    for n in w.nodes {
        out.append(n.name);
    }
    return sorted(out);
}

with entry {
    proj = Project(pid="demo");
    root ++> proj;
    m1 = Module(mid="orgContext", coverage=0.9, threshold=0.8);
    proj +>:Contains:+> m1;
    w = proj spawn AllModules(claimed={});
    print(w.nodes);
    dummy = root spawn AllSteps(claimed={});
    print(dummy.nodes);
}

test "diamond_revisit_adversarial_order" {
    proj = create_project("proj-diamond");
    root ++> proj;
    a = add_module(proj, "A", 1.0, 0.8);
    b = add_module(proj, "B", 1.0, 0.8);
    c = add_module(proj, "C", 1.0, 0.8);
    d = add_module(proj, "D", 1.0, 0.8);
    add_dependency(a, c);
    add_dependency(a, b);
    add_dependency(c, d);
    add_dependency(b, d);
    deps = get_transitive_deps(proj, "A");
    assert deps == ["A", "B", "C", "D"];
}

test "unknown_id_tolerance" {
    proj = create_project("proj-unknown");
    root ++> proj;
    m = add_module(proj, "orgContext", 0.9, 0.8);
    assert get_transitive_deps(proj, "missing") == [];
    assert get_coverage_failures(proj) == [];
    assert list_unit_suites(proj) == [];
    s0 = Step(name="lint");
    root ++> s0;
    assert get_pipeline_order(s0, "nope") == [];
    assert find_module(proj, "nope") is None;
}

test "coverage_threshold_and_suite_migration" {
    proj = create_project("proj-cov");
    root ++> proj;
    m1 = add_module(proj, "entitlements", 0.75, 0.8);
    m2 = add_module(proj, "planGate", 0.8, 0.8);
    m3 = add_module(proj, "pipeline", 0.95, 0.9);
    add_suite(m1, "entitlements.test.ts", "vitest");
    add_suite(m2, "planGate.test.ts", "playwright");
    add_suite(m3, "pipeline.test.ts", "vitest");
    fails = get_coverage_failures(proj);
    assert fails == ["entitlements"];
    suites = list_unit_suites(proj);
    assert suites == ["entitlements.test.ts", "pipeline.test.ts"];
}

test "pipeline_dag_cycle_and_reach" {
    s_lint = Step(name="lint");
    s_unit = Step(name="test:unit");
    s_build = Step(name="build");
    root ++> s_lint;
    link_steps(s_lint, s_unit);
    link_steps(s_unit, s_build);
    link_steps(s_build, s_unit);
    order = get_pipeline_order(s_lint, "lint");
    assert order == ["build", "lint", "test:unit"];
    order2 = get_pipeline_order(s_lint, "test:unit");
    assert order2 == ["build", "test:unit"];
}

test "transitive_deps_cycle_handling" {
    proj = create_project("proj-cycle");
    root ++> proj;
    x = add_module(proj, "X", 1.0, 0.8);
    y = add_module(proj, "Y", 1.0, 0.8);
    z = add_module(proj, "Z", 1.0, 0.8);
    add_dependency(x, y);
    add_dependency(y, z);
    add_dependency(z, x);
    assert get_transitive_deps(proj, "X") == ["X", "Y", "Z"];
    assert get_transitive_deps(proj, "Y") == ["X", "Y", "Z"];
}
