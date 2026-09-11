node Project {
    has pid: str;
}
node Callable {
    has cid: str;
    has is_dynamic: bool = False;
    has effects: list[str] = [];
    has values: list[str] = [];
    has summary_ref: str = "";
}
edge Contains {}
edge CallEdge {}

walker CollectValues {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];
    can gather with Callable entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.cid);
        for v in here.values {
            self.out.append(v);
        }
        kids: list[Callable] = [here ->:CallEdge:->][?:Callable];
        for k in kids {
            visit :0: [k];
        }
    }
}

walker CollectEffects {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];
    can gather_eff with Callable entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.cid);
        for e in here.effects {
            self.out.append(e);
        }
        kids: list[Callable] = [here ->:CallEdge:->][?:Callable];
        for k in kids {
            visit :0: [k];
        }
    }
}

walker BoundedClosure {
    has claimed: dict[str, bool] = {};
    has bound: int = 0;
    has depth: dict[str, int] = {};
    has out: list[str] = [];
    can expand with Callable entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.cid);
        cur: int = 0;
        if here.cid in self.depth {
            cur = self.depth[here.cid];
        }
        if cur > self.bound { skip; }
        self.out.append(here.cid);
        if cur < self.bound {
            kids: list[Callable] = [here ->:CallEdge:->][?:Callable];
            for k in kids {
                if k.cid not in self.depth {
                    self.depth[k.cid] = cur + 1;
                }
                visit :0: [k];
            }
        }
    }
}

walker ReverseCallers {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];
    can gather_rev with Callable entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.cid);
        preds: list[Callable] = [here <-:CallEdge:<-][?:Callable];
        for p in preds {
            if p.cid not in self.claimed {
                self.out.append(p.cid);
            }
            visit :0: [p];
        }
    }
}

walker Demo {
    can start with entry {
        print("demo ready");
    }
}

def find_callable(proj: Project, cid: str) -> Callable | None {
    # scan Contains edges from project
    cands: list[Callable] = [proj ->:Contains:->][?:Callable];
    for c in cands {
        if c.cid == cid {
            return c;
        }
    }
    return None;
}

def make_project(pid: str) -> Project {
    p = Project(pid=pid);
    root ++> p;
    return p;
}

def add_callable(proj: Project, cid: str, effects: list[str] | None = None, values: list[str] | None = None, is_dynamic: bool = False) -> Callable {
    eff: list[str] = [];
    if effects is not None {
        eff = effects;
    }
    vals: list[str] = [];
    if values is not None {
        vals = values;
    }
    c = Callable(cid=cid, is_dynamic=is_dynamic, effects=eff, values=vals, summary_ref="");
    proj ++>:Contains:+> c;
    return c;
}

def add_call_edge(caller: Callable, callee: Callable) {
    caller +>:CallEdge:+> callee;
}

def define_summary(c: Callable, ref: str) -> str {
    c.summary_ref = ref;
    return c.summary_ref;
}

def get_summary_ref(c: Callable) -> str {
    return c.summary_ref;
}

def is_composition_legal(c: Callable) -> bool {
    if c.is_dynamic {
        return False;
    }
    return True;
}

def compose_values(start: Callable) -> list[str] {
    w = start spawn CollectValues(claimed={}, out=[]);
    return sorted(w.out);
}

def compose_effects(start: Callable) -> list[str] {
    w = start spawn CollectEffects(claimed={}, out=[]);
    return sorted(w.out);
}

def compose_call_values(proj: Project, cid: str) -> list[str] {
    c = find_callable(proj, cid);
    if c is None {
        return [];
    }
    w = c spawn CollectValues(claimed={}, out=[]);
    return sorted(w.out);
}

def compose_call_effects(proj: Project, cid: str) -> list[str] {
    c = find_callable(proj, cid);
    if c is None {
        return [];
    }
    w = c spawn CollectEffects(claimed={}, out=[]);
    return sorted(w.out);
}

def bounded_closure_ids(start: Callable, bound: int) -> list[str] {
    d: dict[str, int] = {};
    d[start.cid] = 0;
    w = start spawn BoundedClosure(claimed={}, bound=bound, depth=d, out=[]);
    return sorted(w.out);
}

