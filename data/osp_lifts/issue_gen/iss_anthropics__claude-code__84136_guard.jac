"""anthropics/claude-code#84136 — MCP initialize deadline vs uvx cold-start dependency graph."""

node Package {
    has name: str;
    has install_secs: float = 0.0;
}

edge Depends: Package --> Package {}

walker ClosureWalk {
    has claimed: dict[str, bool] = {};
    has nodes: dict[str, bool] = {};

    can step with Package entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.nodes[here.name] = True;
        visit [->:Depends:->][?:Package];
    }
}

walker TransitiveDepsWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with Package entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.origin {
            self.found.append(here.name);
        }
        visit [->:Depends:->][?:Package];
    }
}

walker DepPathWalk {
    has target: str = "";
    has max_depth: int = 12;
    has trail: list[str] = [];
    has paths: list[list[str]] = [];

    can step with Package entry {
        if here.name in self.trail { skip; }
        nt: list[str] = [];
        for x in self.trail { nt.append(x); }
        nt.append(here.name);
        if here.name == self.target {
            row: list[str] = [];
            for x in nt { row.append(x); }
            self.paths.append(row);
            skip;
        }
        if len(nt) >= self.max_depth { skip; }
        kids = [here ->:Depends:->][?:Package];
        nms: list[str] = [];
        for n in kids { nms.append(n.name); }
        for nm in sorted(nms) {
            for n in kids {
                if n.name == nm {
                    n spawn DepPathWalk(
                        target=self.target,
                        max_depth=self.max_depth,
                        trail=nt,
                        paths=self.paths,
                    );
                }
            }
        }
    }
}

obj PkgGraph {
    has install_secs: dict[str, float] = {};
    has deps: dict[str, list[str]] = {};
    has parents: dict[str, list[str]] = {};
    has packages: dict[str, Package] = {};
}

def load_pkg_graph(
    packages: list[tuple[str, float]],
    edges: list[tuple[str, str]],
) -> PkgGraph {
    g = PkgGraph();
    for (name, secs) in packages {
        g.install_secs[name] = secs;
        g.deps.setdefault(name, []);
        g.parents.setdefault(name, []);
        nd = Package(name=name, install_secs=secs);
        root ++> nd;
        g.packages[name] = nd;
    }
    for (consumer, dep) in edges {
        if consumer in g.install_secs and dep in g.install_secs {
            g.deps[consumer].append(dep);
            g.parents[dep].append(consumer);
            c = g.packages.get(consumer, None);
            d = g.packages.get(dep, None);
            if c is not None and d is not None { c +>:Depends:+> d; }
        }
    }
    return g;
}

def transitive_deps(g: PkgGraph, `root: str) -> list[str] {
    if `root not in g.install_secs { return []; }
    nd = g.packages.get(`root, None);
    if nd is None { return []; }
    w = nd spawn TransitiveDepsWalk(claimed={}, found=[], origin=`root);
    return sorted(w.found);
}

