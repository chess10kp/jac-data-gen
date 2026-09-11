node Cell {
    has cid: str;
    has cost: float;
    has score: float;
    has status: str;
}
edge Depends {}
edge Lineage {}
edge Contains {}

walker DependsClosure {
    has claimed: dict[str, bool] = {};
    has result: list[str] = [];
    can step with Cell entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.result.append(here.cid);
        kids: list[Cell] = [];
        for nxt in [here ->:Depends:->][?:Cell] { kids.append(nxt); }
        if len(kids) > 0 { visit kids; } else { disengage; }
        print(here.cid);
    }
}
walker LineageClosure {
    has claimed: dict[str, bool] = {};
    has result: list[str] = [];
    can step with Cell entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.result.append(here.cid);
        kids: list[Cell] = [];
        for nxt in [here ->:Lineage:->][?:Cell] { kids.append(nxt); }
        if len(kids) > 0 { visit kids; } else { disengage; }
        print(here.cid);
    }
}
def find_cell(cid: str) -> Cell | None {
    for nd in [root ->:Contains:->][?:Cell] {
        if nd.cid == cid { return nd; }
    }
    return None;
}
def add_cell(cid: str, cost: float, score: float, status: str) -> bool {
    for nd in [root ->:Contains:->][?:Cell] {
        if nd.cid == cid { return False; }
    }
    nd: Cell = Cell(cid=cid, cost=cost, score=score, status=status);
    root +>:Contains:+> nd;
    return True;
}
def add_depends(src: str, dst: str) -> bool {
    s: Cell | None = find_cell(src);
    d: Cell | None = find_cell(dst);
    if s is None { return False; }
    if d is None { return False; }
    if src == dst { return False; }
    for nxt in [s ->:Depends:->][?:Cell] {
        if nxt.cid == dst { return False; }
    }
    s +>:Depends:+> d;
    return True;
}
def add_lineage(child: str, parent: str) -> bool {
    c: Cell | None = find_cell(child);
    p: Cell | None = find_cell(parent);
    if c is None { return False; }
    if p is None { return False; }
    if child == parent { return False; }
    for nxt in [c ->:Lineage:->][?:Cell] {
        if nxt.cid == parent { return False; }
    }
    c +>:Lineage:+> p;
    return True;
}
def get_dependencies(cid: str) -> list[str] {
    nd: Cell | None = find_cell(cid);
    if nd is None { return []; }
    w: DependsClosure = nd spawn DependsClosure(claimed={}, result=[]);
    out: list[str] = [];
    for x in w.result { if x != cid { out.append(x); } }
    return sorted(out);
}
def get_lineage(cid: str) -> list[str] {
    nd: Cell | None = find_cell(cid);
    if nd is None { return []; }
    w: LineageClosure = nd spawn LineageClosure(claimed={}, result=[]);
    out: list[str] = [];
    for x in w.result { if x != cid { out.append(x); } }
    return sorted(out);
}
def get_pareto_front() -> list[str] {
    all_cells: list[Cell] = [];
    for nd in [root ->:Contains:->][?:Cell] { all_cells.append(nd); }
    pareto: list[str] = [];
    for c in all_cells {
        dominated: bool = False;
        for o in all_cells {
            if o.cid == c.cid { continue; }
            if o.cost <= c.cost and o.score >= c.score {
                if o.cost < c.cost or o.score > c.score {
                    dominated = True;
                    break;
                }
            }
        }
        if not dominated {
            if c.status != "failed" and c.status != "unsupported" {
                pareto.append(c.cid);
            }
        }
    }
    return sorted(pareto);
}
def get_failed_cells() -> list[str] {
    res: list[str] = [];
    for nd in [root ->:Contains:->][?:Cell] {
        if nd.status == "failed" or nd.status == "unsupported" { res.append(nd.cid); }
    }
    return sorted(res);
}
with entry {
    root spawn DependsClosure(claimed={}, result=[]);
    print("explorer ready");
}
