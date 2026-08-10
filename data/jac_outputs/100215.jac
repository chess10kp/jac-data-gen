glob MAX_UNIT = 1;

"""Computes free space on the figure on both sides."""
def center(width: float, n: int) -> tuple[float, float] {
    free_space = max(0.0, (width - n * MAX_UNIT) / MAX_UNIT);
    free_left = free_space / 2.0;
    free_right = free_space / 2.0;
    return (free_left, free_right);
}