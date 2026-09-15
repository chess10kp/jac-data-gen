"""FK dependency cycle detection — 512itconsulting/dbpm#25."""

node Table {
    has name: str;
}

edge FkRef {}

node TableRegistry {
    has lookup: dict[str, Table] = {};
}

walker CollectReachable {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Table entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.found.append(here.name);
        print("visit " + here.name);
        for dep in [here ->:FkRef:->][?:Table] {
            if dep.name == here.name { continue; }
            visit :0: [dep];
        }
    }
}

def make_registry() -> TableRegistry {
    reg = TableRegistry();
    root ++> reg;
    return reg;
}

def ensure_table(registry: TableRegistry, name: str) -> Table {
    if name in registry.lookup {
        return registry.lookup[name] as Table;
    }
    tbl = Table(name=name);
    registry.lookup[name] = tbl;
    root ++> tbl;
    return tbl;
}

def get_table(registry: TableRegistry, name: str) -> Table | None {
    if name not in registry.lookup {
        return None;
    }
    return registry.lookup[name] as Table;
}

def add_dependency(registry: TableRegistry, child_name: str, parent_name: str) -> None {
    child = ensure_table(registry, child_name);
    parent = ensure_table(registry, parent_name);
    child +>:FkRef:+> parent;
}

def table_neighbors(tbl: Table) -> list[Table] {
    deps: list[Table] = [];
    for dep in [tbl ->:FkRef:->][?:Table] {
        deps.append(dep);
    }
    return deps;
}

def dfs_cycle_visit(tbl: Table, state: dict[str, int], stack: list[str]) -> list[str] | None {
    name = tbl.name;
    state[name] = 1;
    stack.append(name);
    for dep in table_neighbors(tbl) {
        dep_name = dep.name;
        if dep_name == name {
            continue;
        }
        if state[dep_name] == 1 {
            cyc: list[str] = [];
            start_idx: int = -1;
            for i in range(len(stack)) {
                if stack[i] == dep_name {
                    start_idx = i;
                    break;
                }
            }
            if start_idx >= 0 {
                for j in range(start_idx, len(stack)) {
                    cyc.append(stack[j]);
                }
                return sorted(cyc);
            }
        }
        if state[dep_name] == 0 {
            result = dfs_cycle_visit(dep, state, stack);
            if result is not None {
                return result;
            }
        }
    }
    stack.pop();
    state[name] = 2;
    return None;
}

def circular_dependency_tables(registry: TableRegistry) -> list[str] | None {
    state: dict[str, int] = {};
    for tname in registry.lookup {
        state[tname] = 0;
    }
    stack: list[str] = [];
    for tname in sorted(registry.lookup.keys()) {
        if state[tname] == 0 {
            tbl = registry.lookup[tname] as Table;
            result = dfs_cycle_visit(tbl, state, stack);
            if result is not None {
                return result;
            }
        }
    }
    return None;
}

def script_generation_order(registry: TableRegistry) -> list[str] {
    if circular_dependency_tables(registry) is not None {
        return [];
    }
    indeg: dict[str, int] = {};
    for tname in registry.lookup {
        indeg[tname] = 0;
    }
    for tname in registry.lookup {
        tbl = registry.lookup[tname] as Table;
        for dep in table_neighbors(tbl) {
            if dep.name != tname {
                indeg[tname] = indeg[tname] + 1;
            }
        }
    }
    queue: list[str] = [];
    for tname in sorted(indeg.keys()) {
        if indeg[tname] == 0 {
            queue.append(tname);
        }
    }
    order: list[str] = [];
    while len(queue) > 0 {
        cur = queue[0];
        rest: list[str] = [];
        for qi in range(1, len(queue)) {
            rest.append(queue[qi]);
        }
        queue = rest;
        order.append(cur);
        for tname in sorted(registry.lookup.keys()) {
            tbl = registry.lookup[tname] as Table;
            refs_cur = False;
            for dep in table_neighbors(tbl) {
                if dep.name == cur and dep.name != tbl.name {
                    refs_cur = True;
                    break;
                }
            }
            if refs_cur {
                indeg[tname] = indeg[tname] - 1;
                if indeg[tname] == 0 {
                    queue.append(tname);
                }
            }
        }
    }
    if len(order) != len(registry.lookup) {
        return [];
    }
    return order;
}

def reachable_from(registry: TableRegistry, start_name: str) -> list[str] {
    tbl = get_table(registry, start_name);
    if tbl is None {
        return [];
    }
    w = tbl spawn CollectReachable(claimed={});
    return sorted(w.found);
}

test "recon_core_no_false_cycle" {
    reg = make_registry();
    add_dependency(reg, "RC_SUBJECT_SNAPSHOT", "RC_SUBJECT");
    add_dependency(reg, "RC_SUBJECT_SNAPSHOT", "RC_SUBJECT_SNAPSHOT");
    add_dependency(reg, "RC_SNAPSHOT_DATASET", "RC_SUBJECT_SNAPSHOT");
    add_dependency(reg, "RC_SNAPSHOT_DATASET", "RC_DATASET");
    add_dependency(reg, "RC_SNAPSHOT_DATASET", "RC_RUN");
    add_dependency(reg, "RC_SUBJECT_RESULT", "RC_SUBJECT_SNAPSHOT");
    assert circular_dependency_tables(reg) is None;
    order = script_generation_order(reg);
    assert len(order) == 6;
    assert "RC_SUBJECT" in order;
    assert order.index("RC_SUBJECT") < order.index("RC_SUBJECT_SNAPSHOT");
}

test "genuine_three_table_cycle" {
    reg = make_registry();
    add_dependency(reg, "A", "B");
    add_dependency(reg, "B", "C");
    add_dependency(reg, "C", "A");
    cyc = circular_dependency_tables(reg);
    assert cyc == ["A", "B", "C"];
    assert script_generation_order(reg) == [];
}

test "self_fk_only_no_cycle" {
    reg = make_registry();
    add_dependency(reg, "SOLO", "SOLO");
    assert circular_dependency_tables(reg) is None;
    assert script_generation_order(reg) == ["SOLO"];
}

test "diamond_revisit_claim_skip" {
    reg = make_registry();
    add_dependency(reg, "A", "B");
    add_dependency(reg, "A", "C");
    add_dependency(reg, "B", "D");
    add_dependency(reg, "C", "D");
    found = reachable_from(reg, "A");
    assert found == ["A", "B", "C", "D"];
    start_tbl = reg.lookup["A"] as Table;
    w = start_tbl spawn CollectReachable(claimed={});
    assert sorted(w.found) == ["A", "B", "C", "D"];
}

test "unknown_table_tolerance" {
    reg = make_registry();
    assert get_table(reg, "MISSING") is None;
    assert reachable_from(reg, "MISSING") == [];
    add_dependency(reg, "T1", "T2");
    assert get_table(reg, "T1") is not None;
    assert get_table(reg, "NOPE") is None;
}
