"""Dtronix/Quarry#330 — employee manager tree descendant enumeration."""

node Employee {
    has eid: str;
}

edge ReportsTo {}

obj OrgStore {
    has employees: dict[str, Employee] = {};
}

walker DescendantWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Employee entry {
        if here.eid not in self.claimed {
            self.claimed[here.eid] = True;
            self.found.append(here.eid);
        }
        visit [->:ReportsTo:->][?:Employee];
    }
}

def load_org(
    employees: list[str],
    manager_edges: list[tuple[str, str]],
) -> OrgStore {
    store = OrgStore();
    for eid in employees {
        nd = Employee(eid=eid);
        root ++> nd;
        store.employees[eid] = nd;
    }
    for (mgr, rep) in manager_edges {
        m = store.employees.get(mgr, None);
        r = store.employees.get(rep, None);
        if m is not None and r is not None { m +>:ReportsTo:+> r; }
    }
    return store;
}

def manager_descendants(store: OrgStore, emp_id: str) -> list[str] {
    nd = store.employees.get(emp_id, None);
    if nd is None { return []; }
    w = nd spawn DescendantWalk(claimed={emp_id: True});
    return sorted(w.found);
}

def reporting_depth(store: OrgStore, emp_id: str) -> int {
    nd = store.employees.get(emp_id, None);
    if nd is None { return -1; }
    depth = 0;
    cur: Employee | None = nd;
    claimed: dict[str, bool] = {};
    while cur is not None {
        if cur.eid in claimed { return -1; }
        claimed[cur.eid] = True;
        mgrs = [cur <-:ReportsTo:<-][?:Employee];
        if len(mgrs) == 0 { break; }
        depth += 1;
        cur = mgrs[0];
    }
    return depth;
}

def direct_reports(store: OrgStore, emp_id: str) -> list[str] {
    nd = store.employees.get(emp_id, None);
    if nd is None { return []; }
    out: list[str] = [];
    for r in [nd ->:ReportsTo:->][?:Employee] { out.append(r.eid); }
    return sorted(out);
}
