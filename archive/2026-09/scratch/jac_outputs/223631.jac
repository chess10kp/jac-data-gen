"""Breath first search on a given graph."""
def bfs(graph: dict[str, set[str]], start: str, goal: str) -> list[str] {
    queue = [(start, [start])];
    while queue {
        (vertex, path) = queue.pop(0);
        for next_node in graph[vertex] - set(path) {
            if next_node == goal {
                return path + [next_node];
            }
            queue.append((next_node, path + [next_node]));
        }
    }
    return [];
}