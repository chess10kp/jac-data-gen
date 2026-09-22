"""Return greatest item in seq for which item < val applies."""
def max_lt(seq: list[int], val: int) -> int {
    max = 0;
    idx = len(seq) - 1;
    while idx >= 0 {
        if seq[idx] < val and seq[idx] >= 0 and seq[idx] > max {
            max = seq[idx];
        }
        idx -= 1;
    }
    return max;
}