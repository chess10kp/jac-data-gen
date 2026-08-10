"""Compute total number of edges for an undirected graph."""
def num_edges(ugraph: dict[int, list[int]]) -> float {
    total_edges = 0;
    for edges in ugraph.values() {
        total_edges += len(edges);
    }
    return total_edges / 2;
}