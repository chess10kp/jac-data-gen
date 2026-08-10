"""Changeset hash. Returns the short form of a changeset hash,
    i.e. a 12 hexadecimal digit string.
    """
def short(text: str) -> str {
    text[:12]
}