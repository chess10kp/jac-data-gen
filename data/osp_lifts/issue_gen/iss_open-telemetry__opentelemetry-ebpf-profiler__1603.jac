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
