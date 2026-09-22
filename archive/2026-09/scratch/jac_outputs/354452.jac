"""
    Simple method to return the index of the first element of a list that is greater than a specified value.

    Args:
        list: List of floats
        value: The value that the element must be greater than
    """
def find_first_list_element_above(`list: Any, value: Any) -> object {
    return next(
        x[0]
        for x in enumerate(`list)
        if (x[1] > value)
    );
}