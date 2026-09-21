"""
    Count the number of inversions in the given state
    """
def countInversions(state: list[int | str]) -> int {
    n = len(state);
    invs = 0;
    for i in range(n - 1) {
        for j in range(i + 1, n) {
            if 'b' not in (state[i], state[j]) and (state[i] as int) > (state[j] as int) {
                invs += 1;
            }
        }
    }
    return invs;
}