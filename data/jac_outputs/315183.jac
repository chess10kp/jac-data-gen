"""BFS over an adjacency-list graph starting from start."""
def bfs(graph: list[set[int]], start: int) -> set[int] {
    visited = set();
    queue = [start];
    while queue {
        vertex = queue.pop(0);
        if vertex not in visited {
            visited.add(vertex);
            queue.extend(graph[vertex] - visited);
        }
    }
    return visited;
}