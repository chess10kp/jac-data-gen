"""Replaces all negative values with default_value."""
def replace_negative(l: list[int], default_value: int = 0) -> int {
    n_replaced = 0;
    for (i, item) in enumerate(l) {
        if item < 0 {
            l[i] = default_value;
            n_replaced += 1;
        }
    }
    return n_replaced;
}