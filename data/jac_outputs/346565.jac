"""
    Bellman ford shortest path algorithm

    Parameters
    ----------
    nodes : set
            names of all nodes in the graph
    edges : list
            list of dependencies between nodes in the graph
            [(node1, node2, weight), ...]
    source : str
            name of source node

    Returns
    -------
    out : (bool, dict)
          (has_cycle, distances) has_cycle var check if cycle in the graph
          distance dict show len from source node to all nodes in the graph

    """
def bellman_ford(
    nodes: set[str],
    edges: list[tuple[str, str, int]],
    source: str
) -> tuple[bool, dict[str, float]] {
    distances = {`node: float('Inf') for `node in nodes};
    distances[source] = 0;
    for _ in range(1, len(nodes)) {
        for (src, dest, weight) in edges {
            if distances[dest] > distances[src] + weight {
                distances[dest] = distances[src] + weight;
            }
        }
    }
    has_cycle = False;
    for (src, dest, weight) in edges {
        if distances[dest] > distances[src] + weight {
            has_cycle = True;
        }
    }
    return (has_cycle, distances);
}