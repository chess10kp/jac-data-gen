"""
        Binary knapsack solver with identical profits of weight 1.
        Args:
            weights (list) : list of integers
            capacity (int) : maximum capacity
        Returns:
            (int) : maximum number of objects
        """
def _knapsack(weights: list[int], capacity: int) -> int {
    n = len(weights);
    sol = [[0] * (capacity + 1) for i in range(n)];
    added = [[False] * (capacity + 1) for i in range(n)];
    for i in range(n) {
        for j in range(capacity + 1) {
            if weights[i] > j {
                sol[i][j] = sol[i - 1][j];
            } else {
                sol_add = 1 + sol[i - 1][j - weights[i]];
                if sol_add > sol[i - 1][j] {
                    sol[i][j] = sol_add;
                    added[i][j] = True;
                } else {
                    sol[i][j] = sol[i - 1][j];
                }
            }
        }
    }
    return sol[n - 1][capacity];
}