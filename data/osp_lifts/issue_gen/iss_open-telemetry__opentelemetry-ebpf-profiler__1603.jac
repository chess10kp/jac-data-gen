# open-telemetry/opentelemetry-ebpf-profiler#1603 — NestedClass enclosing walk with cycle guard.

node TypeSpec {
    has cid: str;
    has type_name: str;
}

node Anchor {
    has tag: str = "boot";
}

edge Encloses {}
edge Nests {}

obj PeIndex {
    has graph_root: TypeSpec;
    has nodes_by_id: dict[str, TypeSpec] = {};
}

def reverse_list(xs: list[str]) -> list[str] {
    out: list[str] = [];
    i = len(xs) - 1;
    while i >= 0 {
        out.append(xs[i]);
        i -= 1;
    }
    return out;
}

def join_slash(parts: list[str]) -> str {
    if len(parts) == 0 {
        return "";
    }
    out = parts[0];
    i = 1;
    while i < len(parts) {
        out += "/" + parts[i];
        i += 1;
    }
    return out;
}

def make_pe_index(rows: list[tuple[str, str]]) -> PeIndex {
    store = PeIndex();
    anchor = TypeSpec(cid="__anchor__", type_name="__anchor__");
    root ++> anchor;
    store.graph_root = anchor;
    for row in rows {
        cid = row[0];
        name = row[1];
        nd = TypeSpec(cid=cid, type_name=name);
        anchor ++> nd;
        store.nodes_by_id[cid] = nd;
    }
    return store;
}

def apply_nested_rows(store: PeIndex, pairs: list[tuple[str, str]]) -> None {
    for pair in pairs {
        nested_id = pair[0];
        enclosing_id = pair[1];
        nested_nd = store.nodes_by_id[nested_id];
        parent_nd = store.nodes_by_id[enclosing_id];
        nested_nd +>:Encloses:+> parent_nd;
        parent_nd +>:Nests:+> nested_nd;
    }
}

def apply_nests_edges(store: PeIndex, pairs: list[tuple[str, str]]) -> None {
    apply_nested_rows(store, pairs);
}

def resolve_qualified_name(store: PeIndex, start_cid: str) -> str | None {
    if start_cid not in store.nodes_by_id {
        return None;
    }
    start_nd = store.nodes_by_id[start_cid];
    w = start_nd spawn ResolveName(claimed={});
    if w.cycle_hit {
        return None;
    }
    return w.result;
}

def collect_nested_visit_order(store: PeIndex, start_cid: str) -> list[str] {
    if start_cid not in store.nodes_by_id {
        return [];
    }
    start_nd = store.nodes_by_id[start_cid];
    w = start_nd spawn CollectVisit(claimed={});
    return w.order;
}

walker ResolveName {
    has claimed: dict[str, bool] = {};
    has parts: list[str] = [];
    has cycle_hit: bool = False;
    has result: str = "";

    can climb with TypeSpec entry {
        if here.cid in self.claimed {
            self.cycle_hit = True;
            print({"resolve": "cycle", "cid": here.cid});
            skip;
        }
        self.claimed[here.cid] = True;
        self.parts.append(here.type_name);
        parents: list[TypeSpec] = [here ->:Encloses:->][?:TypeSpec];
        if parents {
            visit [parents[0]];
        } else {
            rev = reverse_list(self.parts);
            self.result = join_slash(rev);
            print({"resolve": self.result});
        }
    }
}

walker CollectVisit {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with TypeSpec entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        kids: list[TypeSpec] = [here ->:Nests:->][?:TypeSpec];
        print({"visit": here.cid, "kids": len(kids)});
        for ch in kids {
            visit [ch];
        }
    }
}

walker Bootstrap {
    can boot with Anchor entry {
        store = make_pe_index([("1", "Inner"), ("2", "Outer")]);
        apply_nested_rows(store, [("1", "2")]);
        nm = resolve_qualified_name(store, "1");
        print({"demo": nm});
    }
}

with entry {
    boot_nd = Anchor();
    root ++> boot_nd;
    boot_nd spawn Bootstrap();
}
