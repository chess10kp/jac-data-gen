"""tristanpenman/valijson#200 — recursive JSON Schema $ref resolution and cycle detection."""

node SchemaLoc {
    has ptr: str;
    has ref_to: str = "";
}

edge Child {}
edge Ref {}

def ensure_loc(store: dict[str, SchemaLoc], ptr: str) -> SchemaLoc {
    if ptr in store {
        return store[ptr];
    }
    nd = SchemaLoc(ptr=ptr);
    store[ptr] = nd;
    return nd;
}

def make_registry(entries: list[dict]) -> dict[str, SchemaLoc] {
    store: dict[str, SchemaLoc] = {};
    for ent in entries {
        ptr = ent["ptr"] as str;
        ref_to = "";
        if "ref" in ent {
            ref_to = ent["ref"] as str;
        }
        nd = ensure_loc(store, ptr);
        if ref_to != "" {
            nd.ref_to = ref_to;
        }
    }
    for ent in entries {
        ptr = ent["ptr"] as str;
        src = store[ptr];
        if "children" in ent {
            kids = ent["children"] as list;
            for cp in kids {
                ch_ptr = cp as str;
                ch = ensure_loc(store, ch_ptr);
                src +>:Child:+> ch;
            }
        }
        if "ref" in ent {
            rp = ent["ref"] as str;
            if rp != "" {
                tgt = ensure_loc(store, rp);
                src +>:Ref:+> tgt;
            }
        }
    }
    return store;
}

walker CollectOrdered {
    has claimed: dict[str, bool] = {};
    has ordered: list[str] = [];
    has store: dict[str, SchemaLoc] = {};

    can step with SchemaLoc entry {
        if here.ptr in self.claimed { skip; }
        self.claimed[here.ptr] = True;
        self.ordered.append(here.ptr);
        print("visit ", here.ptr);
        chs: list[SchemaLoc] = [here ->:Child:->][?:SchemaLoc];
        for ch in chs {
            visit :0: ch;
        }
        if here.ref_to != "" {
            if here.ref_to in self.store {
                visit :0: self.store[here.ref_to];
            }
        }
    }
}

walker CycleDetect {
    has chain: dict[str, bool] = {};
    has found: bool = False;
    has store: dict[str, SchemaLoc] = {};

    can probe with SchemaLoc entry {
        if here.ptr in self.chain {
            self.found = True;
            print("cycle_hit ", here.ptr);
            disengage;
        }
        self.chain[here.ptr] = True;
        print("probe ", here.ptr);
        if here.ref_to != "" {
            if here.ref_to in self.store {
                visit self.store[here.ref_to];
            } else {
                disengage;
            }
        } else {
            disengage;
        }
    }
}

def ordered_ref_nodes(store: dict[str, SchemaLoc], start_ptr: str) -> list[str] {
    if start_ptr not in store {
        print("ordered_ref_nodes ", 0);
        return [];
    }
    graph_root = ensure_loc(store, start_ptr);
    root ++> graph_root;
    wk = graph_root spawn CollectOrdered(claimed={}, ordered=[], store=store);
    print("ordered_ref_nodes ", len(wk.ordered));
    return wk.ordered;
}

def detect_ref_cycle(store: dict[str, SchemaLoc], start_ptr: str) -> bool {
    if start_ptr not in store {
        print("detect_ref_cycle ", False);
        return False;
    }
    graph_root = ensure_loc(store, start_ptr);
    root ++> graph_root;
    wk = graph_root spawn CycleDetect(chain={}, found=False, store=store);
    print("detect_ref_cycle ", wk.found);
    return wk.found;
}

test "linear ref chain ordered nodes" {
    entries: list[dict] = [
        {"ptr": "#", "children": ["#/l1"]},
        {"ptr": "#/l1", "ref": "#/l2"},
        {"ptr": "#/l2", "ref": "#/l3"},
        {"ptr": "#/l3", "ref": ""},
    ];
    store = make_registry(entries);
    got = ordered_ref_nodes(store, "#");
    assert got == ["#", "#/l1", "#/l2", "#/l3"];
}

test "self ref items zero cycle" {
    entries: list[dict] = [
        {"ptr": "#", "children": ["#/items/0"]},
        {"ptr": "#/items/0", "ref": "#/items/0"},
    ];
    store = make_registry(entries);
    assert detect_ref_cycle(store, "#/items/0");
}

test "two node ref cycle a to b to a" {
    entries: list[dict] = [
        {"ptr": "#/a", "ref": "#/b"},
        {"ptr": "#/b", "ref": "#/a"},
    ];
    store = make_registry(entries);
    assert detect_ref_cycle(store, "#/a");
}

test "diamond shared ref visited once" {
    entries: list[dict] = [
        {"ptr": "#", "children": ["#/l1", "#/l2"]},
        {"ptr": "#/l1", "ref": "#/shared"},
        {"ptr": "#/l2", "ref": "#/shared"},
        {"ptr": "#/shared", "ref": ""},
    ];
    store = make_registry(entries);
    got = ordered_ref_nodes(store, "#");
    assert len(got) == 4;
    assert sorted(got) == ["#", "#/l1", "#/l2", "#/shared"];
}

test "unknown start pointer tolerance" {
    entries: list[dict] = [
        {"ptr": "#", "ref": ""},
    ];
    store = make_registry(entries);
    assert ordered_ref_nodes(store, "#/missing") == [];
    assert detect_ref_cycle(store, "#/missing") == False;
}

test "acyclic ref chain no cycle" {
    entries: list[dict] = [
        {"ptr": "#/a", "ref": "#/b"},
        {"ptr": "#/b", "ref": "#/c"},
        {"ptr": "#/c", "ref": ""},
    ];
    store = make_registry(entries);
    assert detect_ref_cycle(store, "#/a") == False;
}
