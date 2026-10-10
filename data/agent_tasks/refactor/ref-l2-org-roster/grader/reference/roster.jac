"""Team roster: who reports to whom, and what each team costs."""

node Employee {
    has name: str;
    has salary: int;
}

edge Manages: Employee --> Employee {}

def find(name: str) -> Employee | None {
    wanted = name;
    found = [root -->[?:Employee, name == wanted]];
    return found[0] if found else None;
}

def boss_of(e: Employee) -> Employee | None {
    up = [e <-:Manages:<-];
    return up[0] if up else None;
}

def hire(name: str, salary: int, manager: str) -> bool {
    if find(name) is not None {
        return False;
    }
    boss = find(manager);
    if manager != "" and boss is None {
        return False;
    }
    e = Employee(name=name, salary=salary);
    root ++> e;
    if boss is not None {
        boss +>:Manages():+> e;
    }
    return True;
}

def manager_of(name: str) -> str {
    e = find(name);
    if e is None {
        return "";
    }
    b = boss_of(e);
    return b.name if b is not None else "";
}

def direct_reports(name: str) -> list[str] {
    e = find(name);
    if e is None {
        return [];
    }
    return sorted([r.name for r in [e ->:Manages:->]]);
}

def team_cost(name: str) -> int {
    e = find(name);
    if e is None {
        return 0;
    }
    return e.salary + sum([r.salary for r in [e ->:Manages:->]]);
}

def peers(name: str) -> list[str] {
    e = find(name);
    if e is None {
        return [];
    }
    b = boss_of(e);
    if b is None {
        group = [x for x in [root -->[?:Employee]] if boss_of(x) is None];
    } else {
        group = [b ->:Manages:->];
    }
    return sorted([x.name for x in group if x.name != name]);
}

def transfer(name: str, new_manager: str) -> bool {
    e = find(name);
    if e is None or name == new_manager {
        return False;
    }
    nb = find(new_manager);
    if new_manager != "" and nb is None {
        return False;
    }
    old = boss_of(e);
    if old is not None {
        for link in [edge old ->:Manages:-> e] {
            del link;
        }
    }
    if nb is not None {
        nb +>:Manages():+> e;
    }
    return True;
}

def fire(name: str) -> bool {
    e = find(name);
    if e is None {
        return False;
    }
    up = boss_of(e);
    if up is not None {
        for r in [e ->:Manages:->] {
            up +>:Manages():+> r;
        }
    }
    del e;
    return True;
}
