"""pasca-l/book-reading#9 — Naive tree adjacency descendants and ancestor path."""
import from __future__ { annotations }
class TreeStore {
    def init(self: TreeStore) -> None {
        self._nodes: set[str] = `set();
        self._parent: dict[(str, (str | None))] = {};
        self._children: dict[(str, list[str])] = {};
    }
}
def load_tree(
    nodes: list[str], parent_edges: list[tuple[(str, (str | None))]]
) -> TreeStore {
    t = TreeStore();
    for nid in nodes {
        t._nodes.add(nid);
        t._children.setdefault(nid, []);
    }
    for (nid, par) in parent_edges {
        if (nid not in t._nodes) {
            continue;
        }
        t._parent[nid] = par;
        if ((par is not None) and (par in t._nodes)) {
            t._children.setdefault(par, []).append(nid);
        }
    }
    return t;
}
def _recursive_descendants(store: TreeStore, `root: str, acc: set[str]) -> None {
    for ch in sorted(store._children.get(`root, [])) {
        if (ch in acc) {
            continue;
        }
        acc.add(ch);
        _recursive_descendants(store, ch, acc);
    }
}
def tree_descendants(store: TreeStore, node_id: str) -> list[str] {
    if (node_id not in store._nodes) {
        return [];
    }
    acc: set[str] = {node_id};
    _recursive_descendants(store, node_id, acc);
    return sorted(acc);
}
def ancestor_path(store: TreeStore, node_id: str) -> list[str] {
    if (node_id not in store._nodes) {
        return [];
    }
    chain: list[str] = [node_id];
    claimed: set[str] = {node_id};
    cur = node_id;
    while True {
        parent = store._parent.get(cur);
        if ((parent is None) or (parent in claimed)) {
            break;
        }
        claimed.add(parent);
        chain.append(parent);
        cur = parent;
    }
    return chain;
}

