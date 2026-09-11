"""Import-graph audits, lifted to OSP.

Modules become Module nodes carrying their layer, imports become typed
Imports edges, and the per-module stack/visited DFS probes become one
spawned reach walker per module: arriving back at the start after having
left it closes a cycle, and the claim map terminates the walk on shared
diamond paths. Probing is per node, so detection is insertion-order
insensitive; results are normalized to sorted module names, matching the
source contract. Layer violations scan typed Imports edges directly.
Ref: marioparaschiv/unbound#26
"""
node Module {
    has name: str;
    has layer: str;
}
edge Imports {}

glob LAYER_ORDER: dict[str, int] = {"api": 0, "managers": 1, "stores": 2, "builtins": 3};

"""Loader handle: module names resolve through this lookup map."""
obj Mods {
    has mods: dict[str, Module];

    def resolve(name: str) -> Module | None {
        return self.mods.get(name);
    }
}

"""Deterministic fresh-graph builder from an {imports, layers} spec."""
def load_mods(graph: dict) -> Mods {
    m = Mods(mods={});
    imports: dict[str, list[str]] = graph.get("imports", {});
    layers: dict[str, str] = graph.get("layers", {});
    names: set[str] = set(imports.keys());
    for k in imports.keys() { names = names | set(imports[k]); }
    for name in names {
        nd = Module(name=name, layer=layers.get(name, "builtins"));
        root ++> nd;
        m.mods[name] = nd;
    }
    for name in imports.keys() {
        for dep in imports[name] {
            if dep in m.mods {
                m.mods[name] +>:Imports:+> m.mods[dep];
            }
        }
    }
    return m;
}

walker ReachWalk {
    has start: str;
    has claimed: dict[str, bool] = {};
    has found: bool = False;

    can step with Module entry {
        # Arriving back at the start (after having left it) closes a cycle.
        if here.name == self.start and len(self.claimed) > 0 {
            self.found = True;
            disengage;
        }
        # Cycle policy: one visit per module regardless of path count.
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        visit [->:Imports:->];
    }
}

"""True iff any module participates in an import cycle."""
def has_cycle(graph: dict) -> bool {
    return len(nodes_in_cycles(graph)) > 0;
}

"""Sorted list of every module that can reach itself via imports."""
def nodes_in_cycles(graph: dict) -> list {
    m = load_mods(graph);
    out: list[str] = [];
    for name in m.mods.keys() {
        nd = m.mods[name];
        w = nd spawn ReachWalk(start=name, claimed={}, found=False);
        if w.found {
            out.append(name);
        }
    }
    return sorted(out);
}

"""Sorted "src->dst" strings for imports that point up the layer order."""
def layer_violations(graph: dict) -> list {
    m = load_mods(graph);
    out: list[str] = [];
    for name in m.mods.keys() {
        src: Module = m.mods[name];
        dsts: list[Module] = [src ->:Imports:->];
        for dst in dsts {
            if LAYER_ORDER[dst.layer] < LAYER_ORDER[src.layer] {
                out.append(name + "->" + dst.name);
            }
        }
    }
    return sorted(out);
}


test "clean layered graph has no cycles or violations" {
    clean = {
        "imports": {
            "client": ["user_manager"],
            "user_manager": ["user_store"],
            "user_store": ["deep_clone"],
        },
        "layers": {
            "client": "api",
            "user_manager": "managers",
            "user_store": "stores",
            "deep_clone": "builtins",
        },
    };
    assert has_cycle(clean) == False;
    assert nodes_in_cycles(clean) == [];
    assert layer_violations(clean) == [];
}

test "cross-layer cycle reported with its upward edge" {
    cross = {
        "imports": {"user_manager": ["session_store"], "session_store": ["user_manager"]},
        "layers": {"user_manager": "managers", "session_store": "stores"},
    };
    assert has_cycle(cross) == True;
    assert nodes_in_cycles(cross) == ["session_store", "user_manager"];
    assert layer_violations(cross) == ["session_store->user_manager"];
}

test "self-loop module imports itself" {
    self_loop = {"imports": {"util": ["util"]}, "layers": {"util": "builtins"}};
    assert has_cycle(self_loop) == True;
    assert nodes_in_cycles(self_loop) == ["util"];
    assert layer_violations(self_loop) == [];
}

test "acyclic diamond with shared target is not a cycle" {
    diamond = {
        "imports": {"app": ["left", "right"], "left": ["shared"], "right": ["shared"]},
        "layers": {"app": "api", "left": "managers", "right": "managers", "shared": "stores"},
    };
    assert has_cycle(diamond) == False;
    assert nodes_in_cycles(diamond) == [];
    assert layer_violations(diamond) == [];
}

test "two disjoint cycles plus isolated module" {
    multi = {
        "imports": {"a1": ["a2"], "a2": ["a1"], "b1": ["b2"], "b2": ["b1"], "c": []},
        "layers": {"a1": "builtins", "a2": "builtins", "b1": "managers", "b2": "stores", "c": "api"},
    };
    assert has_cycle(multi) == True;
    assert nodes_in_cycles(multi) == ["a1", "a2", "b1", "b2"];
}

test "missing layers key defaults everything to builtins" {
    nolayers = {"imports": {"a": ["b"], "b": ["a"]}};
    assert has_cycle(nolayers) == True;
    assert nodes_in_cycles(nolayers) == ["a", "b"];
    assert layer_violations(nolayers) == [];
}

test "upward import without a cycle is a violation only" {
    up = {"imports": {"store_x": ["api_y"]}, "layers": {"store_x": "stores", "api_y": "api"}};
    assert has_cycle(up) == False;
    assert nodes_in_cycles(up) == [];
    assert layer_violations(up) == ["store_x->api_y"];
}

test "dep-only module is probed and found acyclic" {
    depsonly = {"imports": {"a": ["z"]}, "layers": {"a": "api", "z": "managers"}};
    assert has_cycle(depsonly) == False;
    assert nodes_in_cycles(depsonly) == [];
    assert layer_violations(depsonly) == [];
}
