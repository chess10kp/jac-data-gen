"""numba/numba#9316 — Per-function cache invalidation via global dependency reach."""
import from __future__ { annotations }
import from collections { deque }
class CacheStore {
    def init(self: CacheStore) -> None {
        self._funcs: set[str] = `set();
        self._globals: set[str] = `set();
        self._uses: dict[(str, list[str])] = {};
        self._dependents: dict[(str, list[str])] = {};
    }
}
def load_cache_graph(
    func_names: list[str], global_names: list[str], use_edges: list[tuple[(str, str)]]
) -> CacheStore {
    store = CacheStore();
    for fn in func_names {
        store._funcs.add(fn);
        store._uses.setdefault(fn, []);
    }
    for g in global_names {
        store._globals.add(g);
        store._dependents.setdefault(g, []);
    }
    for (fn, gl) in use_edges {
        if ((fn in store._funcs) and (gl in store._globals)) {
            store._uses.setdefault(fn, []).append(gl);
            store._dependents.setdefault(gl, []).append(fn);
        }
    }
    return store;
}
def invalidated_by_global(store: CacheStore, changed: list[str]) -> list[str] {
    seen: set[str] = `set();
    queue: deque[str] = deque(
        ch
        for ch in changed
        if (ch in store._globals)
    );
    while queue {
        gl = queue.popleft();
        for fn in store._dependents.get(gl, []) {
            if (fn not in seen) {
                seen.add(fn);
            }
        }
    }
    return sorted(seen);
}
def globals_for_func(store: CacheStore, func: str) -> list[str] {
    if (func not in store._funcs) {
        return [];
    }
    return sorted(store._uses.get(func, []));
}
def would_invalidate(store: CacheStore, func: str, global_name: str) -> bool {
    if ((func not in store._funcs) or (global_name not in store._globals)) {
        return False;
    }
    return (global_name in store._uses.get(func, []));
}

