"""Soroban-GAMorg/StellarScout#66 — function call graph analysis."""

node ContractGraph {
    has functions: list[FunctionNode] = [];
}

node FunctionNode {
    has name: str;
    has caller: bool = False;
    has depth: int = -1;
}

edge Contains {}
edge Calls {}

walker CallerMarker {
    has claimed: dict[str, bool] = {};

    can mark with FunctionNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        print("caller scan " + here.name);
        for kid in [here ->:Calls:->][?:FunctionNode] {
            kid.caller = True;
        }
    }
}

walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can reach with FunctionNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.order.append(here.name);
        print("reachable " + here.name);
        for kid in [here ->:Calls:->][?:FunctionNode] {
            if kid.depth < 0 { kid.depth = here.depth + 1; }
            visit [kid];
        }
    }
}

walker CycleWalker {
    has origin: str;
    has claimed: dict[str, bool] = {};
    has path: list[str] = [];
    has cycles: list[list[str]] = [];

    can cycle with FunctionNode entry {
        if here.name in self.path {
            cycle: list[str] = [];
            started: bool = False;
            for item in self.path {
                if item == here.name { started = True; }
                if started { cycle.append(item); }
            }
            cycle.append(here.name);
            minimum: str = cycle[0];
            for item in cycle {
                if item < minimum { minimum = item; }
            }
            if self.origin == minimum { self.cycles.append(cycle); }
            print("cycle revisit " + here.name);
            skip;
        }
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.path.append(here.name);
        print("cycle scan " + here.name);
        for kid in [here ->:Calls:->][?:FunctionNode] {
            next_claimed: dict[str, bool] = {};
            for key in self.claimed {
                next_claimed[key] = self.claimed[key];
            }
            next_path: list[str] = [];
            for item in self.path { next_path.append(item); }
            cw = kid spawn CycleWalker(
                origin=self.origin,
                claimed=next_claimed,
                path=next_path,
                cycles=self.cycles
            );
        }
    }
}

walker ChainWalker {
    has claimed: dict[str, bool] = {};
    has path: list[str] = [];
    has chains: list[list[str]] = [];

    can chain with FunctionNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        current: list[str] = [];
        for item in self.path { current.append(item); }
        current.append(here.name);
        print("chain " + here.name);

        has_child: bool = False;
        for kid in [here ->:Calls:->][?:FunctionNode] {
            has_child = True;
            next_claimed: dict[str, bool] = {};
            for key in self.claimed {
                next_claimed[key] = self.claimed[key];
            }
            next_path: list[str] = [];
            for item in current { next_path.append(item); }
            cw = kid spawn ChainWalker(
                claimed=next_claimed,
                path=next_path,
                chains=self.chains
            );
        }
        if not has_child { self.chains.append(current); }
    }
}

def make_graph(spec: dict[str, list[str]]) -> ContractGraph {
    graph_root = ContractGraph();
    nodes: dict[str, FunctionNode] = {};

    for name in sorted(spec) {
        fn = FunctionNode(name=name);
        nodes[name] = fn;
        graph_root.functions.append(fn);
        graph_root +>:Contains:+> fn;
    }

    for name in sorted(spec) {
        source: FunctionNode = nodes[name];
        seen_targets: dict[str, bool] = {};
        for target in sorted(spec[name]) {
            if target in nodes {
                if target not in seen_targets {
                    seen_targets[target] = True;
                    callee: FunctionNode = nodes[target];
                    source +>:Calls:+> callee;
                }
            }
        }
    }
    return graph_root;
}

def mark_callers(graph_root: ContractGraph) {
    for fn in graph_root.functions {
        marks: dict[str, bool] = {};
        w = fn spawn CallerMarker(claimed=marks);
    }
}

def choose_roots(
    graph_root: ContractGraph,
    entry_points: list[str] | None = None
) -> list[str] {
    roots: list[str] = [];
    if entry_points is None {
        mark_callers(graph_root);
        for fn in graph_root.functions {
            if not fn.caller { roots.append(fn.name); }
        }
    } else {
        for wanted in entry_points {
            for fn in graph_root.functions {
                if fn.name == wanted { roots.append(wanted); }
            }
        }
    }
    return roots;
}

