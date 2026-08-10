"""Calculate threshold for branch_gen function."""
def _threshold_calc(random_edge: int, max_edge: int, vertex_degree: int) -> int {
    return min(random_edge, abs(max_edge - vertex_degree));
}