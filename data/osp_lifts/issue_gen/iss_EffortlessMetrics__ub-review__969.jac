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
