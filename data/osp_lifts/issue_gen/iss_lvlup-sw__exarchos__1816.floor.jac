"""DKG transitive queries: materialized fold vs recursive CTE oracle.

Source: lvlup-sw/exarchos#1816.
"""
import from __future__ { annotations }
import from collections { deque }
with entry {
    MAX_TRAVERSAL_DEPTH = 32;
}
def _known_nodes(triples: list[tuple[(str, str)]]) -> set[str] {
    nodes: set[str] = `set();
    for (src, dst) in triples {
        nodes.add(src);
        nodes.add(dst);
    }
    return nodes;
}
def _adjacency(triples: list[tuple[(str, str)]]) -> dict[(str, list[str])] {
    adj: dict[(str, list[str])] = {};
    for (src, dst) in triples {
        adj.setdefault(src, []).append(dst);
        adj.setdefault(dst, []);
    }
    return adj;
}
def _fold_lineage(seed: str, triples: list[tuple[(str, str)]]) -> set[str] {
    adj = _adjacency(triples);
    closure: set[str] = {seed};
    changed = True;
    while changed {
        changed = False;
        for `node in `list(closure) {
            for nxt in adj.get(`node, []) {
                if (nxt not in closure) {
                    closure.add(nxt);
                    changed = True;
                }
            }
        }
    }
    return closure;
}
def _recursive_cte(
    seed: str, triples: list[tuple[(str, str)]], max_depth: int = MAX_TRAVERSAL_DEPTH
) -> list[str] {
    adj = _adjacency(triples);
    settled: set[str] = `set();
    order: list[str] = [];
    work: deque[tuple[(str, int)]] = deque([(seed, 0)]);
    while work {
        (`node, depth) = work.popleft();
        if (`node in settled) {
            continue;
        }
        settled.add(`node);
        order.append(`node);
        if (depth >= max_depth) {
            continue;
        }
        for nxt in sorted(adj.get(`node, [])) {
            if (nxt not in settled) {
                work.append((nxt, (depth + 1)));
            }
        }
    }
    return order;
}
def transitive_query(start: str, triples: list[tuple[(str, str)]]) -> list[str] {
    if (start not in _known_nodes(triples)) {
        return [];
    }
    return sorted(_fold_lineage(start, triples));
}
def dkg_reachable(seed: str, triples: list[tuple[(str, str)]]) -> list[str] {
    if (seed not in _known_nodes(triples)) {
        return [];
    }
    return sorted(`set(_recursive_cte(seed, triples)));
}
def fold_oracle(seed: str, triples: list[tuple[(str, str)]]) -> bool {
    if (seed not in _known_nodes(triples)) {
        return True;
    }
    return (transitive_query(seed, triples) == dkg_reachable(seed, triples));
}

