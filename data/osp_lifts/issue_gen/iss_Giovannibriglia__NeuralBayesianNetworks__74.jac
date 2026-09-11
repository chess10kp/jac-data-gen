"""Topological node-role profiling for benchmark query selection.

Giovannibriglia/NeuralBayesianNetworks#74 lifted to OSP: BN variables become
VarNode archetypes and (parent, child) edges become typed Influences edges
plus a mirrored DependentOf edge so parent and child queries stay
walker-native. The recursive descents over adjacency lists become one-hop and
flooding walkers whose seen maps are the cycle policy; the profiler reports
blanket sizes, descendant counts, and deterministic hub/terminal selections.
"""
node VarNode {
    has name: str;
}
edge Influences {}
edge DependentOf {}

"""Handle: variable names resolve through this lookup map."""
obj BayesDag {
    has nodes: dict[str, VarNode];

    def resolve(name: str) -> VarNode | None {
        return self.nodes.get(name);
    }

    def names() -> list[str] {
        out: list[str] = [];
        for k in self.nodes.keys() {
            out.append(k);
        }
        return sorted(out);
    }
}

def build_dag(nodes: list[str], edges: list[tuple[str, str]]) -> BayesDag {
    g = BayesDag(nodes={});
    for n in nodes {
        v = VarNode(name=n);
        root ++> v;
        g.nodes[n] = v;
    }
    for (parent, child) in edges {
        p = g.nodes.get(parent);
        c = g.nodes.get(child);
        if p is not None and c is not None {
            c +>:Influences:+> p;
            p +>:DependentOf:+> c;
        }
    }
    return g;
}

walker ParentHop {
    has outs: list[str] = [];
    has started: bool = False;

    can step with VarNode entry {
        if not self.started {
            self.started = True;
            visit [->:Influences:->];
        } else {
            if here.name not in self.outs {
                self.outs.append(here.name);
            }
        }
    }
}

walker ChildHop {
    has outs: list[str] = [];
    has started: bool = False;

    can step with VarNode entry {
        if not self.started {
            self.started = True;
            visit [->:DependentOf:->];
        } else {
            if here.name not in self.outs {
                self.outs.append(here.name);
            }
        }
    }
}

walker DescendantFlood {
    has claimed: dict[str, bool] = {};
    has count: int = 0;
    has start_name: str = "";

    can step with VarNode entry {
        if here.name in self.claimed {
            skip;
        }
        if here.name != self.start_name {
            self.count += 1;
        }
        self.claimed[here.name] = True;
        visit [->:DependentOf:->];
    }
}

def parents_of(g: BayesDag, var_name: str) -> list[str] {
    v = g.resolve(var_name);
    if v is None {
        return [];
    }
    w = v spawn ParentHop();
    return sorted(w.outs);
}

def children_of(g: BayesDag, var_name: str) -> list[str] {
    v = g.resolve(var_name);
    if v is None {
        return [];
    }
    w = v spawn ChildHop();
    return sorted(w.outs);
}

"""Parents + children + co-parents of ``node`` (sorted, minus itself)."""
def markov_blanket(g: BayesDag, var_name: str) -> list[str] {
    if g.resolve(var_name) is None {
        return [];
    }
    claim: dict[str, bool] = {};
    for p in parents_of(g, var_name) + children_of(g, var_name) {
        claim[p] = True;
    }
    for child in children_of(g, var_name) {
        for cop in parents_of(g, child) {
            claim[cop] = True;
        }
    }
    claim.pop(var_name, None);
    return sorted(claim.keys());
}

def _descendant_count(g: BayesDag, var_name: str) -> int {
    v = g.resolve(var_name);
    if v is None {
        return 0;
    }
    w = v spawn DescendantFlood(start_name=var_name);
    return w.count;
}

"""Per-node (blanket_size, descendant_count), sorted by node name."""
def role_profile(g: BayesDag) -> list[tuple] {
    out: list[tuple] = [];
    for node in g.names() {
        out.append((node, len(markov_blanket(g, node)),
                    _descendant_count(g, node)));
    }
    return out;
}

"""Top-k nodes by Markov-blanket cardinality (ties: name ascending)."""
def hub_nodes(g: BayesDag, k: int) -> list[str] {
    scored: list[tuple] = [];
    for node in g.names() {
        scored.append((-len(markov_blanket(g, node)), node));
    }
    ranked = sorted(scored);
    out: list[str] = [];
    for i in range(min(k, len(ranked))) {
        out.append(ranked[i][1]);
    }
    return out;
}

"""k nodes with the fewest descendants (ties: name ascending)."""
def terminal_nodes(g: BayesDag, k: int) -> list[str] {
    scored: list[tuple] = [];
    for node in g.names() {
        scored.append((_descendant_count(g, node), node));
    }
    ranked = sorted(scored);
    out: list[str] = [];
    for i in range(min(k, len(ranked))) {
        out.append(ranked[i][1]);
    }
    return out;
}

"""Deterministic role split: hubs 30% / terminals 25% / reserve."""
def allocate_queries(budget: int) -> tuple {
    hubs = budget * 30 // 100;
    terminals = budget * 25 // 100;
    return (hubs, terminals, budget - hubs - terminals);
}
