"""
Flatten list of lists into a list
ex:
    [[1, 2], [3]] => [1, 2, 3]

:param lists_of_lists: list(list(elems))
:return: list(elems)
"""
def flatten_lists_of_lists(lists_of_lists: list[list[int]]) -> list[int] {
    return [elem for sublist in lists_of_lists for elem in sublist];
}