"""Check if the given list has unique elements."""
def has_duplicates(n: list[int]) -> bool {
    if `type(n) is not list {
        raise TypeError("Given input is not a list");
    }
    return len(n) != len(set(n));
}