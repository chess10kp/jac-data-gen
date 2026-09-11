"""OSP lift for open-telemetry/opentelemetry-ebpf-profiler#1603."""

node TypeSpec {
    has name: str;
    has enclosing_class: str = "";
    has full_name: str = "";
    has chain: list[str] = [];
}

edge NestedClass {}

walker EnclosingWalk {
    has claimed: dict[str, bool] = {};

    can step with TypeSpec entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print(here.cid);

        for parent in [here ->:NestedClass:->][?:TypeSpec] {
            if len(parent.chain) == 0 {
                parent.chain = here.chain;
                parent.chain.append(parent.cid);
            }
            visit :0: [parent];
        }
    }
}

def link_nested(nested: TypeSpec, enclosing: TypeSpec) {
    nested.enclosing_class = enclosing.cid;
    nested +>:NestedClass:+> enclosing;
}

def find_type(types: list[TypeSpec], wanted: str) -> TypeSpec | None {
    for item in types {
        if item.cid == wanted {
            return item;
        }
    }
    return None;
}

def collect_enclosing_ids(start: TypeSpec) -> list[str] {
    start.chain = [];
    start.chain.append(start.cid);
    start spawn EnclosingWalk;
    return start.chain;
}

def resolve_method_name(start: TypeSpec) -> str {
    if start.full_name == "" {
        start.full_name = start.name;
    }
    collect_enclosing_ids(start);
    return start.full_name;
}

test "self cycle terminates" {
    item = TypeSpec(name="Self");
    link_nested(item, item);
    ids = collect_enclosing_ids(item);
    assert (ids == ["Self"]);
    assert (resolve_method_name(item) == "Self");
}

test "diamond revisits are claimed once" {
    leaf = TypeSpec(name="Leaf");
    left = TypeSpec(name="Left");
    right = TypeSpec(name="Right");
    top = TypeSpec(name="Top");
    link_nested(leaf, left);
    link_nested(leaf, right);
    link_nested(left, top);
    link_nested(right, top);
    ids = collect_enclosing_ids(leaf);
    assert (sorted(ids) == sorted([leaf.cid, left.cid, right.cid, top.cid]));
}

test "unknown type is tolerated" {
    known = TypeSpec(name="Known");
    types: list[TypeSpec] = [];
    types.append(known);
    missing = find_type(types, "missing");
    assert (missing == None);
}

test "ordinary enclosing name remains stable" {
    outer = TypeSpec(name="Outer");
    inner = TypeSpec(name="Inner");
    link_nested(inner, outer);
    assert (resolve_method_name(inner) == "Inner");
    assert (len(collect_enclosing_ids(inner)) == 2);
}
