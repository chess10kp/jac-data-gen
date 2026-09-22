"""Does given bytes object start with the subsequence prefix?

    Compiling bytes.startswith, with no range arguments, compiles this function.
    This function is only intended to be executed in this compiled form.

    Args:
        x: The bytes object to examine.
        prefix: The subsequence to look for.

    Returns:
        Result of check.
    """
def bytes_startswith(x: bytes, prefix: bytes) -> bool {
    if len(x) < len(prefix) {
        return False;
    }
    for (index, i) in enumerate(prefix) {
        if x[index] != i {
            return False;
        }
    }
    return True;
}