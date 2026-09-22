"""
    Returns a integer object from a string object.
    """
def process_immediate(immediate: Any) -> object {
    if not isinstance(immediate, str) {
        raise TypeError('Immediate must be a String object.');
    }
    if immediate.startswith("0x") {
        return int(immediate, 16);
    } else {
        return int(immediate);
    }
}