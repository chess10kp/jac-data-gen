"""samitoyang/skill-customization#29 — candidate + hidden guards."""

# --- candidate (same as .jac) ---
obj ModuleGraph {
    has stamp: int = 0;
}

node Module { has name: str; }
edge ChildOf {}
edge Requires {}

walker FindModule {
    has target: str;
    has reports: list[Module] = [];

    can search with Root entry { visit [-->][?:Module]; }

    can pick with Module entry {
        if here.name == self.target { report here; disengage; }
        visit [-->];
    }
}

walker TransitiveBlockers {
    has origin: str;
    has claimed: dict[str, bool] = {};
    has acc: list[str] = [];

    can begin with Root entry {
        matches = [root-->][?:Module, name == self.origin];
        if not matches { disengage; }
        deps = [matches[0]->:Requires:->][?:Module];
        if deps { visit deps; } else { disengage; }
    }

    can walk with Module entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.acc.append(here.name);
        visit [->:Requires:->][?:Module] else { disengage; };
    }
}

def _find_module(target: str) -> Module | None {
    result = root spawn FindModule(target=target);
    if result.reports { return result.reports[0]; }
    return None;
}

def load_modules(specs: list[tuple[str, str | None, list[str]]]) -> ModuleGraph {
    id_map: dict[str, Module] = {};
    for (name, _parent, _reqs) in specs {
        if name not in id_map {
            mod = Module(name=name);
            root ++> mod;
            id_map[name] = mod;
        }
    }
    for (name, parent, reqs) in specs {
        mod = id_map[name];
        for req_name in reqs {
            req = id_map.get(req_name, None);
            if req is not None { mod +>:Requires:+> req; }
        }
        if parent is not None {
            par = id_map.get(parent, None);
            if par is not None { par +>:ChildOf:+> mod; }
        }
    }
    return ModuleGraph(stamp=1);
}

def child_modules(g: ModuleGraph, name: str) -> list[str] {
    _ = g;
    mod = _find_module(name);
    if mod is None { return []; }
    return sorted([c.name for c in [mod ->:ChildOf:->][?:Module]]);
}

def ancestor_modules(g: ModuleGraph, name: str) -> list[str] {
    _ = g;
    mod = _find_module(name);
    if mod is None { return []; }
    acc: list[str] = [];
    cur = mod;
    seen: dict[str, bool] = {};
    while True {
        parents = [cur <-:ChildOf:<-][?:Module];
        if not parents { break; }
        par = parents[0];
        if par.name in seen { break; }
        seen[par.name] = True;
        acc.append(par.name);
        cur = par;
    }
    return acc;
}

def blocking_deps(g: ModuleGraph, name: str) -> list[str] {
    _ = g;
    mod = _find_module(name);
    if mod is None { return []; }
    return sorted([r.name for r in [mod ->:Requires:->][?:Module]]);
}

def transitive_blockers(g: ModuleGraph, name: str) -> list[str] {
    _ = g;
    if _find_module(name) is None { return []; }
    w = root spawn TransitiveBlockers(origin=name);
    return sorted(w.acc);
}

def frontier(g: ModuleGraph, done: list[str]) -> list[str] {
    _ = g;
    done_set: dict[str, bool] = {};
    for d in done { done_set[d] = True; }
    ready: list[str] = [];
    for m in [-->][?:Module] {
        if m.name in done_set { continue; }
        reqs = [m ->:Requires:->][?:Module];
        if all(r.name in done_set for r in reqs) { ready.append(m.name); }
    }
    return sorted(ready);
}

def migration_order(g: ModuleGraph) -> list[str] | None {
    _ = g;
    pending: dict[str, bool] = {};
    for m in [-->][?:Module] { pending[m.name] = True; }
    order: list[str] = [];
    progress = True;
    while progress {
        progress = False;
        for nm in sorted(pending.keys()) {
            mod = _find_module(nm);
            if mod is None { continue; }
            ready = True;
            for r in [mod ->:Requires:->][?:Module] {
                if r.name in pending { ready = False; break; }
            }
            if ready {
                del pending[nm];
                order.append(nm);
                progress = True;
            }
        }
    }
    return order if not pending else None;
}

# --- hidden guards (pin Python semantics) ---
test "migration slice main" {
    g = load_modules([
        ("provenance", None, []),
        ("registry", None, ["provenance"]),
        ("host_adapters", "registry", ["registry"]),
        ("descriptor", None, ["registry"]),
        ("binding", None, ["descriptor"]),
        ("preflight", None, ["binding"]),
        ("reconciliation", None, ["binding", "preflight"]),
    ]);
    assert child_modules(g, "registry") == ["host_adapters"];
    assert ancestor_modules(g, "host_adapters") == ["registry"];
    assert blocking_deps(g, "reconciliation") == ["binding", "preflight"];
    assert transitive_blockers(g, "reconciliation") == [
        "binding", "descriptor", "preflight", "provenance", "registry",
    ];
    assert frontier(g, []) == ["provenance"];
    assert frontier(g, ["provenance"]) == ["registry"];
    assert migration_order(g) == [
        "binding", "descriptor", "host_adapters", "preflight",
        "provenance", "reconciliation", "registry",
    ];
}

test "unknown module tolerance" {
    g = load_modules([("solo", None, [])]);
    assert child_modules(g, "nope") == [];
    assert ancestor_modules(g, "nope") == [];
    assert blocking_deps(g, "nope") == [];
    assert transitive_blockers(g, "nope") == [];
}

test "requires cycle blocks order" {
    g = load_modules([
        ("a", None, ["b"]),
        ("b", None, ["c"]),
        ("c", None, ["a"]),
    ]);
    assert migration_order(g) is None;
}

test "diamond adversarial blocker order" {
    g = load_modules([
        ("sink", None, []),
        ("left", None, ["sink"]),
        ("right", None, ["sink"]),
        ("top", None, ["left", "right"]),
    ]);
    assert transitive_blockers(g, "top") == ["left", "right", "sink"];
    assert migration_order(g) == ["left", "right", "sink", "top"];
}
