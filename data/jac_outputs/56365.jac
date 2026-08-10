"""
  Gets the highest value the knapsack can carry
  given items of the form [(weight, value)]
  up to a weight W

  Complexity: O(n * S)

  """
def get_optimal_knapsack_value(W: int, items: list[tuple[int, int]]) -> int {
    n = len(items);
    knapsacks: dict[tuple[int, int], int] = dict();
    for i in range(n, -1, -1) {
        for j in range(W + 1) {
            if i == n {
                knapsacks[(i, j)] = 0;
                continue;
            }
            if j == 0 {
                knapsacks[(i, j)] = 0;
                continue;
            }
            (weight, value) = items[i];
            if weight <= j {
                knapsacks[(i, j)] = max(
                    knapsacks[(i + 1, j)],
                    knapsacks[(i + 1, j - weight)] + value
                );
            } else {
                knapsacks[(i, j)] = knapsacks[(i + 1, j)];
            }
        }
    }
    return knapsacks[(0, W)];
}