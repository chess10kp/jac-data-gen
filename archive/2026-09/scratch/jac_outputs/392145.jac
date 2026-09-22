"""Splits a string according at the first instance of a divider."""
def split(string: str, divider: str) -> list[str] {
    pieces = string.split(divider);
    return [pieces[0].strip(), divider.join(pieces[1:])];
}