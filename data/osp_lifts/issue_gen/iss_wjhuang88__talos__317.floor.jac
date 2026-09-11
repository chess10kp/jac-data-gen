"""wjhuang88/talos#317 — Symbol reference closure via identifier graph."""
import from __future__ { annotations }
import from collections { deque }
class SymGraph {
    def init(self: SymGraph) -> None {
        self._nodes: set[str] = `set();
        self._refs: dict[(str, list[str])] = {};
    }
}
def load_symbol_graph(symbols: list[str], refs: list[tuple[(str, str)]]) -> SymGraph {
    g = SymGraph();
    for sid in symbols {
        g._nodes.add(sid);
        g._refs.setdefault(sid, []);
    }
    for (src, dst) in refs {
        if ((src in g._nodes) and (dst in g._nodes)) {
            g._refs[src].append(dst);
        }
    }
    return g;
}
def reference_closure(g: SymGraph, symbol_id: str) -> list[str] {
    if (symbol_id not in g._nodes) {
        return [];
    }
    seen: set[str] = `set();
    q: deque[str] = deque([symbol_id]);
    while q {
        cur = q.popleft();
        if (cur in seen) {
            continue;
        }
        seen.add(cur);
        for nxt in g._refs.get(cur, []) {
            if (nxt not in seen) {
                q.append(nxt);
            }
        }
    }
    return sorted(seen);
}

