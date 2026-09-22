"""
    Returns true if the row contains a missing value somewhere
    """
def contains_missing(row: list[str]) -> bool {
    return any(e == '?' for e in row);
}