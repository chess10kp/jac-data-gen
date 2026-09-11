"""dmidlo/histdata.com-tools#693 — Feature lineage DAG ancestor expansion."""
import from __future__ { annotations }
import from collections { deque }
class LineageStore {
    def init(self: LineageStore) -> None {
        self._nodes: set[str] = `set();
        self._parents: dict[(str, list[str])] = {};
        self._children: dict[(str, list[str])] = {};
    }
}
def load_nodes(
    node_ids: list[str], parent_edges: list[tuple[(str, str)]]
) -> LineageStore {
    ls = LineageStore();
    for nid in node_ids {
        ls._nodes.add(nid);
        ls._parents.setdefault(nid, []);
        ls._children.setdefault(nid, []);
    }
    for (child, parent) in parent_edges {
        if ((child in ls._nodes) and (parent in ls._nodes)) {
            ls._parents.setdefault(child, []).append(parent);
            ls._children.setdefault(parent, []).append(child);
        }
    }
    return ls;
}
def _recursive_ancestors(store: LineageStore, `root: str, acc: set[str]) -> None {
    for p in store._parents.get(`root, []) {
        if (p in acc) {
            continue;
        }
        acc.add(p);
        _recursive_ancestors(store, p, acc);
    }
}
def ancestor_hashes(store: LineageStore, node_id: str) -> list[str] {
    if (node_id not in store._nodes) {
        return [];
    }
    seen: set[str] = `set();
    queue: deque[str] = deque([node_id]);
    out: set[str] = `set();
    while queue {
        cur = queue.popleft();
        for p in store._parents.get(cur, []) {
            if (p not in seen) {
                seen.add(p);
                out.add(p);
                queue.append(p);
            }
        }
    }
    closure: set[str] = `set(out);
    _recursive_ancestors(store, node_id, closure);
    return sorted(closure);
}
def dependents_of(store: LineageStore, node_id: str) -> list[str] {
    if (node_id not in store._nodes) {
        return [];
    }
    seen: set[str] = {node_id};
    stack: list[str] = `list(store._children.get(node_id, []));
    out: set[str] = `set();
    while stack {
        cur = stack.pop();
        if (cur in seen) {
            continue;
        }
        seen.add(cur);
        out.add(cur);
        for ch in store._children.get(cur, []) {
            stack.append(ch);
        }
    }
    return sorted(out);
}
def is_acyclic(store: LineageStore) -> bool {
    indeg = {n: len(store._parents.get(n, [])) for n in store._nodes};
    queue: deque[str] = deque(
        [
            n
            for n in store._nodes
            if (indeg[n] == 0)
        ]
    );
    seen = 0;
    while queue {
        u = queue.popleft();
        seen += 1;
        for ch in store._children.get(u, []) {
            indeg[ch] -= 1;
            if (indeg[ch] == 0) {
                queue.append(ch);
            }
        }
    }
    return (seen == len(store._nodes));
}

