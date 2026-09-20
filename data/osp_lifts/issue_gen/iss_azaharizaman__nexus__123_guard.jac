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

test "create_and_lookup" {
    g = new_graph();
    assert create_employee(g, "e1", "Alice") == "e1";
    assert create_employee(g, "e2", "Bob", "t2") == "e2";
    assert g.lookup("e1").name == "Alice";
    assert g.lookup("e2").tenant_id == "t2";
    assert g.lookup("missing") is None;
}

test "set_manager_and_direct_reports" {
    g = new_graph();
    create_employee(g, "m1", "Mgr");
    create_employee(g, "e1", "Emp");
    assert set_manager(g, "e1", "m1") is True;
    assert list_direct_reports(g, "m1") == ["e1"];
    assert set_manager(g, "e1", None) is True;
    assert list_direct_reports(g, "m1") == [];
    assert set_manager(g, "e1", "bad") is False;
    assert set_manager(g, "bad", "m1") is False;
}

test "all_reports_transitive" {
    g = new_graph();
    create_employee(g, "a", "A");
    create_employee(g, "b", "B");
    create_employee(g, "c", "C");
    create_employee(g, "d", "D");
    set_manager(g, "b", "a");
    set_manager(g, "c", "b");
    set_manager(g, "d", "a");
    assert list_all_reports(g, "a") == ["b", "c", "d"];
    assert list_all_reports(g, "b") == ["c"];
    assert list_all_reports(g, "missing") == [];
}

test "management_chain_upward" {
    g = new_graph();
    create_employee(g, "ceo", "CEO");
    create_employee(g, "mgr", "Mgr");
    create_employee(g, "ic", "IC");
    set_manager(g, "mgr", "ceo");
    set_manager(g, "ic", "mgr");
    assert list_management_chain(g, "ic") == ["ic", "mgr", "ceo"];
    assert list_management_chain(g, "ceo") == ["ceo"];
    assert list_management_chain(g, "missing") == [];
}

test "terminate_disconnects_reports" {
    g = new_graph();
    create_employee(g, "m", "M");
    create_employee(g, "e", "E");
    set_manager(g, "e", "m");
    assert terminate_employee(g, "m") is True;
    assert g.lookup("m").status == "TERMINATED";
    assert list_direct_reports(g, "m") == [];
    assert terminate_employee(g, "missing") is False;
}

test "delete_guards_payroll_and_leave" {
    g = new_graph();
    create_employee(g, "e", "E");
    assert can_delete_employee(g, "e") is True;
    nd = g.lookup("e");
    nd.has_payroll = True;
    assert can_delete_employee(g, "e") is False;
    nd.has_payroll = False;
    nd.has_leave = True;
    assert can_delete_employee(g, "e") is False;
    assert terminate_employee(g, "e") is False;
    assert can_delete_employee(g, "missing") is False;
}
