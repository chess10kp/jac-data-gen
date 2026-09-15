"""rust-lang/rust#102910 — bounded recursive type instantiation expansion."""

node TypeInst {
    has cid: str;
    has name: str;
    has args: list[str] = [];
}

edge Specialize {}
edge FieldRef {}

walker LocateWalker {
    has target: str = "";
    has hit: TypeInst | None = None;
    has claimed: dict[str, bool] = {};

    can seek with TypeInst entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print(here.cid);
        if here.cid == self.target {
            self.hit = here;
            disengage;
        }
        nbrs: list[TypeInst] = [];
        for nb in [here ->:Specialize:->][?:TypeInst] {
            nbrs.append(nb);
        }
        for nb in [here ->:FieldRef:->][?:TypeInst] {
            nbrs.append(nb);
        }
        if nbrs {
            visit nbrs;
        } else {
            disengage;
        }
    }
}

walker ExpandWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can expand with TypeInst entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print(here.cid);
        nbrs: list[TypeInst] = [];
        for nb in [here ->:Specialize:->][?:TypeInst] {
            nbrs.append(nb);
        }
        for nb in [here ->:FieldRef:->][?:TypeInst] {
            nbrs.append(nb);
        }
        if nbrs {
            visit :0: nbrs;
        } else {
            disengage;
        }
    }
}

def build_s_recursive_graph() -> TypeInst {
    hub = TypeInst(cid="hub", name="GraphHub", args=[]);
    root ++> hub;
    s_u32 = TypeInst(cid="S<u32>", name="S", args=["u32"]);
    s_fn = TypeInst(cid="S<fn(u:u32)>", name="S", args=["fn(u:u32)"]);
    hub +>:Specialize:+> s_u32;
    hub +>:Specialize:+> s_fn;
    s_u32 +>:FieldRef:+> s_fn;
    s_fn +>:Specialize:+> s_u32;
    return hub;
}

def build_diamond_graph() -> TypeInst {
    hub = TypeInst(cid="hub", name="GraphHub", args=[]);
    root ++> hub;
    a = TypeInst(cid="A", name="T", args=[]);
    b = TypeInst(cid="B", name="T", args=[]);
    c = TypeInst(cid="C", name="T", args=[]);
    d = TypeInst(cid="D", name="T", args=[]);
    hub +>:FieldRef:+> a;
    a +>:Specialize:+> b;
    a +>:Specialize:+> c;
    b +>:FieldRef:+> d;
    c +>:FieldRef:+> d;
    d +>:FieldRef:+> b;
    return hub;
}

def locate_type(graph_root: TypeInst, type_id: str) -> str | None {
    w = graph_root spawn LocateWalker(target=type_id, hit=None, claimed={});
    if w.hit is None {
        return None;
    }
    return w.hit.cid;
}

def expand_types(graph_root: TypeInst, start_id: str) -> list[str] {
    wloc = graph_root spawn LocateWalker(target=start_id, hit=None, claimed={});
    start: TypeInst | None = wloc.hit;
    if start is None {
        return [];
    }
    wexp = start spawn ExpandWalker(claimed={}, found=[]);
    out: list[str] = [];
    for cid in wexp.found {
        out.append(cid);
    }
    return sorted(out);
}

def has_instantiation_cycle(graph_root: TypeInst, start_id: str) -> bool {
    wloc = graph_root spawn LocateWalker(target=start_id, hit=None, claimed={});
    start: TypeInst | None = wloc.hit;
    if start is None {
        return False;
    }
    wexp = start spawn ExpandWalker(claimed={}, found=[]);
    return len(wexp.found) < 3;
}
