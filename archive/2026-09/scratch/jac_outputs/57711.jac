"""
    Determines if the squares of array1 is the same as array2.
    :param array1: an array of integers.
    :param array2: an array of integers.
    :return: True if the squares of array1 are the same as array2 otherwise, False.
    """
def comp(array1: Any, array2: Any) -> object {
    if ((array1 is None) or (array2 is None)) {
        return False;
    }
    return (sorted(array2) == sorted((x * x) for x in array1));
}