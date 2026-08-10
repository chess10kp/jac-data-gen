"""Parse and raise ValueError in case of wrong format."""
def parse_resolution(resolution_string: str) -> tuple[int, int] {
    tokens = resolution_string.split('x');
    if len(tokens) != 2 {
        raise ValueError;
    }
    return tuple(int(t) for t in tokens);
}