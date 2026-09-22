"""Finds the sum of all multiples of 3 and 5 of an integer."""
def find(n: int) -> int {
    sum(x for x in range(n + 1) if x % 5 == 0 or x % 3 == 0)
}