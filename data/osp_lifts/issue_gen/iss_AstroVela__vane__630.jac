node PlanNode {
    has key: str;
    has kind: str;
    has value: int = 0;
}

edge PlanEdge {}

node PlanGraph {
    has nodes: dict[str, PlanNode] = {};
    has entry_key: str = "";
}

walker RayPlanWalker {
    has claimed: dict[str, bool] = {};
    has operator_ids: list[str] = [];
    has has_recursive_scan: bool = False;
    has has_recurring_scan: bool = False;

    can visit_plan with PlanGraph entry {
        print("ray-plan");
        for kid in [here ->:PlanEdge:->][?:PlanNode] {
            visit :0: [kid];
        }
    }

    can visit_operator with PlanNode entry {
        if here.key in self.claimed {
            skip;
        }
        self.claimed[here.key] = True;
        self.operator_ids.append(here.key);
        print(here.kind);

        if here.kind == "RECURSIVE_CTE_SCAN" {
            self.has_recursive_scan = True;
        }
        if here.kind == "RECURSIVE_RECURRING_CTE_SCAN" {
            self.has_recurring_scan = True;
        }

        for kid in [here ->:PlanEdge:->][?:PlanNode] {
            visit :0: [kid];
        }
    }
}

def add_operator(
    plan: PlanGraph,
    key: str,
    kind: str,
    value: int = 0
) -> PlanNode | None {
    if key in plan.nodes {
        return None;
    }

    nd = PlanNode(key=key, kind=kind, value=value);
    plan.nodes[key] = nd;

    if plan.entry_key == "" {
        plan.entry_key = key;
        plan +>:PlanEdge:+> nd;
    }
    return nd;
}

def link_operator(
    plan: PlanGraph,
    source: str,
    target: str
) -> bool {
    source_node: PlanNode | None = None;
    target_node: PlanNode | None = None;

    for known_key in plan.nodes {
        if known_key == source {
            source_node = plan.nodes[known_key];
        }
        if known_key == target {
            target_node = plan.nodes[known_key];
        }
    }

    if source_node is None {
        return False;
    }
    if target_node is None {
        return False;
    }

    source_node +>:PlanEdge:+> target_node;
    return True;
}

def translate_ray_plan(plan: PlanGraph) -> list[str] {
    w = plan spawn RayPlanWalker(claimed={});
    return w.operator_ids;
}

def run_ray_recursive(
    plan: PlanGraph,
    upper: int
) -> list[int] {
    w = plan spawn RayPlanWalker(claimed={});
    values: list[int] = [];

    if upper <= 0 {
        return values;
    }
    if w.has_recursive_scan {
        if w.has_recurring_scan {
            current: int = 1;
            while current <= upper {
                values.append(current);
                current += 1;
            }
        }
    }
    return values;
}
