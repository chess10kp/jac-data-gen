"""QueryaHub/OxyRoute#141: precomputed dependency DAG resolution."""

node DependencyRoot {
    has marker: str = "dependency-root";
}

node Dependency {
    has dep_id: str;
    has declared_args: list[str] = [];
}

edge Owns {}
edge Requires {}

obj DependencyPlan {
    has graph_root: DependencyRoot;
    has order: list[str] = [];
    has frozen: bool = False;
    has error: str = "";
}

walker FreezeWalker {
    has requested_id: str = "";
    has claimed: dict[str, bool] = {};
    has active: dict[str, bool] = {};
    has ordered: list[str] = [];
    has cycle_found: bool = False;

    can start with DependencyRoot entry {
        print("freeze");
        for dep in [here ->:Owns:->][?:Dependency] {
            if self.requested_id == "" or dep.dep_id == self.requested_id {
                visit :0: [dep];
            }
        }
    }

    can step with Dependency entry {
        if here.dep_id in self.claimed {
            skip;
        }
        self.claimed[here.dep_id] = True;
        self.active[here.dep_id] = True;

        for prerequisite in [here <-:Requires:<-][?:Dependency] {
            if prerequisite.dep_id in self.active {
                if self.active[prerequisite.dep_id] {
                    self.cycle_found = True;
                }
            }
        }

        for prerequisite in [here <-:Requires:<-][?:Dependency] {
            visit :0: [prerequisite];
        }

        self.active[here.dep_id] = False;
        self.ordered.insert(0, here.dep_id);
        print(here.dep_id);
    }
}

def new_plan() -> DependencyPlan {
    graph_root = DependencyRoot();
    return DependencyPlan(graph_root=graph_root);
}

def add_dependency(
    plan: DependencyPlan,
    dep_id: str,
    declared_args: list[str]
) -> Dependency {
    dep = Dependency(dep_id=dep_id, declared_args=declared_args);
    plan.graph_root ++> dep;
    return dep;
}

def depends_on(prerequisite: Dependency, dependent: Dependency) {
    prerequisite +>:Requires:+> dependent;
}

def freeze(plan: DependencyPlan, requested_id: str = "") -> list[str] {
    w = plan.graph_root spawn FreezeWalker(
        requested_id=requested_id,
        claimed={}
    );
    if w.cycle_found {
        plan.frozen = False;
        plan.order = [];
        plan.error = "circular dependency detected during freeze";
    } else {
        plan.frozen = True;
        plan.order = w.ordered;
        plan.error = "";
    }
    return plan.order;
}

def required_kwargs(
    dependency: Dependency,
    available: dict[str, str]
) -> dict[str, str] {
    selected: dict[str, str] = {};
    for arg_name in dependency.declared_args {
        if arg_name in available {
            selected[arg_name] = available[arg_name];
        }
    }
    return selected;
}
