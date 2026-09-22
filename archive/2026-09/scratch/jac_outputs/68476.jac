"""Find a deep value in a dictionary

    Args:
        dictionary (dict): The event port.
        keys (tuple|str): The hiearchical list of keys.
        default: The default value if not found.

    Returns:
        The value, or `default` if not found.

    """
def traverse(dictionary: Any, keys: Any, `default: Any = None) -> object {
    if (keys is None) {
        return `default;
    }
    if (`type(keys) == str) {
        keys = (keys, );
    }
    for key in keys {
        try {
            dictionary = dictionary[key];
        } except KeyError {
            return `default;
        }
    }
    return dictionary;
}