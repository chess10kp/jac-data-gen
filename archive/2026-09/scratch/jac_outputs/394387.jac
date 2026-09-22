"""Count distinct ways to climb n stairs taking 1 or 2 steps at a time."""
def climbStairs(n: int, dic: dict[int, int] = {0: 0, 1: 1, 2: 2}) -> int {
    if n in dic {
        return dic[n];
    }
    dic[n] = climbStairs(n - 1, dic) + climbStairs(n - 2, dic);
    return dic[n];
}