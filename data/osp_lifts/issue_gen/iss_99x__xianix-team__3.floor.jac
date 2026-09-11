"""99x/xianix-team#3 — PR merge impact via dependency graph reachability."""
import from __future__ { annotations }
import from collections { deque }
class ModuleGraph {
    def init(self: ModuleGraph) -> None {
        self._modules: set[str] = `set();
        self._deps: dict[(str, set[str])] = {};
        self._rev: dict[(str, set[str])] = {};
    }
}
def load_module_graph(
    modules: list[str], depends: list[tuple[(str, str)]]
) -> ModuleGraph {
    g = ModuleGraph();
    for m in modules {
        g._modules.add(m);
        g._deps.setdefault(m, `set());
        g._rev.setdefault(m, `set());
    }
    for (user, provider) in depends {
        if ((user in g._modules) and (provider in g._modules)) {
            g._deps[user].add(provider);
            g._rev[provider].add(user);
        }
    }
    return g;
}
def _reverse_reach(g: ModuleGraph, seeds: list[str], max_depth: int) -> set[str] {
    q: deque[tuple[(str, int)]] = deque(
        (s, 0)
        for s in seeds
        if (s in g._modules)
    );
    seen: set[str] = `set();
    while q {
        (cur, depth) = q.popleft();
        if (cur in seen) {
            continue;
        }
        seen.add(cur);
        if (depth >= max_depth) {
            continue;
        }
        for rev in sorted(g._rev.get(cur, ())) {
            if (rev not in seen) {
                q.append((rev, (depth + 1)));
            }
        }
    }
    return seen;
}
def impacted_modules(
    g: ModuleGraph, changed: list[str], max_depth: int = 3
) -> list[str] {
    reach = _reverse_reach(g, changed, max_depth);
    return sorted(
        m
        for m in reach
        if (m not in changed)
    );
}
def direct_dependents(g: ModuleGraph, module_id: str) -> list[str] {
    if (module_id not in g._modules) {
        return [];
    }
    return sorted(g._rev.get(module_id, ()));
}
def dependency_closure(g: ModuleGraph, module_id: str) -> list[str] {
    if (module_id not in g._modules) {
        return [];
    }
    stack = [module_id];
    seen: set[str] = `set();
    while stack {
        cur = stack.pop();
        if (cur in seen) {
            continue;
        }
        seen.add(cur);
        for dep in sorted(g._deps.get(cur, ())) {
            stack.append(dep);
        }
    }
    seen.discard(module_id);
    return sorted(seen);
}

