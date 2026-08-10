"""Removes trailing whitespace from the given lines."""
def strip_trailing_whitespace(lines: Any) -> object {
    return [(line.rstrip() + '\n') for line in lines];
}