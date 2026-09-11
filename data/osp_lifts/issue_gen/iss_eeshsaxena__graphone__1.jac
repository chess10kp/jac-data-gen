"""eeshsaxena/graphone#1 — cycle-safe portfolio graph (OSP lift)."""

obj CompanyGraph {
    has companies: dict[str, Company] = {};
}

node Company {
    has cid: str;
    has name: str;
}

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
        if here.cid in self.claimed {
            self.has_cycle = True;
            skip;
        }
        self.claimed[here.cid] = True;
        visit [->:Invests:->] else { disengage; };
    }
}

def load_graph(
    companies: list[tuple[str, str]],
    investments: list[tuple[str, str]],
) -> CompanyGraph {
    mp: dict[str, Company] = {};
    for (cid, name) in companies {
        c = Company(cid=cid, name=name);
        root ++> c;
        mp[cid] = c;
    }
    for (inv, tgt) in investments {
        a = mp.get(inv, None);
        b = mp.get(tgt, None);
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
        for tgt in [inv ->:Invests:->] {
            if tgt.cid == company_id { out.append(inv.cid); }
        }
    }
    return sorted(out);
}
