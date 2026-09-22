"""Updates the current maximal number allowed by a factor."""
def update_max_for_sim(m: int, init_max: int, max_allowed: int) -> int {
    max_for_sim = 200 * m + init_max;
    if max_for_sim < max_allowed {
        max_for_sim = max_allowed;
    }
    return max_for_sim;
}