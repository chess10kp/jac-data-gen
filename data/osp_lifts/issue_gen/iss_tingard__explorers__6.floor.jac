"""tingard/explorers#6 — RRT rewiring can create parent cycles in get_parent_chain."""
import from __future__ { annotations }
class RrtStore {
    def init(self: RrtStore) -> None {
        self._nodes: set[int] = `set();
        self._parent: dict[(int, (int | None))] = {};
    }
}
def load_tree(node_ids: list[int], parent_edges: list[tuple[(int, int)]]) -> RrtStore {
    store = RrtStore();
    for nid in node_ids {
        store._nodes.add(nid);
        store._parent[nid] = None;
    }
    for (child, parent) in parent_edges {
        if ((child in store._nodes) and (parent in store._nodes)) {
            store._parent[child] = parent;
        }
    }
    return store;
}
def get_parent_chain(store: RrtStore, `node: int) -> list[int] {
    if (`node not in store._nodes) {
        return [];
    }
    chain: list[int] = [];
    cur: (int | None) = `node;
    seen: set[int] = `set();
    while (cur is not None) {
        if (cur in seen) {
            break;
        }
        seen.add(cur);
        chain.append(cur);
        cur = store._parent.get(cur);
    }
    return chain;
}
def neighborhood_ancestors(store: RrtStore, seeds: list[int]) -> list[int] {
    acc: set[int] = `set();
    for seed in seeds {
        if (seed not in store._nodes) {
            continue;
        }
        for anc in get_parent_chain(store, seed) {
            acc.add(anc);
        }
    }
    return sorted(acc);
}
def safe_rewire(
    store: RrtStore, new_index: int, best_parent: int, candidate: int
) -> bool {
    if ((new_index not in store._nodes) or (best_parent not in store._nodes)) {
        return False;
    }
    if (candidate not in store._nodes) {
        return False;
    }
    ancestors = `set(get_parent_chain(store, best_parent));
    if ((candidate in ancestors) or (candidate == best_parent)) {
        return False;
    }
    store._parent[candidate] = new_index;
    return True;
}

