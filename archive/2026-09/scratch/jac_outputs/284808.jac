"""
The total possible combination number is Xn ... X2 * X1 = total.
"""
def getTotalCombinationNumRecursion(n: int, total: int = 0) -> int {
    if n == 1 {
        return total;
    }
    if total == 0 {
        total = n;
    }
    n -= 1;
    total *= n;
    return getTotalCombinationNumRecursion(n, total);
}