"""BFS: Return visited nodes."""
def bfs_visited(`node: int, graph: dict[int, list[int]]) -> list[int] {
    queue = [`node];
    visited = [];
    while queue {
        current = queue.pop();
        queue[0:0] = [
            neighbor
            for neighbor in graph[current]
            if neighbor not in visited
        ];
        visited.append(current);
    }
    return visited;
}