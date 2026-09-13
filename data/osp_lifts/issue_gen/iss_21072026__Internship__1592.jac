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
