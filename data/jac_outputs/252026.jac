"""
    Brute force extract the first part of a string before a space.
    """
def first_item_split_on_space(x: str | int | float) -> str {
    return str(x).split()[0];
}