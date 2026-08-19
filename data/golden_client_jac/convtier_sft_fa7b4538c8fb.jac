node Company {}
node Dept { has name: str; }
node Employee { has dept: str; has salary: int; }

walker PayrollScan {
    has totals: dict = {};
    can start with Company entry { visit [-->][?:Dept]; }
    can open with Dept entry {
        self.totals[here.name] = 0;
        visit [-->][?:Employee];
    }
    can add with Employee entry { self.totals[here.dept] += here.salary; }
}

def richest_department(spec: dict) -> str {
    depts: dict = dict(spec["depts"]);
    if len(depts) == 0 { return ""; }
    co = Company();
    for (dn, sals) in depts.items() {
        d = Dept(name=str(dn));
        co ++> d;
        for s in list(sals) { d ++> Employee(dept=str(dn), salary=int(s)); }
    }
    w = co spawn PayrollScan();
    best: str = ""; bt: int = 0; seen: bool = False;
    for dn in sorted(w.totals.keys()) {
        if not seen or w.totals[dn] > bt { best = dn; bt = w.totals[dn]; seen = True; }
    }
    return best;
}

with entry {
    print(richest_department({'depts': {'eng': [120, 90], 'ops': [50]}}));
}
