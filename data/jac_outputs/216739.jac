"""Splits a positive integer into all but its last digit and its last digit."""
def split(n: int) -> tuple[int, int] {
    return (n // 10, n % 10);
}