"""The driver holds the lookup dictionary and makes the original function call to rodcut function."""
def driver_function(prices: list[float], n: int) -> str {
    memo: dict[tuple[int, int], float] = {};
    def rodcut(prices: list[float], n: int) -> float {
        max_value = float('-inf');
        if n == 0 or len(prices) <= n {
            return 0;
        }
        for i in range(1, n + 1) {
            cut = (i, n - i);
            if cut in memo {
                cost = memo[cut];
            } else {
                cost = prices[i - 1] + rodcut(prices, n - i);
                memo[cut] = cost;
            }
            if cost > max_value {
                max_value = cost;
            }
        }
        return max_value;
    }
    max_value = rodcut(prices, n);
    printable_prices = [str(price) for price in prices];
    return (
        "For this input:\n\n"
        + "prices: "
        + ", ".join(printable_prices)
        + "\nwood length: "
        + str(n)
        + "\n\nThe solution is:\n\n"
        + str(max_value)
    );
}