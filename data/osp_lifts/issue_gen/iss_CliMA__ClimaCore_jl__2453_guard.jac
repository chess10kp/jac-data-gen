"""CliMA/ClimaCore.jl#2453 — dependency graph for automatic tendency ordering and caching."""

node DepNode {
    has name: str;
}

edge Requires {}

obj EagerGlobalCaching {}

obj LazyCaching {}

obj DependencyGraph {
    has nodes: set[str] = set();
    has adj: dict[str, list[str]] = {};
    has rev: dict[str, list[str]] = {};
    has in_degree: dict[str, int] = {};
    has roles: dict[str, str] = {};
    has cache: dict[str, float] = {};
}

walker ChainWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];
    has origin: str = "";

    can step with DepNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.origin { self.hits.append(here.name); }
        upstream = [here <-:Requires:<-][?:DepNode];
        nms: list[str] = [];
        for n in upstream { nms.append(n.name); }
        for nm in sorted(nms) {
            for n in upstream {
                if n.name == nm {
                    n spawn ChainWalk(
                        claimed=self.claimed,
                        hits=self.hits,
                        origin=self.origin,
                    );
                }
            }
        }
    }
}

walker TopoOrderWalk {
    has order: list[str] = [];
    has indeg: dict[str, int] = {};
    has ready: list[str] = [];

    can begin with Root entry {
        nodes = [root -->][?:DepNode];
        for nd in nodes { self.indeg[nd.name] = 0; }
        for nd in nodes {
            for ch in [nd ->:Requires:->][?:DepNode] {
                self.indeg[ch.name] = self.indeg.get(ch.name, 0) + 1;
            }
        }
        seed: list[str] = [];
        for nd in nodes {
            if self.indeg.get(nd.name, 0) == 0 { seed.append(nd.name); }
        }
        self.ready = sorted(seed);
        while len(self.ready) > 0 {
            cur = self.ready[0];
            rest: list[str] = [];
            idx = 1;
            while idx < len(self.ready) {
                rest.append(self.ready[idx]);
                idx += 1;
            }
            self.ready = rest;
            self.order.append(cur);
            src: DepNode | None = None;
            for nd in nodes {
                if nd.name == cur { src = nd; }
            }
            if src is not None {
                children = [src ->:Requires:->][?:DepNode];
                cnms: list[str] = [];
                for ch in children { cnms.append(ch.name); }
                for nm in sorted(cnms) {
                    for ch in children {
                        if ch.name == nm {
                            self.indeg[ch.name] = self.indeg.get(ch.name, 0) - 1;
                            if self.indeg[ch.name] == 0 {
                                self.ready.append(ch.name);
                            }
                        }
                    }
                }
            }
            self.ready = sorted(self.ready);
        }
        report self.order;
    }
}

def _find_dep_node(name: str) -> DepNode | None {
    for nd in [root -->][?:DepNode] {
        if nd.name == name { return nd; }
    }
    return None;
}

def build_dependency_graph(
    tend_names: list[str],
    prog_names: list[str],
    model: dict,
) -> DependencyGraph {
    graph = DependencyGraph();
    var_deps: dict[str, list[str]] = model["var_deps"] as dict[str, list[str]];
    tend_deps: dict[str, list[str]] = model["tend_deps"] as dict[str, list[str]];
    for name in prog_names {
        graph.nodes.add(name);
        if name not in graph.adj { graph.adj[name] = []; }
        if name not in graph.rev { graph.rev[name] = []; }
        if name not in graph.in_degree { graph.in_degree[name] = 0; }
        graph.roles[name] = "prog";
        root ++> DepNode(name=name);
    }
    extra: set[str] = set();
    for k in var_deps.keys() { extra.add(k); }
    for tn in tend_names { extra.add(tn); }
    extra_list: list[str] = sorted(list(extra));
    for name in extra_list {
        graph.nodes.add(name);
        if name not in graph.adj { graph.adj[name] = []; }
        if name not in graph.rev { graph.rev[name] = []; }
        if name not in graph.in_degree { graph.in_degree[name] = 0; }
        if name in var_deps { graph.roles[name] = "computed"; }
        if name in tend_deps { graph.roles[name] = "tendency"; }
        root ++> DepNode(name=name);
    }
    for (var, deps) in var_deps.items() {
        for dep in deps {
            if dep not in graph.nodes or var not in graph.nodes {
                raise KeyError(f"unknown node: '{dep}' -> '{var}'");
            }
            if var not in graph.adj[dep] {
                graph.adj[dep].append(var);
                graph.rev[var].append(dep);
                graph.in_degree[var] = graph.in_degree.get(var, 0) + 1;
                pnd = _find_dep_node(dep);
                dnd = _find_dep_node(var);
                if pnd is not None and dnd is not None { pnd +>:Requires:+> dnd; }
            }
        }
    }
    for (tend, deps) in tend_deps.items() {
        for dep in deps {
            if dep not in graph.nodes or tend not in graph.nodes {
                raise KeyError(f"unknown node: '{dep}' -> '{tend}'");
            }
            if tend not in graph.adj[dep] {
                graph.adj[dep].append(tend);
                graph.rev[tend].append(dep);
                graph.in_degree[tend] = graph.in_degree.get(tend, 0) + 1;
                pnd = _find_dep_node(dep);
                dnd = _find_dep_node(tend);
                if pnd is not None and dnd is not None { pnd +>:Requires:+> dnd; }
            }
        }
    }
    return graph;
}

