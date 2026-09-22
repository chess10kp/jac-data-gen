"""Calculate value of Legendre symbol (a/p)."""
def legendre(a: int, p: int) -> int {
    pow(a, (p - 1) // 2, p)
}