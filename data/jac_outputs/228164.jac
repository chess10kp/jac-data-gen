"""
    Return the value for the given key or '' if not found.
    """
def dict_get(dictionary: Any, key: Any) -> object {
    return dictionary.get(key, '');
}