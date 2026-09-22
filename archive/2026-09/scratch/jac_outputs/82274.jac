"""
    Find the shortest paths between nodes using dijkstra algorithm.

    :param list graph: List of lists(adjacency matrix), that represents the graph.
    :param int start: Starting vertex. Search runs from here.

    :returns: List with the shortest paths to all possible nodes from the provided start.
    """
def dijkstra_path(graph: Any, start: Any) -> object {
    graph_length = len(graph);
    is_visited = [False] * graph_length;
    cost = [float("inf")] * graph_length;
    cost[start] = 0;
    min_cost = 0;
    while (min_cost < float("inf")) {
        is_visited[start] = True;
        for (i, vertex) in enumerate(graph[start]) {
            if ((vertex != 0) and not is_visited[i]) {
                if (cost[i] > (vertex + cost[start])) {
                    cost[i] = vertex + cost[start];
                }
            }
        }
        min_cost = float("inf");
        for vertex_index in range(graph_length) {
            if ((min_cost > cost[vertex_index]) and not is_visited[vertex_index]) {
                min_cost = cost[vertex_index];
                start = vertex_index;
            }
        }
    }
    return cost;
}