# iss_ilevkivskyi__typing_inspect__36.jac
# ilevkivskyi/typing_inspect#36 — type-tree origin walk with typing-canonical origins

node TypeNode {
    has tid: str;
    has origin_name: str;
}

edge ArgEdge {}

def origin_aliases -> dict[str, str] {
    aliases: dict[str, str] = {};
    aliases["collections.abc.Iterable"] = "typing.Iterable";
    aliases["collections.abc.Mapping"] = "typing.Mapping";
    aliases["collections.abc.Sequence"] = "typing.Sequence";
    aliases["collections.abc.Callable"] = "typing.Callable";
    return aliases;
}

def normalize_origin(name: str) -> str {
    aliases = origin_aliases;
    if name in aliases {
        return aliases[name];
    }
    return name;
}

def get_origin(node_id: str, store: dict[str, TypeNode]) -> str | None {
    if node_id not in store {
        return None;
    }
    nd = store[node_id] as TypeNode;
    return normalize_origin(nd.origin_name);
}

def get_args(node_id: str, store: dict[str, TypeNode]) -> list[str] {
    if node_id not in store {
        return [];
    }
    parent = store[node_id] as TypeNode;
    args: list[str] = [];
    for ch in [parent ->:ArgEdge:->][?:TypeNode] {
        args.append(ch.tid);
    }
    return sorted(args);
}

walker OriginWalker {
    has claimed: dict[str, bool] = {};
    has bag: list[str] = {};

    can step with TypeNode entry {
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        canon = normalize_origin(here.origin_name);
        self.bag.append(canon);
        print("origin " + here.tid + " => " + canon);
        kids: list[TypeNode] = [here ->:ArgEdge:->][?:TypeNode];
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def collect_origins(node_id: str, store: dict[str, TypeNode]) -> list[str] {
    if node_id not in store {
        return [];
    }
    graph_root = store[node_id] as TypeNode;
    w = graph_root spawn OriginWalker(claimed={}, bag={});
    uniq: dict[str, bool] = {};
    for name in w.bag {
        uniq[name] = True;
    }
    out: list[str] = [];
    for name in uniq {
        out.append(name);
    }
    return sorted(out);
}
