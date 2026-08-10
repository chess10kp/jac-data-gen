"""Returns whether the given entry in the header is a expected header."""
def is_entry_a_header(key: str, value: str, `entry: str) -> bool {
    return key.lower() in `entry.lower() or value.lower() in `entry.lower();
}