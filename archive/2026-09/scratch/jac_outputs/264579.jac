"""
Compute the dependencies of each path var.
"""
def to_dependencies_of(g: dict[str, list[str]]) -> dict[str, list[str]] {
    deps: dict[str, set[str]] = {};
    for (k, vertices) in g.items() {
        for v in vertices {
            if v not in deps {
                deps[v] = set();
            }
            deps[v].add(k);
        }
    }
    return {k: sorted(v) for (k, v) in deps.items()};
}