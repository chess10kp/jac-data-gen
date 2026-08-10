"""
    Return the number of ways that `k` stairs can be climbed
    given that you can climb either 1 or 2 stairs at a time
    """
def climb_stairs(k: int) -> int {
    num_ways = [1];
    for idx in range(1, k + 1) {
        one_step = num_ways[idx - 1];
        two_step = num_ways[idx - 2] if idx > 1 else 0;
        num_ways.append(one_step + two_step);
    }
    return num_ways[-1];
}