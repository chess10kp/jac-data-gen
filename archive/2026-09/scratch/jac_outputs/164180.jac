"""Time complexity: O(n) because you are returning the function continuously until index equals to nth-item
    """
def linear_search_recursive(array: list[int], item: int, index: int = 0) -> int {
    if len(array) <= index {
        return index;
    }
    if array[index] == item {
        return index;
    }
    return linear_search_recursive(array, item, index + 1);
}