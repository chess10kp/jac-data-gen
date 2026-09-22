"""Gives the number of possibilities of n objects chosen r times, order matters"""
def combinations(n: int, r: int) -> object {
    product = 1;
    for i in range(((n - r) + 1), (n + 1)) {
        product *= i;
    }
    for x in range(2, (r + 1)) {
        product /= x;
    }
    return product;
}