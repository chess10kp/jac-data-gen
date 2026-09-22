"""
    Check if an object is a list of integers
    :param value:
    :return:
    """
def is_list_of_int(value: Any) -> object {
    return (
        bool(value)
        and isinstance(value, list)
        and all(isinstance(elem, int) for elem in value)
    );
}