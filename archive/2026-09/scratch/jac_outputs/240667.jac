"""
    input: [7, 1, 5, 3, 6, 4]
    diff : [X, -6, 4, -2, 3, -2]
    """
def max_profit_optimized(prices: list[int]) -> int {
    (cur_max, max_so_far) = (0, 0);
    for i in range(1, len(prices)) {
        cur_max = max(0, cur_max + prices[i] - prices[i - 1]);
        max_so_far = max(max_so_far, cur_max);
    }
    return max_so_far;
}