"""Guard tests for iss_t3x-dev__t3x-core__1297.jac"""

obj HistoryGraph { has modules: dict[str, Module] = {}; has events: list[tuple[str, str]] = []; }
node Module { has mid: str; has stack: str; has retired: bool = False; has active: bool = True; }
edge ChildOf {}
edge DependsOn {}

walker StackSubtreeCollect {
    has claimed: dict[str, bool] = {};
    has found: list[Module] = [];
    can step with Module entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        self.found.append(here);
        visit [->:ChildOf:->][?:Module];
    }
}

walker DependentCollect {
    has claimed: dict[str, bool] = {};
    has found: list[Module] = [];
    can step with Module entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        if not here.retired { self.found.append(here); }
        visit [<-:DependsOn:<-][?:Module];
    }
}

def _wire(
    modules: list[tuple[str, str]],
    contains: list[tuple[str, str]],
    depends: list[tuple[str, str]],
    events: list[tuple[str, str]],
) -> HistoryGraph {
    mp: dict[str, Module] = {};
    for (mid, stack) in modules { m = Module(mid=mid, stack=stack); root ++> m; mp[mid] = m; }
    for (parent, child) in contains {
        p = mp.get(parent, None); c = mp.get(child, None);
        if p is not None and c is not None { p +>:ChildOf:+> c; }
    }
    for (consumer, provider) in depends {
        a = mp.get(consumer, None); b = mp.get(provider, None);
        if a is not None and b is not None { a +>:DependsOn:+> b; }
    }
    return HistoryGraph(modules=mp, events=events);
}

def load_history(
    modules: list[tuple[str, str]],
    contains: list[tuple[str, str]],
    depends: list[tuple[str, str]],
    events: list[tuple[str, str]],
) -> HistoryGraph { return _wire(modules, contains, depends, events); }

def mark_retired(g: HistoryGraph, stack_root: str) -> list[str] {
    start = g.modules.get(stack_root, None);
    if start is None { return []; }
    w = start spawn StackSubtreeCollect(claimed={}, found=[]);
    marked: list[str] = [];
    for m in w.found {
        if not m.retired { m.retired = True; marked.append(m.mid); }
    }
    return sorted(marked);
}

def purge_retired(g: HistoryGraph) -> list[str] {
    seeds: list[Module] = [];
    for m in g.modules.values() { if m.retired { seeds.append(m); } }
    seeds.sort(key=lambda x: x.mid);
    if not seeds { return []; }
    dep_claimed: dict[str, bool] = {};
    doomed: dict[str, Module] = {};
    for seed in seeds {
        dw = seed spawn DependentCollect(claimed=dep_claimed, found=[]);
        dep_claimed = dw.claimed;
        for m in dw.found { doomed[m.mid] = m; }
    }
    deactivated: list[str] = [];
    for mid in sorted(doomed.keys()) {
        m = doomed[mid];
        if m.active { m.active = False; deactivated.append(mid); }
    }
    return deactivated;
}

def active_modules(g: HistoryGraph) -> list[str] {
    out: list[str] = [];
    for m in g.modules.values() { if m.active and not m.retired { out.append(m.mid); } }
    return sorted(out);
}

test "retire chat stack then purge dependents" {
    g = load_history(
        [
            ("chat_stack", "chat"), ("chat_api", "chat"), ("chat_ui", "chat"),
            ("core_engine", "core"), ("workflow_runner", "core"), ("export_tool", "core"),
        ],
        [("chat_stack", "chat_api"), ("chat_stack", "chat_ui")],
        [("workflow_runner", "chat_api"), ("export_tool", "core_engine")],
        [("chat_api", "chat"), ("core_engine", "core"), ("workflow_runner", "chat")],
    );
    assert active_modules(g) == [
        "chat_api", "chat_stack", "chat_ui", "core_engine", "export_tool", "workflow_runner",
    ];
    assert mark_retired(g, "chat_stack") == ["chat_api", "chat_stack", "chat_ui"];
    assert active_modules(g) == ["core_engine", "export_tool", "workflow_runner"];
    assert purge_retired(g) == ["workflow_runner"];
    assert active_modules(g) == ["core_engine", "export_tool"];
    assert len(g.events) == 3;
}

test "diamond adversarial dependent purge" {
    g = load_history(
        [
            ("chat_stack", "chat"), ("chat_api", "chat"),
            ("sink_b", "core"), ("sink_c", "core"), ("sink_d", "core"),
        ],
        [("chat_stack", "chat_api")],
        [
            ("sink_d", "sink_c"), ("sink_d", "sink_b"),
            ("sink_c", "chat_api"), ("sink_b", "chat_api"),
        ],
        [("chat_api", "chat")],
    );
    mark_retired(g, "chat_stack");
    assert purge_retired(g) == ["sink_b", "sink_c", "sink_d"];
    assert active_modules(g) == [];
}

test "unknown stack root tolerant" {
    g = load_history([("only", "core")], [], [], []);
    assert mark_retired(g, "missing") == [];
    assert purge_retired(g) == [];
    assert active_modules(g) == ["only"];
}

test "idempotent retire and purge" {
    g = load_history(
        [("chat_stack", "chat"), ("chat_api", "chat"), ("runner", "core")],
        [("chat_stack", "chat_api")],
        [("runner", "chat_api")],
        [("chat_api", "chat")],
    );
    assert mark_retired(g, "chat_stack") == ["chat_api", "chat_stack"];
    assert mark_retired(g, "chat_stack") == [];
    assert purge_retired(g) == ["runner"];
    assert purge_retired(g) == [];
}
