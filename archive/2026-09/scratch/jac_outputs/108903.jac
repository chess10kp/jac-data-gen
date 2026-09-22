"""Returns n counters after the increment and max operations coded in array."""
def solution(n: int, array: list[int]) -> list[int] {
    counters = [0] * n;
    max_count = 0;
    last_max_value = 0;
    for val in array {
        if val == n + 1 {
            last_max_value = max_count;
        } else {
            if counters[val - 1] < last_max_value {
                counters[val - 1] = last_max_value + 1;
            } else {
                counters[val - 1] += 1;
            }
            if counters[val - 1] > max_count {
                max_count = counters[val - 1];
            }
        }
    }
    return [max(i, last_max_value) for i in counters];
}