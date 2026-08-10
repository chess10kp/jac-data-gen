"""Parse an integer from a string, or return None for empty input."""
def int_or_none(s: str) -> int | None {
    None if not s else int(s)
}