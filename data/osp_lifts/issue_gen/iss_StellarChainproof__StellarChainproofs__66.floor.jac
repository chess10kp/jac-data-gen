"""StellarChainproof/StellarChainproofs#66 — Multi-hop call-graph reentrancy path detection."""
import from __future__ { annotations }
import from collections { deque }
class CallGraph {
    def init(self: CallGraph) -> None {
        self._funcs: set[str] = `set();
        self._contract: dict[(str, str)] = {};
        self._calls: dict[(str, set[str])] = {};
        self._unfinalized: set[str] = `set();
    }
}
def load_call_graph(
    funcs: list[tuple[(str, str)]],
    calls: list[tuple[(str, str)]],
    unfinalized: list[str]
) -> CallGraph {
    g = CallGraph();
    for (fid, contract) in funcs {
        g._funcs.add(fid);
        g._contract[fid] = contract;
        g._calls.setdefault(fid, `set());
    }
    for (caller, callee) in calls {
        if ((caller in g._funcs) and (callee in g._funcs)) {
            g._calls[caller].add(callee);
        }
    }
    g._unfinalized = `set(unfinalized);
    return g;
}
def _walk_paths(g: CallGraph, start: str, max_hops: int) -> list[list[str]] {
    q: deque[tuple[(str, list[str], set[str])]] = deque([(start, [start], {start})]);
    chains: list[list[str]] = [];
    while q {
        (cur, path, seen) = q.popleft();
        if ((len(path) - 1) >= max_hops) {
            continue;
        }
        for nxt in sorted(g._calls.get(cur, ())) {
            if (nxt in seen) {
                continue;
            }
            npath = path + [nxt];
            chains.append(npath);
            q.append((nxt, npath, (seen | {nxt})));
        }
    }
    return chains;
}
def reentrant_chains(g: CallGraph, entry_func: str, max_hops: int = 3) -> list[str] {
    if (entry_func not in g._funcs) {
        return [];
    }
    origin = g._contract[entry_func];
    hits: set[str] = `set();
    for chain in _walk_paths(g, entry_func, max_hops) {
        if (len(chain) < 2) {
            continue;
        }
        tail = chain[-1];
        if ((g._contract[tail] == origin) and (tail != entry_func)) {
            if `any((fid in g._unfinalized) for fid in chain) {
                hits.update(chain);
            }
        }
    }
    return sorted(hits);
}
def cross_contract_hops(g: CallGraph, entry_func: str, max_hops: int = 3) -> list[str] {
    if (entry_func not in g._funcs) {
        return [];
    }
    seen_funcs: set[str] = `set();
    q: deque[tuple[(str, int)]] = deque([(entry_func, 0)]);
    while q {
        (cur, depth) = q.popleft();
        if (cur in seen_funcs) {
            continue;
        }
        seen_funcs.add(cur);
        if (depth >= max_hops) {
            continue;
        }
        for nxt in sorted(g._calls.get(cur, ())) {
            if (g._contract[nxt] != g._contract[cur]) {
                q.append((nxt, (depth + 1)));
            }
        }
    }
    seen_funcs.discard(entry_func);
    return sorted(seen_funcs);
}
def is_guarded_chain(g: CallGraph, chain: list[str], guarded: set[str]) -> bool {
    return all((fid in guarded) for fid in chain);
}
def contracts_in_chain(g: CallGraph, chain: list[str]) -> list[str] {
    out: list[str] = [];
    seen: set[str] = `set();
    for fid in chain {
        c = g._contract.get(fid);
        if ((c is not None) and (c not in seen)) {
            seen.add(c);
            out.append(c);
        }
    }
    return out;
}

