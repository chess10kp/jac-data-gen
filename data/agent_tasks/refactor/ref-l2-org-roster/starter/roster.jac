"""Team roster: who reports to whom, and what each team costs."""

node Roster {
    has boss: dict[str, str] = {};
    has pay: dict[str, int] = {};
}

def _roster() -> Roster {
    for n in [root -->] {
        if isinstance(n, Roster) {
            return n;
        }
    }
    r = Roster();
    root ++> r;
    return r;
}

def hire(name: str, salary: int, manager: str) -> bool {
    r = _roster();
    if name in r.pay {
        return False;
    }
    if manager != "" and manager not in r.pay {
        return False;
    }
    r.pay[name] = salary;
    r.boss[name] = manager;
    return True;
}

def manager_of(name: str) -> str {
    r = _roster();
    if name not in r.boss {
        return "";
    }
    return r.boss[name];
}

def direct_reports(name: str) -> list[str] {
    r = _roster();
    if name not in r.pay {
        return [];
    }
    out: list[str] = [];
    for e in r.boss {
        if r.boss[e] == name {
            out.append(e);
        }
    }
    return sorted(out);
}

def team_cost(name: str) -> int {
    r = _roster();
    if name not in r.pay {
        return 0;
    }
    total = r.pay[name];
    for e in r.boss {
        if r.boss[e] == name {
            total += r.pay[e];
        }
    }
    return total;
}

def peers(name: str) -> list[str] {
    r = _roster();
    if name not in r.boss {
        return [];
    }
    out: list[str] = [];
    for e in r.boss {
        if e != name and r.boss[e] == r.boss[name] {
            out.append(e);
        }
    }
    return sorted(out);
}

def transfer(name: str, new_manager: str) -> bool {
    r = _roster();
    if name not in r.pay or name == new_manager {
        return False;
    }
    if new_manager != "" and new_manager not in r.pay {
        return False;
    }
    r.boss[name] = new_manager;
    return True;
}

def fire(name: str) -> bool {
    r = _roster();
    if name not in r.pay {
        return False;
    }
    up = r.boss[name];
    for e in r.boss {
        if r.boss[e] == name {
            r.boss[e] = up;
        }
    }
    r.boss.pop(name);
    r.pay.pop(name);
    return True;
}
