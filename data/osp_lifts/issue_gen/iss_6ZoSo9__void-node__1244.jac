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
