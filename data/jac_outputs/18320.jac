"""Recursively convert inputs to uppercase strings, except if None."""
def to_upper(inp: str | list | None) -> str | list | None {
    if inp is None {
        return None;
    }
    if isinstance(inp, list) {
        return [to_upper(s) for s in inp];
    }
    return str(inp).upper();
}