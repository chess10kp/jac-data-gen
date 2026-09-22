"""Appends arg_name to the front of all values in keys.

    Args:
        arg_name: (string) String containing argument name.
        keys: (list of strings) Possible inputs of argument.

    Returns:
        List of strings with arg_name append to front of keys.
    """
def arg_keys(arg_name: Any, keys: Any) -> object {
    return ["{0}_{1}".format(arg_name, key) for key in keys];
}