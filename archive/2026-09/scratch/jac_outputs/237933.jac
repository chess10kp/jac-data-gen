"""
    Ternary Search
    Complexity: O(log3(N))

    Requires a unimodal array. That means
    that the array has to be increasing and then
    decreasing (or the opposite). The point is to
    find the maximum (or minimum) element. Small
    modifications needed to work with descending
    and then ascending order as well.
    """
def ternary_search(array: list[int]) -> int {
    lower = 0;
    upper = len(array) - 1;
    while lower < upper {
        first_third = lower + (upper - lower) // 3;
        second_third = upper - (upper - lower) // 3;
        if array[first_third] < array[second_third] {
            lower = first_third + 1;
        } else {
            upper = second_third - 1;
        }
    }
    return lower;
}