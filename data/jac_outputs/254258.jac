"""Returns the reverse of the given list."""
def reverse_iter(lst: list[int]) -> list[int] {
    reverse: list[int] = [];
    for item in lst {
        reverse.insert(0, item);
    }
    return reverse;
}