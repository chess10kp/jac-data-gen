"""The number of leading spaces in a string."""
def space_indentation(s: str) -> int {
    return len(s) - len(s.lstrip(" "));
}