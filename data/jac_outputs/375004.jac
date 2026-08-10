"""Takes an array and creates a list of combinations from it."""
def create_combinations_from_array[T](array: list[T]) -> list[tuple[T, T]] {
    return [
        (item_1, item_2) for item_1 in array
        for item_2 in array
        if item_1 is not item_2
    ];
}