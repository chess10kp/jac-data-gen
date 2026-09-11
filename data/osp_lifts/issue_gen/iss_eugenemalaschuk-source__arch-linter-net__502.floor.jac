"""eugenemalaschuk-source/arch-linter-net#502 — Benchmark graph shape reachability counts."""
import from __future__ { annotations }
import from collections { deque }
class ShapeGraph {
    def init(self: ShapeGraph) -> None {
        self._nodes: set[str] = `set();
        self._edges: dict[(str, list[str])] = {};
    }
}
def load_shape_graph(nodes: list[str], edges: list[tuple[(str, str)]]) -> ShapeGraph {
    g = ShapeGraph();
    for n in nodes {
        g._nodes.add(n);
        g._edges.setdefault(n, []);
    }
    for (src, dst) in edges {
        if ((src in g._nodes) and (dst in g._nodes)) {
            g._edges[src].append(dst);
        }
    }
    return g;
}
def reachable_from(g: ShapeGraph, start: str) -> list[str] {
    if (start not in g._nodes) {
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
        for nxt in g._edges.get(cur, []) {
            if (nxt not in seen) {
                q.append(nxt);
            }
        }
    }
    return sorted(seen);
}
def shape_stats(g: ShapeGraph, starts: list[str]) -> dict[(str, int)] {
    out: dict[(str, int)] = {};
    for s in sorted(starts) {
        out[s] = len(reachable_from(g, s));
    }
    return out;
}

