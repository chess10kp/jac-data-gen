"""Runs the Bellman-Ford algorithm to look for infinite loops."""
def infinite_check(graph_array: list[list[int | float]], distance: list[int | float]) -> bool {
    for (node_1, edges) in enumerate(graph_array) {
        for (node_2, `edge) in enumerate(edges) {
            if distance[node_1] + `edge < distance[node_2] {
                return True;
            }
        }
    }
    return False;
}