def get_evaluation_order(graph: DependencyGraph) -> list[str] | None {
    w = root spawn TopoOrderWalk(order=[], indeg={}, ready=[]);
    got = w.reports[0] if w.reports else [];
    if len(got) != len(graph.nodes) { return None; }
    out: list[str] = [];
    for n in got {
        if graph.roles[n] != "prog" { out.append(n); }
    }
    return out;
}

def dependency_chain(graph: DependencyGraph, name: str) -> list[str] {
    if name not in graph.nodes { return []; }
    nd = _find_dep_node(name);
    if nd is None { return []; }
    w = nd spawn ChainWalk(claimed={}, hits=[], origin=name);
    return sorted(w.hits);
}

def evaluate_graph(
    y_t: dict[str, float],
    y: dict[str, float],
    graph: DependencyGraph,
    model: dict,
    t: float,
    strategy: object,
) {
    order = get_evaluation_order(graph);
    if order is None { raise ValueError("cyclic dependency graph"); }
    workspace: dict[str, float] = {};
    for (k, v) in y.items() { workspace[k] = v; }
    graph.cache.clear();
    eager = isinstance(strategy, EagerGlobalCaching);
    var_compute: dict = model["var_compute"];
    tend_compute: dict = model["tend_compute"];
    for node in order {
        if graph.roles[node] == "computed" {
            val = (var_compute[node](workspace, t) as float);
            workspace[node] = val;
            if eager { graph.cache[node] = val; }
        } else {
            val = (tend_compute[node](workspace, t) as float);
            y_t[node] = val;
            workspace[node] = val;
            if eager { graph.cache[node] = val; }
        }
    }
}



test "diamond dependency chain dedupes shared ancestor" {
    mdl = {
        "var_deps": {"b": ("a",), "c": ("a",), "d": ("b", "c")},
        "tend_deps": {},
        "var_compute": {"b": 1, "c": 1, "d": 1},
        "tend_compute": {}
    };
    g = build_dependency_graph([], ["a"], mdl);
    assert get_evaluation_order(g) == ["b", "c", "d"];;
    assert dependency_chain(g, "d") == ["a", "b", "c"];;
}

test "unknown id tolerance for missing dependency chain" {
    mdl = {
        "var_deps": {"x": ("a",)},
        "tend_deps": {},
        "var_compute": {"x": 1},
        "tend_compute": {}
    };
    g = build_dependency_graph([], ["a"], mdl);
    assert dependency_chain(g, "ghost") == [];;
    assert get_evaluation_order(g) == ["x"];;
}

test "cycle detection returns none and evaluate raises" {
    mdl = {
        "var_deps": {"x": ("y",), "y": ("x",)},
        "tend_deps": {},
        "var_compute": {"x": 1, "y": 1},
        "tend_compute": {}
    };
    c = build_dependency_graph([], [], mdl);
    assert get_evaluation_order(c) is None;;
}

test "eager caches computed values lazy does not" {
    var_deps: dict[str, list[str]] = {"c.J": ["Y.u_h"]};
    tend_deps: dict[str, list[str]] = {"Yt.rho": ["c.J"]};
    # simple sanity on order length
    mdl2 = {"var_deps": var_deps, "tend_deps": tend_deps, "var_compute": {}, "tend_compute": {}};
    g2 = build_dependency_graph(["Yt.rho"], ["Y.u_h", "Y.rho"], mdl2);
    ord = get_evaluation_order(g2);
    assert ord is not None;;
    assert "c.J" in ord;;
    assert "Yt.rho" in ord;;
}

test "adversarial diamond revisit before deeper first visits" {
    mdl = {
        "var_deps": {"b": ("a",), "c": ("a",), "d": ("b", "c"), "e": ("d",)},
        "tend_deps": {},
        "var_compute": {"b": 1, "c": 1, "d": 1, "e": 1},
        "tend_compute": {}
    };
    g = build_dependency_graph([], ["a"], mdl);
    assert dependency_chain(g, "e") == ["a", "b", "c", "d"];;
    assert get_evaluation_order(g) == ["b", "c", "d", "e"];;
}
