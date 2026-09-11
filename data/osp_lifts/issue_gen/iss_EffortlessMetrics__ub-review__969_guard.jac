node Source { has sid: str; has authority: int; has digest: str; has path: str; has allowlisted: bool = True; }
node ContractEntry { has eid: str; has kind: str; has authority: int; has source_id: str; has section: str; has is_inferred: bool = False; has superseded: bool = False; }
node MaterialFact { has mid: str; has pkg: str; has path: str; }
edge Depends {}
edge Implies {}
edge MaterialEdge {}
edge SourceLink {}
edge Supersedes {}

walker GatherWalker {
    has claimed: dict[str, bool] = {};
    has result: list[str] = [];
    has bound: int = 10;
    can collect_entry with ContractEntry entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        print(here.eid);
        if here.is_inferred == False {
            self.result.append(here.eid);
        }
        if len(self.result) >= self.bound { disengage; }
        for nxt in [here ->:Depends:->][?:ContractEntry] { visit :0: [nxt]; }
        for nxt2 in [here ->:Implies:->][?:ContractEntry] { visit :0: [nxt2]; }
    }
    can collect_fact with MaterialFact entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        print(here.mid);
        for ent in [here ->:MaterialEdge:->][?:ContractEntry] { visit :0: [ent]; }
    }
}
walker EdgeExposeWalker {
    has claimed: dict[str, bool] = {};
    has edges: list[str] = [];
    can expose with ContractEntry entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        print(here.eid);
        for nxt in [here ->:Implies:->][?:ContractEntry] {
            self.edges.append(here.eid + "->" + nxt.eid);
            visit :0: [nxt];
        }
        for nxt2 in [here ->:Depends:->][?:ContractEntry] { visit :0: [nxt2]; }
    }
}

def is_path_safe(p: str) -> bool {
    # reject escape and absolute
    if ".." in p { return False; }
    if p.startswith("/") { return False; }
    return True;
}
def compile_packet(start: ContractEntry, bound: int) -> list[str] {
    w = start spawn GatherWalker(bound=bound);
    out: list[str] = w.result;
    out = sorted(out);
    return out;
}
def compile_packet_from_id(eid: str, idx: dict[str, ContractEntry], bound: int) -> list[str] {
    if eid not in idx { return []; }
    nd = idx[eid] as ContractEntry;
    return compile_packet(nd, bound);
}
def verify_packet(packet: list[str], idx: dict[str, ContractEntry], sources: dict[str, Source]) -> bool {
    for eid in packet {
        if eid not in idx { return False; }
        ent = idx[eid] as ContractEntry;
        if ent.is_inferred == True { return False; }
        if ent.source_id not in sources { return False; }
        src = sources[ent.source_id] as Source;
        if src.allowlisted == False { return False; }
        if src.digest == "" { return False; }
        if is_path_safe(src.path) == False { return False; }
        if len(src.path) > 256 { return False; }
    }
    return True;
}
def get_typed_inputs(start: ContractEntry) -> list[str] {
    w = start spawn EdgeExposeWalker();
    res: list[str] = sorted(w.edges);
    return res;
}
with entry {
    s = Source(sid="demo", authority=10, digest="abc123", path="src/contract.yaml");
    e = ContractEntry(eid="demo-e", kind="canonical", authority=10, source_id="demo", section="sec-a");
    root ++> s;
    root ++> e;
    e +>:SourceLink:+> s;
    w = e spawn GatherWalker(bound=5);
    print(w.result);
}

test "diamond revisit adversarial order" {
    a = ContractEntry(eid="a", kind="canonical", authority=10, source_id="s1", section="sec");
    b = ContractEntry(eid="b", kind="ownership", authority=9, source_id="s1", section="sec");
    c = ContractEntry(eid="c", kind="mirror", authority=8, source_id="s1", section="sec");
    d = ContractEntry(eid="d", kind="schema", authority=7, source_id="s1", section="sec");
    s1 = Source(sid="s1", authority=10, digest="d1", path="src/a.yaml");
    root ++> a; root ++> b; root ++> c; root ++> d; root ++> s1;
    a +>:Depends:+> c;
    a +>:Depends:+> b;
    b +>:Depends:+> d;
    c +>:Depends:+> d;
    out = compile_packet(a, 10);
    assert(sorted(out) == ["a", "b", "c", "d"]);
    out2 = compile_packet(a, 10);
    assert(out == out2);
}
test "unknown id tolerance" {
    idx: dict[str, ContractEntry] = {};
    out = compile_packet_from_id("missing", idx, 10);
    assert(len(out) == 0);
    srcs: dict[str, Source] = {};
    assert(verify_packet([], idx, srcs) == True);
    assert(verify_packet(["ghost"], idx, srcs) == False);
}
test "bound truncation deterministic" {
    a = ContractEntry(eid="a", kind="canonical", authority=10, source_id="s1", section="sec");
    b = ContractEntry(eid="b", kind="ownership", authority=9, source_id="s1", section="sec");
    c = ContractEntry(eid="c", kind="mirror", authority=8, source_id="s1", section="sec");
    d = ContractEntry(eid="d", kind="schema", authority=7, source_id="s1", section="sec");
    root ++> a; root ++> b; root ++> c; root ++> d;
    a +>:Depends:+> b;
    b +>:Depends:+> c;
    c +>:Depends:+> d;
    full = compile_packet(a, 10);
    assert(len(full) == 4);
    trunc = compile_packet(a, 2);
    assert(len(trunc) == 2);
    assert(sorted(trunc) == trunc);
}
test "verify rejects private unallowlisted stale and inferred" {
    good_src = Source(sid="good", authority=10, digest="abc", path="allow/good.yaml", allowlisted=True);
    bad_src = Source(sid="bad", authority=1, digest="", path="../escape.yaml", allowlisted=False);
    e_good = ContractEntry(eid="e2", kind="canonical", authority=10, source_id="good", section="sec");
    e_bad = ContractEntry(eid="e1", kind="canonical", authority=10, source_id="bad", section="sec");
    e_inf = ContractEntry(eid="inf", kind="canonical", authority=10, source_id="good", section="sec", is_inferred=True);
    idx_good: dict[str, ContractEntry] = {"e2": e_good};
    idx_bad: dict[str, ContractEntry] = {"e1": e_bad};
    idx_inf: dict[str, ContractEntry] = {"inf": e_inf};
    sm_good: dict[str, Source] = {"good": good_src};
    sm_bad: dict[str, Source] = {"bad": bad_src};
    assert(verify_packet(["e2"], idx_good, sm_good) == True);
    assert(verify_packet(["e1"], idx_bad, sm_bad) == False);
    assert(verify_packet(["inf"], idx_inf, sm_good) == False);
}
test "typed edge inputs exposed without mutation" {
    a = ContractEntry(eid="ta", kind="canonical", authority=10, source_id="s1", section="s");
    b = ContractEntry(eid="tb", kind="trust", authority=5, source_id="s1", section="s");
    root ++> a; root ++> b;
    a +>:Implies:+> b;
    edges = get_typed_inputs(a);
    assert("ta->tb" in edges);
    edges2 = get_typed_inputs(a);
    assert(edges == edges2);
    pkt = compile_packet(a, 10);
    assert("ta" in pkt);
    assert("tb" in pkt);
}
