"""
    Format the argument so it appears as a memory index.

    See :func:`~.is_memory_index` for details on what a memory index is.

    Args:
        argument (str): The argument to represent as a memory index.
    Returns:
        str: The formatted argument.
    """
def represent_as_memory_index(argument: Any) -> object {
    return "[{argument}]".format(argument=argument);
}