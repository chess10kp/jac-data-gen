"""Transforms a list into a string.

The entries of the list are seperated by a seperator.
"""
def list_to_string(l: list[str], s: str = "\n") -> str {
    r = "";
    for e in l {
        r += e + s;
    }
    return r;
}