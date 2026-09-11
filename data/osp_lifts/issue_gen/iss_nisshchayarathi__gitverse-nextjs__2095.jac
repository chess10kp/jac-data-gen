"""nisshchayarathi/gitverse-nextjs#2095 — Circular import parsing with visited cache."""

node SourceModule { has path: str; }
edge Imports {}

obj ModuleGraph { has modules: dict[str, SourceModule] = {}; }

walker ImportWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with SourceModule entry {
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        self.found.append(here.path);
        visit [->:Imports:->][?:SourceModule];
    }
}

walker CycleDetect {
    has visited: dict[str, bool] = {};
    has stack: dict[str, bool] = {};
    has cyclic: bool = False;

    can step with SourceModule entry {
        if self.cyclic { skip; }
        if here.path in self.visited { skip; }
        self.visited[here.path] = True;
        self.stack[here.path] = True;
        for nxt in [here ->:Imports:->][?:SourceModule] {
            if nxt.path in self.stack {
                self.cyclic = True;
            } elif not (nxt.path in self.visited) {
                visit [nxt];
            }
        }
        self.stack[here.path] = False;
    }
}

def load_modules(
    modules: list[str],
    import_edges: list[tuple[str, str]],
) -> ModuleGraph {
    g = ModuleGraph();
    for mod in modules {
        nd = SourceModule(path=mod);
        root ++> nd;
        g.modules[mod] = nd;
    }
    for (src, dst) in import_edges {
        a = g.modules.get(src, None);
        b = g.modules.get(dst, None);
        if a is not None and b is not None { a +>:Imports:+> b; }
    }
    return g;
}

def import_closure(g: ModuleGraph, module_id: str) -> list[str] {
    nd = g.modules.get(module_id, None);
    if nd is None { return []; }
    w = nd spawn ImportWalk(claimed={}, found=[]);
    out: dict[str, bool] = {};
    for p in w.found { out[p] = True; }
    keys: list[str] = [];
    for k in out.keys() { keys.append(k); }
    return sorted(keys);
}

def has_cycle(g: ModuleGraph) -> bool {
    visited: dict[str, bool] = {};
    for k in sorted(g.modules.keys()) {
        if k in visited { continue; }
        nd = g.modules[k];
        w = nd spawn CycleDetect(visited=visited, stack={}, cyclic=False);
        if w.cyclic { return True; }
        visited = w.visited;
    }
    return False;
}
