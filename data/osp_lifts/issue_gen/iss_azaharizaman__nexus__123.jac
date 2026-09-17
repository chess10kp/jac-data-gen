# azaharizaman/nexus#123 — Employee Management Foundation
# Idiomatic OSP lift: employee records, manager hierarchy, lifecycle events.

node Employee {
    has eid: str;
    has name: str;
    has status: str = "ACTIVE";
    has etype: str = "FULL_TIME";
    has ssn_enc: str = "";
    has anonymous: bool = False;
    has history: list[str] = [];
}

edge ReportsTo {}

edge InTenant {
    has tid: str;
}

glob EMP_INDEX: dict[str, Employee] = {};

def register(e: Employee) {
    EMP_INDEX[e.eid] = e;
}

def lookup(eid: str) -> Employee | None {
    if eid in EMP_INDEX {
        return EMP_INDEX[eid];
    }
    return None;
}

def hire(eid: str, name: str, ssn: str, tenant: Employee, etype: str = "FULL_TIME") -> Employee {
    e = Employee(eid=eid, name=name, etype=etype);
    e.ssn_enc = "enc(" + ssn + ")";
    e.history.append("HIRE");
    tenant +>:InTenant(tid=tenant.eid):+> e;
    register(e);
    return e;
}

def set_manager(emp: Employee, mgr: Employee) {
    emp +>:ReportsTo:+> mgr;
    emp.history.append("TRANSFER");
}

def terminate(eid: str) -> bool {
    e = lookup(eid);
    if e is None { return False; }
    if e.status == "TERMINATED" { return False; }
    e.status = "TERMINATED";
    e.history.append("TERMINATION");
    return True;
}

def anonymize(eid: str) -> bool {
    e = lookup(eid);
    if e is None { return False; }
    e.name = "Anonymous";
    e.ssn_enc = "";
    e.anonymous = True;
    return True;
}

def direct_reports(eid: str) -> list[str] {
    e = lookup(eid);
    if e is None { return []; }
    outs: list[str] = [];
    for r in [e ->:ReportsTo:<-][?:Employee] {
        outs.append(r.eid);
    }
    return sorted(outs);
}

def chain_up(eid: str) -> list[str] {
    # climb manager chain, cycle-safe via claim map
    start = lookup(eid);
    if start is None { return []; }
    seen: dict[str, bool] = {};
    chain: list[str] = [];
    cur = start;
    while cur is not None and cur.eid not in seen {
        seen[cur.eid] = True;
        chain.append(cur.eid);
        mgrs = [cur ->:ReportsTo:->][?:Employee];
        if len(mgrs) == 0 { break; }
        cur = mgrs[0];
    }
    return chain;
}

walker OrgScan {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Employee entry {
        if here.eid in self.claimed {
            skip;
        }
        self.claimed[here.eid] = True;
        if here.status == "ACTIVE" {
            self.found.append(here.eid);
        }
        kids = [here ->:ReportsTo:<-][?:Employee];
        visit kids;
    }
}

def active_under(eid: str) -> list[str] {
    e = lookup(eid);
    if e is None { return []; }
    w = e spawn OrgScan(claimed={});
    return sorted(w.found);
}

with entry {
    ceo = Employee(eid="T1", name="CEO");
    register(ceo);
    hire("E1", "Alice", "111", ceo);
    hire("E2", "Bob", "222", ceo, etype="INTERN");
    set_manager(lookup("E1"), ceo);
    set_manager(lookup("E2"), lookup("E1"));
    print(sorted(active_under("T1")));
}
