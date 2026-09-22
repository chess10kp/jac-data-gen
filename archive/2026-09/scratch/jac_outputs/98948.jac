"""Return [0, 1*multiplier, 2*multiplier, ...]."""
def get_multiples(multiplier: int, count: int) -> list[int] {
    [i * multiplier for i in range(count)]
}