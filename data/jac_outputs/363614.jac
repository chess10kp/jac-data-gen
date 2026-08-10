"""
        Check if a field exists in a dictionary, and if that field is not None or the empty string.
    """
def filled(f: str, d: dict[str, object]) -> bool {
    return f in d and d[f] is not None and d[f] != "";
}