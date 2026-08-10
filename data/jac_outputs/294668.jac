"""Return True if the string starts with triple single/double quotes."""
def starts_with_triple(string: str) -> bool {
    stripped = string.strip();
    return stripped.startswith('"""') or stripped.startswith("'''");
}