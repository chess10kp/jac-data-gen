"""Return the number from its prime factors."""
def calcDivisor(factors: dict[int, int]) -> int {
    acc = 1;
    for (f, e) in factors.items() {
        acc *= f ** e;
    }
    return acc;
}