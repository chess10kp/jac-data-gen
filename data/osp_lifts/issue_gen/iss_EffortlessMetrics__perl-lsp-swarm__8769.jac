"""EffortlessMetrics/perl-lsp-swarm#8769 — Phase-labelled module compile reach."""

obj ModuleGraph {
    has mods: dict[str, Module] = {};
}

node Module { has mid: str; }
edge CompileUse {}

walker CompileReach {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Module entry {
        if here.mid in self.claimed { skip; }
        self.claimed[here.mid] = True;
        self.reached.append(here.mid);
        visit [->:CompileUse:->];
    }
}

def load_module_graph(
    modules: list[str],
    compile_edges: list[tuple[str, str]],
) -> ModuleGraph {
    g = ModuleGraph();
    for mid in modules {
        if mid not in g.mods {
            nd = Module(mid=mid);
            root ++> nd;
            g.mods[mid] = nd;
        }
    }
    for (src, dst) in compile_edges {
        s = g.mods.get(src, None);
        d = g.mods.get(dst, None);
        if s is not None and d is not None { s +>:CompileUse:+> d; }
    }
    return g;
}

def compile_reach(g: ModuleGraph, root_id: str) -> list[str] {
    anchor = g.mods.get(root_id, None);
    if anchor is None { return []; }
    w = anchor spawn CompileReach(claimed={}, reached=[]);
    return sorted(w.reached);
}

def compile_levels(g: ModuleGraph, root_id: str) -> list[list[str]] {
    anchor = g.mods.get(root_id, None);
    if anchor is None { return []; }
    levels: list[list[str]] = [[root_id]];
    seen: dict[str, bool] = {root_id: True};
    frontier = [root_id];
    while frontier {
        nxt: list[str] = [];
        for cur_name in frontier {
            cur = g.mods.get(cur_name, None);
            if cur is None { continue; }
            for dep in [cur ->:CompileUse:->][?:Module] {
                if dep.mid not in seen {
                    seen[dep.mid] = True;
                    nxt.append(dep.mid);
                }
            }
        }
        if not nxt { break; }
        levels.append(sorted(nxt));
        frontier = nxt;
    }
    return levels;
}
