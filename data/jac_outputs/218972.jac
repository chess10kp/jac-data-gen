"""Sums up edge weights by adding the minum of w1 and w2. This results
    in lower weighted edges for margin figures.
    """
def sum_min_edge_weight(acc: float, w1: float, w2: float) -> float {
    return acc + min(w1, w2);
}