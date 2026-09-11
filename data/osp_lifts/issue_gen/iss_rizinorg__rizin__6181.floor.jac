"""rizinorg/rizin#6181 — RzGraph out-edge adjacency reachability.

Hand-rolled adjacency dict plus deque BFS collects nodes reachable from a
start hash_id; used to probe call-graph neighborhood before optimization.
"""
import from __future__ { annotations }
import from collections { deque }
class RzGraph {
    def init(self: RzGraph) -> None {
        self.nodes: set[str] = `set();
        self.out_edges: dict[(str, list[str])] = {};
    }
}
def load_graph(nodes: list[str], edges: list[tuple[(str, str)]]) -> RzGraph {
    g = RzGraph();
    for nid in nodes {
        g.nodes.add(nid);
        g.out_edges.setdefault(nid, []);
    }
    for (src, dst) in edges {
        if ((src in g.nodes) and (dst in g.nodes)) {
            g.out_edges.setdefault(src, []).append(dst);
        }
    }
    return g;
}
def reachable_from(g: RzGraph, start: str) -> list[str] {
    if (start not in g.nodes) {
        return [];
    }
    seen: set[str] = `set();
    queue: deque[str] = deque([start]);
    while queue {
        cur = queue.popleft();
        if (cur in seen) {
            continue;
        }
        seen.add(cur);
        for nxt in g.out_edges.get(cur, []) {
            if (nxt not in seen) {
                queue.append(nxt);
            }
        }
    }
    return sorted(seen);
}
def has_path(g: RzGraph, src: str, dst: str) -> bool {
    return (dst in reachable_from(g, src));
}

