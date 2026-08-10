def calc_max_num_clones(
    walker_weight: float, min_weight: float, max_num_walkers: int
) -> int {
    n_splits = 2;
    while (walker_weight / n_splits) >= min_weight and n_splits <= max_num_walkers {
        n_splits += 1;
    }
    n_splits -= 1;
    return n_splits - 1;
}