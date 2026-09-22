"""Assigns the total number of dependencies to each node."""
def _count_dependencies(graph: dict[str, list[str]]) -> dict[str, int] {
    dependency_counter = {parent: 0 for parent in graph};
    for current_node in graph {
        stack: list[tuple[str, int]] = [(current_node, 0)];
        visited = set();
        visited.add(current_node);
        while stack {
            (node, idx) = stack[-1];
            children = graph[node];
            if idx < len(children) {
                stack[-1] = (node, idx + 1);
                child = children[idx];
                if child not in visited {
                    visited.add(child);
                    dependency_counter[current_node] += 1;
                    stack.append((child, 0));
                }
            } else {
                stack.pop();
            }
        }
    }
    return dependency_counter;
}