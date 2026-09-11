"""larabail/UrDatabase#18 — Recursive library scan can follow symlink cycles."""
import from __future__ { annotations }
import from collections { deque }
class ScanStore {
    def init(self: ScanStore) -> None {
        self._dirs: set[str] = `set();
        self._children: dict[(str, list[str])] = {};
        self._reparse: set[str] = `set();
    }
}
def load_library(
    dir_names: list[str],
    child_edges: list[tuple[(str, str)]],
    reparse_points: (list[str] | None) = None
) -> ScanStore {
    store = ScanStore();
    for name in dir_names {
        store._dirs.add(name);
        store._children.setdefault(name, []);
    }
    for (parent, child) in child_edges {
        if ((parent in store._dirs) and (child in store._dirs)) {
            store._children.setdefault(parent, []).append(child);
        }
    }
    if reparse_points {
        store._reparse.update(reparse_points);
    }
    return store;
}
def scan_subdirs(
    store: ScanStore, `root: str, follow_links: bool = False
) -> list[str] {
    if (`root not in store._dirs) {
        return [];
    }
    seen: set[str] = `set();
    queue: deque[str] = deque([`root]);
    found: list[str] = [];
    while queue {
        cur = queue.popleft();
        if (cur in seen) {
            continue;
        }
        seen.add(cur);
        found.append(cur);
        for sub in store._children.get(cur, []) {
            if (not follow_links and (sub in store._reparse)) {
                continue;
            }
            if (sub not in seen) {
                queue.append(sub);
            }
        }
    }
    return sorted(found);
}
def reachable_without_guard(
    store: ScanStore, `root: str, max_steps: int = 64
) -> list[str] {
    if (`root not in store._dirs) {
        return [];
    }
    queue: deque[str] = deque([`root]);
    found: list[str] = [];
    steps = 0;
    while (queue and (steps < max_steps)) {
        cur = queue.popleft();
        found.append(cur);
        steps += 1;
        for sub in store._children.get(cur, []) {
            queue.append(sub);
        }
    }
    return sorted(`set(found));
}

