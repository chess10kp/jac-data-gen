"""Splits the input string by whitespace, returning a list of non-whitespace components."""
def string_to_list(s: str) -> list[str] {
    return list(filter(lambda (x: str) { x; }, s.strip().split(' ')));
}