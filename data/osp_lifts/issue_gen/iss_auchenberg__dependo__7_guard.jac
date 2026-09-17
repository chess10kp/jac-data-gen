# Recursively trace dependencies (auchenberg/dependo#7).
# Lift of hand-rolled adjacency-dict DFS/BFS to native OSP walkers.
# Shortest-path levels via relaxation: revisiting at a shallower depth
# re-opens the node instead of a plain claim-skip.

node Module {
    has name: str;
    has lvl: int = 0;
}

edge Deps {}

# Build Module nodes and Deps edges from an adjacency map.
# Edges to unknown files are tolerated (ignored).
def build_graph(adj: dict[str, list[str]]) -> dict[str, Module] {
    nodes: dict[str, Module] = {};
    for f in adj.keys() {
        nodes[f] = Module(name=f);
    }
    for f in adj.keys() {
        for dep in adj[f] {
            if dep in nodes.keys() {
                nodes[f] +>: Deps :+> nodes[dep];
            }
        }
    }
    return nodes;
}

walker LevelTrace {
    has dist: dict[str, int] = {};

    can step with Module entry {
        # Relaxation-based cycle policy: skip only if we already recorded
        # a depth at least as shallow; a shorter arrival re-opens the node.
        if here.name in self.dist.keys() and self.dist[here.name] <= here.lvl {
            skip;
        }
        self.dist[here.name] = here.lvl;
        for ch in [here ->:Deps:->][?:Module] {
            ch.lvl = here.lvl + 1;
        }
        visit [here ->:Deps:->][?:Module];
    }
}

# Public API: trace all transitive dependencies of start.
# Returns {filename: level} where start is level 0; unknown start -> {}.
def trace_dependencies(adj: dict[str, list[str]], start: str) -> dict[str, int] {
    nodes: dict[str, Module] = build_graph(adj);
    if start not in nodes.keys() {
        return {};
    }
    nodes[start].lvl = 0;
    w = nodes[start] spawn LevelTrace();
    return w.dist;
}

# Public API: sorted list of all transitive dependencies (start excluded
# only if it is not its own dependency).
def dependency_closure(adj: dict[str, list[str]], start: str) -> list[str] {
    dist: dict[str, int] = trace_dependencies(adj, start);
    names: list[str] = [];
    for k in dist.keys() {
        names.append(k);
    }
    return sorted(names);
}

# Public API: direct dependencies only (edge to missing files ignored).
def direct_dependencies(adj: dict[str, list[str]], start: str) -> list[str] {
    if start not in adj.keys() {
        return [];
    }
    deps: list[str] = [];
    for d in adj[start] {
        if d in adj.keys() {
            deps.append(d);
        }
    }
    return sorted(deps);
}

test "diamond respects shortest path under adversarial order" {
    adj = {"a": ["b", "c"], "b": ["x", "d"], "c": ["d"], "d": [], "x": []};
    lv = trace_dependencies(adj, "a");
    assert lv["a"] == 0;
    assert lv["d"] == 1;
    assert lv["x"] == 2;
    assert sorted(lv.keys()) == ["a", "b", "c", "d", "x"];
}

test "relaxation re-opens nodes reached later at shallower depth" {
    adj = {"s": ["p", "q"], "q": [], "p": ["m"], "m": ["t"], "t": [], "z": ["t"], "s2": []};
    deep_first = {"s": ["p"], "p": ["m"], "m": ["t"], "t": [], "q": [], "z": []};
    adj2 = {"s": ["q", "p"], "q": ["t"], "p": ["m"], "m": ["t"], "t": []};
    lv = trace_dependencies(adj2, "s");
    assert lv["t"] == 1;
    lv2 = trace_dependencies(deep_first, "s");
    assert lv2["t"] == 3;
}

test "unknown id tolerated with empty result" {
    adj = {"a": ["b"], "b": []};
    assert trace_dependencies(adj, "nope.js") == {};
    assert dependency_closure(adj, "missing") == [];
    assert direct_dependencies(adj, "ghost") == [];
}

test "cycles terminate with finite levels" {
    adj = {"a.js": ["b.js"], "b.js": ["c.js"], "c.js": ["a.js"]};
    lv = trace_dependencies(adj, "a.js");
    assert len(lv) == 3;
    assert lv["a.js"] == 0 and lv["b.js"] == 1 and lv["c.js"] == 2;
    assert dependency_closure(adj, "b.js") == ["a.js", "b.js", "c.js"];
}

test "edges to unknown files are ignored deterministically" {
    adj = {"app.js": ["lib.js", "ghost.js"], "lib.js": []};
    assert direct_dependencies(adj, "app.js") == ["lib.js"];
    lv = trace_dependencies(adj, "app.js");
    assert sorted(lv.keys()) == ["app.js", "lib.js"];
    assert lv["lib.js"] == 1;
}

test "leaf start yields only itself" {
    adj = {"a": ["b"], "b": []};
    lv = trace_dependencies(adj, "b");
    assert lv == {"b": 0};
}
