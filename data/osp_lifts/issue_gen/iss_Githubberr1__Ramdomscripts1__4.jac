"""Githubberr1/Ramdomscripts1#4 -- employee hierarchy."""

node Emp {
    has eid: str;
}

edge Manages {}

obj Org {
    has emps: dict[str, Emp] = {};
}

walker ReportsWalk {
    has claimed: dict[str, bool] = {};
    has out: list[tuple[str, int]] = [];
    has depth_map: dict[str, int] = {};
    can step with Emp entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        lvl = self.depth_map.get(here.eid, 0);
        self.out.append((here.eid, lvl));
        for ch in [here ->:Manages:->][?:Emp] {
            if not (ch.eid in self.depth_map) {
                self.depth_map[ch.eid] = lvl + 1;
            }
            visit ch;
        }
    }
}

walker CycleProbe {
    has path_seen: set[str] = set();
    has found: bool = False;
    can step with Emp entry {
        if here.eid in self.path_seen { self.found = True; return; }
        new_seen = self.path_seen | {here.eid};
        for ch in [here ->:Manages:->][?:Emp] {
            sub = CycleProbe(path_seen=new_seen);
            ch spawn sub;
            if sub.found { self.found = True; return; }
        }
    }
}

def make_org() -> Org {
    return Org();
}

def add_employee(org: Org, emp: str, manager: str | None) -> None {
    if emp in org.emps { raise ValueError("duplicate employee"); }
    e = Emp(eid=emp);
    root ++> e;
    org.emps[emp] = e;
    if manager is not None {
        if not (manager in org.emps) {
            m = Emp(eid=manager);
            root ++> m;
            org.emps[manager] = m;
        }
        org.emps[manager] +>:Manages:+> e;
    }
}

def all_reports(org: Org, manager: str) -> list[tuple[str, int]] {
    if not (manager in org.emps) { return []; }
    mgr = org.emps[manager];
    w = mgr spawn ReportsWalk(claimed={}, out=[], depth_map={manager: 0});
    res: list[tuple[str, int]] = [];
    for (eid, lvl) in w.out {
        if eid != manager { res.append((eid, lvl)); }
    }
    return sorted(res);
}

def chain_to_root(org: Org, emp: str) -> list[str] {
    if not (emp in org.emps) { return []; }
    chain: list[str] = [];
    seen: set[str] = set();
    cur: str | None = emp;
    while cur is not None and not (cur in seen) {
        chain.append(cur);
        seen.add(cur);
        # find manager via reverse edge
        found: str | None = None;
        for k in org.emps {
            for ch in [org.emps[k] ->:Manages:->][?:Emp] {
                if ch.eid == cur { found = k; }
            }
        }
        cur = found;
    }
    return chain;
}

def has_cycle(org: Org) -> bool {
    for eid in org.emps {
        w = org.emps[eid] spawn CycleProbe(path_seen=set(), found=False);
        if w.found { return True; }
    }
    return False;
}

def top_customers_mock(orders: list[dict], days: int) -> list[tuple[str, float]] {
    totals: dict[str, float] = {};
    for o in orders {
        cid: str = o.get("customer_id", "");
        amt: float = o.get("total_amount", 0.0);
        if cid in totals { totals[cid] = totals[cid] + amt; } else { totals[cid] = amt; }
    }
    items: list[tuple[str, float]] = [];
    for k in totals { items.append((k, totals[k])); }
    # sort descending by amount (simple bubble)
    for i in range(items.__len__()) {
        for j in range(i + 1, items.__len__()) {
            if items[j][1] > items[i][1] {
                tmp = items[i]; items[i] = items[j]; items[j] = tmp;
            }
        }
    }
    out: list[tuple[str, float]] = [];
    lim = 5;
    if items.__len__() < lim { lim = items.__len__(); }
    for i in range(lim) { out.append(items[i]); }
    return out;
}
