# iss_ilevkivskyi__typing_inspect__36.jac
# ilevkivskyi/typing_inspect#36 — type-tree origin deconstruction for recursive fold/rebuild

node TypeNode {
    has cid: str;
    has origin_name: str;
    has canonical_origin: str;
}

edge ArgEdge {}

node GraphRegistry {
    has anchor: TypeNode;
    has by_id: dict[str, TypeNode] = {};
}

walker FoldOrigins {
    has claimed: dict[str, bool] = {};
    has collected: list[str] = [];
    has root_id: str = "";

    can step with TypeNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.collected.append(here.canonical_origin);
        print(here.canonical_origin);
        kids: list[TypeNode] = [here ->:ArgEdge:->][?:TypeNode];
        for ch in kids {
            visit ch;
        }
    }
}

walker GatherLabels {
    has claimed: dict[str, bool] = {};
    has cache: dict[str, str] = {};
    has start_id: str = "";

    can gather with TypeNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        kids: list[TypeNode] = [here ->:ArgEdge:->][?:TypeNode];
        for ch in kids {
            visit ch;
        }
        parts: list[str] = [];
        for ch in kids {
            if ch.cid in self.cache {
                parts.append(self.cache[ch.cid]);
            }
        }
        parts = sorted(parts);
        inner = "";
        if len(parts) > 0 {
            inner = parts[0];
            idx = 1;
            while idx < len(parts) {
                inner = inner + ", " + parts[idx];
                idx += 1;
            }
            inner = "[" + inner + "]";
        }
        self.cache[here.cid] = here.canonical_origin + inner;
        print(self.cache[here.cid]);
    }
}

def resolve_canonical_origin(origin: str) -> str {
    if origin == "collections.abc.Iterable" {
        return "typing.Iterable";
    }
    if origin == "collections.abc.Mapping" {
        return "typing.Mapping";
    }
    if origin == "collections.abc.Sequence" {
        return "typing.Sequence";
    }
    return origin;
}

def get_origin(reg: GraphRegistry, type_id: str) -> str | None {
    if type_id not in reg.by_id {
        return None;
    }
    n = reg.by_id[type_id] as TypeNode;
    return n.origin_name;
}

def get_args(reg: GraphRegistry, type_id: str) -> list[str] {
    if type_id not in reg.by_id {
        return [];
    }
    n = reg.by_id[type_id] as TypeNode;
    kids: list[TypeNode] = [n ->:ArgEdge:->][?:TypeNode];
    out: list[str] = [];
    for kid in kids {
        out.append(kid.cid);
    }
    return sorted(out);
}

def fold_canonical_origins(reg: GraphRegistry, type_id: str) -> list[str] {
    if type_id not in reg.by_id {
        return [];
    }
    start = reg.by_id[type_id] as TypeNode;
    w = start spawn FoldOrigins(root_id=type_id);
    return sorted(w.collected);
}

def reconstruct_type(reg: GraphRegistry, type_id: str) -> str {
    if type_id not in reg.by_id {
        return "";
    }
    start = reg.by_id[type_id] as TypeNode;
    cache: dict[str, str] = {};
    wk = start spawn GatherLabels(start_id=type_id, cache=cache);
    if type_id in wk.cache {
        return wk.cache[type_id];
    }
    return "";
}

def make_iterable_int_reg -> GraphRegistry {
    iter_n = TypeNode(
        cid="iter",
        origin_name="collections.abc.Iterable",
        canonical_origin="typing.Iterable"
    );
    int_n = TypeNode(
        cid="int",
        origin_name="builtins.int",
        canonical_origin="builtins.int"
    );
    iter_n +>:ArgEdge:+> int_n;
    root ++> iter_n;
    idx: dict[str, TypeNode] = {};
    idx["iter"] = iter_n;
    idx["int"] = int_n;
    return GraphRegistry(anchor=iter_n, by_id=idx);
}

def make_diamond_reg -> GraphRegistry {
    u = TypeNode(cid="u", origin_name="typing.Union", canonical_origin="typing.Union");
    la = TypeNode(
        cid="la",
        origin_name="collections.abc.Iterable",
        canonical_origin="typing.Iterable"
    );
    lb = TypeNode(
        cid="lb",
        origin_name="collections.abc.Iterable",
        canonical_origin="typing.Iterable"
    );
    i = TypeNode(cid="i", origin_name="builtins.int", canonical_origin="builtins.int");
    u +>:ArgEdge:+> la;
    u +>:ArgEdge:+> lb;
    la +>:ArgEdge:+> i;
    lb +>:ArgEdge:+> i;
    root ++> u;
    idx: dict[str, TypeNode] = {};
    idx["u"] = u;
    idx["la"] = la;
    idx["lb"] = lb;
    idx["i"] = i;
    return GraphRegistry(anchor=u, by_id=idx);
}

with entry {
    reg = make_iterable_int_reg();
    w = reg.anchor spawn FoldOrigins(root_id="iter");
    print(get_origin(reg, "iter"));
    print(fold_canonical_origins(reg, "iter"));
    print(reconstruct_type(reg, "iter"));
    print(len(w.collected));
}

test "get_origin_iterable" {
    reg = make_iterable_int_reg();
    assert get_origin(reg, "iter") == "collections.abc.Iterable";;
}

test "get_args_iterable" {
    reg = make_iterable_int_reg();
    assert get_args(reg, "iter") == ["int"];;
}

test "fold_canonical_origins_iterable" {
    reg = make_iterable_int_reg();
    assert fold_canonical_origins(reg, "iter") == ["builtins.int", "typing.Iterable"];;
}

test "reconstruct_type_iterable" {
    reg = make_iterable_int_reg();
    assert reconstruct_type(reg, "iter") == "typing.Iterable[builtins.int]";;
}

test "diamond_reconstruct_union" {
    reg = make_diamond_reg();
    assert reconstruct_type(reg, "u") == "typing.Union[typing.Iterable[builtins.int], typing.Iterable[builtins.int]]";;
}

test "unknown_id_tolerance" {
    reg = make_iterable_int_reg();
    assert get_origin(reg, "missing") == None;;
    assert get_args(reg, "missing") == [];;
    assert fold_canonical_origins(reg, "missing") == [];;
    assert reconstruct_type(reg, "missing") == "";;
}
