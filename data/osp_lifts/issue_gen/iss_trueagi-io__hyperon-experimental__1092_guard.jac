"""Guard: trueagi-io/hyperon-experimental#1092."""

node TypeNode { has name: str; }
edge SubtypeOf {}
edge Imports {}
obj TypeStore { has types: dict[str, TypeNode] = {}; }

walker SupertypeWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has max_depth: int = 0;
    has depth: int = 0;
    can step with TypeNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if self.depth > 0 { self.found.append(here.name); }
        if self.depth >= self.max_depth { disengage; }
        for sup in [here ->:SubtypeOf:->][?:TypeNode] {
            if not (sup.name in self.claimed) {
                child = sup spawn SupertypeWalk(
                    claimed=self.claimed, found=self.found,
                    max_depth=self.max_depth, depth=self.depth + 1,
                );
                self.claimed = child.claimed;
                self.found = child.found;
            }
        }
    }
}

walker ImportProbe {
    has claimed: dict[str, bool] = {};
    has target: str = "";
    has origin: str = "";
    has mutual: bool = False;
    can step with TypeNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        for nxt in [here ->:Imports:->][?:TypeNode] {
            if here.name == self.origin and nxt.name == self.target {
                for r in [nxt ->:Imports:->][?:TypeNode] {
                    if r.name == self.origin { self.mutual = True; }
                }
            }
            if not (nxt.name in self.claimed) { visit [nxt]; }
        }
    }
}

def load_type_graph(
    types: list[str],
    supertypes: list[tuple[str, str]],
    imports: list[tuple[str, str]] | None = None,
) -> TypeStore {
    store = TypeStore();
    for name in types {
        nd = TypeNode(name=name);
        root ++> nd;
        store.types[name] = nd;
    }
    for (sub, sup) in supertypes {
        s = store.types.get(sub, None);
        p = store.types.get(sup, None);
        if s is not None and p is not None { s +>:SubtypeOf:+> p; }
    }
    if imports is not None {
        for (src, dst) in imports {
            a = store.types.get(src, None);
            b = store.types.get(dst, None);
            if a is not None and b is not None { a +>:Imports:+> b; }
        }
    }
    return store;
}

def collect_supertypes(store: TypeStore, type_name: str, max_depth: int) -> list[str] {
    nd = store.types.get(type_name, None);
    if nd is None or max_depth < 0 { return []; }
    w = nd spawn SupertypeWalk(claimed={}, found=[], max_depth=max_depth, depth=0);
    return sorted(w.found);
}

def detect_mutual_import(store: TypeStore, module_a: str, module_b: str) -> bool {
    a = store.types.get(module_a, None);
    if a is None { return False; }
    w = a spawn ImportProbe(claimed={}, target=module_b, origin=module_a, mutual=False);
    return w.mutual;
}

test "bounded supertypes" {
    store = load_type_graph(["A", "B", "C", "D"], [("A", "B"), ("B", "C"), ("C", "D")]);
    assert collect_supertypes(store, "A", 2) == ["B", "C"];
    assert collect_supertypes(store, "A", 10) == ["B", "C", "D"];
}

test "mutual import detect" {
    store = load_type_graph(["M1", "M2"], [], [("M1", "M2"), ("M2", "M1")]);
    assert detect_mutual_import(store, "M1", "M2") is True;
}
