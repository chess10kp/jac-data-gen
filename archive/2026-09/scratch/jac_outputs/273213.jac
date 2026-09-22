"""Return True if name is an API extension name (ends with an upper-case author ID).

This assumes that author IDs are at least two characters."""
def isextension(name: str) -> bool {
    return name[-2:].isalpha() and name[-2:].isupper();
}