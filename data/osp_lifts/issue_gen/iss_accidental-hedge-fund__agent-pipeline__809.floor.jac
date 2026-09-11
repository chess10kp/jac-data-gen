"""accidental-hedge-fund/agent-pipeline#809 — Symbol call-graph path queries."""
import from __future__ { annotations }
import from collections { deque }
class SymbolGraph {
    def init(self: SymbolGraph) -> None {
        self._symbols: set[str] = `set();
        self._calls: dict[(str, set[str])] = {};
    }
}
def load_symbol_graph(
    symbols: list[str], calls: list[tuple[(str, str)]]
) -> SymbolGraph {
    g = SymbolGraph();
    for s in symbols {
        g._symbols.add(s);
        g._calls.setdefault(s, `set());
    }
    for (caller, callee) in calls {
        if ((caller in g._symbols) and (callee in g._symbols)) {
            g._calls[caller].add(callee);
        }
    }
    return g;
}
def _forward_paths(
    g: SymbolGraph, start: str, target: str, max_hops: int
) -> list[list[str]] {
    if ((start not in g._symbols) or (target not in g._symbols)) {
        return [];
    }
    q: deque[tuple[(str, list[str], set[str])]] = deque([(start, [start], {start})]);
    hits: list[list[str]] = [];
    while q {
        (cur, path, seen) = q.popleft();
        if ((len(path) - 1) > max_hops) {
            continue;
        }
        if ((cur == target) and (len(path) > 1)) {
            hits.append(path);
            continue;
        }
        for nxt in sorted(g._calls.get(cur, ())) {
            if (nxt in seen) {
                continue;
            }
            q.append((nxt, (path + [nxt]), (seen | {nxt})));
        }
    }
    return hits;
}
def call_paths(g: SymbolGraph, source: str, sink: str, max_hops: int = 4) -> list[str] {
    paths = _forward_paths(g, source, sink, max_hops);
    flat: set[str] = `set();
    for p in paths {
        flat.update(p);
    }
    return sorted(flat);
}
def reachable_symbols(g: SymbolGraph, source: str, max_hops: int = 3) -> list[str] {
    if (source not in g._symbols) {
        return [];
    }
    q: deque[tuple[(str, int)]] = deque([(source, 0)]);
    seen: set[str] = {source};
    while q {
        (cur, depth) = q.popleft();
        if (depth >= max_hops) {
            continue;
        }
        for nxt in sorted(g._calls.get(cur, ())) {
            if (nxt not in seen) {
                seen.add(nxt);
                q.append((nxt, (depth + 1)));
            }
        }
    }
    seen.discard(source);
    return sorted(seen);
}
def has_cycle(g: SymbolGraph) -> bool {
    visited: set[str] = `set();
    stack: set[str] = `set();
    def dfs(`node: str) -> bool {
        visited.add(`node);
        stack.add(`node);
        for nxt in g._calls.get(`node, ()) {
            if (nxt not in visited) {
                if dfs(nxt) {
                    return True;
                }
            } elif (nxt in stack) {
                return True;
            }
        }
        stack.remove(`node);
        return False;
    }
    for sym in sorted(g._symbols) {
        if ((sym not in visited) and dfs(sym)) {
            return True;
        }
    }
    return False;
}

