"""HaxeFoundation/haxe#11233 — inline overload recursive dispatch."""

node Slot {
    has name: str;
    has arg_type: str;
    has terminal: bool = False;
    has cid: str;
}

edge Resolve {}

obj OverloadResolver {
    has slot_map: dict[str, Slot] = {};
    has graph_root: Slot;
}

walker ChainWalker {
    has claimed: dict[str, bool] = {};
    has path: list[str] = [];
    has cycled: bool = False;

    can step with Slot entry {
        if here.cid in self.claimed {
            self.cycled = True;
            print({"event": "skip", "cid": here.cid});
            skip;
        }
        self.claimed[here.cid] = True;
        label = here.name + ":" + here.arg_type;
        self.path.append(label);
        print({"event": "visit", "label": label});
        if not here.terminal {
            outs: list[Slot] = [here ->:Resolve:->][?:Slot];
            if len(outs) > 0 {
                visit :0: outs;
            } else {
                disengage;
            }
        }
    }
}

def make_resolver -> OverloadResolver {
    rt = Slot(name="__root__", arg_type="", terminal=True, cid="__root__");
    root ++> rt;
    smap: dict[str, Slot] = {};
    res = OverloadResolver(slot_map=smap, graph_root=rt);
    return res;
}

def register_slot(
    resolver: OverloadResolver,
    name: str,
    arg_type: str,
    terminal: bool = False,
) -> None {
    key = name + "|" + arg_type;
    if key in resolver.slot_map {
        return;
    }
    nd = Slot(name=name, arg_type=arg_type, terminal=terminal, cid=key);
    resolver.slot_map[key] = nd;
    resolver.graph_root ++> nd;
}

def link_overload(
    resolver: OverloadResolver,
    from_name: str,
    from_arg: str,
    to_name: str,
    to_arg: str,
) -> None {
    fkey = from_name + "|" + from_arg;
    tkey = to_name + "|" + to_arg;
    if fkey not in resolver.slot_map {
        return;
    }
    if tkey not in resolver.slot_map {
        return;
    }
    src = resolver.slot_map[fkey] as Slot;
    dst = resolver.slot_map[tkey] as Slot;
    src +>:Resolve:+> dst;
}

def resolve_chain(
    resolver: OverloadResolver,
    name: str,
    arg_type: str,
) -> tuple[list[str], bool] {
    key = name + "|" + arg_type;
    if key not in resolver.slot_map {
        empty: list[str] = [];
        return (empty, False);
    }
    start_nd = resolver.slot_map[key] as Slot;
    w = start_nd spawn ChainWalker(claimed={}, path=[], cycled=False);
    return (w.path, w.cycled);
}

def add(resolver: OverloadResolver, item_id: int) -> bool {
    chain = resolve_chain(resolver, "add", "id_int");
    path = chain[0];
    cycled = chain[1];
    if cycled {
        return False;
    }
    if len(path) == 0 {
        return False;
    }
    return True;
}

test "add_missing_slot" {
    res = make_resolver();
    assert not add(res, 1);
}

test "add_terminal_slot" {
    res = make_resolver();
    register_slot(res, "add", "id_int", True);
    assert add(res, 42);
}

test "resolve_chain_unknown" {
    res = make_resolver();
    out = resolve_chain(res, "missing", "none");
    assert len(out[0]) == 0;
    assert not out[1];
}

test "linear_resolve_path" {
    res = make_resolver();
    register_slot(res, "add", "id_int", False);
    register_slot(res, "add", "obj", True);
    link_overload(res, "add", "id_int", "add", "obj");
    out = resolve_chain(res, "add", "id_int");
    assert not out[1];
    assert len(out[0]) == 2;
    assert out[0][0] == "add:id_int";
    assert out[0][1] == "add:obj";
}

test "recursive_overload_cycle" {
    res = make_resolver();
    register_slot(res, "add", "id_int", False);
    register_slot(res, "add", "fallback", False);
    link_overload(res, "add", "id_int", "add", "fallback");
    link_overload(res, "add", "fallback", "add", "id_int");
    out = resolve_chain(res, "add", "id_int");
    assert out[1];
    assert not add(res, 1);
}

test "link_missing_slots_noop" {
    res = make_resolver();
    register_slot(res, "add", "id_int", True);
    link_overload(res, "add", "id_int", "missing", "x");
    assert add(res, 1);
}
