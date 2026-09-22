"""recursive knapsac problem where
    W = max weight knapsack can hold
    val = array of values
    weight = array of weights associated with values
    n = length of the arrays
    """
def knapsack_rec(W: int, val: list[int], weight: list[int], n: int) -> int {
    if n == 0 or W == 0 {
        return 0;
    }
    if weight[n - 1] > W {
        return knapsack_rec(W, val, weight, n - 1);
    }
    return max(
        val[n - 1] + knapsack_rec(W - weight[n - 1], val, weight, n - 1),
        knapsack_rec(W, val, weight, n - 1)
    );
}