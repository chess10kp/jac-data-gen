"""turndb/turndb#11 — Publication gate lineage reach for shipped items."""
import from __future__ { annotations }
import from collections { deque }
class GateStore {
    def init(self: GateStore) -> None {
        self._items: set[str] = `set();
        self._refs: dict[(str, list[str])] = {};
        self._state: dict[(str, str)] = {};
    }
}
def load_gate(
    item_names: list[str],
    ref_edges: list[tuple[(str, str)]],
    states: (dict[(str, str)] | None) = None
) -> GateStore {
    store = GateStore();
    for name in item_names {
        store._items.add(name);
        store._refs.setdefault(name, []);
        store._state[name] = "open";
    }
    for (src, dst) in ref_edges {
        if ((src in store._items) and (dst in store._items)) {
            store._refs.setdefault(src, []).append(dst);
        }
    }
    if states {
        for (k, v) in states.items() {
            if (k in store._items) {
                store._state[k] = v;
            }
        }
    }
    return store;
}
def downstream_items(store: GateStore, `root: str) -> list[str] {
    if (`root not in store._items) {
        return [];
    }
    seen: set[str] = `set();
    queue: deque[str] = deque([`root]);
    while queue {
        cur = queue.popleft();
        for nxt in store._refs.get(cur, []) {
            if (nxt not in seen) {
                seen.add(nxt);
                queue.append(nxt);
            }
        }
    }
    return sorted(seen);
}
def blocked_by_state(
    store: GateStore, `root: str, blocked_states: list[str]
) -> list[str] {
    reach = `set(downstream_items(store, `root));
    reach.add(`root);
    out: list[str] = [];
    for item in sorted(reach) {
        if (store._state.get(item) in blocked_states) {
            out.append(item);
        }
    }
    return out;
}
def unresolved_refs(store: GateStore) -> list[str] {
    missing: set[str] = `set();
    for (src, targets) in store._refs.items() {
        for dst in targets {
            if (dst not in store._items) {
                missing.add(dst);
            }
        }
    }
    return sorted(missing);
}

