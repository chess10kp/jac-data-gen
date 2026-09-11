"""Chris-Wolfgang/repo-template#411 — transitive NuGet dependency walk."""

node Package {
    has name: str;
}

edge Requires {}

obj DepGraph {
    has pkgs: dict[str, Package] = {};
}

walker TransitiveWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Package entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [->:Requires:->][?:Package];
    }
}

def load_packages(pkgs: list[str], edges: list[tuple[str, str]]) -> DepGraph {
    g = DepGraph();
    for p in pkgs {
        nd = Package(name=p);
        root ++> nd;
        g.pkgs[p] = nd;
    }
    for (a, b) in edges {
        pa = g.pkgs.get(a, None);
        pb = g.pkgs.get(b, None);
        if pa is not None and pb is not None { pa +>:Requires:+> pb; }
    }
    return g;
}

def transitive_deps(store: DepGraph, pkg: str) -> list[str] {
    nd = store.pkgs.get(pkg, None);
    if nd is None { return []; }
    w = nd spawn TransitiveWalk(claimed={}, reached=[]);
    out: list[str] = [];
    for n in w.reached {
        if n != pkg { out.append(n); }
    }
    return sorted(out);
}
