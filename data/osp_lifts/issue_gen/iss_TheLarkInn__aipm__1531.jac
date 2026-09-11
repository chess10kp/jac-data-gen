"""TheLarkInn/aipm#1531 — transitive crate dependency reachability from workspace roots."""

obj CrateGraph { has crates: dict[str, CrateNode] = {}; }
node CrateNode { has name: str; }
edge Depends {}

walker DepHop {
    has claimed: dict[str, bool];
    has next: list[CrateNode] = [];

    can step with CrateNode entry {
        for nxt in [here ->:Depends:->][?:CrateNode] {
            if nxt.name in self.claimed { continue; }
            self.claimed[nxt.name] = True;
            self.next.append(nxt);
        }
    }
}

def load_crates(
    crates: list[str],
    edges: list[tuple[str, str]],
) -> CrateGraph {
    g = CrateGraph(crates={});
    for c in crates {
        n = CrateNode(name=c);
        root ++> n;
        g.crates[c] = n;
    }
    for (src, dst) in edges {
        a = g.crates.get(src, None);
        b = g.crates.get(dst, None);
        if a is not None and b is not None { a +>:Depends:+> b; }
    }
    return g;
}

def transitive_deps(g: CrateGraph, `root: str) -> list[str] {
    anchor = g.crates.get(`root, None);
    if anchor is None { return []; }
    claimed: dict[str, bool] = {`root: True};
    reached: list[str] = [`root];
    frontier: list[CrateNode] = [anchor];
    while len(frontier) > 0 {
        nxt: list[CrateNode] = [];
        for f in frontier {
            w = f spawn DepHop(claimed=claimed, next=nxt);
            nxt = w.next;
        }
        for n in nxt { reached.append(n.name); }
        frontier = nxt;
    }
    return sorted(reached);
}

def on_critical_path(g: CrateGraph, roots: list[str], target: str) -> bool {
    if g.crates.get(target, None) is None { return False; }
    for r in roots {
        reach: dict[str, bool] = {};
        for d in transitive_deps(g, r) { reach[d] = True; }
        if target in reach { return True; }
    }
    return False;
}
