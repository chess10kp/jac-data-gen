node Cell {
    has cid: str;
    has status: str;
    has cost: float;
    has arch: str;
}
edge Registry {}
edge Depends {}
edge Lineage {}

walker LineageReach {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can collect with Cell entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print(here.cid);
        kids: list[Cell] = [];
        for nxt in [here ->:Depends:->][?:Cell] { kids.append(nxt); }
        for nxt in [here ->:Lineage:->][?:Cell] { kids.append(nxt); }
        if kids { visit :0: kids; } else { disengage; }
    }
}

walker FailReach {
    has claimed: dict[str, bool] = {};
    has fails: list[str] = [];
    can gather with Cell entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.status == "failed" or here.status == "unsupported" { self.fails.append(here.cid); }
        print(here.cid);
        kids: list[Cell] = [];
        for nxt in [here ->:Depends:->][?:Cell] { kids.append(nxt); }
        for nxt in [here ->:Lineage:->][?:Cell] { kids.append(nxt); }
        if kids { visit :0: kids; } else { disengage; }
    }
}

walker RootDemo {
    has seen: dict[str, bool] = {};
    can start with entry {
        print("explorer_demo");
        disengage;
    }
}

def find_cell(cid: str) -> Cell | None {
    res: Cell | None = None;
    for nd in [root ->:Registry:->][?:Cell] {
        if nd.cid == cid { res = nd; break; }
    }
    return res;
}

def create_cell(cid: str, status: str, cost: float, arch: str) -> Cell {
    ex: Cell | None = find_cell(cid);
    if ex is not None { return ex; }
    nd = Cell(cid=cid, status=status, cost=cost, arch=arch);
    root +>:Registry:+> nd;
    return nd;
}

def add_dependency(src: str, dst: str) -> bool {
    s: Cell | None = find_cell(src);
    d: Cell | None = find_cell(dst);
    if s is None or d is None { return False; }
    s +>:Depends:+> d;
    return True;
}

def add_lineage(src: str, dst: str) -> bool {
    s: Cell | None = find_cell(src);
    d: Cell | None = find_cell(dst);
    if s is None or d is None { return False; }
    s +>:Lineage:+> d;
    return True;
}

def get_lineage(start_id: str) -> list[str] {
    start: Cell | None = find_cell(start_id);
    if start is None { return []; }
    w = start spawn LineageReach(claimed={}, found=[]);
    return sorted(w.found);
}

def get_failures(start_id: str) -> list[str] {
    start: Cell | None = find_cell(start_id);
    if start is None { return []; }
    w = start spawn FailReach(claimed={}, fails=[]);
    return sorted(w.fails);
}

def get_pareto_front() -> list[str] {
    all_cells: list[Cell] = [];
    for nd in [root ->:Registry:->][?:Cell] { all_cells.append(nd); }
    front: list[str] = [];
    for c in all_cells {
        if c.status != "supported" { continue; }
        dominated: bool = False;
        for o in all_cells {
            if o.status != "supported" { continue; }
            if o.cost < c.cost { dominated = True; break; }
        }
        if dominated == False { front.append(c.cid); }
    }
    return sorted(front);
}

def diff_architectures(a_id: str, b_id: str) -> dict[str, str] {
    res: dict[str, str] = {};
    ca: Cell | None = find_cell(a_id);
    cb: Cell | None = find_cell(b_id);
    if ca is None or cb is None { res["error"] = "unknown_id"; return res; }
    if ca.arch == cb.arch { res["same"] = "true"; } else { res["arch_a"] = ca.arch; res["arch_b"] = cb.arch; }
    return res;
}

def explain_mutation(cid: str) -> str {
    c: Cell | None = find_cell(cid);
    if c is None { return "unknown"; }
    if c.status == "failed" { return "failed: " + c.arch; }
    if c.status == "unsupported" { return "unsupported: " + c.arch; }
    return "supported: " + c.arch;
}

with entry {
    demo = create_cell("demo_explorer", "supported", 1.0, "base");
    w = demo spawn LineageReach(claimed={}, found=[]);
    print(w.found);
    r = root spawn RootDemo(seen={});
    print(r.seen);
}
