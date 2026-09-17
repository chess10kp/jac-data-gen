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
