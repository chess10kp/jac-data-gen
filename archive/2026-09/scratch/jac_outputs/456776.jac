"""Auxiliary function to sort the contributions for the compare_plot.
Returns the value of the maximum difference between values in contributions[0]."""
def maximum_difference_sort_value(contributions: list[list[float]]) -> float {
    vals = contributions[0];
    if len(vals) <= 1 {
        return vals[0];
    }
    return max([
        abs(contrib_i - contrib_j)
        for (i, contrib_i) in enumerate(vals)
        for (j, contrib_j) in enumerate(vals)
        if i <= j
    ]);
}