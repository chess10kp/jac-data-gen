"""docker/sbx-releases#266 — Virtiofs directory tree walk for mutation hotspots."""
import from __future__ { annotations }
import from collections { deque }
class DirStore {
    def init(self: DirStore) -> None {
        self._nodes: set[str] = `set();
        self._kind: dict[(str, str)] = {};
        self._children: dict[(str, list[str])] = {};
    }
}
def load_tree(
    entries: list[tuple[(str, str)]], contains: list[tuple[(str, str)]]
) -> DirStore {
    store = DirStore();
    for (path, kind) in entries {
        store._nodes.add(path);
        store._kind[path] = kind;
        store._children.setdefault(path, []);
    }
    for (parent, child) in contains {
        if ((parent in store._nodes) and (child in store._nodes)) {
            store._children.setdefault(parent, []).append(child);
        }
    }
    return store;
}
def _subtree_paths(store: DirStore, `root: str, seen: set[str]) -> list[str] {
    hits: list[str] = [];
    q: deque[str] = deque(store._children.get(`root, []));
    while q {
        cur = q.popleft();
        if (cur in seen) {
            continue;
        }
        seen.add(cur);
        hits.append(cur);
        for ch in store._children.get(cur, []) {
            q.append(ch);
        }
    }
    return hits;
}
def subtree_file_count(store: DirStore, root_path: str) -> int {
    if (root_path not in store._nodes) {
        return 0;
    }
    seen: set[str] = {root_path};
    count = 0;
    for path in _subtree_paths(store, root_path, seen) {
        if (store._kind.get(path) == "file") {
            count += 1;
        }
    }
    return count;
}
def subtree_paths(store: DirStore, root_path: str) -> list[str] {
    if (root_path not in store._nodes) {
        return [];
    }
    seen: set[str] = {root_path};
    return sorted(_subtree_paths(store, root_path, seen));
}
def max_depth(store: DirStore, root_path: str) -> int {
    if (root_path not in store._nodes) {
        return 0;
    }
    best = 0;
    stack: list[tuple[(str, int)]] = [(root_path, 0)];
    seen: set[str] = {root_path};
    while stack {
        (cur, depth) = stack.pop();
        best = max(best, depth);
        for ch in store._children.get(cur, []) {
            if (ch not in seen) {
                seen.add(ch);
                stack.append((ch, (depth + 1)));
            }
        }
    }
    return best;
}
def entry_kind(store: DirStore, path: str) -> (str | None) {
    return store._kind.get(path);
}

