"""federicodiaz-dev/ImpactLens#28 — reverse dependency reachability for affected files.

Static analyzer discovers dependents of changed files via a reverse graph built
from import edges. Traversal uses an explicit queue and visited set with an
optional maxDepth cap; cycles must not truncate the closure.
"""
import from __future__ { annotations }
import from collections { deque }
class DepGraph {
    def init(self: DepGraph) -> None {
        self.files: dict[(str, bool)] = {};
        self.dependents: dict[(str, list[str])] = {};
    }
    def add_file(self: DepGraph, path: str) -> None {
        self.files[path] = True;
        self.dependents.setdefault(path, []);
    }
    def add_dependency(self: DepGraph, importer: str, imported: str) -> None {
        if ((imported not in self.files) or (importer not in self.files)) {
            return;
        }
        self.dependents[imported].append(importer);
    }
}
def load_graph(files: list[str], depends_on: list[tuple[(str, str)]]) -> DepGraph {
    g = DepGraph();
    for f in files {
        g.add_file(f);
    }
    for (importer, imported) in depends_on {
        g.add_dependency(importer, imported);
    }
    return g;
}
def _walk_dependents(
    g: DepGraph, seeds: list[str], max_depth: (int | None)
) -> dict[(str, int)] {
    depths: dict[(str, int)] = {};
    seen: set[str] = `set();
    q: deque[tuple[(str, int)]] = deque();
    for s in seeds {
        if (s not in g.files) {
            continue;
        }
        q.append((s, 0));
    }
    while q {
        (cur, depth) = q.popleft();
        if (cur in seen) {
            continue;
        }
        seen.add(cur);
        if ((cur not in depths) or (depth < depths[cur])) {
            depths[cur] = depth;
        }
        if ((max_depth is not None) and (depth >= max_depth)) {
            continue;
        }
        for nxt in g.dependents.get(cur, []) {
            if (nxt not in seen) {
                q.append((nxt, (depth + 1)));
            }
        }
    }
    return depths;
}
def affected_files(
    g: DepGraph, changed: list[str], max_depth: (int | None) = None
) -> list[tuple[(str, int)]] {
    depths = _walk_dependents(g, changed, max_depth);
    out = [
        (f, depths[f])
        for f in depths
        if (f not in `set(changed))
    ];
    return sorted(out);
}
def affected_paths(
    g: DepGraph, changed: list[str], max_depth: (int | None) = None
) -> list[str] {
    return sorted(f for (f, _) in affected_files(g, changed, max_depth));
}

