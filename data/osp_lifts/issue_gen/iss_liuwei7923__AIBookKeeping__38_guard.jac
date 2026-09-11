"""CI workflow DAG expansion tracker — liuwei7923/AIBookKeeping#38."""

node CIStage {
    has stage_id: str;
    has label: str;
    has required_pr: bool = False;
    has scheduled_only: bool = False;
}

edge Depends {}

node WorkflowGraph {
    has entry_stage: CIStage;
}

walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with CIStage entry {
        if here.stage_id in self.claimed { skip; }
        self.claimed[here.stage_id] = True;
        self.found.append(here.stage_id);
        kids: list[CIStage] = [];
        for kid in [here ->:Depends:->][?:CIStage] {
            kids.append(kid);
        }
        for kid in kids {
            visit :0: kid;
        }
    }
}

walker FindWalker {
    has sought: str = "";
    has claimed: dict[str, bool] = {};
    has found: CIStage = None;

    can seek with CIStage entry {
        if here.stage_id in self.claimed { skip; }
        self.claimed[here.stage_id] = True;
        if here.stage_id == self.sought {
            self.found = here;
            disengage;
        }
        kids: list[CIStage] = [];
        for kid in [here ->:Depends:->][?:CIStage] {
            kids.append(kid);
        }
        for kid in kids {
            visit kid;
        } else {
            disengage;
        }
    }
}

walker PrWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with CIStage entry {
        if here.stage_id in self.claimed { skip; }
        self.claimed[here.stage_id] = True;
        if here.required_pr {
            self.found.append(here.stage_id);
        }
        kids: list[CIStage] = [];
        for kid in [here ->:Depends:->][?:CIStage] {
            kids.append(kid);
        }
        for kid in kids {
            visit kid;
        }
    }
}

walker SchedWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with CIStage entry {
        if here.stage_id in self.claimed { skip; }
        self.claimed[here.stage_id] = True;
        if here.scheduled_only {
            self.found.append(here.stage_id);
        }
        kids: list[CIStage] = [];
        for kid in [here ->:Depends:->][?:CIStage] {
            kids.append(kid);
        }
        for kid in kids {
            visit kid;
        }
    }
}

walker TopoWalker {
    has claimed: dict[str, bool] = {};
    has postorder: list[str] = [];

    can descend with CIStage entry {
        if here.stage_id in self.claimed { skip; }
        self.claimed[here.stage_id] = True;
        kids: list[CIStage] = [];
        for kid in [here ->:Depends:->][?:CIStage] {
            kids.append(kid);
        }
        for kid in kids {
            visit kid;
        }
        self.postorder.append(here.stage_id);
    }
}

walker DemoWalker {
    has start: CIStage;
    has claimed: dict[str, bool] = {};

    can boot with entry {
        visit self.start;
    }

    can step with CIStage entry {
        if here.stage_id in self.claimed { skip; }
        self.claimed[here.stage_id] = True;
        print(here.stage_id);
        kids: list[CIStage] = [];
        for kid in [here ->:Depends:->][?:CIStage] {
            kids.append(kid);
        }
        for kid in kids {
            visit kid;
        }
    }
}

def _find_stage(graph: WorkflowGraph, stage_id: str) -> CIStage {
    w = graph.entry_stage spawn FindWalker(sought=stage_id, claimed={});
    return w.found;
}

