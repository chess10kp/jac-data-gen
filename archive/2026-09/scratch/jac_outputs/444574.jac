"""List of N-1 ratios from N proportions."""
def _unpack_proportions(values: list[float]) -> list[float] {
    if len(values) == 1 {
        return [];
    }
    half = len(values) // 2;
    (num, denom) = (sum(values[half:]), sum(values[:half]));
    assert num > 0 and denom > 0;
    ratio = num / denom;
    return [ratio] + _unpack_proportions(values[:half]) + _unpack_proportions(values[half:]);
}