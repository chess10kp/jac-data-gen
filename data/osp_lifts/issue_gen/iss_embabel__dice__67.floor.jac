"""embabel/dice#67 — Extraction run lineage with parent/superseded chains."""
import from __future__ { annotations }
import from collections { deque }
class RunStore {
    def init(self: RunStore) -> None {
        self._runs: set[str] = `set();
        self._parent: dict[(str, (str | None))] = {};
        self._superseded: dict[(str, (str | None))] = {};
        self._tenant: dict[(str, str)] = {};
        self._status: dict[(str, str)] = {};
    }
}
def load_runs(
    runs: list[tuple[(str, str)]],
    parents: list[tuple[(str, str)]],
    superseded: list[tuple[(str, str)]],
    statuses: list[tuple[(str, str)]]
) -> RunStore {
    store = RunStore();
    for (rid, tenant) in runs {
        store._runs.add(rid);
        store._parent[rid] = None;
        store._superseded[rid] = None;
        store._tenant[rid] = tenant;
        store._status[rid] = "completed";
    }
    for (child, parent) in parents {
        if ((child in store._runs) and (parent in store._runs)) {
            store._parent[child] = parent;
        }
    }
    for (old, new) in superseded {
        if ((old in store._runs) and (new in store._runs)) {
            store._superseded[old] = new;
        }
    }
    for (rid, status) in statuses {
        if (rid in store._runs) {
            store._status[rid] = status;
        }
    }
    return store;
}
def _lineage_walk(
    store: RunStore, start: str, field: str, max_depth: int
) -> list[str] {
    if (start not in store._runs) {
        return [];
    }
    q: deque[tuple[(str, int)]] = deque([(start, 0)]);
    seen: set[str] = {start};
    hits: list[str] = [];
    while q {
        (cur, depth) = q.popleft();
        if (depth >= max_depth) {
            continue;
        }
        nxt = store._parent[cur] if (field == "parent") else store._superseded.get(cur);
        if ((nxt is None) or (nxt in seen)) {
            continue;
        }
        seen.add(nxt);
        hits.append(nxt);
        q.append((nxt, (depth + 1)));
    }
    return hits;
}
def parent_lineage(store: RunStore, run_id: str, max_depth: int = 10) -> list[str] {
    return sorted(_lineage_walk(store, run_id, "parent", max_depth));
}
def superseded_chain(store: RunStore, run_id: str, max_depth: int = 10) -> list[str] {
    return sorted(_lineage_walk(store, run_id, "superseded", max_depth));
}
def would_create_parent_cycle(store: RunStore, child: str, new_parent: str) -> bool {
    if ((child not in store._runs) or (new_parent not in store._runs)) {
        return False;
    }
    if (child == new_parent) {
        return True;
    }
    seen: set[str] = {child};
    cur: (str | None) = new_parent;
    while (cur is not None) {
        if (cur in seen) {
            return True;
        }
        seen.add(cur);
        cur = store._parent.get(cur);
    }
    return False;
}
def set_parent(store: RunStore, child: str, parent: (str | None)) -> None {
    if (child not in store._runs) {
        raise KeyError(child);
    }
    if (parent is not None) {
        if (parent not in store._runs) {
            raise KeyError(parent);
        }
        if would_create_parent_cycle(store, child, parent) {
            raise ValueError("parent cycle");
        }
    }
    store._parent[child] = parent;
}
def runs_for_tenant(store: RunStore, tenant: str) -> list[str] {
    return sorted(
        r
        for r in store._runs
        if (store._tenant[r] == tenant)
    );
}
def run_status(store: RunStore, run_id: str) -> (str | None) {
    return store._status.get(run_id);
}

