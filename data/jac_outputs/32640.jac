"""Either takes the last element or it doesn't.

This algorithm takes exponential time."""
def _recursive_01_knapsack_aux(capacity: int, w: list[int], v: list[int], value: int) -> int {
    if capacity == 0 {
        return 0;
    }
    if len(w) > 0 and len(v) > 0 {
        if w[-1] > capacity {
            value = _recursive_01_knapsack_aux(capacity, w[:-1], v[:-1], value);
        } else {
            value = max(
                v[-1] + _recursive_01_knapsack_aux(capacity - w[-1], w[:-1], v[:-1], value),
                _recursive_01_knapsack_aux(capacity, w[:-1], v[:-1], value)
            );
        }
    }
    return value;
}