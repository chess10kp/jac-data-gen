"""ACEsuit/mace#1609 — Governance ticket dependency graph for release policy."""
import from __future__ { annotations }
import from collections { deque }
class GovStore {
    def init(self: GovStore) -> None {
        self._tickets: set[str] = `set();
        self._depends: dict[(str, list[str])] = {};
        self._blocks: dict[(str, list[str])] = {};
    }
}
def load_governance(
    ticket_ids: list[str], depends_edges: list[tuple[(str, str)]]
) -> GovStore {
    store = GovStore();
    for tid in ticket_ids {
        store._tickets.add(tid);
        store._depends.setdefault(tid, []);
        store._blocks.setdefault(tid, []);
    }
    for (upstream, downstream) in depends_edges {
        if ((upstream in store._tickets) and (downstream in store._tickets)) {
            store._depends.setdefault(downstream, []).append(upstream);
            store._blocks.setdefault(upstream, []).append(downstream);
        }
    }
    return store;
}
def unblock_order(store: GovStore) -> list[str] {
    indegree: dict[(str, int)] = {
        t: len(store._depends.get(t, [])) for t in store._tickets
    };
    order: list[str] = [];
    ready = {
        t
        for (t, d) in indegree.items()
        if (d == 0)
    };
    while ready {
        nxt = min(ready);
        ready.remove(nxt);
        order.append(nxt);
        for blocked in store._blocks.get(nxt, []) {
            indegree[blocked] -= 1;
            if (indegree[blocked] == 0) {
                ready.add(blocked);
            }
        }
    }
    return order if (len(order) == len(store._tickets)) else [];
}
def transitive_blockers(store: GovStore, ticket: str) -> list[str] {
    if (ticket not in store._tickets) {
        return [];
    }
    seen: set[str] = `set();
    queue: deque[str] = deque([ticket]);
    while queue {
        cur = queue.popleft();
        for dep in store._depends.get(cur, []) {
            if (dep not in seen) {
                seen.add(dep);
                queue.append(dep);
            }
        }
    }
    return sorted(seen);
}
def has_cycle(store: GovStore) -> bool {
    return (len(unblock_order(store)) != len(store._tickets));
}

