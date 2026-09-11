"""NousResearch/hermes-agent#81324 — SL3-alpha activation gate dependency routing."""

node Gate {
    has name: str;
    has status: str = "pending";
}

edge DependsOn {}

obj GateGraph {
    has gates: dict[str, Gate] = {};
}

walker CycleProbe {
    has visited: dict[str, bool] = {};
    has stack: dict[str, bool] = {};
    has errors: list[tuple[str, str]] = [];

    can step with Gate entry {
        if here.name in self.visited { skip; }
        self.visited[here.name] = True;
        self.stack[here.name] = True;
        for dep in [here ->:DependsOn:->][?:Gate] {
            if dep.name in self.stack {
                self.errors.append((here.name, dep.name));
            } else {
                if not (dep.name in self.visited) { visit [dep]; }
            }
        }
        self.stack[here.name] = False;
    }
}

def load_gate_graph(
    gates: list[str],
    depends_edges: list[tuple[str, str]],
    status: dict[str, str] | None = None,
) -> GateGraph {
    g = GateGraph();
    for name in gates {
        nd = Gate(name=name);
        root ++> nd;
        g.gates[name] = nd;
    }
    for (blocker, blocked) in depends_edges {
        b = g.gates.get(blocker, None);
        d = g.gates.get(blocked, None);
        if b is not None and d is not None { d +>:DependsOn:+> b; }
    }
    if status {
        for (k, v) in status.items() {
            n = g.gates.get(k, None);
            if n is not None { n.status = v; }
        }
    }
    return g;
}

def ready_gates(store: GateGraph) -> list[str] {
    out: list[str] = [];
    for name in sorted(store.gates.keys()) {
        nd = store.gates.get(name, None);
        if nd is None or nd.status != "pending" { continue; }
        ready = True;
        for dep in [nd ->:DependsOn:->][?:Gate] {
            if dep.status != "passed" { ready = False; }
        }
        if ready { out.append(name); }
    }
    return out;
}

def activation_path_depth(store: GateGraph, gate: str) -> int {
    nd = store.gates.get(gate, None);
    if nd is None { return -1; }
    depth: dict[str, int] = {gate: 0};
    frontier: list[Gate] = [nd];
    best = 0;
    while len(frontier) > 0 {
        cur = frontier.pop(0);
        cur_depth = depth[cur.name];
        for dep in [cur ->:DependsOn:->][?:Gate] {
            nd2 = cur_depth + 1;
            if nd2 > best { best = nd2; }
            if not (dep.name in depth) or nd2 > depth[dep.name] {
                depth[dep.name] = nd2;
                frontier.append(dep);
            }
        }
    }
    return best;
}

def detect_gate_cycles(store: GateGraph) -> list[tuple[str, str]] {
    errors: list[tuple[str, str]] = [];
    visited: dict[str, bool] = {};
    for k in sorted(store.gates.keys()) {
        if k in visited { continue; }
        nd = store.gates[k];
        w = nd spawn CycleProbe(visited=visited, stack={}, errors=[]);
        errors = errors + w.errors;
        visited = w.visited;
    }
    return sorted(errors);
}
