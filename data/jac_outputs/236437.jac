"""Computes a modified form of the edge clustering coefficient using squares instead of triangles."""
def edge_clustering_coefficient_4(
    u: int, v: int, degree: dict[int, int], neighbors: dict[int, set[int]]
) -> float {
    udeg = degree[u];
    vdeg = degree[v];
    mdeg = (udeg - 1) * (vdeg - 1);
    if mdeg == 0 {
        return float('inf');
    }
    uneighbors = neighbors[u] - {v};
    vneighbors = neighbors[v] - {u};
    num_squares = 0;
    for w in uneighbors {
        wneighbors = neighbors[w] - {u};
        num_squares += len(wneighbors & vneighbors);
    }
    return (num_squares + 1.0) / mdeg;
}