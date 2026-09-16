# azaharizaman/nexus#123 — Employee Management Foundation
# Lifted hand-rolled hierarchy recursion to idiomatic OSP graph.

node Employee {
    has eid: str;
    has name: str;
    has email: str;
    has employee_number: str;
    has tenant_id: str;
    has status: str = "ACTIVE";
    has employment_type: str = "FULL_TIME";
    has deleted: bool = False;
}

edge ReportsTo {}

edge HistoryEvent {
    has event_type: str;
    has event_date: str;
}

def employee(eid: str, name: str, email: str, num: str, tenant: str) -> Employee {
    return Employee(eid=eid, name=name, email=email, employee_number=num, tenant_id=tenant);
}

# record a lifecycle event, scoped by tenant employee-number uniqueness
def hire(mgr: Employee | None, emp: Employee) -> Employee {
    if mgr {
        mgr +>:ReportsTo:+> emp;
    } else {
        root ++> emp;
    }
    emp spawn HireEvent(etype="HIRE");
    return emp;
}

def transfer(emp: Employee, new_mgr: Employee) -> Employee {
    for rm in [emp -:ReportsTo:->] { del rm; }
    new_mgr +>:ReportsTo:+> emp;
    emp spawn LifecycleEvent(etype="TRANSFER");
    return emp;
}

def terminate(emp: Employee) -> bool {
    emp.status = "TERMINATED";
    emp spawn LifecycleEvent(etype="TERMINATION");
    return True;
}

# recursive direct/indirect reports closure via walker, claim-map cycle policy
walker ReportClosure {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Employee entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        kids: list[Employee] = [];
        for ch in [here ->:ReportsTo:->] { kids.append(ch); }
        for k in kids {
            self.found.append(k.eid);
        }
        visit kids;
    }
}

def all_reports(emp: Employee) -> list[str] {
    w = emp spawn ReportClosure(claimed={});
    res: list[str] = [];
    for e in w.found {
        if e != emp.eid { res.append(e); }
    }
    return sorted(res);
}

walker HireEvent {
    has etype: str;
    can go with Employee entry {
        here +>:HistoryEvent(event_type=self.etype, event_date="2024-01-01"):+> here;
        print("event recorded: " + self.etype + " for " + here.eid);
    }
}

walker LifecycleEvent {
    has etype: str;
    can go with Employee entry {
        here +>:HistoryEvent(event_type=self.etype, event_date="2024-06-01"):+> here;
        print("lifecycle: " + self.etype + " for " + here.eid);
    }
}

def can_be_deleted(emp: Employee) -> bool {
    evs: list[HistoryEvent] = [emp ->:HistoryEvent:->];
    for ev in evs {
        if ev.event_type == "TERMINATION" { return False; }
    }
    return True;
}

def anonymize(emp: Employee) -> Employee {
    emp.name = "Anonymous";
    emp.email = "anonymous@example.invalid";
    print("anonymized " + emp.eid);
    return emp;
}

with entry {
    ceo = employee("e1", "Ada", "ada@x.io", "E-0001", "t1");
    hire(None, ceo);
    b = employee("e2", "Bob", "bob@x.io", "E-0002", "t1");
    c = employee("e3", "Cid", "cid@x.io", "E-0003", "t1");
    hire(ceo, b);
    hire(ceo, c);
    transfer(c, b);
    print(sorted(all_reports(ceo)));
}

test "hire_and_transfer_reports" {
    ceo = employee("e1", "Ada", "ada@x.io", "E-0001", "t1");
    hire(None, ceo);
    b = employee("e2", "Bob", "bob@x.io", "E-0002", "t1");
    c = employee("e3", "Cid", "cid@x.io", "E-0003", "t1");
    hire(ceo, b);
    hire(ceo, c);
    transfer(c, b);
    assert all_reports(ceo) == ["e2", "e3"];;
    assert all_reports(b) == ["e3"];;
}

test "transfer_moves_edge" {
    m1 = employee("m1", "A", "a@x", "E-1", "t1");
    m2 = employee("m2", "B", "b@x", "E-2", "t1");
    s = employee("s1", "C", "c@x", "E-3", "t1");
    hire(m1, s);
    transfer(s, m2);
    assert all_reports(m1) == [];;
    assert all_reports(m2) == ["s1"];;
}

test "terminate_blocks_delete" {
    e = employee("t9", "X", "x@x", "E-9", "t1");
    hire(None, e);
    assert can_be_deleted(e);;
    terminate(e);
    assert not can_be_deleted(e);;
    assert e.status == "TERMINATED";;
}

test "closure_diamond_adversarial_order" {
    ceo = employee("d1", "A", "a@x", "E-1", "t1");
    hire(None, ceo);
    mid = employee("d2", "B", "b@x", "E-2", "t1");
    leaf = employee("d3", "C", "c@x", "E-3", "t1");
    # insert leaf edge first so a revisit fires before deeper first-visits
    hire(ceo, leaf);
    hire(ceo, mid);
    hire(mid, leaf);
    assert all_reports(ceo) == ["d2", "d3"];;
}

test "anonymize_fields" {
    e = employee("a1", "Zed", "zed@x", "E-4", "t1");
    hire(None, e);
    e = anonymize(e);
    assert e.name == "Anonymous";;
    assert e.email == "anonymous@example.invalid";;
}
