"""Employee management hierarchy — azaharizaman/nexus#123."""

glob STATUS_ACTIVE = "ACTIVE";
glob STATUS_TERMINATED = "TERMINATED";

node Employee {
    has eid: str;
    has name: str;
    has status: str = "ACTIVE";
    has tenant_id: str = "t1";
    has has_payroll: bool = False;
    has has_leave: bool = False;
}

edge Manages {}

obj EmployeeGraph {
    has index: dict[str, Employee] = {};

    def lookup(self, eid: str) -> Employee | None {
        if eid in self.index {
            return self.index[eid];
        }
        return None;
    }
}

walker AllReportsWalker {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];

    can step with Employee entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        print("reports", here.eid);
        kids: list[Employee] = [];
        for ch in [here ->:Manages:->][?:Employee] {
            kids.append(ch);
        }
        for ch in kids {
            self.out.append(ch.eid);
            visit :0: [ch];
        }
    }
}

walker ChainWalker {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];

    can step_up with Employee entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        self.out.append(here.eid);
        print("chain", here.eid);
        mgrs: list[Employee] = [];
        for m in [here <-:Manages:<-][?:Employee] {
            mgrs.append(m);
        }
        if mgrs {
            visit [mgrs[0]];
        } else {
            disengage;
        }
    }
}

def new_graph -> EmployeeGraph {
    return EmployeeGraph();
}

def create_employee(graph: EmployeeGraph, eid: str, name: str, tenant_id: str = "t1") -> str {
    nd = Employee(eid=eid, name=name, tenant_id=tenant_id);
    root ++> nd;
    graph.index[eid] = nd;
    return eid;
}

def set_manager(graph: EmployeeGraph, eid: str, manager_id: str | None = None) -> bool {
    emp = graph.lookup(eid);
    if not emp {
        return False;
    }
    old_mgrs: list[Employee] = [];
    for om in [emp <-:Manages:<-][?:Employee] {
        old_mgrs.append(om);
    }
    for om in old_mgrs {
        destroy om +>:Manages:+> emp;
    }
    if manager_id is None {
        return True;
    }
    mgr = graph.lookup(manager_id);
    if not mgr {
        return False;
    }
    mgr +>:Manages:+> emp;
    return True;
}

def list_direct_reports(graph: EmployeeGraph, eid: str) -> list[str] {
    nd = graph.lookup(eid);
    if not nd {
        return [];
    }
    ids: list[str] = [];
    for ch in [nd ->:Manages:->][?:Employee] {
        ids.append(ch.eid);
    }
    return sorted(ids);
}

def list_all_reports(graph: EmployeeGraph, eid: str) -> list[str] {
    nd = graph.lookup(eid);
    if not nd {
        return [];
    }
    w = nd spawn AllReportsWalker(claimed={});
    return sorted(w.out);
}

def list_management_chain(graph: EmployeeGraph, eid: str) -> list[str] {
    nd = graph.lookup(eid);
    if not nd {
        return [];
    }
    w = nd spawn ChainWalker(claimed={});
    return w.out;
}

def terminate_employee(graph: EmployeeGraph, eid: str) -> bool {
    emp = graph.lookup(eid);
    if not emp {
        return False;
    }
    if emp.has_leave {
        return False;
    }
    reps: list[Employee] = [];
    for r in [emp ->:Manages:->][?:Employee] {
        reps.append(r);
    }
    for r in reps {
        destroy emp +>:Manages:+> r;
    }
    emp.status = STATUS_TERMINATED;
    return True;
}

def can_delete_employee(graph: EmployeeGraph, eid: str) -> bool {
    nd = graph.lookup(eid);
    if not nd {
        return False;
    }
    if nd.has_payroll {
        return False;
    }
    if nd.has_leave {
        return False;
    }
    return True;
}
