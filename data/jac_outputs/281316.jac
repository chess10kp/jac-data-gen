"""Convert cumulative array to normal array."""
def cumarray_to_array(ar: list[int | float]) -> list[int | float] {
    return [
        x if i == 0 else ar[i] - ar[i - 1]
        for (i, x) in enumerate(ar)
    ];
}