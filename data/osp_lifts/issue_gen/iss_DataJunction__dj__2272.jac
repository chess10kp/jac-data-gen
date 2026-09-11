"""Bulk node-deletion impact analysis for a lineage DAG.

DataJunction/dj#2272 lifted to OSP: lineage nodes become LineageNode
archetypes and parent->child links become typed FlowsTo edges. The
per-seed frontier BFS collapses into one flooding walker whose claim map is
the explicit cycle policy; seed nodes are pre-claimed so everything internal
to the delete set drops out of the boundary automatically.
"""
node LineageNode {
    has name: str;
}
edge FlowsTo {}

"""Loader handle: node names resolve through this lookup map."""
obj Lineage {
    has nodes: dict[str, LineageNode];

    def resolve(name: str) -> LineageNode | None {
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

"""Deterministic fresh-graph builder; only seeds attach under root."""
def build_lineage(nodes: list[str], edges: list[tuple[str, str]]) -> Lineage {
    ws = Lineage(nodes={});
    for n in nodes {
        it = LineageNode(name=n);
        root ++> it;
        ws.nodes[n] = it;
    }
    for (parent, child) in edges {
        p = ws.nodes.get(parent);
        c = ws.nodes.get(child);
        if p is not None and c is not None {
            p +>:FlowsTo:+> c;
        }
    }
    return ws;
}

"""Floods FlowsTo edges from one seed; cycle policy = expanded map.

Seeds stay out of ``reached``; sub-spawns share the expanded/reached state
so multi-seed floods see each node exactly once.
"""
walker BoundaryFlood {
    has seeds: list[str] = [];
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with LineageNode entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        is_seed = False;
        for s in self.seeds {
            if s == here.name {
                is_seed = True;
            }
        }
        if not is_seed {
            self.reached.append(here.name);
        }
        # Leaves are normal here: a bare visit keeps sibling branches alive
        # (an else-disengage would kill the whole flooded walk).
        visit [->:FlowsTo:->];
    }
}

walker ImpactedProbe {
    has target: str = "";
    has found: bool = False;
    has claimed: dict[str, bool] = {};

    can step with LineageNode entry {
        if here.name == self.target {
            self.found = True;
            disengage;
        }
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        visit [->:FlowsTo:->];
    }
}

def _seed_nodes(ws: Lineage, seeds: list[str]) -> list[LineageNode] {
    starts: list[LineageNode] = [];
    for s in seeds {
        n = ws.resolve(s);
        if n is not None {
            starts.append(n);
        }
    }
    return starts;
}

def _seed_flood(ws: Lineage, seeds: list[str]) -> list[str] {
    acc: list[str] = [];
    shared: dict[str, bool] = {};
    for st in _seed_nodes(ws, seeds) {
        w = st spawn BoundaryFlood(seeds=seeds, claimed=shared, reached=acc);
        acc = w.reached;
    }
    return sorted(acc);
}

"""All nodes reachable from any seed, excluding the seeds themselves."""
def downstream_closure(ws: Lineage, seeds: list[str]) -> list[str] {
    return sorted(_seed_flood(ws, seeds));
}

"""Downstream nodes of the seed set that survive deletion (the boundary)."""
def delete_boundary(ws: Lineage, seeds: list[str]) -> list[str] {
    closed = _seed_flood(ws, seeds);
    keep: list[str] = [];
    for n in closed {
        is_seed = False;
        for s in seeds {
            if s == n {
                is_seed = True;
            }
        }
        if not is_seed {
            keep.append(n);
        }
    }
    return sorted(keep);
}

"""True when ``target_node`` sits strictly below at least one seed."""
def is_impacted(ws: Lineage, seeds: list[str], target_node: str) -> bool {
    if ws.resolve(target_node) is None {
        return False;
    }
    for s in seeds {
        if s == target_node {
            return False;
        }
    }
    shared: dict[str, bool] = {};
    for st in _seed_nodes(ws, seeds) {
        w = st spawn ImpactedProbe(target=target_node, claimed=shared);
        if w.found {
            return True;
        }
        shared = w.claimed;
    }
    return False;
}
