"""C360Studio/semstreams#230 — dependency coordinate reachability for resolver workflow."""

obj DepStore {
    has packages: dict[str, PkgNode] = {};
}

node PkgNode {
    has name: str;
    has coord: str | None = None;
}

edge Requires {}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with PkgNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [->:Requires:->] else { disengage; };
    }
}

def load_packages(
    packages: list[tuple[str, str | None]],
    edges: list[tuple[str, str]],
) -> DepStore {
    st = DepStore(packages={});
    for (name, coord) in packages {
        n = PkgNode(name=name, coord=coord);
        root ++> n;
        st.packages[name] = n;
    }
    for (src, dst) in edges {
        a = st.packages.get(src, None);
        b = st.packages.get(dst, None);
        if a is not None and b is not None { a +>:Requires:+> b; }
    }
    return st;
}

def reachable_packages(st: DepStore, roots: list[str]) -> list[str] {
    reached: list[str] = [];
    claimed: dict[str, bool] = {};
    for r in roots {
        anchor = st.packages.get(r, None);
        if anchor is None { continue; }
        w = anchor spawn ReachWalk(claimed=claimed, reached=reached);
        reached = w.reached;
        claimed = w.claimed;
    }
    return sorted(reached);
}

def unverified_coordinates(st: DepStore, roots: list[str]) -> list[str] {
    reach: dict[str, bool] = {};
    for p in reachable_packages(st, roots) { reach[p] = True; }
    out: list[str] = [];
    for k in reach.keys() {
        pkg = st.packages.get(k, None);
        if pkg is not None and pkg.coord is None { out.append(k); }
    }
    return sorted(out);
}
