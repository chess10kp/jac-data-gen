"""t3x-dev/t3x-core#1297 — Preserve mixed history and remove retired Chat stack (OSP)."""

obj HistoryGraph {
    has modules: dict[str, Module] = {};
    has events: list[tuple[str, str]] = [];
}

node Module {
    has mid: str;
    has stack: str;
    has retired: bool = False;
    has active: bool = True;
}

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
        if not here.retired {
            self.found.append(here);
        }
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
    for (mid, stack) in modules {
        m = Module(mid=mid, stack=stack);
        root ++> m;
        mp[mid] = m;
    }
    for (parent, child) in contains {
        p = mp.get(parent, None);
        c = mp.get(child, None);
        if p is not None and c is not None { p +>:ChildOf:+> c; }
    }
    for (consumer, provider) in depends {
        a = mp.get(consumer, None);
        b = mp.get(provider, None);
        if a is not None and b is not None { a +>:DependsOn:+> b; }
    }
    return HistoryGraph(modules=mp, events=events);
}

def load_history(
    modules: list[tuple[str, str]],
    contains: list[tuple[str, str]],
    depends: list[tuple[str, str]],
    events: list[tuple[str, str]],
) -> HistoryGraph {
    return _wire(modules, contains, depends, events);
}

def mark_retired(g: HistoryGraph, stack_root: str) -> list[str] {
    start = g.modules.get(stack_root, None);
    if start is None { return []; }
    w = start spawn StackSubtreeCollect(claimed={}, found=[]);
    marked: list[str] = [];
    for m in w.found {
        if not m.retired {
            m.retired = True;
            marked.append(m.mid);
        }
    }
    return sorted(marked);
}

def purge_retired(g: HistoryGraph) -> list[str] {
    seeds: list[Module] = [];
    for m in g.modules.values() {
        if m.retired { seeds.append(m); }
    }
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
        if m.active {
            m.active = False;
            deactivated.append(mid);
        }
    }
    return deactivated;
}

def active_modules(g: HistoryGraph) -> list[str] {
    out: list[str] = [];
    for m in g.modules.values() {
        if m.active and not m.retired { out.append(m.mid); }
    }
    return sorted(out);
}
