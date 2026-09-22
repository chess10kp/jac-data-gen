"""Returns products of first_list with second_list shifted by one index."""
def get_shifted_product(first_list: list[int], second_list: list[int]) -> list[int] {
    shifted_second_list = second_list[1:];
    return [(a * b) for (a, b) in zip(first_list, shifted_second_list)];
}