def install_order(g: PkgGraph, `root: str) -> list[str] {
    if `root not in g.install_secs { return []; }
    nd = g.packages.get(`root, None);
    if nd is None { return []; }
    w = nd spawn ClosureWalk(claimed={}, nodes={});
    nodes: dict[str, bool] = {};
    for k in w.nodes.keys() { nodes[k] = True; }
    indeg: dict[str, int] = {};
    for n in nodes { indeg[n] = 0; }
    for n in nodes {
        for dep in g.deps.get(n, []) {
            if dep in nodes { indeg[n] += 1; }
        }
    }
    q: list[str] = [];
    for n in nodes {
        if indeg[n] == 0 { q.append(n); }
    }
    q = sorted(q);
    order: list[str] = [];
    while len(q) > 0 {
        cur = q[0];
        q = q[1:];
        order.append(cur);
        for child in sorted(g.parents.get(cur, [])) {
            if child not in nodes { continue; }
            indeg[child] -= 1;
            if indeg[child] == 0 { q.append(child); }
        }
    }
    if len(order) != len(nodes) { return []; }
    return order;
}

def cold_start_seconds(
    g: PkgGraph,
    `root: str,
    cached: set[str] | None = None,
) -> float {
    warm = cached if cached is not None else set();
    total = 0.0;
    for pkg in install_order(g, `root) {
        if pkg not in warm {
            total += g.install_secs[pkg];
        }
    }
    return total;
}

def initialize_status(
    g: PkgGraph,
    `root: str,
    deadline: float = 60.0,
    cached: set[str] | None = None,
) -> str {
    if `root not in g.install_secs { return "cancelled"; }
    warm = cached if cached is not None else set();
    elapsed = 0.0;
    for pkg in install_order(g, `root) {
        if pkg in warm { continue; }
        elapsed += g.install_secs[pkg];
        if elapsed > deadline { return "cancelled"; }
    }
    return "ready";
}

def dependency_paths(
    g: PkgGraph,
    source: str,
    target: str,
    *,
    max_depth: int = 12,
) -> list[list[str]] {
    if source not in g.install_secs or target not in g.install_secs { return []; }
    nd = g.packages.get(source, None);
    if nd is None { return []; }
    w = nd spawn DepPathWalk(
        target=target,
        max_depth=max_depth,
        trail=[],
        paths=[],
    );
    out: list[list[str]] = [];
    for p in w.paths {
        row: list[str] = [];
        for x in p { row.append(x); }
        out.append(row);
    }
    return sorted(out);
}

test "diamond transitive deps" {
    g = load_pkg_graph(
        [("mcp", 1.0), ("uv", 5.0), ("node", 3.0), ("join", 2.0)],
        [("mcp", "uv"), ("mcp", "node"), ("uv", "join"), ("node", "join")],
    );
    assert transitive_deps(g, "mcp") == ["join", "node", "uv"];
    assert install_order(g, "mcp") == ["join", "node", "uv", "mcp"];
}

test "cycle install order empty" {
    g = load_pkg_graph(
        [("a", 1.0), ("b", 1.0), ("c", 1.0)],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert install_order(g, "a") == [];
    assert transitive_deps(g, "a") == ["b", "c"];
}

test "cold start and initialize deadline" {
    g = load_pkg_graph(
        [("srv", 10.0), ("dep", 55.0)],
        [("srv", "dep")],
    );
    assert cold_start_seconds(g, "srv") == 65.0;
    assert cold_start_seconds(g, "srv", cached={"dep"}) == 10.0;
    assert initialize_status(g, "srv", deadline=60.0) == "cancelled";
    assert initialize_status(g, "srv", deadline=65.0) == "ready";
    assert initialize_status(g, "srv", deadline=60.0, cached={"dep"}) == "ready";
    assert initialize_status(g, "missing") == "cancelled";
}

test "dependency paths" {
    g = load_pkg_graph(
        [("a", 0.0), ("b", 0.0), ("c", 0.0), ("d", 0.0)],
        [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")],
    );
    assert dependency_paths(g, "a", "d") == [["a", "b", "d"], ["a", "c", "d"]];
    assert dependency_paths(g, "a", "a") == [["a"]];
    assert dependency_paths(g, "a", "d", max_depth=2) == [];
    assert dependency_paths(g, "ghost", "a") == [];
}

test "diamond revisit closure and topo" {
    g = load_pkg_graph(
        [("root", 1.0), ("left", 1.0), ("right", 1.0), ("shared", 1.0), ("leaf", 1.0)],
        [("root", "left"), ("root", "right"), ("left", "shared"), ("right", "shared"), ("shared", "leaf")],
    );
    assert transitive_deps(g, "root") == ["leaf", "left", "right", "shared"];
    assert install_order(g, "root") == ["leaf", "shared", "left", "right", "root"];
}

test "unknown edge ids ignored" {
    g = load_pkg_graph(
        [("a", 1.0), ("b", 2.0)],
        [("a", "b"), ("a", "ghost"), ("phantom", "b"), ("phantom", "a")],
    );
    assert transitive_deps(g, "a") == ["b"];
    assert install_order(g, "a") == ["b", "a"];
    assert dependency_paths(g, "a", "ghost") == [];
    assert dependency_paths(g, "phantom", "b") == [];
}

test "unknown root ids tolerated" {
    g = load_pkg_graph([("x", 4.0)], []);
    assert install_order(g, "missing") == [];
    assert transitive_deps(g, "missing") == [];
    assert cold_start_seconds(g, "missing") == 0.0;
    assert dependency_paths(g, "missing", "x") == [];
    assert dependency_paths(g, "x", "missing") == [];
    assert initialize_status(g, "missing") == "cancelled";
}

test "deadline exact boundary" {
    g = load_pkg_graph(
        [("a", 30.0), ("b", 30.0)],
        [("a", "b")],
    );
    assert initialize_status(g, "a", deadline=60.0) == "ready";
    assert initialize_status(g, "a", deadline=59.0) == "cancelled";
}

test "cycle path search and max depth boundary" {
    g = load_pkg_graph(
        [("a", 0.0), ("b", 0.0), ("c", 0.0), ("s", 0.0), ("t", 0.0), ("u", 0.0)],
        [("a", "b"), ("b", "c"), ("c", "a"), ("s", "t"), ("t", "u")],
    );
    assert dependency_paths(g, "a", "c") == [["a", "b", "c"]];
    assert dependency_paths(g, "s", "u", max_depth=2) == [];
    assert dependency_paths(g, "s", "u", max_depth=3) == [["s", "t", "u"]];
}
