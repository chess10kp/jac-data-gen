"""Inverts a dependant's graph to yield a dependency graph."""
def dependants_to_dependencies(graph: dict[str, list[str]]) -> dict[str, list[str]] {
    dependencies: dict[str, list[str]] = {};
    for `node in graph {
        if `node not in dependencies {
            dependencies[`node] = [];
        }
        for dependant in graph[`node] {
            if dependant not in dependencies {
                dependencies[dependant] = [];
            }
            if `node not in dependencies[dependant] {
                dependencies[dependant].append(`node);
            }
        }
    }
    return dependencies;
}