def build_workflow_graph() -> WorkflowGraph {
    ci37 = CIStage(
        stage_id="ci37",
        label="baseline compile and test",
        required_pr=True,
    );
    root ++> ci37;

    s1 = CIStage(
        stage_id="s1_ruff",
        label="ruff lint and format",
        required_pr=True,
    );
    ci37 +>:Depends:+> s1;

    s2 = CIStage(
        stage_id="s2_deps",
        label="reproducible dependencies",
        required_pr=False,
    );
    ci37 +>:Depends:+> s2;

    s3 = CIStage(
        stage_id="s3_coverage",
        label="coverage and typing",
        required_pr=False,
    );
    s2 +>:Depends:+> s3;

    s4 = CIStage(
        stage_id="s4_security",
        label="security and contract validation",
        required_pr=False,
    );
    s3 +>:Depends:+> s4;

    s5 = CIStage(
        stage_id="s5_compat",
        label="compatibility and build readiness",
        required_pr=False,
    );
    s4 +>:Depends:+> s5;

    sched_eval = CIStage(
        stage_id="sched_eval",
        label="live OpenAI evaluation",
        required_pr=False,
        scheduled_only=True,
    );
    ci37 +>:Depends:+> sched_eval;

    sched_bench = CIStage(
        stage_id="sched_bench",
        label="performance benchmarks",
        required_pr=False,
        scheduled_only=True,
    );
    s5 +>:Depends:+> sched_bench;

    g = WorkflowGraph(entry_stage=ci37);
    return g;
}

def reachable_from(graph: WorkflowGraph, start_id: str) -> list[str] {
    start = _find_stage(graph, start_id);
    if start is None {
        empty: list[str] = [];
        return empty;
    }
    w = start spawn ReachWalker(claimed={}, found=[]);
    return sorted(w.found);
}

def required_pr_stages(graph: WorkflowGraph) -> list[str] {
    w = graph.entry_stage spawn PrWalker(claimed={}, found=[]);
    return sorted(w.found);
}

def scheduled_stages(graph: WorkflowGraph) -> list[str] {
    w = graph.entry_stage spawn SchedWalker(claimed={}, found=[]);
    return sorted(w.found);
}

def topo_sort(graph: WorkflowGraph) -> list[str] {
    w = graph.entry_stage spawn TopoWalker(claimed={}, postorder=[]);
    return w.postorder;
}

def is_reachable(graph: WorkflowGraph, from_id: str, to_id: str) -> bool {
    ids = reachable_from(graph, from_id);
    for sid in ids {
        if sid == to_id {
            return True;
        }
    }
    return False;
}

with entry {
    g = build_workflow_graph();
    root spawn DemoWalker(start=g.entry_stage, claimed={});
}

test "required_pr_stages_sorted" {
    g = build_workflow_graph();
    got = required_pr_stages(g);
    assert got == sorted(["ci37", "s1_ruff"]);
}

test "diamond_revisit_multiset" {
    a = CIStage(stage_id="a", label="a", required_pr=True);
    b = CIStage(stage_id="b", label="b", required_pr=True);
    c = CIStage(stage_id="c", label="c", required_pr=True);
    d = CIStage(stage_id="d", label="d", required_pr=True);
    root ++> a;
    a +>:Depends:+> b;
    a +>:Depends:+> c;
    b +>:Depends:+> d;
    c +>:Depends:+> d;
    g = WorkflowGraph(entry_stage=a);
    got = reachable_from(g, "a");
    assert got == sorted(["a", "b", "c", "d"]);
}

test "unknown_start_id_empty" {
    g = build_workflow_graph();
    got = reachable_from(g, "no_such_stage");
    assert got == [];
}

test "scheduled_not_required_pr" {
    g = build_workflow_graph();
    pr = required_pr_stages(g);
    sched = scheduled_stages(g);
    for sid in sched {
        found = False;
        for pid in pr {
            if sid == pid {
                found = True;
            }
        }
        assert not found;
    }
    assert sorted(sched) == sorted(["sched_eval", "sched_bench"]);
}

test "topo_prereq_before_dependent" {
    g = build_workflow_graph();
    order = topo_sort(g);
    pos: dict[str, int] = {};
    for i in range(len(order)) {
        pos[order[i]] = i;
    }
    assert pos["ci37"] < pos["s1_ruff"];
    assert pos["s2_deps"] < pos["s3_coverage"];
    assert pos["s3_coverage"] < pos["s4_security"];
}

test "is_reachable_negative" {
    g = build_workflow_graph();
    assert not is_reachable(g, "s1_ruff", "ci37");
    assert not is_reachable(g, "missing", "ci37");
}
