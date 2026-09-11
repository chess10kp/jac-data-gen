"""AmpersandTarski/Ampersand#1651 — Kleene plus/star relation reachability.

Hand-rolled adjacency dict + fixpoint queue walk for transitive closure before
ENFORCE desugaring replaces recursive CTE generation.
"""
import from __future__ { annotations }
import from collections { deque }
class RelationGraph {
    def init(self: RelationGraph) -> None {
        self._nodes: set[str] = `set();
        self._edges: dict[(str, list[str])] = {};
    }
}
def load_relation(nodes: list[str], pairs: list[tuple[(str, str)]]) -> RelationGraph {
    g = RelationGraph();
    for n in nodes {
        g._nodes.add(n);
        g._edges.setdefault(n, []);
    }
    for (src, dst) in pairs {
        if ((src in g._nodes) and (dst in g._nodes)) {
            g._edges.setdefault(src, []).append(dst);
        }
    }
    return g;
}
def kleene_plus(g: RelationGraph, start: str) -> list[str] {
    if (start not in g._nodes) {
        return [];
    }
    seen: set[str] = `set();
    q: deque[str] = deque([start]);
    while q {
        cur = q.popleft();
        for nxt in g._edges.get(cur, []) {
            if (nxt not in seen) {
                seen.add(nxt);
                q.append(nxt);
            }
        }
    }
    return sorted(seen);
}
def kleene_star(g: RelationGraph, start: str) -> list[str] {
    if (start not in g._nodes) {
        return [];
    }
    return sorted(([start] + kleene_plus(g, start)));
}
def has_path(g: RelationGraph, src: str, dst: str) -> bool {
    if ((src not in g._nodes) or (dst not in g._nodes)) {
        return False;
    }
    if (src == dst) {
        return True;
    }
    return (dst in kleene_plus(g, src));
}

