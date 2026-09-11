"""genfeedai/genfeed.ai#1635 — module import reachability for dependency reconciliation."""

obj ModuleGraph { has modules: dict[str, ModNode] = {}; }
node ModNode { has name: str; }
edge Imports {}

walker ImportHop {
    has claimed: dict[str, bool];
    has next: list[ModNode] = [];

    can step with ModNode entry {
        for nxt in [here ->:Imports:->][?:ModNode] {
            if nxt.name in self.claimed { continue; }
            self.claimed[nxt.name] = True;
            self.next.append(nxt);
        }
    }
}

def load_modules(
    modules: list[str],
    edges: list[tuple[str, str]],
) -> ModuleGraph {
    g = ModuleGraph(modules={});
    for m in modules {
        n = ModNode(name=m);
        root ++> n;
        g.modules[m] = n;
    }
    for (src, dst) in edges {
        a = g.modules.get(src, None);
        b = g.modules.get(dst, None);
        if a is not None and b is not None { a +>:Imports:+> b; }
    }
    return g;
}

def reachable_from_entries(g: ModuleGraph, entries: list[str]) -> list[str] {
    claimed: dict[str, bool] = {};
    reached: list[str] = [];
    frontier: list[ModNode] = [];
    for e in entries {
        anchor = g.modules.get(e, None);
        if anchor is None { continue; }
        if e not in claimed {
            claimed[e] = True;
            reached.append(e);
            frontier.append(anchor);
        }
    }
    while len(frontier) > 0 {
        nxt: list[ModNode] = [];
        for f in frontier {
            w = f spawn ImportHop(claimed=claimed, next=nxt);
            nxt = w.next;
        }
        for n in nxt { reached.append(n.name); }
        frontier = nxt;
    }
    return sorted(reached);
}

def orphan_modules(g: ModuleGraph, entries: list[str]) -> list[str] {
    reach: dict[str, bool] = {};
    for m in reachable_from_entries(g, entries) { reach[m] = True; }
    out: list[str] = [];
    for k in g.modules.keys() {
        if k not in reach { out.append(k); }
    }
    return sorted(out);
}
