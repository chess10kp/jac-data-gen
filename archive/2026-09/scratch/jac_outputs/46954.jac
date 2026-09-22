"""Ensures that the value is a list.
        If it is not a list, it creates a new list with `value` as an item.

    Args:
        value (object): A list or something else.
        return_empty_list_if_none (bool, optional): When True (default), None you passed as `value`
            will be converted to a empty list (i.e., `[]`). When False, None will be converted to
            a list that has an None (i.e., `[None]`). Defaults to True.
        convert_tuple_to_list (bool, optional): When True (default), a tuple you passed as `value`
            will be converted to a list. When False, a tuple will be unconverted
            (i.e., returning a tuple object that was passed as `value`). Defaults to True.
    Returns:
        list: A list. When `value` is a tuple and `convert_tuple_to_list` is False, a tuple.
    """
def listify[T](
    value: T,
    return_empty_list_if_none: bool = True,
    convert_tuple_to_list: bool = True
) -> list {
    if not isinstance(value, list) {
        if value is None and return_empty_list_if_none {
            value = [];
        } elif isinstance(value, tuple) and convert_tuple_to_list {
            value = list(value);
        } else {
            value = [value];
        }
    }
    return value;
}