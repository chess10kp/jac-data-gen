"""Uniform prior: 1 if theta is inside parameter_intervals, else 0."""
def prior(theta: tuple[float, ...], parameter_intervals: list[tuple[float, float]]) -> int {
    for index in range(len(theta)) {
        if theta[index] < parameter_intervals[index][0] or theta[index] > parameter_intervals[index][1] {
            return 0;
        }
    }
    return 1;
}