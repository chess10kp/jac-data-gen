"""Return the sum of the prefix sums of sequence S."""
def example4(S: list[int]) -> int {
    n = len(S);
    prefix = 0;
    total = 0;
    for j in range(n) {
        prefix += S[j];
        total += prefix;
    }
    return total;
}