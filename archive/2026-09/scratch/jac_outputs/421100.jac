"""Problem 48: Find the last digits of series n^n (n = 1 to series limit)."""
def problem_48_self_powers(series_limit: int, digits: int) -> str {
    result = 0;
    for number in range(1, series_limit + 1) {
        result += number ** number;
    }
    return str(result)[-digits:];
}