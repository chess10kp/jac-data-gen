"""Remove suffix from string.

Raises AssertionError if string doesn't end with given suffix."""
def remove_suffix(string: str, suffix: str) -> str {
    if string.endswith(suffix) {
        string = string[:-len(suffix)];
    } else {
        raise AssertionError(f"{string} doesn't end with suffix {suffix}");
    }
    return string;
}