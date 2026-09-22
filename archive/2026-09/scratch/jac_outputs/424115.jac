"""Determine if there is a route between two nodes."""
def is_route_bfs(graph: dict[int, list[int]], node1: int, node2: int) -> bool {
    queue = [node1];
    visited_nodes = set();
    while queue {
        current_node = queue.pop(0);
        for child_node in graph[current_node] {
            if child_node not in visited_nodes {
                if child_node == node2 {
                    return True;
                }
                queue.append(child_node);
            }
        }
        visited_nodes.add(current_node);
    }
    return False;
}