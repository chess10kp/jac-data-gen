"""Prints the content of a list."""
def print_array(arr: list[int | str | float]) -> str {
    return ' '.join(str(a) for a in arr);
}