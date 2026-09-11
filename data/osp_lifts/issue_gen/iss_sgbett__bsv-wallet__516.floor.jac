"""sgbett/bsv-wallet#516 — Persistent verification cache over ancestor graph."""
import from __future__ { annotations }
import from collections { deque }
class TxStore {
    def init(self: TxStore) -> None {
        self._txs: set[str] = `set();
        self._parent: dict[(str, (str | None))] = {};
        self._children: dict[(str, list[str])] = {};
        self._verified: dict[(str, bool)] = {};
    }
}
def load_tx_graph(tx_ids: list[str], spends_edges: list[tuple[(str, str)]]) -> TxStore {
    ts = TxStore();
    for tid in tx_ids {
        ts._txs.add(tid);
        ts._parent[tid] = None;
        ts._children.setdefault(tid, []);
        ts._verified[tid] = False;
    }
    for (child, parent) in spends_edges {
        if ((child in ts._txs) and (parent in ts._txs)) {
            ts._parent[child] = parent;
            ts._children.setdefault(parent, []).append(child);
        }
    }
    return ts;
}
def _recursive_unproven(store: TxStore, `root: str, acc: set[str]) -> None {
    for ch in store._children.get(`root, []) {
        if not store._verified.get(ch, False) {
            acc.add(ch);
        }
        _recursive_unproven(store, ch, acc);
    }
}
def unproven_ancestors(store: TxStore, tx_id: str) -> list[str] {
    if (tx_id not in store._txs) {
        return [];
    }
    out: set[str] = `set();
    seen: set[str] = `set();
    cur = store._parent.get(tx_id);
    queue: deque[str] = deque();
    if (cur is not None) {
        queue.append(cur);
    }
    while queue {
        `node = queue.popleft();
        if (`node in seen) {
            continue;
        }
        seen.add(`node);
        if not store._verified.get(`node, False) {
            out.add(`node);
        }
        nxt = store._parent.get(`node);
        if ((nxt is not None) and (nxt not in seen)) {
            queue.append(nxt);
        }
    }
    extra: set[str] = `set();
    _recursive_unproven(store, tx_id, extra);
    out.update(extra);
    return sorted(out);
}
def mark_verified(store: TxStore, tx_id: str) -> bool {
    if (tx_id not in store._txs) {
        return False;
    }
    store._verified[tx_id] = True;
    return True;
}
def cache_hits(store: TxStore, tx_ids: list[str]) -> list[str] {
    return sorted(
        t
        for t in tx_ids
        if store._verified.get(t, False)
    );
}

