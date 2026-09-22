"""returns the factors of n"""
def factors(n: int) -> list[int] {
    [i for i in range(1, n // 2 + 1) if not n % i] + [n]
}