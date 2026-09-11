"""Scan local uses into composite actions. Source: gmeligio/gx#124."""
import from __future__ { annotations }
import from collections { deque }
def _adj(uses: list[tuple[(str, str)]]) -> dict[(str, list[str])] {
    out: dict[(str, list[str])] = {};
    for (src, dst) in uses {
        out.setdefault(src, []).append(dst);
    }
    return out;
}
"""BFS follow use edges; enter composite actions for nested refs."""
def follow_local_uses(
    start: str, uses: list[tuple[(str, str)]], composite: set[str]
) -> list[str] {
    adj = _adj(uses);
    seen: set[str] = `set();
    order: list[str] = [];
    q: deque[str] = deque([start]);
    while q {
        `node = q.popleft();
        if (`node in seen) {
            continue;
        }
        seen.add(`node);
        order.append(`node);
        for nxt in sorted(adj.get(`node, [])) {
            if (nxt not in seen) {
                q.append(nxt);
            }
            if (nxt in composite) {
                for nested in sorted(adj.get(nxt, [])) {
                    if (nested not in seen) {
                        q.append(nested);
                    }
                }
            }
        }
    }
    return order;
}
def nested_references(
    action: str, uses: list[tuple[(str, str)]], composite: set[str]
) -> list[str] {
    if (action not in composite) {
        return [];
    }
    return sorted(_adj(uses).get(action, []));
}
def managed_closure(
    seeds: list[str], uses: list[tuple[(str, str)]], composite: set[str]
) -> list[str] {
    seen: set[str] = `set();
    for seed in sorted(seeds) {
        for item in follow_local_uses(seed, uses, composite) {
            seen.add(item);
        }
    }
    return sorted(seen);
}

