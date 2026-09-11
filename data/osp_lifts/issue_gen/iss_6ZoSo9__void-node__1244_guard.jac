"""6ZoSo9/void-node#1244 - Dijkstra state-machine audit: path reachability and terminal closure."""

node Machine { has mid: str; }
node State { has sid: str; has terminal: bool = False; }

edge Contains {}
edge Trans {}

walker Collect {
    has claimed: dict[str, bool] = {};
    has collected: list[str] = [];
    can step with State entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.collected.append(here.sid);
        print(here.sid);
        kids: list[State] = [];
        for nxt in [here ->:Trans:->][?:State] {
            if nxt.sid not in self.claimed {
                kids.append(nxt);
            }
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker CheckReach {
    has target: str = "";
    has claimed: dict[str, bool] = {};
    has found: bool = False;
    can step with State entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        print(here.sid);
        if here.sid == self.target {
            self.found = True;
        }
        kids: list[State] = [];
        for nxt in [here ->:Trans:->][?:State] {
            if nxt.sid not in self.claimed {
                kids.append(nxt);
            }
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def make_machine(mid: str) -> Machine {
    nd: Machine = Machine(mid=mid);
    root ++> nd;
    return nd;
}

def make_state(sid: str, terminal: bool) -> State {
    nd: State = State(sid=sid, terminal=terminal);
    return nd;
}

def attach_machine_state(machine: Machine, state: State) -> None {
    machine +>:Contains:+> state;
}

def link_states(src: State, dst: State) -> None {
    src +>:Trans:+> dst;
}

def reachable_ids(start: State) -> list[str] {
    w: Collect = start spawn Collect();
    res: list[str] = w.collected;
    return res;
}

def can_reach(start: State, target: str) -> bool {
    w: CheckReach = start spawn CheckReach(target=target);
    return w.found;
}

def terminal_ids(machine: Machine) -> list[str] {
    out: list[str] = [];
    for st in [machine ->:Contains:->][?:State] {
        if st.terminal {
            out.append(st.sid);
        }
    }
    return out;
}

def list_all_states(machine: Machine) -> list[str] {
    out: list[str] = [];
    for st in [machine ->:Contains:->][?:State] {
        out.append(st.sid);
    }
    return out;
}

with entry {
    demo_m: Machine = Machine(mid="demo");
    root ++> demo_m;
    demo_s: State = State(sid="demo_s", terminal=False);
    demo_m +>:Contains:+> demo_s;
    root spawn Collect();
    print("demo ready");
}

test "diamond revisit adversarial order" {
    m = make_machine("m_dia");
    a = make_state("a", False);
    b = make_state("b", False);
    c = make_state("c", False);
    d = make_state("d", True);
    attach_machine_state(m, a);
    attach_machine_state(m, b);
    attach_machine_state(m, c);
    attach_machine_state(m, d);
    link_states(a, b);
    link_states(a, c);
    link_states(b, d);
    link_states(c, d);
    got = reachable_ids(a);
    assert(sorted(got) == ["a", "b", "c", "d"]);
    assert(can_reach(a, "d") == True);
    assert(can_reach(b, "c") == False);
}

test "cycle does not loop and still reaches" {
    m = make_machine("m_cyc");
    x = make_state("x", False);
    y = make_state("y", False);
    z = make_state("z", False);
    attach_machine_state(m, x);
    attach_machine_state(m, y);
    attach_machine_state(m, z);
    link_states(x, y);
    link_states(y, z);
    link_states(z, x);
    got = reachable_ids(x);
    assert(sorted(got) == ["x", "y", "z"]);
    assert(can_reach(x, "x") == True);
    assert(can_reach(y, "x") == True);
}

test "unknown id tolerance and terminal closure" {
    m = make_machine("m_unk");
    s1 = make_state("s1", False);
    s2 = make_state("s2", True);
    attach_machine_state(m, s1);
    attach_machine_state(m, s2);
    # isolated s1 no edges
    assert(reachable_ids(s1) == ["s1"]);
    assert(can_reach(s1, "nope") == False);
    assert(can_reach(s1, "s2") == False);
    assert(sorted(terminal_ids(m)) == ["s2"]);
    assert(sorted(list_all_states(m)) == ["s1", "s2"]);
    # unknown target on isolated terminal
    assert(can_reach(s2, "ghost") == False);
}

test "parent child containment and path reach edge case" {
    m = make_machine("m_pc");
    p = make_state("p", False);
    q = make_state("q", False);
    r = make_state("r", True);
    attach_machine_state(m, p);
    attach_machine_state(m, q);
    attach_machine_state(m, r);
    link_states(p, q);
    # no link to r, r unreachable
    assert(can_reach(p, "r") == False);
    assert(sorted(reachable_ids(p)) == ["p", "q"]);
    link_states(q, r);
    assert(can_reach(p, "r") == True);
    assert(sorted(terminal_ids(m)) == ["r"]);
}
