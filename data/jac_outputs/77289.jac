"""This function return the sum of all multiples of 3 and 5."""
def find(n: int) -> int {
    sum(i for i in range(2, n + 1) if not i % 3 or not i % 5)
}