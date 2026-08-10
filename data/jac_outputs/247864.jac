"""Converts a list-of-lists to a list-of-dicts.

    Ex: [["a","b"],[1, 2],[3, 4]] ---> [{'a': 1, 'b': 2}, {'a': 3, 'b': 4}]

    Args:
        list_list (<list<list>>): A 2d list with a header row. Ex. [['a','b'], [1, 2], [3, 4]]

    Returns:
        <list<dict>>: list-of-dicts. Ex: [{'a': 1, 'b': 2}, {'a': 3, 'b': 4}]
    """
def to_listdict(list_list: Any) -> object {
    return [`dict(zip(list_list[0], i)) for i in list_list[1:]];
}