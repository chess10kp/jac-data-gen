node Entity {
    has eid: str;
    has kind: str;
}
edge Depends {}

walker ClosureWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can traverse with Entity entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        self.found.append(here.eid);
        print(here.eid);
        kids: list[Entity] = [];
        for nxt in [here ->:Depends:->][?:Entity] {
            kids.append(nxt);
        }
        visit :0: kids else { disengage; }
    }
}

walker CycleProbe {
    has claimed: dict[str, bool] = {};
    has has_cycle: bool = False;
    can probe with Entity entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        print(here.eid);
        for nxt in [here ->:Depends:->][?:Entity] {
            if nxt.eid in self.claimed {
                self.has_cycle = True;
            }
        }
        kids: list[Entity] = [];
        for nxt in [here ->:Depends:->][?:Entity] {
            kids.append(nxt);
        }
        visit :0: kids else { disengage; }
    }
}

def create_context() -> dict[str, Entity] {
    store: dict[str, Entity] = {};
    return store;
}

def register_entity(store: dict[str, Entity], eid: str, kind: str) -> bool {
    if eid in store {
        return False;
    }
    nd = Entity(eid=eid, kind=kind);
    root ++> nd;
    store[eid] = nd;
    return True;
}

def add_relationship(store: dict[str, Entity], src: str, dst: str) -> bool {
    if src not in store {
        return False;
    }
    if dst not in store {
        return False;
    }
    s = store[src];
    d = store[dst];
    s +>:Depends:+> d;
    return True;
}

def get_reachable(store: dict[str, Entity], start_id: str) -> list[str] {
    if start_id not in store {
        return [];
    }
    st = store[start_id];
    w = st spawn ClosureWalker(claimed={}, found=[]);
    res: list[str] = w.found;
    res = sorted(res);
    return res;
}

def has_cycle_from(store: dict[str, Entity], start_id: str) -> bool {
    if start_id not in store {
        return False;
    }
    st = store[start_id];
    w = st spawn CycleProbe(claimed={}, has_cycle=False);
    return w.has_cycle;
}
