"""Time Complexity: O(n*k*k). Space Complexity: (n*k)."""
def egg_drop_problem(num_eggs: int, num_floors: int) -> int {
    dp = [[0] * (num_floors + 1) for _ in range(num_eggs + 1)];
    for floor in range(1, num_floors + 1) {
        dp[1][floor] = floor;
    }
    for eggs in range(1, num_eggs + 1) {
        dp[eggs][1] = 1;
    }
    for eggs in range(2, num_eggs + 1) {
        for floor in range(2, num_floors + 1) {
            drops = num_floors;
            for k in range(1, floor) {
                drops = min(drops, 1 + max(dp[eggs - 1][k - 1], dp[eggs][floor - k]));
            }
            dp[eggs][floor] = drops;
        }
    }
    return dp[num_eggs][num_floors];
}