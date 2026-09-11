"""Guard tests for iss_eeshsaxena__graphone__1.jac"""

obj CompanyGraph { has companies: dict[str, Company] = {}; }
node Company { has cid: str; has name: str; }
edge Invests {}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    can step with Company entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.reached.append(here.cid);
        visit [->:Invests:->] else { disengage; };
    }
}

walker CycleWalk {
    has claimed: dict[str, bool] = {};
    has has_cycle: bool = False;
    can step with Company entry {
        if here.cid in self.claimed { self.has_cycle = True; skip; }
        self.claimed[here.cid] = True;
        visit [->:Invests:->] else { disengage; };
    }
}

def load_graph(companies: list[tuple[str, str]], investments: list[tuple[str, str]]) -> CompanyGraph {
    mp: dict[str, Company] = {};
    for (cid, name) in companies { c = Company(cid=cid, name=name); root ++> c; mp[cid] = c; }
    for (inv, tgt) in investments {
        a = mp.get(inv, None); b = mp.get(tgt, None);
        if a is not None and b is not None { a +>:Invests:+> b; }
    }
    return CompanyGraph(companies=mp);
}

def graph_endpoint(g: CompanyGraph, company_id: str) -> list[str] {
    anchor = g.companies.get(company_id, None);
    if anchor is None { return []; }
    w = anchor spawn ReachWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

def has_investment_cycle(g: CompanyGraph, company_id: str) -> bool {
    anchor = g.companies.get(company_id, None);
    if anchor is None { return False; }
    w = anchor spawn CycleWalk(claimed={}, has_cycle=False);
    return w.has_cycle;
}

def investors_of(g: CompanyGraph, company_id: str) -> list[str] {
    if company_id not in g.companies { return []; }
    out: list[str] = [];
    for inv in g.companies.values() {
        for tgt in [inv ->:Invests:->] { if tgt.cid == company_id { out.append(inv.cid); } }
    }
    return sorted(out);
}

test "chain reach and investors" {
    g = load_graph(
        [("a", "Alpha"), ("b", "Beta"), ("c", "Gamma")],
        [("a", "b"), ("b", "c")],
    );
    assert graph_endpoint(g, "a") == ["a", "b", "c"];
    assert has_investment_cycle(g, "a") is False;
    assert investors_of(g, "c") == ["b"];
}

test "directed cycle terminates" {
    g = load_graph(
        [("a", "A"), ("b", "B"), ("c", "C")],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert graph_endpoint(g, "a") == ["a", "b", "c"];
    assert has_investment_cycle(g, "a") is True;
}

test "diamond adversarial once per node" {
    g = load_graph(
        [("top", "T"), ("l", "L"), ("r", "R"), ("base", "B")],
        [("top", "l"), ("top", "r"), ("l", "base"), ("r", "base")],
    );
    assert graph_endpoint(g, "top") == ["base", "l", "r", "top"];
}

test "unknown company tolerant" {
    g = load_graph([("only", "O")], []);
    assert graph_endpoint(g, "missing") == [];
    assert has_investment_cycle(g, "missing") is False;
    assert investors_of(g, "missing") == [];
}
