"""Guard: elgansayer/elgl#7035."""

obj FactoryGraph { has locked: set[str] = set(); }
node Step { has sid: str; }
edge Blocks {}

def _find(sid: str) -> Step | None {
    for s in [-->][?:Step] { if s.sid == sid { return s; } }
    return None;
}

def load_factory(deps: list[tuple[str, str]], locked: list[str]) -> FactoryGraph {
    mp: dict[str, Step] = {};
    for (blocker, blocked) in deps {
        for sid in [blocker, blocked] {
            if sid not in mp { nd = Step(sid=sid); root ++> nd; mp[sid] = nd; }
        }
        b = mp.get(blocker, None); t = mp.get(blocked, None);
        if b is not None and t is not None { b +>:Blocks:+> t; }
    }
    return FactoryGraph(locked=set(locked));
}

def ready_steps(g: FactoryGraph) -> list[str] {
    indeg: dict[str, int] = {};
    for s in [-->][?:Step] { indeg[s.sid] = len([s ->:Blocks:->][?:Step]); }
    return sorted([nm for (nm, d) in indeg.items() if d == 0 and nm not in g.locked]);
}

walker CycleProbe {
    has stack: list[str] = [];
    has found: bool = False;
    can dfs with Step entry {
        if here.sid in self.stack { self.found = True; skip; }
        self.stack = self.stack + [here.sid];
        visit [->:Blocks:->] else { disengage; };
        self.stack = self.stack[:-1];
    }
}

def has_lock_cycle(g: FactoryGraph) -> bool {
    _ = g;
    for s in [-->][?:Step] {
        w = s spawn CycleProbe(stack=[], found=False);
        if w.found { return True; }
    }
    return False;
}

walker ReachLocked {
    has claimed: dict[str, bool] = {};
    has locked: set[str] = set();
    has hits: list[str] = [];
    can step with Step entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        if here.sid in self.locked { self.hits.append(here.sid); }
        visit [->:Blocks:->] else { disengage; };
    }
}

def locked_reachable(g: FactoryGraph, start: str) -> list[str] {
    anchor = _find(start);
    if anchor is None { return []; }
    w = anchor spawn ReachLocked(claimed={}, locked=g.locked, hits=[]);
    return sorted(w.hits);
}

test "ready and locked reach" {
    g = load_factory([("cut", "weld"), ("weld", "paint"), ("prep", "cut")], ["weld"]);
    assert ready_steps(g) == ["prep"];
    assert locked_reachable(g, "prep") == ["weld"];
    assert not has_lock_cycle(g);
}

test "cycle detected" {
    g = load_factory([("a", "b"), ("b", "c"), ("c", "a")], []);
    assert has_lock_cycle(g);
}

test "diamond adversarial" {
    g = load_factory(
        [("hub", "left"), ("hub", "right"), ("left", "sink"), ("right", "sink")],
        ["sink"],
    );
    assert locked_reachable(g, "hub") == ["sink"];
}
