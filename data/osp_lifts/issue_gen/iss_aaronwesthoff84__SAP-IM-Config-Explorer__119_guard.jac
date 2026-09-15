"""aaronwesthoff84/SAP-IM-Config-Explorer#119."""

glob PIPELINE_STAGES = ["Credit", "Primary", "Secondary", "Incentive", "Deposit"];

node FormulaNode {
    has node_id: str;
    has stage: str;
    has expression: str;
    has output_val: float = 0.0;
}

edge Dep {}

node SimRoot {
    has max_steps: int = 1000;
    has registry: dict[str, FormulaNode] = {};
}

walker EventPropagator {
    has claimed: dict[str, bool] = {};
    has steps: list = [];
    has step_count: int = 0;
    has max_steps: int = 1000;
    has halted: bool = False;
    has halt_reason: str = "";
    has event_amount: float = 0.0;

    can walk_node with FormulaNode entry {
        if here.node_id in self.claimed {
            skip;
        }
        if self.step_count >= self.max_steps {
            self.halted = True;
            self.halt_reason = "max_steps";
            disengage;
        }
        self.claimed[here.node_id] = True;
        self.step_count += 1;
        inputs: dict[str, float] = {};
        dep_sum: float = 0.0;
        for up in [<-:Dep:<-][?:FormulaNode] {
            inputs[up.node_id] = up.output_val;
            dep_sum += up.output_val;
        }
        out: float = 0.0;
        if here.stage == "Credit" {
            out = self.event_amount;
        } elif here.expression == "sum_deps" {
            out = dep_sum;
        } else {
            rate: float = float(here.expression);
            if dep_sum > 0.0 {
                out = dep_sum * rate;
            } else {
                out = self.event_amount * rate;
            }
        }
        here.output_val = out;
        rec: dict = {};
        rec["node_id"] = here.node_id;
        rec["stage"] = here.stage;
        rec["inputs"] = inputs;
        rec["expression"] = here.expression;
        rec["output"] = out;
        self.steps.append(rec);
        print(here.node_id, here.stage, out);
        kids: list[FormulaNode] = [];
        for ch in [here ->:Dep:->][?:FormulaNode] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def compensation_rule_simulator(max_steps: int = 1000) -> SimRoot {
    sr = SimRoot(max_steps=max_steps);
    root ++> sr;
    return sr;
}

def register_node(sim: SimRoot, node_id: str, stage: str, expression: str) -> None {
    if node_id in sim.registry {
        return;
    }
    nd = FormulaNode(node_id=node_id, stage=stage, expression=expression);
    sim.registry[node_id] = nd;
    sim ++> nd;
}

def add_dependency(sim: SimRoot, upstream: str, downstream: str) -> None {
    if upstream not in sim.registry {
        return;
    }
    if downstream not in sim.registry {
        return;
    }
    up_nd = sim.registry[upstream] as FormulaNode;
    down_nd = sim.registry[downstream] as FormulaNode;
    up_nd +>: Dep :+> down_nd;
}

def _stage_rank(stage: str) -> int {
    idx: int = 0;
    for st in PIPELINE_STAGES {
        if st == stage {
            return idx;
        }
        idx += 1;
    }
    return 99;
}

def _find_roots(sim: SimRoot) -> list[FormulaNode] {
    roots: list[FormulaNode] = [];
    for nid in sim.registry {
        nd = sim.registry[nid] as FormulaNode;
        has_in: bool = False;
        for _up in [nd <-:Dep:<-][?:FormulaNode] {
            has_in = True;
        }
        if not has_in {
            roots.append(nd);
        }
    }
    return roots;
}

def _sort_roots_by_stage(roots: list[FormulaNode]) -> list[FormulaNode] {
    ordered: list[FormulaNode] = [];
    for st in PIPELINE_STAGES {
        for nd in roots {
            if nd.stage == st {
                ordered.append(nd);
            }
        }
    }
    return ordered;
}

def run_simulation(sim: SimRoot, events: list) -> dict {
    amount: float = 0.0;
    for ev in events {
        evd = ev as dict;
        if "amount" in evd {
            amount += evd["amount"] as float;
        }
    }
    roots = _sort_roots_by_stage(_find_roots(sim));
    merged: list = [];
    halted: bool = False;
    halt_reason: str = "";
    shared_claimed: dict[str, bool] = {};
    for rnd in roots {
        wk = rnd spawn EventPropagator(
            claimed=shared_claimed,
            steps=[],
            step_count=len(merged),
            max_steps=sim.max_steps,
            halted=False,
            halt_reason="",
            event_amount=amount
        );
        for st in wk.steps {
            merged.append(st);
        }
        if wk.halted {
            halted = True;
            halt_reason = wk.halt_reason;
        }
    }
    trace: dict = {};
    trace["steps"] = merged;
    trace["halted"] = halted;
    if halted {
        trace["reason"] = halt_reason;
    } else {
        trace["reason"] = None;
    }
    return trace;
}

obj __jac_entry__ {
    with entry {
        sim = compensation_rule_simulator(1000);
        register_node(sim, "c1", "Credit", "1.0");
        evs: list = [];
        ev: dict = {};
        ev["event_type"] = "sale";
        ev["amount"] = 100.0;
        evs.append(ev);
        tr = run_simulation(sim, evs);
        print(tr);
    }
}

test "basic_credit_root" {
    sim = compensation_rule_simulator(1000);
    register_node(sim, "c1", "Credit", "1.0");
    evs: list = [];
    ev: dict = {};
    ev["amount"] = 100.0;
    evs.append(ev);
    tr = run_simulation(sim, evs);
    assert tr["halted"] == False;
    assert tr["reason"] == None;
    assert len(tr["steps"]) == 1;
    assert tr["steps"][0]["node_id"] == "c1";
    assert tr["steps"][0]["output"] == 100.0;
}

test "sum_deps_chain" {
    sim = compensation_rule_simulator(1000);
    register_node(sim, "c1", "Credit", "1.0");
    register_node(sim, "p1", "Primary", "sum_deps");
    add_dependency(sim, "c1", "p1");
    evs: list = [];
    ev: dict = {};
    ev["amount"] = 50.0;
    evs.append(ev);
    tr = run_simulation(sim, evs);
    assert tr["halted"] == False;
    assert len(tr["steps"]) == 2;
    assert tr["steps"][0]["node_id"] == "c1";
    assert tr["steps"][0]["output"] == 50.0;
    assert tr["steps"][1]["node_id"] == "p1";
    assert tr["steps"][1]["output"] == 50.0;
}

test "rate_on_deps" {
    sim = compensation_rule_simulator(1000);
    register_node(sim, "c1", "Credit", "1.0");
    register_node(sim, "i1", "Incentive", "0.1");
    add_dependency(sim, "c1", "i1");
    evs: list = [];
    ev: dict = {};
    ev["amount"] = 200.0;
    evs.append(ev);
    tr = run_simulation(sim, evs);
    assert len(tr["steps"]) == 2;
    assert tr["steps"][1]["node_id"] == "i1";
    assert tr["steps"][1]["output"] == 20.0;
}

test "rate_without_deps_uses_event" {
    sim = compensation_rule_simulator(1000);
    register_node(sim, "p1", "Primary", "0.5");
    evs: list = [];
    ev: dict = {};
    ev["amount"] = 80.0;
    evs.append(ev);
    tr = run_simulation(sim, evs);
    assert len(tr["steps"]) == 1;
    assert tr["steps"][0]["node_id"] == "p1";
    assert tr["steps"][0]["output"] == 40.0;
}

test "diamond_sum_deps_once" {
    sim = compensation_rule_simulator(1000);
    register_node(sim, "c1", "Credit", "1.0");
    register_node(sim, "p1", "Primary", "sum_deps");
    register_node(sim, "p2", "Primary", "sum_deps");
    register_node(sim, "s1", "Secondary", "sum_deps");
    add_dependency(sim, "c1", "p1");
    add_dependency(sim, "c1", "p2");
    add_dependency(sim, "p1", "s1");
    add_dependency(sim, "p2", "s1");
    evs: list = [];
    ev: dict = {};
    ev["amount"] = 10.0;
    evs.append(ev);
    tr = run_simulation(sim, evs);
    ids: list[str] = [];
    for st in tr["steps"] {
        ids.append(st["node_id"] as str);
    }
    assert len(ids) == 4;
    assert ids.count("s1") == 1;
    assert tr["steps"][-1]["node_id"] == "s1";
    assert tr["steps"][-1]["output"] == 20.0;
}

test "ignore_unknown_dependency" {
    sim = compensation_rule_simulator(1000);
    register_node(sim, "c1", "Credit", "1.0");
    add_dependency(sim, "c1", "missing");
    add_dependency(sim, "missing", "c1");
    evs: list = [];
    ev: dict = {};
    ev["amount"] = 5.0;
    evs.append(ev);
    tr = run_simulation(sim, evs);
    assert len(tr["steps"]) == 1;
    assert tr["steps"][0]["node_id"] == "c1";
}
