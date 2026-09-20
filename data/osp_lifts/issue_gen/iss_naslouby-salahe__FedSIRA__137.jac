# naslouby-salahe/FedSIRA#137 — experiment planner, runner, execution order, cell registry

node Experiment {
    has name: str;
    has post_core: bool = False;
    has core_resolved: bool = False;
}

node Cell {
    has cid: str;
    has label: str;
    has status: str = "pending";
}

edge Depends {}
edge Contains {}

walker OrderWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step_exp with Experiment entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        deps: list[Experiment] = [here ->:Depends:->][?:Experiment];
        for dep in deps {
            visit :0: [dep];
        }
        self.order.append(here.name);
        print("order", here.name);
    }
}

walker CollectCells {
    has claimed: dict[str, bool] = {};
    has cells: list[str] = [];

    can collect_exp with Experiment entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        deps: list[Experiment] = [here ->:Depends:->][?:Experiment];
        for dep in deps {
            visit :0: [dep];
        }
        owned: list[Cell] = [here ->:Contains:->][?:Cell];
        for c in owned {
            self.cells.append(c.cid);
        }
        print("cells", here.name, len(owned));
    }
}

def _get_experiment(store: dict[str, object], name: str) -> Experiment {
    if name not in store {
        raise ValueError("unknown experiment");
    }
    return store[name] as Experiment;
}

def build_store() -> dict[str, object] {
    store: dict[str, object] = {};
    e_core = Experiment(name="collapse_core", core_resolved=False);
    e_post = Experiment(name="post_core_eval", post_core=True);
    c_prep = Cell(cid="core_prep", label="prep");
    c_train = Cell(cid="core_train", label="train");
    c_post = Cell(cid="post_eval", label="eval");
    e_core +>:Contains:+> c_prep;
    e_core +>:Contains:+> c_train;
    e_post +>:Contains:+> c_post;
    e_post +>:Depends:+> e_core;
    store["collapse_core"] = e_core;
    store["post_core_eval"] = e_post;
    return store;
}

def _wire_diamond(store: dict[str, object]) {
    e_base = Experiment(name="base");
    e_left = Experiment(name="left");
    e_right = Experiment(name="right");
    e_merge = Experiment(name="merge");
    e_merge +>:Depends:+> e_right;
    e_merge +>:Depends:+> e_left;
    e_right +>:Depends:+> e_base;
    e_left +>:Depends:+> e_base;
    cb = Cell(cid="b0", label="base_cell");
    cl = Cell(cid="l0", label="left_cell");
    cr = Cell(cid="r0", label="right_cell");
    cm = Cell(cid="m0", label="merge_cell");
    e_base +>:Contains:+> cb;
    e_left +>:Contains:+> cl;
    e_right +>:Contains:+> cr;
    e_merge +>:Contains:+> cm;
    store["base"] = e_base;
    store["left"] = e_left;
    store["right"] = e_right;
    store["merge"] = e_merge;
}

def resolve_execution_order(store: dict[str, object], root_name: str) -> list[str] {
    root_exp = _get_experiment(store, root_name);
    w = root_exp spawn OrderWalker(claimed={}, order=[]);
    return w.order;
}

def count_semantic_cells(store: dict[str, object], name: str) -> int {
    exp = _get_experiment(store, name);
    w = exp spawn CollectCells(claimed={}, cells=[]);
    ids: list[str] = sorted(w.cells);
    seen: dict[str, bool] = {};
    count = 0;
    for cid in ids {
        if cid not in seen {
            seen[cid] = True;
            count += 1;
        }
    }
    return count;
}

def plan_experiment(store: dict[str, object], name: str) -> dict[str, object] {
    exp = _get_experiment(store, name);
    blocked = False;
    if exp.post_core {
        deps: list[Experiment] = [exp ->:Depends:->][?:Experiment];
        for dep in deps {
            if not dep.core_resolved {
                blocked = True;
            }
        }
    }
    order = resolve_execution_order(store, name);
    cells: list[str] = [];
    w_cells = exp spawn CollectCells(claimed={}, cells=[]);
    sorted_cells: list[str] = sorted(w_cells.cells);
    for cid in sorted_cells {
        cells.append(cid);
    }
    result: dict[str, object] = {};
    result["name"] = name;
    result["order"] = order;
    result["cell_count"] = len(cells);
    result["cells"] = cells;
    result["blocked"] = blocked;
    return result;
}

def run_experiment(store: dict[str, object], name: str) -> str {
    exp = _get_experiment(store, name);
    if exp.name != name {
        raise ValueError("exact name required");
    }
    planned = plan_experiment(store, name);
    if planned["blocked"] as bool {
        return "Failed";
    }
    owned: list[Cell] = [exp ->:Contains:->][?:Cell];
    all_done = True;
    for c in owned {
        if c.status != "completed" {
            all_done = False;
        }
    }
    if all_done and len(owned) > 0 {
        return "Completed";
    }
    for c in owned {
        c.status = "completed";
    }
    if exp.name == "collapse_core" {
        exp.core_resolved = True;
    }
    return "Completed";
}

def safe_plan(store: dict[str, object], name: str) -> bool {
    if name not in store {
        return False;
    }
    plan_experiment(store, name);
    return True;
}

def safe_run(store: dict[str, object], name: str) -> bool {
    if name not in store {
        return False;
    }
    run_experiment(store, name);
    return True;
}
