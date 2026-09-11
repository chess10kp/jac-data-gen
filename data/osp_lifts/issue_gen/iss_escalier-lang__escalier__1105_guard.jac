"""escalier-lang/escalier#1105 — class extends graph cycle detection."""

class ExtendsCycleError(Exception) {}

node ClassDef {
    has name: str;
}

edge Extends {}

obj ClassStore {
    has classes: dict[str, ClassDef] = {};
}

def load_classes(
    classes: list[tuple[str, str | None]],
) -> ClassStore {
    store = ClassStore();
    for (name, base) in classes {
        nd = ClassDef(name=name);
        root ++> nd;
        store.classes[name] = nd;
    }
    for (name, base) in classes {
        if base is not None {
            child = store.classes.get(name, None);
            parent = store.classes.get(base, None);
            if child is not None and parent is not None {
                child +>:Extends:+> parent;
            }
        }
    }
    return store;
}

def extends_chain(store: ClassStore, class_name: str) -> list[str] {
    nd = store.classes.get(class_name, None);
    if nd is None { return []; }
    chain: list[str] = [];
    cur: ClassDef | None = nd;
    seen: dict[str, bool] = {};
    while cur is not None {
        if cur.name in seen { break; }
        seen[cur.name] = True;
        chain.append(cur.name);
        parent: ClassDef | None = None;
        for p in [cur ->:Extends:->][?:ClassDef] {
            parent = p;
            break;
        }
        cur = parent;
    }
    return chain;
}

def extends_cycle_classes(store: ClassStore) -> list[str] {
    found: dict[str, bool] = {};
    for cls in sorted(store.classes.keys()) {
        nd = store.classes.get(cls, None);
        if nd is None { continue; }
        cur: ClassDef | None = nd;
        seen: dict[str, bool] = {};
        while cur is not None {
            if cur.name in seen {
                found[cur.name] = True;
                break;
            }
            seen[cur.name] = True;
            parent: ClassDef | None = None;
            for p in [cur ->:Extends:->][?:ClassDef] {
                parent = p;
                break;
            }
            cur = parent;
        }
    }
    out: list[str] = [];
    for k in sorted(found.keys()) { out.append(k); }
    return out;
}

def add_extends(store: ClassStore, child: str, base: str | None) {
    if base is not None {
        cur_nd = store.classes.get(base, None);
        seen: dict[str, bool] = {};
        seen[child] = True;
        while cur_nd is not None {
            if cur_nd.name in seen {
                raise ExtendsCycleError(f"cycle involving {child}");
            }
            seen[cur_nd.name] = True;
            parent: ClassDef | None = None;
            for p in [cur_nd ->:Extends:->][?:ClassDef] {
                parent = p;
                break;
            }
            cur_nd = parent;
        }
    }
    cnd = store.classes.get(child, None);
    if cnd is None {
        cnd = ClassDef(name=child);
        root ++> cnd;
        store.classes[child] = cnd;
    }
    for old in [cnd ->:Extends:->][?:ClassDef] {
        cnd del ->:Extends:-> old;
    }
    if base is not None {
        bnd = store.classes.get(base, None);
        if bnd is not None { cnd +>:Extends:+> bnd; }
    }
}

def is_valid_hierarchy(store: ClassStore) -> bool {
    return len(extends_cycle_classes(store)) == 0;
}

test "extends cycle detection" {
    store = load_classes([("A", "B"), ("B", "A")]);
    assert sorted(extends_cycle_classes(store)) == ["A", "B"];
    assert is_valid_hierarchy(store) is False;

    store2 = load_classes([("Child", "Base"), ("Base", None)]);
    assert extends_chain(store2, "Child") == ["Child", "Base"];
    assert is_valid_hierarchy(store2) is True;
}

test "self extend raises" {
    store3 = load_classes([("X", None)]);
    caught = False;
    try {
        add_extends(store3, "X", "X");
    } except ExtendsCycleError {
        caught = True;
    }
    assert caught is True;
}
