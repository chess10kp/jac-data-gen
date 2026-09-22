"""
    Binary search recursive function.
    :param bs: int
        What to search
    :param arr: array
        Array of ints where to search. Array must be sorted.
    :return: string
        Position of required element or "cannot found" string
    """
def search(bs: int, arr: list[int]) -> str {
    length = len(arr);
    check_item = arr[int(length / 2)];
    if check_item == bs {
        return str(check_item) + ' is on position ' + str(arr[int(length / 2)]);
    }
    if check_item < bs {
        return search(bs, arr[int(length / 2):]);
    }
    if check_item > bs {
        return search(bs, arr[:int(length / 2)]);
    }
    return "cannot found";
}