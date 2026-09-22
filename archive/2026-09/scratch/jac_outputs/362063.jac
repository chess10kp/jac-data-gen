"""Reverse the direction of edges in a graph."""
def reverse(graph: list[list[int]]) -> list[list[int]] {
    reverse_graph = [[] for _ in range(len(graph))];
    for (node_idx, children) in enumerate(graph) {
        for child in children {
            reverse_graph[child].append(node_idx);
        }
    }
    return reverse_graph;
}