"""Return the sum of the elements with even index in sequence S."""
def example3(S: list[int | str]) -> int {
    n = len(S);
    total = 0;
    for j in range(n) {
        for k in range(1 + j) {
            total += int(S[k]);
        }
    }
    return total;
}