"""AlisinaDevelo/LOOM#104 — Bounded provenance graph queries.

Evidence nodes carry typed parent relationships; upstream lineage queries walk
parent pointers with a depth bound using recursive stack descent.
"""
import from __future__ { annotations }
class ProvenanceGraph {
    def init(self: ProvenanceGraph) -> None {
        self.parent_of: dict[(str, (str | None))] = {};
        self.nodes: set[str] = `set();
    }
}
def load_provenance(
    nodes: list[str], derives: list[tuple[(str, str)]]
) -> ProvenanceGraph {
    g = ProvenanceGraph();
    for nid in nodes {
        g.nodes.add(nid);
        g.parent_of[nid] = None;
    }
    for (child, parent) in derives {
        if ((child in g.nodes) and (parent in g.nodes)) {
            g.parent_of[child] = parent;
        }
    }
    return g;
}
def _walk_up(g: ProvenanceGraph, start: str, limit: int, acc: list[str]) -> None {
    cur = g.parent_of.get(start);
    depth = 0;
    while ((cur is not None) and (depth < limit)) {
        acc.append(cur);
        depth += 1;
        cur = g.parent_of.get(cur);
    }
}
def upstream_lineage(g: ProvenanceGraph, node_id: str, limit: int) -> list[str] {
    if (node_id not in g.nodes) {
        return [];
    }
    acc: list[str] = [node_id];
    _walk_up(g, node_id, limit, acc);
    return sorted(`set(acc));
}
def within_bound(g: ProvenanceGraph, node_id: str, limit: int) -> bool {
    trail = upstream_lineage(g, node_id, (limit + 10));
    ups = [
        n
        for n in trail
        if (n != node_id)
    ];
    return (len(ups) <= limit);
}

