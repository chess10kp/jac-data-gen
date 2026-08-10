"""Determine the nth digit of an integer, starting at the right and counting from zero."""
def _nth_digit(i: int, n: int) -> int {
    return (i // (10 ** n)) % 10;
}