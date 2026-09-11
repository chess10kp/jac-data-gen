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

test "circular paleoContext localities no loop" {
    ctx: dict[str, Entity] = create_context();
    assert (register_entity(ctx, "paleoContext", "paleo") == True);
    assert (register_entity(ctx, "locality", "locality") == True);
    assert (add_relationship(ctx, "paleoContext", "locality") == True);
    assert (add_relationship(ctx, "locality", "paleoContext") == True);
    reach: list[str] = get_reachable(ctx, "paleoContext");
    assert (reach == ["locality", "paleoContext"]);
    assert (has_cycle_from(ctx, "paleoContext") == True);
}

test "diamond revisit adversarial order" {
    ctx: dict[str, Entity] = create_context();
    assert (register_entity(ctx, "A", "t") == True);
    assert (register_entity(ctx, "B", "t") == True);
    assert (register_entity(ctx, "C", "t") == True);
    assert (register_entity(ctx, "D", "t") == True);
    assert (add_relationship(ctx, "A", "B") == True);
    assert (add_relationship(ctx, "A", "C") == True);
    assert (add_relationship(ctx, "B", "D") == True);
    assert (add_relationship(ctx, "C", "D") == True);
    assert (add_relationship(ctx, "D", "B") == True);
    reach: list[str] = get_reachable(ctx, "A");
    assert (reach == ["A", "B", "C", "D"]);
    assert (has_cycle_from(ctx, "A") == True);
}

test "unknown id tolerance" {
    ctx: dict[str, Entity] = create_context();
    assert (register_entity(ctx, "x", "t") == True);
    empty: list[str] = get_reachable(ctx, "missing");
    assert (empty == []);
    assert (has_cycle_from(ctx, "missing") == False);
    assert (add_relationship(ctx, "missing", "x") == False);
    assert (add_relationship(ctx, "x", "missing") == False);
    assert (add_relationship(ctx, "missing", "missing2") == False);
}

test "self loop and linear chain" {
    ctx: dict[str, Entity] = create_context();
    assert (register_entity(ctx, "self", "t") == True);
    assert (add_relationship(ctx, "self", "self") == True);
    reach: list[str] = get_reachable(ctx, "self");
    assert (reach == ["self"]);
    assert (has_cycle_from(ctx, "self") == True);
    assert (register_entity(ctx, "a", "t") == True);
    assert (register_entity(ctx, "b", "t") == True);
    assert (register_entity(ctx, "c", "t") == True);
    assert (add_relationship(ctx, "a", "b") == True);
    assert (add_relationship(ctx, "b", "c") == True);
    reach2: list[str] = get_reachable(ctx, "a");
    assert (reach2 == ["a", "b", "c"]);
    assert (has_cycle_from(ctx, "a") == False);
}
