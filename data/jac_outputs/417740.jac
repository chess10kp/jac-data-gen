""" partition split array in half """
def partition(array: list[int]) -> list[list[int]] {
    return [array[len(array) // 2:], array[:len(array) // 2]];
}