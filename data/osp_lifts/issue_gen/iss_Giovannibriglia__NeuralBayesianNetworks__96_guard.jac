# PROGRAM iss_Giovannibriglia__NeuralBayesianNetworks__96.jac

node Store {
    has label: str;
}

node Cell {
    has cell_id: str;
    has family: str;
    has n_nodes: int;
    has status: str;
    has total_time_s: float;
}

edge Contains {}
edge Depends {}

walker CellWalk {
    has target_id: str = "";
    has found: bool = False;
    has claimed: dict[str, bool] = {};
    has cells: list[Cell] = [];

    can scan_store with Store entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.label);
        visit :0: [here ->:Contains:->][?:Cell];
    }

    can scan_cell with Cell entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.cells.append(here);
        print(here.cell_id);
        if here.cell_id == self.target_id {
            self.found = True;
        }
        for kid in [here ->:Depends:->][?:Cell] {
            visit :0: [kid];
        }
    }
}

def create_store(label: str) -> Store {
    return Store(label=label);
}

def create_cell(
    cell_id: str,
    family: str,
    n_nodes: int,
    status: str,
    total_time_s: float
) -> Cell {
    return Cell(
        cell_id=cell_id,
        family=family,
        n_nodes=n_nodes,
        status=status,
        total_time_s=total_time_s
    );
}

def attach_cell(store: Store, cell: Cell) -> None {
    store +>:Contains:+> cell;
    return None;
}

def link_cells(source: Cell, target: Cell) -> None {
    source +>:Depends:+> target;
    return None;
}

def reachable_cell_ids(store: Store) -> list[str] {
    w = store spawn CellWalk(target_id="", claimed={});
    ids: list[str] = [];
    for cell in w.cells {
        ids.append(cell.cell_id);
    }
    return sorted(ids);
}

def path_reaches(store: Store, target_id: str) -> bool {
    w = store spawn CellWalk(target_id=target_id, claimed={});
    return w.found;
}

def summarize_status(store: Store) -> dict[str, int] {
    w = store spawn CellWalk(target_id="", claimed={});
    counts: dict[str, int] = {};
    for cell in w.cells {
        if cell.status in counts {
            counts[cell.status] = counts[cell.status] + 1;
        } else {
            counts[cell.status] = 1;
        }
    }
    return counts;
}

def total_runtime(store: Store) -> float {
    w = store spawn CellWalk(target_id="", claimed={});
    runtime: float = 0.0;
    for cell in w.cells {
        runtime = runtime + cell.total_time_s;
    }
    return runtime;
}

def baseline_applicable(family: str) -> bool {
    return family == "continuous_lg" or family == "continuous_nongauss";
}

def accuracy_supported(family: str) -> bool {
    return False;
}

test "diamond closure skips revisits" {
    store = create_store("diamond");
    left_node = create_cell("left", "continuous_lg", 100, "ok", 1.0);
    right_node = create_cell("right", "continuous_lg", 100, "ok", 2.0);
    leaf_node = create_cell("leaf", "continuous_lg", 100, "ok", 3.0);

    attach_cell(store, right_node);
    attach_cell(store, left_node);
    link_cells(left_node, leaf_node);
    link_cells(right_node, leaf_node);
    assert (reachable_cell_ids(store) == ["leaf", "left", "right"]);
    assert (path_reaches(store, "leaf") == True);
    assert (summarize_status(store) == {"ok": 3});
    assert (total_runtime(store) == 6.0);
}

test "unknown target is tolerated" {
    store = create_store("known");
    cell = create_cell("only", "continuous_nongauss", 1000, "ok", 1.0);
    attach_cell(store, cell);

    assert (path_reaches(store, "missing") == False);
    assert (path_reaches(store, "only") == True);
}

test "empty store has empty aggregates" {
    store = create_store("empty");

    assert (reachable_cell_ids(store) == []);
    assert (summarize_status(store) == {});
    assert (total_runtime(store) == 0.0);
    assert (path_reaches(store, "missing") == False);
}

test "registry policy covers supported families" {
    assert (baseline_applicable("continuous_lg") == True);
    assert (baseline_applicable("continuous_nongauss") == True);
    assert (baseline_applicable("discrete") == False);
    assert (baseline_applicable("hybrid") == False);
    assert (accuracy_supported("continuous_lg") == False);
    assert (accuracy_supported("continuous_nongauss") == False);
}