def bounded_closure_for(proj: Project, cid: str, bound: int) -> list[str] {
    c = find_callable(proj, cid);
    if c is None {
        return [];
    }
    d: dict[str, int] = {};
    d[c.cid] = 0;
    w = c spawn BoundedClosure(claimed={}, bound=bound, depth=d, out=[]);
    return sorted(w.out);
}

def stale_callers_ids(target: Callable) -> list[str] {
    w = target spawn ReverseCallers(claimed={}, out=[]);
    return sorted(w.out);
}

def stale_callers_for(proj: Project, cid: str) -> list[str] {
    c = find_callable(proj, cid);
    if c is None {
        return [];
    }
    w = c spawn ReverseCallers(claimed={}, out=[]);
    return sorted(w.out);
}

with entry {
    root spawn Demo();
}

test "diamond revisit collects once sorted" {
    proj = make_project("p_diamond");
    a = add_callable(proj, "A", effects=["eA"], values=["vA"]);
    b = add_callable(proj, "B", effects=["eB"], values=["vB"]);
    c = add_callable(proj, "C", effects=["eC"], values=["vC"]);
    d = add_callable(proj, "D", effects=["eD"], values=["vD"]);
    add_call_edge(a, b);
    add_call_edge(a, c);
    add_call_edge(b, d);
    add_call_edge(c, d);
    assert sorted(compose_values(a)) == ["vA", "vB", "vC", "vD"];
    assert sorted(compose_effects(a)) == ["eA", "eB", "eC", "eD"];
    assert sorted(compose_values(d)) == ["vD"];
}

test "bounded closure respects bound adversarial order" {
    proj2 = make_project("p_bounded");
    a2 = add_callable(proj2, "A2", values=["va"]);
    b2 = add_callable(proj2, "B2", values=["vb"]);
    c2 = add_callable(proj2, "C2", values=["vc"]);
    d2 = add_callable(proj2, "D2", values=["vd"]);
    add_call_edge(a2, b2);
    add_call_edge(a2, c2);
    add_call_edge(b2, d2);
    add_call_edge(c2, d2);
    assert sorted(bounded_closure_ids(a2, 0)) == ["A2"];
    assert sorted(bounded_closure_ids(a2, 1)) == ["A2", "B2", "C2"];
    assert sorted(bounded_closure_ids(a2, 2)) == ["A2", "B2", "C2", "D2"];
    assert sorted(bounded_closure_for(proj2, "A2", 1)) == ["A2", "B2", "C2"];
}

test "unknown id tolerance returns empty" {
    proj3 = make_project("p_unknown");
    x = add_callable(proj3, "X", values=["vx"]);
    assert compose_call_values(proj3, "MISSING") == [];
    assert compose_call_effects(proj3, "MISSING") == [];
    assert bounded_closure_for(proj3, "NOPE", 5) == [];
    assert stale_callers_for(proj3, "NOPE") == [];
    assert sorted(compose_call_values(proj3, "X")) == ["vx"];
}

test "stale callers reverse closure and dynamic refusal" {
    proj4 = make_project("p_stale");
    r = add_callable(proj4, "R", values=["vr"]);
    s = add_callable(proj4, "S", values=["vs"]);
    t = add_callable(proj4, "T", values=["vt"], is_dynamic=True);
    add_call_edge(r, s);
    add_call_edge(s, t);
    assert sorted(stale_callers_ids(t)) == ["R", "S"];
    assert sorted(stale_callers_for(proj4, "T")) == ["R", "S"];
    assert sorted(stale_callers_ids(s)) == ["R"];
    assert is_composition_legal(t) == False;
    assert is_composition_legal(r) == True;
    define_summary(s, "summ_s_v1");
    assert get_summary_ref(s) == "summ_s_v1";
}

test "cycle bounded closure terminates via claim map" {
    proj5 = make_project("p_cycle");
    p = add_callable(proj5, "P", values=["vp"]);
    q = add_callable(proj5, "Q", values=["vq"]);
    rr = add_callable(proj5, "RR", values=["vr"]);
    add_call_edge(p, q);
    add_call_edge(q, rr);
    add_call_edge(rr, p);
    add_call_edge(rr, q);
    assert sorted(compose_values(p)) == ["vp", "vq", "vr"];
    assert sorted(bounded_closure_ids(p, 10)) == ["P", "Q", "RR"];
    assert sorted(stale_callers_ids(p)) == ["Q", "RR"];
}
