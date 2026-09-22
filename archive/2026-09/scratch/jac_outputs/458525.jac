"""Strip any whitespace then outer characters."""
def parse_tuple(tuple_string: str) -> str {
    return tuple_string.strip().strip("\"[]");
}