# PROGRAM: iss_DanMarshall909__workflow-tools__10.jac

node PlanRoot {
    has plan_id: str = "workflow";
}

node Phase {
    has phase_id: str;
    has rank: int = 0;
}

node Epic {
    has epic_id: str;
    has title: str;
    has sequence: int = 0;
}

edge HasPhase {}
edge HasEpic {}
edge Unlocks {}

obj ExecutionPlan {
    has graph: PlanRoot;
}

walker OrderWalker {
    has claimed: dict[str, bool] = {};
    has ordered: list[str] = [];

    can scan_root with PlanRoot entry {
        print("execution order");
        for phase in [here ->:HasPhase:->][?:Phase] {
            visit :0: [phase];
        }
    }

    can scan_phase with Phase entry {
        for epic in [here ->:HasEpic:->][?:Epic] {
            visit :0: [epic];
        }
    }

    can scan_epic with Epic entry {
        if here.epic_id in self.claimed {
            skip;
        }
        self.claimed[here.epic_id] = True;
        self.ordered.append(here.epic_id);
        for next_epic in [here ->:Unlocks:->][?:Epic] {
            visit :0: [next_epic];
        }
    }
}

walker LookupWalker {
    has target: str;
    has claimed: dict[str, bool] = {};
    has found: bool = False;
    has found_node: Epic | None = None;

    can lookup_root with PlanRoot entry {
        print("lookup");
        for phase in [here ->:HasPhase:->][?:Phase] {
            visit :0: [phase];
        }
    }

    can lookup_phase with Phase entry {
        for epic in [here ->:HasEpic:->][?:Epic] {
            visit :0: [epic];
        }
    }

    can lookup_epic with Epic entry {
        if here.epic_id in self.claimed {
            skip;
        }
        self.claimed[here.epic_id] = True;
        if here.epic_id == self.target {
            self.found = True;
            self.found_node = here;
        }
        for next_epic in [here ->:Unlocks:->][?:Epic] {
            visit :0: [next_epic];
        }
    }
}

def new_plan() -> ExecutionPlan {
    graph_root = PlanRoot(plan_id="workflow");
    plan = ExecutionPlan(graph=graph_root);
    return plan;
}

def add_phase(plan: ExecutionPlan, phase_id: str, rank: int) -> Phase {
    phase_node = Phase(phase_id=phase_id, rank=rank);
    plan.graph +>:HasPhase:+> phase_node;
    return phase_node;
}

def add_epic(
    phase_node: Phase,
    epic_id: str,
    title: str,
    sequence: int
) -> Epic {
    epic_node = Epic(epic_id=epic_id, title=title, sequence=sequence);
    phase_node +>:HasEpic:+> epic_node;
    return epic_node;
}

def locate_epic(plan: ExecutionPlan, epic_id: str) -> Epic | None {
    w = plan.graph spawn LookupWalker(target=epic_id, claimed={});
    return w.found_node;
}

def contains_epic(plan: ExecutionPlan, epic_id: str) -> bool {
    w = plan.graph spawn LookupWalker(target=epic_id, claimed={});
    return w.found;
}

def link_dependency(
    plan: ExecutionPlan,
    prerequisite_id: str,
    dependent_id: str
) -> bool {
    prerequisite = locate_epic(plan, prerequisite_id);
    if prerequisite == None {
        return False;
    }
    dependent = locate_epic(plan, dependent_id);
    if dependent == None {
        return False;
    }
    prerequisite +>:Unlocks:+> dependent;
    return True;
}

def execution_order(plan: ExecutionPlan) -> list[str] {
    w = plan.graph spawn OrderWalker(claimed={});
    return w.ordered;
}

test "foundation execution order" {
    plan = new_plan();
    phase = add_phase(plan, "foundation", 0);
    anchor = add_epic(phase, "anchor", "Use Anchor template", 1);
    shared = add_epic(phase, "shared", "Create shared library", 2);
    assert link_dependency(plan, "anchor", "shared");
    assert execution_order(plan) == ["anchor", "shared"];
}

test "diamond revisit is claimed once" {
    plan = new_plan();
    phase = add_phase(plan, "core", 1);
    a = add_epic(phase, "a", "A", 1);
    b = add_epic(phase, "b", "B", 2);
    c = add_epic(phase, "c", "C", 3);
    d = add_epic(phase, "d", "D", 4);
    assert link_dependency(plan, "a", "c");
    assert link_dependency(plan, "a", "b");
    assert link_dependency(plan, "b", "d");
    assert link_dependency(plan, "c", "d");
    order = execution_order(plan);
    assert len(order) == 4;
    assert sorted(order) == ["a", "b", "c", "d"];
}

test "unknown epic ids are tolerated" {
    plan = new_plan();
    phase = add_phase(plan, "foundation", 0);
    add_epic(phase, "real", "Real epic", 1);
    assert contains_epic(plan, "real") == True;
    assert contains_epic(plan, "missing") == False;
    assert locate_epic(plan, "missing") == None;
    assert link_dependency(plan, "missing", "real") == False;
    assert link_dependency(plan, "real", "missing") == False;
}

test "empty and disconnected plans" {
    empty_plan = new_plan();
    assert execution_order(empty_plan) == [];
    phase = add_phase(empty_plan, "later", 2);
    add_epic(phase, "solo", "Standalone epic", 9);
    assert execution_order(empty_plan) == ["solo"];
}
