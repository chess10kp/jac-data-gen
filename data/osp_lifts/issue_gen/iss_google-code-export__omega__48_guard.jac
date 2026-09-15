"""google-code-export/omega#48 — refinement failure with recursive Equal."""

node TVar {
    has cid: str;
    has tag: str;
}

node EqPat {
    has cid: str;
    has lhs: str;
    has rhs: str;
}

edge ToArg {}
edge ToExcl {}

obj EqualGraph {
    has by_id: dict[str, object] = {};
    has eq_ids: dict[str, bool] = {};

    def add_var(vid: str, tag: str) -> TVar {
        nd = TVar(cid=vid, tag=tag);
        self.by_id[vid] = nd;
        root ++> nd;
        return nd;
    }

    def add_eq(eid: str, lhs: str, rhs: str) -> EqPat {
        pat = EqPat(cid=eid, lhs=lhs, rhs=rhs);
        self.by_id[eid] = pat;
        self.eq_ids[eid] = True;
        root ++> pat;
        lnd = self.by_id[lhs] as TVar;
        rnd = self.by_id[rhs] as TVar;
        pat +>:ToArg:+> lnd;
        pat +>:ToArg:+> rnd;
        return pat;
    }

    def link_exclude(eid: str, vid: str) {
        pat = self.by_id[eid] as EqPat;
        vnd = self.by_id[vid] as TVar;
        pat +>:ToExcl:+> vnd;
    }
}

def format_equal_type(exclude: dict[str, bool], bind: str) -> str {
    keys: list[str] = [];
    for k in exclude {
        keys.append(k);
    }
    keys = sorted(keys);
    chunks: list[str] = [];
    for k in keys {
        chunks.append(k);
    }
    inner = " ".join(chunks);
    return "Equal{exclude " + inner + "} " + bind;
}

walker InferW {
    has claimed: dict[str, bool] = {};
    has exclude: dict[str, bool] = {};
    has bind: str = "";
    has allow_recursive: bool = False;
    has result: str = "";
    has failed: bool = False;

    can on_var with TVar entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("infer var ", here.cid);
        if here.cid == self.bind and here.cid in self.exclude and not self.allow_recursive {
            self.failed = True;
            print("refine fail self-ref Equal at ", here.cid);
            disengage;
        }
        eqs: list[EqPat] = [];
        for e in [here ->:ToArg:<-][?:EqPat] {
            eqs.append(e);
        }
        if eqs {
            visit :0: eqs;
        } else {
            if here.cid == self.bind {
                self.result = format_equal_type(self.exclude, self.bind);
            }
            disengage;
        }
    }

    can on_eq with EqPat entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("infer eq ", here.cid);
        excls: list[TVar] = [];
        for x in [here ->:ToExcl:->][?:TVar] {
            excls.append(x);
        }
        for x in excls {
            self.exclude[x.cid] = True;
        }
        args: list[TVar] = [];
        for a in [here ->:ToArg:->][?:TVar] {
            args.append(a);
        }
        if args {
            visit :0: args;
        } else {
            disengage;
        }
    }
}

def build_issue48(g: EqualGraph) -> str {
    g.add_var("_b", "var");
    g.add_var("_c", "var");
    eq = g.add_eq("Eq", "_b", "_c");
    g.link_exclude("Eq", "_b");
    g.link_exclude("Eq", "_c");
    return eq.cid;
}

def pattern_is_eq(g: EqualGraph, eid: str) -> bool {
    return eid in g.eq_ids;
}

def reorder_patterns(ids: list[str]) -> list[str] {
    out: list[str] = sorted(ids);
    return out;
}

def refine_recursive_equal(
    g: EqualGraph,
    eq_id: str,
    bind: str,
    exclude: list[str] | None = None,
    allow_recursive: bool = False
) -> str | None {
    if eq_id not in g.eq_ids {
        return None;
    }
    if bind not in g.by_id {
        return None;
    }
    ex_map: dict[str, bool] = {};
    if exclude {
        for x in exclude {
            ex_map[x] = True;
        }
    }
    start = g.by_id[bind] as TVar;
    w = start spawn InferW(
        exclude=ex_map,
        bind=bind,
        allow_recursive=allow_recursive
    );
    print("refine done failed=", w.failed, " type=", w.result);
    if w.failed {
        return None;
    }
    return w.result;
}

def expected_equal_type(exclude: list[str], bind: str) -> str {
    ex_map: dict[str, bool] = {};
    for x in exclude {
        ex_map[x] = True;
    }
    return format_equal_type(ex_map, bind);
}

test "self_ref_equal_fails" {
    g = EqualGraph();
    eq_id = build_issue48(g);
    got = refine_recursive_equal(g, eq_id, "_b", ["_b", "_c"], False);
    assert got is None;
}

test "allow_recursive_succeeds" {
    g = EqualGraph();
    eq_id = build_issue48(g);
    got = refine_recursive_equal(g, eq_id, "_b", ["_b", "_c"], True);
    exp = expected_equal_type(["_b", "_c"], "_b");
    assert got == exp;
}

test "unknown_eq_returns_none" {
    g = EqualGraph();
    build_issue48(g);
    got = refine_recursive_equal(g, "Missing", "_b", None, False);
    assert got is None;
}

test "pattern_is_eq" {
    g = EqualGraph();
    eq_id = build_issue48(g);
    assert pattern_is_eq(g, eq_id);
    assert not pattern_is_eq(g, "nope");
}

test "reorder_patterns_sorted" {
    out = reorder_patterns(["z", "a", "m"]);
    assert out == ["a", "m", "z"];
}

test "format_exclude_order" {
    got = expected_equal_type(["_c", "_b"], "_b");
    assert got == "Equal{exclude _b _c} _b";
}
