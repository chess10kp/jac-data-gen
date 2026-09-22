"""Helper method to define maximum number of iterations for a given campaign."""
def n_max_iter_heuristics(
    n_data: int, n_query: int, low_bound: int = 5, up_bound: int = 20
) -> int {
    target = round(n_data * 0.25 / n_query);
    if target < low_bound {
        return low_bound;
    }
    return min(target, up_bound);
}