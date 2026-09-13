node Module {
    has mid: str;
}
node Commit {
    has cid: str;
}
edge Depends {}
edge Parent {}

walker DepWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can step with Module entry {
        if here.mid in self.claimed {
            skip;
        }
        self.claimed[here.mid] = True;
        self.found.append(here.mid);
        print(here.mid);
        kids: list[Module] = [here ->:Depends:->][?:Module];
        visit :0: kids else {
            disengage;
        }
    }
}

walker CommitWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can step with Commit entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print(here.cid);
        kids: list[Commit] = [here ->:Parent:->][?:Commit];
        visit :0: kids else {
            disengage;
        }
    }
}

def create_registry() -> dict[str, Module] {
    reg: dict[str, Module] = {};
    return reg;
}

def create_module_registry() -> dict[str, Module] {
    return create_registry();
}

def register_module(reg: dict[str, Module], mid: str) -> Module {
    if mid in reg {
        return reg[mid];
    }
    nd = Module(mid=mid);
    root ++> nd;
    reg[mid] = nd;
    return nd;
}

def add_dependency(reg: dict[str, Module], from_id: str, to_id: str) -> None {
    a = register_module(reg, from_id);
    b = register_module(reg, to_id);
    a +>:Depends:+> b;
}

def get_transitive_deps(reg: dict[str, Module], start_id: str) -> list[str] {
    if start_id not in reg {
        return [];
    }
    start: Module = reg[start_id];
    w = start spawn DepWalker(claimed={});
    return w.found;
}

def create_commit_store() -> dict[str, Commit] {
    store: dict[str, Commit] = {};
    return store;
}

def register_commit(store: dict[str, Commit], cid: str) -> Commit {
    if cid in store {
        return store[cid];
    }
    nd = Commit(cid=cid);
    root ++> nd;
    store[cid] = nd;
    return nd;
}

def add_parent(store: dict[str, Commit], child: str, parent: str) -> None {
    c = register_commit(store, child);
    p = register_commit(store, parent);
    c +>:Parent:+> p;
}

def get_commit_lineage(store: dict[str, Commit], start_id: str) -> list[str] {
    if start_id not in store {
        return [];
    }
    start: Commit = store[start_id];
    w = start spawn CommitWalker(claimed={});
    return w.found;
}

def get_ancestors(store: dict[str, Commit], start_id: str) -> list[str] {
    return get_commit_lineage(store, start_id);
}

with entry {
    demo_reg = create_registry();
    add_dependency(demo_reg, "demoA", "demoB");
    a = demo_reg["demoA"];
    w = a spawn DepWalker(claimed={});
    print(w.found);
    demo_store = create_commit_store();
    register_commit(demo_store, "demoC");
    c = demo_store["demoC"];
    w2 = c spawn CommitWalker(claimed={});
    print(w2.found);
}

test "transitive_deps_diamond_and_cycle" {
    reg = create_registry();
    add_dependency(reg, "X", "Y");
    add_dependency(reg, "X", "Z");
    add_dependency(reg, "Y", "W");
    add_dependency(reg, "Z", "W");
    add_dependency(reg, "W", "X");
    res = get_transitive_deps(reg, "X");
    assert(sorted(res) == sorted(["X", "Y", "Z", "W"]));
    assert(len(res) == 4);
}

test "transitive_deps_unknown_and_single" {
    reg = create_registry();
    add_dependency(reg, "A", "B");
    res = get_transitive_deps(reg, "MISSING");
    assert(res == []);
    res2 = get_transitive_deps(reg, "B");
    assert(sorted(res2) == sorted(["B"]));
    assert(len(res2) == 1);
}

test "commit_lineage_diamond_and_cycle" {
    store = create_commit_store();
    add_parent(store, "A", "B");
    add_parent(store, "A", "C");
    add_parent(store, "B", "D");
    add_parent(store, "C", "D");
    add_parent(store, "D", "A");
    res = get_commit_lineage(store, "A");
    assert(sorted(res) == sorted(["A", "B", "C", "D"]));
    assert(len(res) == 4);
}

test "commit_lineage_unknown_and_chain" {
    store = create_commit_store();
    register_commit(store, "X");
    res = get_commit_lineage(store, "X");
    assert(res == ["X"]);
    assert(len(res) == 1);
    assert(get_commit_lineage(store, "NOPE") == []);
    add_parent(store, "Y", "X");
    add_parent(store, "Z", "Y");
    res2 = get_commit_lineage(store, "Z");
    assert(sorted(res2) == sorted(["Z", "Y", "X"]));
    assert(len(res2) == 3);
}
