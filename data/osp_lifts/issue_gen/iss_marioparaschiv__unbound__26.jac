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
