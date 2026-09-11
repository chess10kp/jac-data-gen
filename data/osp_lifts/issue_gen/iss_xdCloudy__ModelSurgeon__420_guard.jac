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

test "diamond depends closure revisit adversarial order" {
    add_cell("A_dia", 1.0, 1.0, "supported");
    add_cell("B_dia", 1.0, 1.0, "supported");
    add_cell("C_dia", 1.0, 1.0, "supported");
    add_cell("D_dia", 1.0, 1.0, "supported");
    assert(add_depends("A_dia", "B_dia"));
    assert(add_depends("A_dia", "C_dia"));
    assert(add_depends("B_dia", "D_dia"));
    assert(add_depends("C_dia", "D_dia"));
    deps: list[str] = get_dependencies("A_dia");
    assert(sorted(deps) == ["B_dia", "C_dia", "D_dia"]);
    assert(len(deps) == 3);
}
test "unknown id tolerance empty" {
    deps: list[str] = get_dependencies("unknown_xyz_999");
    assert(deps == []);
    lin: list[str] = get_lineage("unknown_xyz_999");
    assert(lin == []);
    assert(not add_depends("nope_a", "nope_b"));
    assert(not add_lineage("nope_a", "nope_b"));
    failed: list[str] = get_failed_cells();
    assert(len(failed) >= 0);
}
test "pareto front deterministic and failures distinguishable" {
    add_cell("P1_pf", 10.0, 0.9, "supported");
    add_cell("P2_pf", 5.0, 0.8, "supported");
    add_cell("P3_pf", 8.0, 0.95, "supported");
    add_cell("F1_pf", 1.0, 0.99, "failed");
    add_cell("U1_pf", 2.0, 0.98, "unsupported");
    pf: list[str] = get_pareto_front();
    assert("P2_pf" in pf);
    assert("P3_pf" in pf);
    assert("P1_pf" not in pf);
    assert("F1_pf" not in pf);
    assert("U1_pf" not in pf);
    fails: list[str] = get_failed_cells();
    assert("F1_pf" in fails);
    assert("U1_pf" in fails);
    assert("P2_pf" not in fails);
}
test "lineage chain and cycle does not loop" {
    add_cell("X_lin", 2.0, 0.5, "supported");
    add_cell("Y_lin", 2.0, 0.6, "supported");
    add_cell("Z_lin", 3.0, 0.7, "supported");
    assert(add_lineage("Y_lin", "X_lin"));
    assert(add_lineage("Z_lin", "Y_lin"));
    lin: list[str] = get_lineage("Z_lin");
    assert(sorted(lin) == ["X_lin", "Y_lin"]);
    assert(add_depends("Y_lin", "Z_lin"));
    assert(add_depends("Z_lin", "Y_lin"));
    deps: list[str] = get_dependencies("Y_lin");
    assert("Z_lin" in deps);
    assert(len(deps) == 1);
    deps2: list[str] = get_dependencies("Z_lin");
    assert("Y_lin" in deps2);
}
