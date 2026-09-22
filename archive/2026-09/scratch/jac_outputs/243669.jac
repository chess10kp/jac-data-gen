"""Generates a complete undirected graph as a dictionary."""
def make_complete_graph(num_nodes: int) -> dict[int, set[int]] {
    ugraph = {};
    full_set = set(range(num_nodes));
    for `node in full_set {
        ugraph[`node] = full_set.difference(set([`node]));
    }
    return ugraph;
}