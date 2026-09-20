"""Static namespace bracket call preservation — mohanagy/madar#739."""

node Sym { has sid: str; has label: str; has mid: str; }
edge Call {}
edge Bind {}

obj CallGraph {
    has graph_root: Sym;
    has by_id: dict[str, Sym] = {};
    has binds: dict[str, str] = {};

    def get(self, sid: str) -> Sym | None {
        if sid in self.by_id { return self.by_id[sid]; }
        return None;
    }

    def add_sym(self, s: Sym) {
        self.graph_root ++> s;
        self.by_id[s.sid] = s;
    }
}

def dot_callee(g: CallGraph, module_id: str, receiver: str, attr: str) -> str | None {
    bk: str = module_id + ":" + receiver;
    if bk not in g.binds { return None; }
    tsid: str = g.binds[bk];
    if tsid not in g.by_id { return None; }
    t = g.by_id[tsid];
    if attr == t.label { return t.label; }
    return None;
}

def bracket_callee(g: CallGraph, module_id: str, receiver: str, key: str) -> str | None {
    bk: str = module_id + ":" + receiver;
    if bk not in g.binds { return None; }
    tsid: str = g.binds[bk];
    if tsid not in g.by_id { return None; }
    t = g.by_id[tsid];
    if key != t.label { return None; }
    return t.label;
}

def link_callee(g: CallGraph, caller_sid: str, callee_name: str) -> bool {
    caller = g.get(caller_sid);
    if caller is None { return False; }
    callee: Sym | None = None;
    for sid in g.by_id {
        s = g.by_id[sid];
        if s.label == callee_name { callee = s; }
    }
    if callee is None { return False; }
    caller +>:Call:+> callee;
    print("link " + caller_sid + "->" + callee_name);
    return True;
}

def add_dot_call(g: CallGraph, caller_sid: str, receiver: str, attr: str) -> bool {
    caller = g.get(caller_sid);
    if caller is None { return False; }
    callee_name = dot_callee(g, caller.mid, receiver, attr);
    if callee_name is None { return False; }
    return link_callee(g, caller_sid, callee_name);
}

def ensure_static_bracket(g: CallGraph, caller_sid: str, receiver: str, key: str) -> bool {
    caller = g.get(caller_sid);
    if caller is None { return False; }
    callee_name = bracket_callee(g, caller.mid, receiver, key);
    if callee_name is None { return False; }
    return link_callee(g, caller_sid, callee_name);
}

walker ChainWalk {
    has claimed: dict[str, bool] = {};
    has end_label: str = "";
    has paths: list[list[str]] = [];
    has stack: list[str] = [];

    can walk with Sym entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.stack.append(here.label);
        print("chain " + here.label);
        if here.label == self.end_label {
            cp: list[str] = [];
            for x in self.stack { cp.append(x); }
            self.paths.append(cp);
        }
        kids: list[Sym] = [here ->:Call:->][?:Sym];
        if kids { visit kids; } else { disengage; }
    }
}

walker CollectWalk {
    has claimed: dict[str, bool] = {};
    has labels: list[str] = [];

    can collect with Sym entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.labels.append(here.label);
        print("collect " + here.label);
        kids: list[Sym] = [here ->:Call:->][?:Sym];
        idx: int = len(kids) - 1;
        while idx >= 0 {
            visit :0: kids[idx];
            idx -= 1;
        }
    }
}

walker DemoWalk {
    can run entry {
        g = make_base_graph();
        add_dot_call(g, "m1:renderGreeting", "names", "prepareName");
        ch = call_chain(g, "renderGreeting", "trimName");
        print("demo chains " + str(len(ch)));
    }
}

def norm_paths(ps: list[list[str]]) -> list[list[str]] { return sorted(ps); }

