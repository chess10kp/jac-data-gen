"""Get the first n octagonal numbers."""
def get_octagonals(num: int) -> list[int] {
    [int(i * (3 * i - 2)) for i in range(1, num + 1)]
}