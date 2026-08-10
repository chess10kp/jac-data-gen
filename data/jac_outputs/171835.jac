"""Get the first key from a dictionary."""
def get_akey(d: dict[str, object]) -> str {
    return next(iter(d.keys()));
}