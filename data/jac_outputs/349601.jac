"""Calculates the smallest enclosing power of two for an input."""
def _next_power_of_two(x: int | float) -> int {
    1 if x == 0 else 2 ** (int(x) - 1).bit_length()
}