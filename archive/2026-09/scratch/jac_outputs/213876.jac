"""Returns the span of array: the difference between the last and
first elements, or array[array.length-1] - array[0]."""
def span(array: list[int]) -> int {
    array[-1] - array[0]
}