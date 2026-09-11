"""skybristol/gkc#216 — Ontology seed dependency ordering workflow."""
import from __future__ { annotations }
import from collections { deque }
class SeedStore {
    def init(self: SeedStore) -> None {
        self._entities: set[str] = `set();
        self._depends: dict[(str, list[str])] = {};
        self._kind: dict[(str, str)] = {};
    }
}
def load_seed(
    entities: list[tuple[(str, str)]], depends_edges: list[tuple[(str, str)]]
) -> SeedStore {
    ss = SeedStore();
    for (eid, kind) in entities {
        ss._entities.add(eid);
        ss._kind[eid] = kind;
        ss._depends.setdefault(eid, []);
    }
    for (entity, dep) in depends_edges {
        if ((entity in ss._entities) and (dep in ss._entities)) {
            ss._depends.setdefault(entity, []).append(dep);
        }
    }
    return ss;
}
def _kahn_walk(store: SeedStore) -> tuple[(list[str], bool)] {
    indeg = {e: 0 for e in store._entities};
    for e in store._entities {
        for d in store._depends.get(e, []) {
            indeg[e] += 1;
        }
    }
    queue: deque[str] = deque(
        sorted(
            e
            for e in store._entities
            if (indeg[e] == 0)
        )
    );
    order: list[str] = [];
    while queue {
        u = queue.popleft();
        order.append(u);
        for v in store._entities {
            if (u in store._depends.get(v, [])) {
                indeg[v] -= 1;
                if (indeg[v] == 0) {
                    queue.append(v);
                }
            }
        }
    }
    return (order, (len(order) == len(store._entities)));
}
def dependency_order(store: SeedStore) -> list[str] {
    (order, ok) = _kahn_walk(store);
    if not ok {
        return [];
    }
    return order;
}
def detect_unresolved(store: SeedStore) -> list[str] {
    (order, ok) = _kahn_walk(store);
    if ok {
        return [];
    }
    placed = `set(order);
    return sorted(
        e
        for e in store._entities
        if (e not in placed)
    );
}
def entity_kind(store: SeedStore, entity_id: str) -> (str | None) {
    return store._kind.get(entity_id);
}

