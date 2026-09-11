"""iSparshP/Algorithms#3 — Adjacency-list graph BFS reach and cycle probe."""
import from __future__ { annotations }
import from collections { deque }
class AdjGraph {
    def init(self: AdjGraph) -> None {
        self._verts: set[str] = `set();
        self._adj: dict[(str, list[str])] = {};
    }
}
def load_adj_graph(vertices: list[str], edges: list[tuple[(str, str)]]) -> AdjGraph {
    g = AdjGraph();
    for v in vertices {
        g._verts.add(v);
        g._adj.setdefault(v, []);
    }
    for (src, dst) in edges {
        if ((src not in g._verts) or (dst not in g._verts)) {
            continue;
        }
        g._adj[src].append(dst);
    }
    return g;
}
def bfs_reach(g: AdjGraph, start: str) -> list[str] {
    if (start not in g._verts) {
        return [];
    }
    seen: set[str] = `set();
    q: deque[str] = deque([start]);
    while q {
        cur = q.popleft();
        if (cur in seen) {
            continue;
        }
        seen.add(cur);
        for nxt in g._adj.get(cur, []) {
            if (nxt not in seen) {
                q.append(nxt);
            }
        }
    }
    return sorted(seen);
}
def adjacent_to(g: AdjGraph, vertex_id: str) -> list[str] {
    if (vertex_id not in g._verts) {
        return [];
    }
    return sorted(g._adj.get(vertex_id, []));
}

