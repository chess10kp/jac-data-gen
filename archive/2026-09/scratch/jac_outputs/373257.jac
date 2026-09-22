"""
    Simple method to return the index of the first element of a list that is greater than a specified value.

    Args:
        a_list: List of floats
        value: The value that the element must be greater than
    """
def find_first_list_element_above(a_list: Any, value: Any) -> object {
    if (max(a_list) <= value) {
        ValueError('The requested value is greater than max(a_list)');
    }
    for (i, val) in enumerate(a_list) {
        if (val > value) {
            return i;
        }
    }
}