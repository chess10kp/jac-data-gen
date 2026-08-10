"""Returns list of running sums."""
def sum_values(values: list[int], period: int | None = None) -> list[int] {
    if period {
        if period < 1 {
            raise ValueError("period must be 1 or greater");
        }
        period = int(period);
    }
    results: list[int] = [];
    running_sum: int | None = None;
    for (idx, value) in enumerate(values) {
        if running_sum is None {
            running_sum = value;
        } elif not period or idx < period {
            running_sum += value;
        } else {
            old_value = values[idx - period];
            running_sum += value - old_value;
        }
        results.append(running_sum);
    }
    return results;
}