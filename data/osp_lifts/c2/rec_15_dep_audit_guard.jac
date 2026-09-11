"""Build-system dependency auditor lifted to OSP.

Modules become nodes; dependency declarations become directed DependsOn
edges carrying the build/runtime kind payload. The list-as-stack DFS
becomes a flooding walker whose claim map is the explicit cycle policy,
and chain checks disengage as soon as the target module surfaces below
the root (never counting the root itself).
"""
node Module {
    has name: str;
}
edge DependsOn {
    has kind: str;
}

"""Loader handle: module names resolve through this lookup map."""
obj Workspace {
    has mods: dict[str, Module];

    def resolve(name: str) -> Module | None {
        return self.mods.get(name);
    }
}

"""Deterministic fresh-graph builder; creation order = fixture order."""
def build_workspace(modules: list[str], depends: list[tuple[str, str, str]]) -> Workspace {
    ws = Workspace(mods={});
    for m in modules {
        n = Module(name=m);
        root ++> n;
        ws.mods[m] = n;
    }
    for (m, d, kind) in depends {
        a = ws.mods[m];
        b = ws.mods[d];
        a +>:DependsOn(kind=kind):+> b;
    }
    return ws;
}

walker DepFlood {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has skip_root: str = "";

    can step with Module entry {
        if here.name == self.skip_root and here.name in self.claimed {
            skip;
        }
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        if here.name != self.skip_root {
            self.reached.append(here.name);
        }
        visit [->:DependsOn:->] else { disengage; }
    }
}

walker ChainProbe {
    has target: str;
    has found: bool = False;
    has claimed: dict[str, bool] = {};
    has started: bool = False;

    can step with Module entry {
        if not self.started {
            self.started = True;
            self.claimed[here.name] = True;
            visit [->:DependsOn:->] else { disengage; }
        } else {
            if here.name == self.target {
                self.found = True;
                disengage;
            }
            if here.name in self.claimed {
                skip;
            }
            self.claimed[here.name] = True;
            visit [->:DependsOn:->] else { disengage; }
        }
    }
}

"""Transitive dependencies of ``mod`` (sorted, excluding itself)."""
def closure(ws: Workspace, mod: str) -> list[str] {
    start = ws.resolve(mod);
    if start is None {
        return [];
    }
    w = start spawn DepFlood(skip_root=mod);
    return sorted(w.reached);
}

"""True when ``dst`` sits at least one dependency edge below ``src``."""
def depends_on_chain(ws: Workspace, src: str, dst: str) -> bool {
    start = ws.resolve(src);
    if start is None {
        return False;
    }
    if ws.resolve(dst) is None {
        return False;
    }
    w = start spawn ChainProbe(target=dst);
    return w.found;
}

test "closure multiset" {
    ws = build_workspace(["app", "web", "api", "core", "util"], [("app", "web", "runtime"), ("app", "api", "runtime"), ("web", "core", "runtime"), ("api", "core", "build"), ("core", "util", "runtime")]);
    assert closure(ws, "app") == ["api", "core", "util", "web"];
    assert closure(ws, "core") == ["util"];
    assert closure(ws, "util") == [];
}

test "chain probes" {
    ws = build_workspace(["app", "web", "core"], [("app", "web", "runtime"), ("web", "core", "runtime")]);
    assert depends_on_chain(ws, "app", "core");
    assert not depends_on_chain(ws, "core", "app");
    assert not depends_on_chain(ws, "core", "core");
}

test "dependency cycle terminates and root excluded once" {
    ws = build_workspace(["a", "b", "c"], [("a", "b", "runtime"), ("b", "c", "runtime"), ("c", "a", "runtime")]);
    assert closure(ws, "a") == ["b", "c"];
    assert depends_on_chain(ws, "a", "a");
}

test "unknown modules" {
    ws = build_workspace(["app"], []);
    assert closure(ws, "ghost") == [];
    assert not depends_on_chain(ws, "app", "ghost");
    assert not depends_on_chain(ws, "ghost", "app");
}

test "diamond dependency closure is complete" {
    ws = build_workspace(["a", "b", "c", "d"], [("a", "b", "runtime"), ("a", "c", "runtime"), ("b", "d", "runtime"), ("c", "d", "runtime")]);
    assert closure(ws, "a") == ["b", "c", "d"];
}
