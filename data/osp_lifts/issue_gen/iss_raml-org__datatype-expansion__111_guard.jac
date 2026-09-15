"""Lift target: raml-org/datatype-expansion#111 — recursive minType / $recur markers."""

glob RECUR: str = "$recur";
glob UNKNOWN: str = "unknown";

node TypeNode {
    has tid: str;
    has kind: str;
}

edge Ref {}

obj SchemaBundle {
    has graph_root: TypeNode;
    has registry: dict[str, TypeNode] = {};
}

def min_type(candidates: list) -> str {
    if len(candidates) == 0 {
        return UNKNOWN;
    }
    normalized: list[str] = [];
    for c in candidates {
        normalized.append(str(c));
    }
    all_recur: bool = True;
    for c in normalized {
        if c != RECUR {
            all_recur = False;
            break;
        }
    }
    if all_recur {
        return RECUR;
    }
    non_recur: list[str] = [];
    for c in normalized {
        if c != RECUR {
            non_recur.append(c);
        }
    }
    if len(non_recur) == 0 {
        return RECUR;
    }
    base: str = non_recur[0];
    uniform: bool = True;
    for c in non_recur {
        if c != base {
            uniform = False;
            break;
        }
    }
    if uniform {
        return base;
    }
    return "incompatible";
}

walker CollectKinds {
    has claimed: dict[str, bool] = {};
    has kinds: list[str] = [];

    can step with TypeNode entry {
        if here.tid in self.claimed {
            self.kinds.append(RECUR);
            print("recur", here.tid);
            skip;
        }
        self.claimed[here.tid] = True;
        self.kinds.append(here.kind);
        print("visit", here.tid, here.kind);
        kids: list[TypeNode] = [];
        for ch in [here ->:Ref:->][?:TypeNode] {
            kids.append(ch);
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def expand_recursive(graph_root: TypeNode, type_name: str, registry: dict[str, TypeNode]) -> list[str] {
    if type_name not in registry {
        return [];
    }
    start: TypeNode = registry[type_name];
    wk = start spawn CollectKinds(claimed={}, kinds=[]);
    print("expand_recursive", type_name, len(wk.kinds));
    return wk.kinds;
}

def canonical_min(graph_root: TypeNode, type_name: str, registry: dict[str, TypeNode]) -> str {
    kinds: list[str] = expand_recursive(graph_root, type_name, registry);
    return min_type(kinds);
}

def to_canonical(graph_root: TypeNode, type_name: str, registry: dict[str, TypeNode]) -> dict {
    resolved: str = canonical_min(graph_root, type_name, registry);
    out: dict = {};
    out["type"] = resolved;
    return out;
}

def build_self_ref_schema() -> SchemaBundle {
    graph_root = TypeNode(tid="__root__", kind="anchor");
    root ++> graph_root;
    foo = TypeNode(tid="Foo", kind="object");
    graph_root +>:Ref:+> foo;
    foo +>:Ref:+> foo;
    registry: dict[str, TypeNode] = {};
    registry["Foo"] = foo;
    return SchemaBundle(graph_root=graph_root, registry=registry);
}

def build_diamond_schema() -> SchemaBundle {
    graph_root = TypeNode(tid="__root__", kind="anchor");
    root ++> graph_root;
    foo = TypeNode(tid="Foo", kind="object");
    bar = TypeNode(tid="Bar", kind="object");
    baz = TypeNode(tid="Baz", kind="object");
    graph_root +>:Ref:+> foo;
    foo +>:Ref:+> bar;
    foo +>:Ref:+> baz;
    bar +>:Ref:+> foo;
    baz +>:Ref:+> foo;
    registry: dict[str, TypeNode] = {};
    registry["Foo"] = foo;
    registry["Bar"] = bar;
    registry["Baz"] = baz;
    return SchemaBundle(graph_root=graph_root, registry=registry);
}

test "min_type_pair_recur_collapses" {
    got: str = min_type(["$recur", "$recur"]);
    assert got == "$recur";;
}

test "self_ref_canonical_object" {
    bundle = build_self_ref_schema();
    got: str = canonical_min(bundle.graph_root, "Foo", bundle.registry);
    assert got == "object";;
}

test "diamond_revisit_emits_multiple_recur" {
    bundle = build_diamond_schema();
    kinds: list[str] = expand_recursive(bundle.graph_root, "Foo", bundle.registry);
    recur_count: int = 0;
    for k in kinds {
        if k == "$recur" {
            recur_count += 1;
        }
    }
    assert recur_count >= 2;;
    collapsed: str = min_type(kinds);
    assert collapsed == "object";;
}

test "unknown_type_id_tolerated" {
    bundle = build_self_ref_schema();
    kinds: list[str] = expand_recursive(bundle.graph_root, "Missing", bundle.registry);
    assert len(kinds) == 0;;
    canon: dict = to_canonical(bundle.graph_root, "Missing", bundle.registry);
    assert canon["type"] == "unknown";;
}

test "min_type_incompatible_primitives" {
    got: str = min_type(["object", "array"]);
    assert got == "incompatible";;
}
