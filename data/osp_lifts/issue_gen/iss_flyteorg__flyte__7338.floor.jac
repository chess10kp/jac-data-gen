"""flyteorg/flyte#7338 — Bounded sync_node_execution tree walk."""
import from __future__ { annotations }
class ExecStore {
    def init(self: ExecStore) -> None {
        self._nodes: set[str] = `set();
        self._parent: dict[(str, (str | None))] = {};
        self._children: dict[(str, list[str])] = {};
    }
}
def load_execution(
    node_ids: list[str], child_edges: list[tuple[(str, str)]]
) -> ExecStore {
    store = ExecStore();
    for nid in node_ids {
        store._nodes.add(nid);
        store._parent[nid] = None;
        store._children.setdefault(nid, []);
    }
    for (parent, child) in child_edges {
        if ((parent in store._nodes) and (child in store._nodes)) {
            store._parent[child] = parent;
            if (child not in store._children[parent]) {
                store._children[parent].append(child);
            }
        }
    }
    return store;
}
def _walk_nodes(store: ExecStore, `root: str, acc: set[str]) -> None {
    for ch in store._children.get(`root, []) {
        if (ch in acc) {
            continue;
        }
        acc.add(ch);
        _walk_nodes(store, ch, acc);
    }
}
def count_nodes(store: ExecStore, `root: str) -> int {
    if (`root not in store._nodes) {
        return 0;
    }
    seen: set[str] = {`root};
    stack = [`root];
    while stack {
        cur = stack.pop();
        for ch in store._children.get(cur, []) {
            if (ch not in seen) {
                seen.add(ch);
                stack.append(ch);
            }
        }
    }
    extra: set[str] = `set(seen);
    _walk_nodes(store, `root, extra);
    return len(extra);
}
def sync_depth(store: ExecStore, `root: str, max_depth: int) -> bool {
    if (`root not in store._nodes) {
        return False;
    }
    depth: dict[(str, int)] = {`root: 0};
    stack = [`root];
    while stack {
        cur = stack.pop();
        for ch in store._children.get(cur, []) {
            nd = depth[cur] + 1;
            if (nd > max_depth) {
                return False;
            }
            if ((ch not in depth) or (nd > depth[ch])) {
                depth[ch] = nd;
                stack.append(ch);
            }
        }
    }
    return True;
}
def max_observed_depth(store: ExecStore, `root: str) -> int {
    if (`root not in store._nodes) {
        return -1;
    }
    depth: dict[(str, int)] = {`root: 0};
    stack = [`root];
    while stack {
        cur = stack.pop();
        for ch in store._children.get(cur, []) {
            nd = depth[cur] + 1;
            if ((ch not in depth) or (nd > depth[ch])) {
                depth[ch] = nd;
                stack.append(ch);
            }
        }
    }
    return max(depth.values()) if depth else 0;
}

