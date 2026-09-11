"""chittihq/pintail#29 — FK cascade candidate repair for CDC-invisible deletes."""
import from __future__ { annotations }
class ReplicaStore {
    def init(self: ReplicaStore) -> None {
        self.rows: dict[(str, dict[(str, set[str])])] = {};
        self.fk_edges: list[tuple[(str, str, str, str)]] = [];
        self.tombstones: set[tuple[(str, str)]] = `set();
    }
}
def load_replica(
    tables: list[str], fk_pairs: list[tuple[(str, str)]], rows: dict[(str, list[str])]
) -> ReplicaStore {
    store = ReplicaStore();
    for tbl in tables {
        store.rows[tbl] = {rid: `set() for rid in rows.get(tbl, [])};
    }
    for (parent, child) in fk_pairs {
        if ((parent not in store.rows) or (child not in store.rows)) {
            continue;
        }
        for pid in store.rows[parent] {
            for cid in store.rows[child] {
                store.rows[parent][pid].add(cid);
                store.fk_edges.append((parent, pid, child, cid));
            }
        }
    }
    return store;
}
def _collect_cascade(
    store: ReplicaStore, table: str, row_id: str
) -> list[tuple[(str, str)]] {
    stack: list[tuple[(str, str)]] = [(table, row_id)];
    seen: set[tuple[(str, str)]] = `set();
    out: list[tuple[(str, str)]] = [];
    while stack {
        (cur_tbl, cur_id) = stack.pop();
        key = (cur_tbl, cur_id);
        if (key in seen) {
            continue;
        }
        seen.add(key);
        out.append(key);
        for (p_tbl, p_id, c_tbl, c_id) in store.fk_edges {
            if ((p_tbl == cur_tbl) and (p_id == cur_id)) {
                stack.append((c_tbl, c_id));
            }
        }
    }
    return out;
}
def cascade_tombstone(
    store: ReplicaStore, table: str, row_id: str
) -> list[tuple[(str, str)]] {
    if ((table not in store.rows) or (row_id not in store.rows[table])) {
        raise KeyError("unknown row");
    }
    candidates = _collect_cascade(store, table, row_id);
    applied: list[tuple[(str, str)]] = [];
    for (tbl, rid) in candidates {
        if ((tbl, rid) not in store.tombstones) {
            store.tombstones.add((tbl, rid));
            applied.append((tbl, rid));
        }
    }
    return sorted(applied);
}
def active_rows(store: ReplicaStore, table: str) -> list[str] {
    if (table not in store.rows) {
        return [];
    }
    live = [
        r
        for r in store.rows[table]
        if ((table, r) not in store.tombstones)
    ];
    return sorted(live);
}

