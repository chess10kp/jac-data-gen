"""Returns true if the key is complete. Complete keys are marked
    with a blank symbol at the end of the string. A complete key
    corresponds to a full word, incomplete keys cannot be mapped to
    word IDs.

    Args:
        key (string): The key

    Returns:
        bool. Return true if the last character in ``key`` is blank.
    """
def is_key_complete(key: Any) -> object {
    return (key and (key[-1] == ' '));
}