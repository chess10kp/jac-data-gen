"""specd-sdd/SpecD#39 — Execution flow detection via BFS over CALLS edges.

Code symbols form a call graph; process detection BFS-walks forward from entry
points along adjacency dict edges with a depth cap and collects reachable nodes.
"""
import from __future__ { annotations }
import from collections { deque }
class CodeGraph {
    def init(self: CodeGraph) -> None {
        self.symbols: set[str] = `set();
        self.calls: dict[(str, list[str])] = {};
    }
}
def load_graph(symbols: list[str], call_edges: list[tuple[(str, str)]]) -> CodeGraph {
    g = CodeGraph();
    for sym in symbols {
        g.symbols.add(sym);
        g.calls.setdefault(sym, []);
    }
    for (src, dst) in call_edges {
        if ((src in g.symbols) and (dst in g.symbols)) {
            g.calls.setdefault(src, []).append(dst);
            g.calls.setdefault(dst, g.calls.get(dst, []));
        }
    }
    return g;
}
def reachable_flow(g: CodeGraph, entry_sym: str, max_depth: int) -> list[str] {
    if (entry_sym not in g.symbols) {
        return [];
    }
    seen: set[str] = {entry_sym};
    depth_map: dict[(str, int)] = {entry_sym: 0};
    q: deque[str] = deque([entry_sym]);
    while q {
        cur = q.popleft();
        cur_depth = depth_map[cur];
        if (cur_depth >= max_depth) {
            continue;
        }
        for nxt in g.calls.get(cur, []) {
            nd = cur_depth + 1;
            if (nxt not in seen) {
                seen.add(nxt);
                depth_map[nxt] = nd;
                q.append(nxt);
            }
        }
    }
    return sorted(seen);
}
def process_count(g: CodeGraph, entries: list[str], max_depth: int) -> int {
    merged: set[str] = `set();
    for ent in entries {
        for sym in reachable_flow(g, ent, max_depth) {
            merged.add(sym);
        }
    }
    return len(merged);
}

