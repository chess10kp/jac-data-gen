"""Filters items from a list based on callback function return

    Args:
        arr ( list ) : a list to iterate
        func ( function ) : a callback function

    Examples:
        >>> array = Array(1, 2, 3, 4)
        >>> array.filter(lambda item, index: item % 2 == 0)
        [2, 4]
    """
def filter(arr: list[int], func: callable[[int, int], bool]) -> list[int] {
    _arr = [];
    for index in range(len(arr)) {
        if func(arr[index], index) {
            _arr.append(arr[index]);
        }
    }
    return _arr;
}