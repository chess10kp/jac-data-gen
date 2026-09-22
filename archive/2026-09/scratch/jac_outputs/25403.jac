"""Scales all the edge-weights described by a dictionary."""
def scale_edge_weights(
    edge_weights: dict[tuple[int | str, int | str], float], w: float
) -> dict[tuple[int | str, int | str], float] {
    return {
        (n1, n2): w * edge_weights[(n1, n2)]
        for (n1, n2) in edge_weights
    };
}