def reachable_names(
    graph_root: ContractGraph,
    roots: list[str]
) -> list[str] {
    claimed: dict[str, bool] = {};
    order: list[str] = [];
    for wanted in roots {
        for fn in graph_root.functions {
            if fn.name == wanted {
                if fn.name not in claimed {
                    fn.depth = 0;
                    w = fn spawn ReachWalker(
                        claimed=claimed,
                        order=order
                    );
                }
            }
        }
    }
    return sorted(order);
}

def sequence_key(values: list[str]) -> str {
    key: str = "";
    for value in values { key = key + value + "|"; }
    return key;
}

def canonical_cycle(cycle: list[str]) -> list[str] {
    base: list[str] = [];
    for i in range(len(cycle) - 1) { base.append(cycle[i]); }

    best: list[str] = [];
    best_key: str = "";
    first: bool = True;
    for i in range(len(base)) {
        candidate: list[str] = [];
        for j in range(len(base)) {
            candidate.append(base[(i + j) % len(base)]);
        }
        candidate_key: str = sequence_key(candidate);
        if first or candidate_key < best_key {
            best = candidate;
            best_key = candidate_key;
            first = False;
        }
    }
    best.append(best[0]);
    return best;
}

def build_call_graph(spec: dict[str, list[str]]) -> dict[str, list[str]] {
    graph_root = make_graph(spec);
    result: dict[str, list[str]] = {};
    for fn in graph_root.functions {
        calls: list[str] = [];
        for kid in [fn ->:Calls:->][?:FunctionNode] {
            calls.append(kid.name);
        }
        result[fn.name] = calls;
    }
    return result;
}

def identify_entry_points(spec: dict[str, list[str]]) -> list[str] {
    graph_root = make_graph(spec);
    return choose_roots(graph_root);
}

def find_unused_functions(
    spec: dict[str, list[str]],
    entry_points: list[str] | None = None
) -> list[str] {
    graph_root = make_graph(spec);
    roots: list[str] = choose_roots(graph_root, entry_points);
    reachable: list[str] = reachable_names(graph_root, roots);
    unused: list[str] = [];
    for fn in graph_root.functions {
        if fn.name not in reachable { unused.append(fn.name); }
    }
    return sorted(unused);
}

def calculate_call_depths(
    spec: dict[str, list[str]],
    entry_points: list[str] | None = None
) -> dict[str, int] {
    graph_root = make_graph(spec);
    roots: list[str] = choose_roots(graph_root, entry_points);
    reachable_names(graph_root, roots);
    depths: dict[str, int] = {};
    for fn in graph_root.functions { depths[fn.name] = fn.depth; }
    return depths;
}

def detect_cycles(spec: dict[str, list[str]]) -> list[list[str]] {
    graph_root = make_graph(spec);
    raw: list[list[str]] = [];
    for fn in graph_root.functions {
        claimed: dict[str, bool] = {};
        path: list[str] = [];
        w = fn spawn CycleWalker(
            origin=fn.name,
            claimed=claimed,
            path=path,
            cycles=raw
        );
    }

    unique: dict[str, list[str]] = {};
    for cycle in raw {
        normalized: list[str] = canonical_cycle(cycle);
        unique[sequence_key(normalized)] = normalized;
    }

    result: list[list[str]] = [];
    for key in sorted(unique) { result.append(unique[key]); }
    return result;
}

def generate_call_chains(
    spec: dict[str, list[str]],
    entry_points: list[str] | None = None
) -> list[list[str]] {
    graph_root = make_graph(spec);
    roots: list[str] = choose_roots(graph_root, entry_points);
    raw: list[list[str]] = [];

    for wanted in roots {
        for fn in graph_root.functions {
            if fn.name == wanted {
                claimed: dict[str, bool] = {};
                path: list[str] = [];
                w = fn spawn ChainWalker(
                    claimed=claimed,
                    path=path,
                    chains=raw
                );
            }
        }
    }

    unique: dict[str, list[str]] = {};
    for chain in raw { unique[sequence_key(chain)] = chain; }
    result: list[list[str]] = [];
    for key in sorted(unique) { result.append(unique[key]); }
    return result;
}

def render_call_graph(spec: dict[str, list[str]]) -> list[str] {
    graph_root = make_graph(spec);
    lines: list[str] = [];
    for fn in graph_root.functions {
        children: list[str] = [];
        for kid in [fn ->:Calls:->][?:FunctionNode] {
            children.append(fn.name + " -> " + kid.name);
        }
        if len(children) == 0 { lines.append(fn.name); }
        else {
            for line in children { lines.append(line); }
        }
    }
    return lines;
}
