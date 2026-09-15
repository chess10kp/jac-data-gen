"""cartazio/omega#48 — recursive Equal refinement (self-referential exclude)."""

node TypeVar { has vid: str; }
node EqualPat {
    has pid: str;
    has lhs_vid: str;
    has rhs_vid: str;
    has excludes: list[str] = [];
}
edge RefE {}

obj RefineStore {
    has anchor: node;

    def add_var(self: RefineStore, vid: str) -> None {
        nd = TypeVar(vid=vid);
        self.anchor ++> nd;
    }

    def add_equal(
        self: RefineStore,
        pid: str,
        lhs: str,
        rhs: str,
        excludes: list[str] | None = None
    ) -> None {
        exs: list[str] = [];
        if excludes {
            for ex in excludes {
                exs.append(ex);
            }
        }
        nd = EqualPat(pid=pid, lhs_vid=lhs, rhs_vid=rhs, excludes=exs);
        self.anchor ++> nd;
    }

    def connect_ref(self: RefineStore, parent: str, child: str) -> None {
        pw = self.anchor spawn FindEqual(target=parent, claimed={}, found=None);
        cw = self.anchor spawn FindEqual(target=child, claimed={}, found=None);
        if pw.found and cw.found {
            pw.found +>:RefE:+> cw.found;
        }
    }

    def lookup(self: RefineStore, pid: str) -> EqualPat | None {
        w = self.anchor spawn FindEqual(target=pid, claimed={}, found=None);
        return w.found;
    }
}

walker FindEqual {
    has target: str;
    has claimed: dict[str, bool] = {};
    has found: EqualPat | None = None;

    can seek with EqualPat entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        print({"find": here.pid});
        if here.pid == self.target {
            self.found = here;
            disengage;
        }
        nxt: list[EqualPat] = [];
        for ch in [here ->:RefE:->][?:EqualPat] {
            nxt.append(ch);
        }
        visit :0: nxt else { disengage; }
    }
}

walker RefineWalker {
    has claimed: dict[str, bool] = {};
    has env: dict[str, str] = {};

    can step_equal with EqualPat entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        print({"refine": here.pid, "rhs": here.rhs_vid});
        rhs: str = here.rhs_vid;
        lhs: str = here.lhs_vid;
        if rhs not in self.env {
            self.env[rhs] = rhs;
        }
        if lhs not in self.env {
            self.env[lhs] = rhs;
        }
        kids: list[EqualPat] = [];
        for ch in [here ->:RefE:->][?:EqualPat] {
            kids.append(ch);
        }
        visit :0: kids;
    }
}

walker CollectVars {
    has claimed: dict[str, bool] = {};
    has acc: list[str] = [];

    can step_eq with EqualPat entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        print({"collect": here.pid});
        if here.lhs_vid not in self.acc {
            self.acc.append(here.lhs_vid);
        }
        if here.rhs_vid not in self.acc {
            self.acc.append(here.rhs_vid);
        }
        for ex in here.excludes {
            if ex not in self.acc {
                self.acc.append(ex);
            }
        }
        nxt: list[EqualPat] = [];
        for ch in [here ->:RefE:->][?:EqualPat] {
            nxt.append(ch);
        }
        visit :0: nxt;
    }
}

def make_store() -> RefineStore {
    return RefineStore(anchor=root);
}

def add_var(store: RefineStore, vid: str) {
    store.add_var(vid);
}

def add_equal(
    store: RefineStore,
    pid: str,
    lhs: str,
    rhs: str,
    excludes: list[str] | None = None
) {
    store.add_equal(pid, lhs, rhs, excludes);
}

def connect_ref(store: RefineStore, parent: str, child: str) {
    store.connect_ref(parent, child);
}

def refine(store: RefineStore, root_pid: str) -> dict[str, str] | None {
    start = store.lookup(root_pid);
    if not start {
        return None;
    }
    w = start spawn RefineWalker(claimed={}, env={});
    out: dict[str, str] = {};
    for k, v in w.env {
        out[k] = v;
    }
    return out;
}

def vars_in_pattern(store: RefineStore, root_pid: str) -> list[str] {
    start = store.lookup(root_pid);
    if not start {
        return [];
    }
    w = start spawn CollectVars(claimed={}, acc=[]);
    xs: list[str] = [];
    for v in w.acc {
        xs.append(v);
    }
    return sorted(xs);
}

test "refine_simple_equal" {
    st = make_store();
    add_equal(st, "e1", "x", "y");
    out = refine(st, "e1");
    assert (out == {"x": "y", "y": "y"});
}

test "refine_unknown_returns_none" {
    st = make_store();
    assert (refine(st, "missing") == None);
    assert (vars_in_pattern(st, "missing") == []);
}

test "vars_in_pattern_sorted_with_excludes" {
    st = make_store();
    add_equal(st, "e1", "a", "b", excludes=["c", "a"]);
    assert (vars_in_pattern(st, "e1") == ["a", "b", "c"]);
}

test "connected_refine_closure" {
    st = make_store();
    add_equal(st, "e1", "a", "b");
    add_equal(st, "e2", "b", "c");
    connect_ref(st, "e1", "e2");
    out = refine(st, "e1");
    assert (out == {"a": "b", "b": "b", "c": "c"});
}

test "self_ref_exclude_recursive" {
    st = make_store();
    add_equal(st, "e1", "a", "a", excludes=["e1"]);
    add_equal(st, "e2", "a", "b", excludes=["e1"]);
    connect_ref(st, "e1", "e2");
    out = refine(st, "e1");
    assert (out == {"a": "a", "b": "b"});
    assert (vars_in_pattern(st, "e1") == ["a", "b", "e1"]);
}

test "lookup_finds_pattern" {
    st = make_store();
    add_equal(st, "p1", "u", "v");
    hit = st.lookup("p1");
    assert (hit != None);
    assert (hit.pid == "p1");
}
