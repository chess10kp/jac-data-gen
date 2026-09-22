"""Compute the induced subgraph formed by a subset of the vertices in a graph."""
def compute_induced_subgraph(
    graph: dict[str, set[str]],
    subgraph_nodes: set[str]
) -> dict[str, set[str]] {
    new_graph = {};
    for (node, children) in graph.items() {
        if node in subgraph_nodes {
            new_graph[node] = children & subgraph_nodes;
        }
    }
    return new_graph;
}