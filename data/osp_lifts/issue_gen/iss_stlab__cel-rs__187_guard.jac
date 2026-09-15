"""stlab/cel-rs#187 — Kahn topological sort replaces Tarjan SCC for planner."""

glob FILTER_CYCLE = "FilterCycle";

node PlanStep {
    has sid: str;
    has indegree: int = 0;
}

edge Before {}

obj PlannerGraph {
    has steps: list[PlanStep] = [];
    has n: int = 0;
}

def lookup_step(g: PlannerGraph, sid: str) -> PlanStep | None {
    for st in g.steps {
        if st.sid == sid {
            return st;
        }
    }
    return None;
}

def build_planner_graph(step_ids: list[str], deps: list[list[str]]) -> PlannerGraph {
    g: PlannerGraph = PlannerGraph();
    for sid in step_ids {
        st: PlanStep = PlanStep(sid=sid);
        root ++> st;
        g.steps.append(st);
    }
    g.n = len(g.steps);
    for pair in deps {
        if len(pair) < 2 {
            continue;
        }
        frm: str = pair[0];
        to: str = pair[1];
        src: PlanStep | None = lookup_step(g, frm);
        dst: PlanStep | None = lookup_step(g, to);
        if src is not None and dst is not None {
            src +>:Before:+> dst;
            dst.indegree += 1;
        }
    }
    return g;
}

def indegree_snapshot(g: PlannerGraph) -> dict[str, int] {
    snap: dict[str, int] = {};
    for st in g.steps {
        snap[st.sid] = st.indegree;
    }
    return snap;
}

def restore_indegrees(g: PlannerGraph, snap: dict[str, int]) {
    for st in g.steps {
        st.indegree = snap[st.sid];
    }
}

walker KahnWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has graph: PlannerGraph;
    has seeded: bool = False;

    can prime with PlanStep entry {
        if self.seeded {
            skip;
        }
        self.seeded = True;
        for st in self.graph.steps {
            if st.indegree == 0 {
                visit :0: [st];
            }
        }
        print ["kahn_prime", self.graph.n];
        disengage;
    }

    can emit with PlanStep entry {
        if here.sid in self.claimed {
            skip;
        }
        if here.indegree != 0 {
            disengage;
        }
        self.claimed[here.sid] = True;
        self.order.append(here.sid);
        succs: list[PlanStep] = [here ->:Before:->][?:PlanStep];
        for succ in succs {
            succ.indegree -= 1;
            if succ.indegree == 0 {
                visit :0: [succ];
            }
        }
        print ["kahn_emit", here.sid];
        disengage;
    }
}

def kahn_emit(g: PlannerGraph) -> list[str] {
    if g.n == 0 {
        empty: list[str] = [];
        return empty;
    }
    w: KahnWalker = g.steps[0] spawn KahnWalker(claimed={}, order=[], graph=g, seeded=False);
    return w.order;
}

def is_acyclic(step_ids: list[str], deps: list[list[str]]) -> bool {
    g: PlannerGraph = build_planner_graph(step_ids, deps);
    snap: dict[str, int] = indegree_snapshot(g);
    topo_order: list[str] = kahn_emit(g);
    restore_indegrees(g, snap);
    return len(topo_order) == g.n;
}

def plan(step_ids: list[str], deps: list[list[str]]) -> list[str] {
    g: PlannerGraph = build_planner_graph(step_ids, deps);
    snap: dict[str, int] = indegree_snapshot(g);
    topo_order: list[str] = kahn_emit(g);
    restore_indegrees(g, snap);
    if len(topo_order) != g.n {
        raise [FILTER_CYCLE];
    }
    return topo_order;
}

with entry {
    root spawn DemoKahn;
}

walker DemoKahn {
    can demo with entry {
        ids: list[str] = ["seed", "match", "release"];
        deps: list[list[str]] = [["seed", "match"], ["match", "release"]];
        topo_order: list[str] = plan(ids, deps);
        print ["demo_plan", topo_order];
    }
}

test "plan_linear_chain" {
    ids: list[str] = ["seed", "match", "release"];
    deps: list[list[str]] = [["seed", "match"], ["match", "release"]];
    got: list[str] = plan(ids, deps);
    assert got == ["seed", "match", "release"];
}

test "empty_graph_plan" {
    ids: list[str] = [];
    deps: list[list[str]] = [];
    got: list[str] = plan(ids, deps);
    assert got == [];
}

test "is_acyclic_true" {
    ids: list[str] = ["seed", "match", "release"];
    deps: list[list[str]] = [["seed", "match"], ["match", "release"]];
    assert is_acyclic(ids, deps) == True;
}

test "is_acyclic_false_cycle" {
    ids: list[str] = ["a", "b"];
    deps: list[list[str]] = [["a", "b"], ["b", "a"]];
    assert is_acyclic(ids, deps) == False;
}

test "kahn_partial_on_cycle" {
    g: PlannerGraph = build_planner_graph(["a", "b"], [["a", "b"], ["b", "a"]]);
    snap: dict[str, int] = indegree_snapshot(g);
    got: list[str] = kahn_emit(g);
    restore_indegrees(g, snap);
    assert len(got) == 1;
}

test "plan_unknown_dep_ignored" {
    ids: list[str] = ["only"];
    deps: list[list[str]] = [["ghost", "only"], ["only"]];
    got: list[str] = plan(ids, deps);
    assert got == ["only"];
}
