"""Recursively get value from dictionary deep key.

    Args:
        items (list): List of dictionary keys
        data (dict): Portion of dictionary to operate on

    Returns
        object: Value from dictionary

    Raises:
        KeyError: If key does not exist
    """
def get_from(items: Any, data: Any) -> object {
    if not isinstance(data, `dict) {
        raise KeyError;
    }
    item = items.pop(0);
    data = data[item];
    return get_from(items, data) if items else data;
}