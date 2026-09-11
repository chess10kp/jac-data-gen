"""05798/pytest-git-selector#19 — Import dep graph reverse closure to tests."""
import from __future__ { annotations }
class ImportGraph {
    def init(self: ImportGraph) -> None {
        self._nodes: set[str] = `set();
        self._pred: dict[(str, set[str])] = {};
        self._rev: dict[(str, set[str])] = {};
        self._tests: set[str] = `set();
    }
}
def load_import_graph(
    files: list[str], deps: list[tuple[(str, str)]], tests: list[str]
) -> ImportGraph {
    g = ImportGraph();
    for f in files {
        g._nodes.add(f);
        g._pred.setdefault(f, `set());
        g._rev.setdefault(f, `set());
    }
    for (user, provider) in deps {
        if ((user not in g._nodes) or (provider not in g._nodes)) {
            continue;
        }
        g._pred[user].add(provider);
        g._rev[provider].add(user);
    }
    g._tests = `set(tests);
    return g;
}
def _reverse_closure(g: ImportGraph, seeds: list[str]) -> set[str] {
    stack = `list(seeds);
    seen: set[str] = `set();
    while stack {
        cur = stack.pop();
        if (cur in seen) {
            continue;
        }
        if (cur not in g._nodes) {
            continue;
        }
        seen.add(cur);
        for rev in g._rev.get(cur, ()) {
            if (rev not in seen) {
                stack.append(rev);
            }
        }
    }
    return seen;
}
def tests_for_changes(g: ImportGraph, changed: list[str]) -> list[str] {
    reachable = _reverse_closure(g, changed);
    hits = sorted(
        f
        for f in reachable
        if (f in g._tests)
    );
    return hits;
}

