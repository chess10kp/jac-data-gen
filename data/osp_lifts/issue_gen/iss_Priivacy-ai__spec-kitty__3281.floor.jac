"""Priivacy-ai/spec-kitty#3281 — Lane dependency closure and missing propagation."""
import from __future__ { annotations }
import from collections { deque }
class LaneStore {
    def init(self: LaneStore) -> None {
        self._lanes: set[str] = `set();
        self._depends: dict[(str, list[str])] = {};
        self._merged: dict[(str, bool)] = {};
    }
}
def load_lanes(
    lane_ids: list[str], depends_edges: list[tuple[(str, str)]]
) -> LaneStore {
    store = LaneStore();
    for lid in lane_ids {
        store._lanes.add(lid);
        store._depends.setdefault(lid, []);
        store._merged[lid] = False;
    }
    for (upstream, downstream) in depends_edges {
        if ((upstream in store._lanes) and (downstream in store._lanes)) {
            store._depends.setdefault(downstream, []).append(upstream);
        }
    }
    return store;
}
def dependency_closure(store: LaneStore, lane: str) -> list[str] {
    if (lane not in store._lanes) {
        return [];
    }
    seen: set[str] = `set();
    queue: deque[str] = deque([lane]);
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
def missing_dependencies(store: LaneStore, lane: str) -> list[str] {
    if (lane not in store._lanes) {
        return [];
    }
    required = dependency_closure(store, lane);
    return sorted(
        dep
        for dep in required
        if not store._merged.get(dep, False)
    );
}
def mark_merged(store: LaneStore, lane: str) -> None {
    if (lane in store._lanes) {
        store._merged[lane] = True;
    }
}
def is_ancestor_merged(store: LaneStore, lane: str) -> bool {
    deps = dependency_closure(store, lane);
    if not deps {
        return True;
    }
    return all(store._merged.get(dep, False) for dep in deps);
}

