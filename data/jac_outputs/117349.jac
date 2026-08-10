"""Takes a string representation of a comma separated list and returns a list
of elements with trimmed whitespace."""
def parse_list(raw: str) -> list[str] {
    return [word.strip() for word in raw.split(",")];
}