def call_chain(g: CallGraph, start: str, end: str) -> list[list[str]] {
    start_sym: Sym | None = None;
    for sid in g.by_id {
        s = g.by_id[sid];
        if s.label == start { start_sym = s; }
    }
    if start_sym is None { return []; }
    w = start_sym spawn ChainWalk(end_label=end);
    return norm_paths(w.paths);
}

def collect_reach_labels(g: CallGraph, start_sid: str) -> list[str] {
    st = g.get(start_sid);
    if st is None { return []; }
    w = st spawn CollectWalk;
    return sorted(w.labels);
}

def make_base_graph -> CallGraph {
    gr = Sym(sid="groot", label="groot", mid="");
    g = CallGraph(graph_root=gr, by_id={}, binds={});
    root ++> gr;
    rg = Sym(sid="m1:renderGreeting", label="renderGreeting", mid="m1");
    pn = Sym(sid="m2:prepareName", label="prepareName", mid="m2");
    tn = Sym(sid="m3:trimName", label="trimName", mid="m3");
    g.add_sym(rg);
    g.add_sym(pn);
    g.add_sym(tn);
    pn +>:Call:+> tn;
    g.binds["m1:names"] = "m2:prepareName";
    return g;
}

def make_diamond_graph -> CallGraph {
    gr = Sym(sid="dgroot", label="dgroot", mid="");
    g = CallGraph(graph_root=gr, by_id={}, binds={});
    root ++> gr;
    st = Sym(sid="d:start", label="start", mid="d");
    a = Sym(sid="d:a", label="a", mid="d");
    b = Sym(sid="d:b", label="b", mid="d");
    midn = Sym(sid="d:mid", label="mid", mid="d");
    deep = Sym(sid="d:deep", label="deep", mid="d");
    tail = Sym(sid="d:tail", label="tail", mid="d");
    g.add_sym(st);
    g.add_sym(a);
    g.add_sym(b);
    g.add_sym(midn);
    g.add_sym(deep);
    g.add_sym(tail);
    st +>:Call:+> a;
    st +>:Call:+> b;
    a +>:Call:+> midn;
    a +>:Call:+> deep;
    b +>:Call:+> midn;
    midn +>:Call:+> tail;
    return g;
}

def path_eq(a: list[str], b: list[str]) -> bool {
    if len(a) != len(b) { return False; }
    i: int = 0;
    while i < len(a) {
        if a[i] != b[i] { return False; }
        i += 1;
    }
    return True;
}

with entry {
    root spawn DemoWalk;
}

test "dot_call_chain" {
    g = make_base_graph();
    ok = add_dot_call(g, "m1:renderGreeting", "names", "prepareName");
    assert ok;
    got = call_chain(g, "renderGreeting", "trimName");
    exp: list[list[str]] = [["renderGreeting", "prepareName", "trimName"]];
    assert got == exp;
}

test "bracket_call_link" {
    g = make_base_graph();
    ok = ensure_static_bracket(g, "m1:renderGreeting", "names", "prepareName");
    assert ok;
    got = call_chain(g, "renderGreeting", "trimName");
    exp: list[list[str]] = [["renderGreeting", "prepareName", "trimName"]];
    assert got == exp;
}

test "unknown_caller_dot" {
    g = make_base_graph();
    ok = add_dot_call(g, "m9:missing", "names", "prepareName");
    assert ok == False;
}

test "diamond_reach_sorted" {
    g = make_diamond_graph();
    got = collect_reach_labels(g, "d:start");
    exp: list[str] = ["a", "b", "deep", "mid", "start", "tail"];
    assert got == exp;
}

test "diamond_paths_to_tail" {
    g = make_diamond_graph();
    got = call_chain(g, "start", "tail");
    exp: list[list[str]] = [
        ["start", "a", "mid", "tail"],
        ["start", "a", "deep"],
        ["start", "b", "mid", "tail"],
    ];
    assert got == exp;
}

test "missing_start_chain" {
    g = make_base_graph();
    got = call_chain(g, "noSuch", "trimName");
    assert got == [];
}
