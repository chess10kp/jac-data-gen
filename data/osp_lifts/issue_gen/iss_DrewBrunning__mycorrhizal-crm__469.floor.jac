"""DrewBrunning/mycorrhizal-crm#469 — Multi-hop contact relationship traversal.

Hand-rolled adjacency dict + BFS for relationship reachability and hub detection
before core operation benchmarks pin query-count regressions.
"""
import from __future__ { annotations }
import from collections { deque }
class ContactGraph {
    def init(self: ContactGraph) -> None {
        self._contacts: set[str] = `set();
        self._links: dict[(str, list[str])] = {};
        self._kinds: dict[(str, str)] = {};
    }
}
def load_contacts(
    contacts: list[tuple[(str, str)]], edges: list[tuple[(str, str)]]
) -> ContactGraph {
    g = ContactGraph();
    for (cid, kind) in contacts {
        g._contacts.add(cid);
        g._kinds[cid] = kind;
        g._links.setdefault(cid, []);
    }
    for (src, dst) in edges {
        if ((src in g._contacts) and (dst in g._contacts)) {
            g._links.setdefault(src, []).append(dst);
            g._links.setdefault(dst, []).append(src);
        }
    }
    return g;
}
def reachable_contacts(g: ContactGraph, start: str, max_hops: int = 3) -> list[str] {
    if (start not in g._contacts) {
        return [];
    }
    seen: set[str] = {start};
    q: deque[tuple[(str, int)]] = deque([(start, 0)]);
    while q {
        (cur, depth) = q.popleft();
        if (depth >= max_hops) {
            continue;
        }
        for nb in g._links.get(cur, []) {
            if (nb not in seen) {
                seen.add(nb);
                q.append((nb, (depth + 1)));
            }
        }
    }
    seen.discard(start);
    return sorted(seen);
}
def hops_between(g: ContactGraph, start: str, end: str) -> (int | None) {
    if ((start not in g._contacts) or (end not in g._contacts)) {
        return None;
    }
    if (start == end) {
        return 0;
    }
    seen: set[str] = {start};
    q: deque[tuple[(str, int)]] = deque([(start, 0)]);
    while q {
        (cur, depth) = q.popleft();
        for nb in g._links.get(cur, []) {
            if (nb == end) {
                return (depth + 1);
            }
            if (nb not in seen) {
                seen.add(nb);
                q.append((nb, (depth + 1)));
            }
        }
    }
    return None;
}
def hub_contacts(g: ContactGraph, min_degree: int) -> list[str] {
    hits: list[str] = [];
    for cid in sorted(g._contacts) {
        if (len(g._links.get(cid, [])) >= min_degree) {
            hits.append(cid);
        }
    }
    return hits;
}

